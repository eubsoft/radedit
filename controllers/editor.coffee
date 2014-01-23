fs = require 'fs'

radedit = require 'radedit'
app = radedit.app
appPath = radedit.appPath
io = radedit.io
loader = radedit.loader
log = radedit.log

SOCKET_EMIT_DELAY = 0 # Modify for testing latency, but don't commit anything but 0.
VERSION_INDEX = 3
EDIT_INDEX = 4
AUTO_SAVE_INDEX = 5

app.get '/radedit', (request, response) ->
	rel = request.query.rel
	respond = (file) ->
		response.view 'radedit/editor', {file: file}
	if rel?
		getFile rel, (file) ->
			v = file.version
			r = stringify rel
			c = stringify file.code
			s = file.code isnt file.savedCode
			respond "{version:#{v},rel:'#{r}',code:'#{c}',canSave:#{s}}"
	else
		respond null


stringify = (string) ->
	string = string.replace /\\/g, "\\\\"
	string = string.replace /'/g, "\\'"
	string = string.replace /\n/g, "\\n"
	return string


getFile = (rel, callback) ->
	file = loader.cache[rel]
	if file
		callback file
	else
		readFile rel, callback


readFile = (rel, callback) ->
	path = appPath + '/' + rel
	fs.readFile path, (err, content) ->
		if err
			log.warn "Could not open file (#{path}) for editing. Assuming empty."
			if not content?
				content = ''
		code = ('' + content).replace /\r/g, ''
		file =
			version: 0
			rel: rel
			code: code
			savedCode: code
			clients: {}
			transforms: {}
		loader.cache[rel] = file
		callback file

writeFile = (rel) ->
	file = loader.cache[rel]
	file.savedCode = file.code
	path = appPath + '/' + rel
	loader.loadFile path, file.code
	fs.writeFile path, file.code


io.connect (socket) ->

	socket.currentFile = null
	socket.nextEdit = {}
	socket.edits = {}

	closeCurrentFile = ->
		file = socket.currentFile
		if file
			delete file.clients[socket.id]

	connectToFile = (file) ->
		rel = file.rel
		socket.currentFile = file
		socket.nextEdit[rel] = 0
		socket.edits[rel] = {}
		file.clients[socket.id] = socket

	sendFile = (file, emissionId) ->
		connectToFile file
		socket.emit 'radedit:got',
			EID: emissionId
			rel: file.rel
			code: file.code
			version: file.version
			canSave: (file.code isnt file.savedCode)
	
	socket.on 'disconnect', ->
		closeCurrentFile()


	socket.on 'radedit:get', (json) ->
		getFile json.rel, (file) ->
			sendFile file, json.EID
			if socket.currentFile isnt file
				closeCurrentFile()

	# Incorporate a new edit from a client.
	socket.on 'radedit:edit', (json) ->
		EID = json.EID # Emission ID for relating the response to the request.
		rel = json.rel # Relative file path.
		edit = json.edit # CodeMirror change.

		if json.autoSave
			edit[AUTO_SAVE_INDEX] = true

		# The client retrieved the file before editing, so it should be in cache.
		file = loader.cache[rel]
		if not file
			return log.error "Received change for non-existent file: #{rel}"

		# If this client hasn't edited the file yet, connect.
		if not socket.nextEdit[rel]
			connectToFile file

		nextEdit = socket.nextEdit[rel]
		editNumber = edit[EDIT_INDEX]

		# If this edit is present or future, queue it for integration.
		if editNumber >= nextEdit
			edit[EDIT_INDEX] = EID
			socket.edits[rel]["e#{editNumber}"] = edit
			integrateEdits file


	integrateEdits = (file) ->
		rel = file.rel
		edits = socket.edits[rel]
		nextEdit = socket.nextEdit[rel]
		edit = edits["e#{nextEdit}"]

		# If the next edit isn't there yet, we can try later.
		if not edit
			return

		# If the client was working with an old version, we must transform its edits.
		fromVersion = edit[VERSION_INDEX]
		if fromVersion < file.version
			# Iterating from the source version to the last version gets us up to date.
			for version in [fromVersion .. file.version - 1]
				applyTransform file, version, edit

		# Apply the transformed edit.
		from = edit[0]
		to = from + edit[1]
		text = edit[2]
		file.code = file.code.substr(0, from) + text + file.code.substr(to)

		if edit[AUTO_SAVE_INDEX]
			loader.processFile appPath + '/' + rel, file.code

		# Broadcast changes to the clients that are connected to this file.
		json =
			EID: edit[EDIT_INDEX]
			rel: file.rel
			edit: edit

		edit[VERSION_INDEX] = file.version
		edit.length = EDIT_INDEX
		socketEmit socket, 'radedit:edited', json
		delete json.EID
		for own id, client of file.clients
			if id isnt socket.id
				socketEmit client, 'radedit:edited', json

		edit[EDIT_INDEX] = socket.id
		file.transforms["v#{file.version}"] = edit
		file.version++

		# Call this function again in case another edit is queued.
		socket.nextEdit[rel]++
		integrateEdits file


	applyTransform = (file, version, edit) ->
		transform = file.transforms["v#{version}"]
		if transform[EDIT_INDEX] isnt socket.id

			# Apply the transform.
			start = transform[0]
			deleted = transform[1]
			end = start + deleted
			inserted = transform[2].length

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
				else
					log.warn "Unhandled transformation (partially enclosed)."

	socket.on 'radedit:save', (json) ->
		writeFile json.rel


	if loader.treeString
		socket.emit 'radedit:tree', loader.treeString

	
	if log.lines
		socket.emit 'radedit:log', log.lines

	process.on 'radedit:log', (lines) ->
		socket.emit 'radedit:log', lines



socketEmit = (client, tag, json) ->
	jsonToSend = JSON.parse JSON.stringify json
	setTimeout(->
		client.emit tag, jsonToSend
	, SOCKET_EMIT_DELAY * Math.random())
