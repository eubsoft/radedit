function getResponse(url, data, onSuccess, onFailure, evalJson) {
	// The data argument is optional.
	if (typeof data == 'function') {
		evalJson = onFailure;
		onFailure = onSuccess;
		onSuccess = data;
		data = 0;
	}
	var request;
	if (window.XMLHttpRequest) {
		request = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
		request = new ActiveXObject('Microsoft.XMLHTTP');
	} else {
		return false;
	}
	if (request) {
		request.onreadystatechange = function() {
			if (request.readyState == 4) {
				var callback = request.status == 200 ? onSuccess : onFailure || function() {};
				var response = request.responseText;
				if (evalJson) {
					try {
						response = JSON.parse(response);
					}
					catch (e) {
						log('ERROR: Could not parse JSON', response);
					}
				}
				callback(response, request);
			}
		};
		request.open(data ? 'POST' : 'GET', url, true);
		if (data) {
			request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
		}
		request.send(data);
	}
	return true;
}

function getJson(url, onSuccess, onFailure) {
	getResponse(url, onSuccess, onFailure, true);
}
