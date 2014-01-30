#NOCLOSURE

REFRESH_SETUP_DELAY = 1000
RECONNECT_DELAY = 100
RECONNECT_BACKOFF_FACTOR = 2
SOCKET_EMIT_DELAY = 0 # Modify for testing latency, but don't commit anything but 0.
SOCKET_EMIT_RETRY_COUNT = 5
SOCKET_EMIT_RETRY_TIMEOUT = 500

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
		socket = connect()
	, delay)

# Refresh the browser.
refresh = ->
	#location.reload()

# When the server disconnects, try to reconnect.
socketOn 'disconnect', ->
	reconnect RECONNECT_DELAY
	showConnectionStatus '_OFF'

# When the server reconnects, cancel reconnection retries.
socketOn 'connect', ->
	clearTimeout reconnect.t
	showConnectionStatus '_ON'

# Wait to listen for refresh signals in case lingering calls trickle in.
setTimeout(->
	socketOn 'refresh', refresh
, REFRESH_SETUP_DELAY)

# Try to emit data, and optionally retry.
socketEmit = (tag, data, retries, onFailure) ->

	if retries?

		if not data.EID
			data.EID = socketEmit.EID++

			# Clone the data so that changes can't be made externally.
			data = JSON.parse JSON.stringify data

			socketEmit['STARTED' + data.EID] = new Date
			if typeof retries isnt 'number'
				retries = SOCKET_EMIT_RETRY_COUNT

		if retries
			socketEmit['TIMEOUT' + data.EID] = setTimeout(->
				#if SOCKET_EMIT_DELAY
					#log "Retrying emission #{data.EID} - #{tag} " + JSON.stringify data
				socketEmit tag, data, retries - 1, onFailure
			, SOCKET_EMIT_RETRY_TIMEOUT)
		else if onFailure
			return onFailure()

	setTimeout(->
		socket.emit tag, data
	, Math.random() * SOCKET_EMIT_DELAY)

# Start the emissionId sequence at 1.
socketEmit.EID = 1

# Try to emit data, and optionally retry.
socketOn = (tag, callback) ->
	socketOn tag, (data) ->
		emissionId = data.EID
		if emissionId
			started = socketEmit['STARTED' + emissionId]
			if started
				delete socketEmit['STARTED' + emissionId]
				elapsed = (new Date) - started
				#if SOCKET_EMIT_DELAY
					#log "Emission #{emissionId} completed in #{elapsed} milliseconds."
				clearTimeout socketEmit['TIMEOUT' + emissionId]
				callback data
		else
			callback data

