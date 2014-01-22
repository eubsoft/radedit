// Initially, the socket is just a holder for handlers.
var socket = {H: {}};

var SOCKET_IO_PATH = '/socket.io/1/';
var socketEmissionId = 0;

/**
 * Make a new socket connection.
 */
var socketConnect = function() {
	var url = getBaseUrl() + SOCKET_IO_PATH + '?t=' + getTime();
	getResponse(url, socketSetup, socketConnect);
};

/**
 * Set up a socket based on a setup string returned from the server.
 */
var socketSetup = function(setupString) {
	var setupData = setupString.split(':');
	var socketId = setupData[0];
	var oldSocket = socket;
	socket = new WebSocket('ws://' + getHost() + SOCKET_IO_PATH + 'websocket/' + socketId);
	socket.H = oldSocket.H;
	delete oldSocket.H;

	socket.onmessage = function(message) {
		var data = message.data;
		var type = data[0] * 1;

		// Accept the "connected" message.
		if (type == 1) {
			socketTrigger('connected');

		// Echo the heartbeat data.
		} else if (type == 2) {
			socket.send(data);

		// A message was emitted to the client.
		} else if (type == 5) {
			data = data.replace(/[0-9]:+/, '');
			try {
				data = JSON.parse(data);
			}
			catch (e) {
				log('ERROR: Malformed socket data', data);
			}
			socketTrigger(data.name, data.args[0]);

		// We don't care about all message types.
		} else {
			log('ERROR: Unknown socket message type', data);
		}
	};

	// When disconnected, attempt to reconnect.
	socket.onclose = function(data) {
		socketConnect();
	};
};

/**
 * Trigger handlers for a named event.
 */
var socketTrigger = function(name, data) {
	var handlers = socket.H;
	var callbacks = handlers[name] = handlers[name] || [];
	forEach(callbacks, function(callback) {
		callback(data);
	});
};

/**
 * Set a new handler for a named event.
 */
var socketOn = function(name, callback) {
	var handlers = socket.H;
	var callbacks = handlers[name] = handlers[name] || [];
	callbacks.push(callback);
};

// Set up a new connection.
socketConnect();

socketOn('refresh', function(changed) {
	log('refresh', changed);
	location.reload();
});