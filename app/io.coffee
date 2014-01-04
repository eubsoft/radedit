socketIo = require 'socket.io'
radedit = require 'radedit'
app = radedit.app
config = radedit.config
log = radedit.log

io = module.exports = socketIo.listen app.listener, {log: false}

log.info "Listening on port #{config.port}."

io.connect = (callback) ->
	io.sockets.on 'connection', callback

io.connect (socket) ->

	socket.on 'error', (error) ->
		log error