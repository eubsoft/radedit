socketIo = require 'socket.io'
radedit = require 'radedit'
app = radedit.app
config = radedit.config
log = radedit.log

io = module.exports = socketIo.listen app.listener, {log: false}

suffix = if config.port is 80 then '' else ':' + config.port
location = "http://localhost#{suffix}/"

log.info "Listening at #{location}"

io.connect = (callback) ->
	io.sockets.on 'connection', callback

io.connect (socket) ->

	socket.on 'error', (error) ->
		log error