REFRESH_SETUP_DELAY = 1000
RECONNECT_DELAY = 100
RECONNECT_BACKOFF_FACTOR = 2
DEV_MODE = false

# Set up a new socket if there's no active socket.
connect = ->
	if not socket or not (socket.socket.connecting or socket.socket.connected)
		return socket = io.connect location.protocol + '//' + location.host
socket = connect()

# Ping the server until it's successful, then refresh.
reconnect = (delay) ->
	clearTimeout reconnect.t
	reconnect.t = setTimeout(->
		reconnect delay * RECONNECT_BACKOFF_FACTOR
		if DEV_MODE
			getJson '/ping', (data) ->
				clearTimeout reconnect.t
				refresh()
		else
			socket = connect()
	, delay)

# Refresh the browser.
refresh = ->
	location.reload()

# When the server disconnects, try to reconnect.
socket.on 'disconnect', ->
	reconnect RECONNECT_DELAY
	showConnectionStatus 'off'

# When the server reconnects, cancel reconnection retries.
socket.on 'connect', ->
	clearTimeout reconnect.t
	showConnectionStatus 'on'

# Wait to listen for refresh signals in case lingering calls trickle in.
setTimeout(->
	socket.on 'refresh', refresh
, REFRESH_SETUP_DELAY)

