fs = require 'fs'

radedit = require 'radedit'
app = radedit.app
appPath = radedit.appPath
io = radedit.io
loader = radedit.loader
log = radedit.log

SOCKET_EMIT_DELAY = 0 # Modify for testing latency, but don't commit anything but 0.

app.get '/radedit', (request, response) ->
	response.view 'radedit/editor'


readFile = (rel, callback, emissionId) ->
	path = appPath + '/' + rel
	fs.readFile path, (err, content) ->
		code = ('' + content).replace /\r/g, ''
		file =
			version: 0
			rel: rel
			code: code
			savedCode: code
			clients: {}
			transforms: {}
		loader.cache[rel] = file
		callback file, emissionId

writeFile = (rel) ->
	file = loader.cache[rel]
	file.savedCode = file.code
	path = appPath + '/' + rel
	loader.loadFile path, file.code
	fs.writeFile path, file.code



io.connect (socket) ->
	
	# Track the number of edits that have been incorporated.
	socket.editCounts = {}

	closeCurrentFile = ->
		file = socket.currentFile
		if file
			delete file.clients[socket.id]

	sendFile = (file, emissionId) ->
		file.clients[socket.id] = socket
		socket.currentFile = file
		socket.emit 'radedit:got',
			EID: emissionId
			rel: file.rel
			code: file.code
			version: file.version
			canSave: (file.code isnt file.savedCode) 
	
	socket.on 'disconnect', ->
		closeCurrentFile()

	socket.on 'radedit:get', (json) ->
		rel = json.rel
		file = loader.cache[rel]
		if file
			sendFile file, json.EID
		else
			readFile rel, sendFile, json.EID

		if socket.currentFile isnt file
			closeCurrentFile()

	# Incorporate a new change from a client.
	socket.on 'radedit:change', (json) ->
		EID = json.EID # Emission ID for relating the response to the request.
		rel = json.rel # Relative file path.
		edits = json.edits # Array of CodeMirror edits.
		version = json.version # Version to which edits are being applied.

		# The client retrieved the file before editing, so it should be in cache.
		file = loader.cache[rel]
		if not file
			return log.error "Received change for non-existent file: #{rel}"

		# Get the number of edits that this client has already made to this version.
		versionKey = "#{rel}|v#{version}"
		editCount = socket.editCounts[versionKey] or 0
		newEdits = []

		# Apply any new edits.
		for edit, index in edits

			# Some edits may have already been applied.
			if index > editCount - 1

				# If the client was working with an old version, we must transform its edits.
				if json.version < file.version
					for version in [json.version .. file.version - 1]

						transform = file.transforms["v#{version}"]
						if transform.author isnt socket.id
							log.debug "Need to apply transform #{version}: " + JSON.stringify transform
							# TODO: Apply transform.
							for t in transform
								start = t[0]
								deleted = t[1]
								end = start + deleted
								inserted = t[2].length
								
								# If the transform started left of the edit, adjust.
								if start <= edit[0]
									# If the transform finished left of the edit, shift the edit.
									if end <= edit[0]
										edit[0] += inserted - deleted
									# If the transform encloses the edit, nullify the edit.
									else if end >= edit[0] + edit[1]
										edit[1] = 0
										edit[2] = ''
									# TODO: What if the transform partially encloses the edit?

				code = file.code
				from = edit[0]
				to = from + edit[1]
				text = edit[2]

				# Record the transformed edit for broadcast.
				newEdits.push edit

				# Apply the transformed edit
				file.code = code.substr(0, from) + text + code.substr(to)

		if newEdits.length
			# Remember how many edits have been applied to this version by this client.
			socket.editCounts[versionKey] = edits.length
	
			sendChangeToClient = (json, client) ->
				setTimeout(->
					if client is socket
						json.EID = EID
					else
						delete json.EID
					client.emit 'radedit:changed', json
				, SOCKET_EMIT_DELAY * Math.random())
	
			# We should only send the edits that haven't been previously applied.
			json.edits = newEdits
			# Clients must apply edits to the same version as the server.
			json.version = file.version
			# Broadcast changes to the clients that are connected to this file.
			for own id, client of file.clients
				sendChangeToClient json, client
	
			newEdits.author = socket.id
			file.transforms["v#{file.version}"] = newEdits
			file.version++

	socket.on 'radedit:save', (json) ->
		writeFile json.rel

	if loader.treeString
		socket.emit 'radedit:tree', loader.treeString
	
	if log.lines
		socket.emit 'radedit:log', log.lines

	process.on 'radedit:log', (lines) ->
		socket.emit 'radedit:log', lines


