app.get '/radedit', (request, response) ->
	response.view 'radedit/editor'


readFile = (rel, callback) ->
	path = documentRoot + '/' + rel
	fs.readFile path, (err, content) ->
		code = ('' + content).replace /\r/g, ''
		file =
			version: 0
			rel: rel
			code: code
			savedCode: code
			clients: {}
		loader.cache[rel] = file
		callback file

writeFile = (rel) ->
	file = loader.cache[rel]
	file.savedCode = file.code
	path = documentRoot + '/' + rel
	fs.writeFile path, file.code, ->
		loader.loadFile path, true



io.connect (socket) ->

	closeCurrentFile = ->
		rel = socket.currentRel
		file = loader.cache[rel]
		if file
			delete file.clients[socket.id]

	sendFile = (file) ->
		file.clients[socket.id] = socket
		socket.currentRel = file.rel
		socket.emit 'radedit:got',
			rel: file.rel
			code: file.code
			canSave: (file.code isnt file.savedCode) 
	
	socket.on 'disconnect', ->
		closeCurrentFile()

	socket.on 'radedit:get', (json) ->
		rel = json.rel
		if socket.currentRel isnt rel
			closeCurrentFile()

		file = loader.cache[rel]
		if file
			sendFile file
		else
			readFile rel, sendFile

	socket.on 'radedit:change', (json) ->
		rel = json.rel
		change = json.change
		file = loader.cache[rel]
		if file
			code = file.code
			from = change[0]
			to = from + change[1]
			text = change[2]
			file.code = code.substr(0, from) + text + code.substr(to)
			for id, client of file.clients
				if id isnt socket.id
					client.emit 'radedit:changed', json

	socket.on 'radedit:save', (json) ->
		writeFile json.rel

	if loader.treeString
		socket.emit 'radedit:tree', loader.treeString
	
	if log.lines
		socket.emit 'radedit:log', log.lines

	process.on 'radedit:log', (lines) ->
		socket.emit 'radedit:log', lines

