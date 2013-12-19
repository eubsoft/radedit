function ajax(url, data, onSuccess, onFailure, evalJson) {
	var request;
	if (window.XMLHttpRequest) {
		request = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
		request = new ActiveXObject("Microsoft.XMLHTTP");
	} else {
		return false;
	}
	if (request) {
		request.onreadystatechange = function() {
			if (request.readyState == 4) {
				var callback = request.status == 200 ? onSuccess : onFailure || function() {};
				var response = request.responseText;
				if (evalJson) {
					response = JSON.parse(response);
				}
				callback(response, request);
			}
		};
		request.open(data ? 'POST' : 'GET', url, true);
		if (data) {
			request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
			request.setRequestHeader('Content-length', data.length);
			request.setRequestHeader('Connection', 'close');
		}
		request.send(data);
	}
	return true;
}

function getJson(url, onSuccess, onFailure) {
	ajax(url, 0, onSuccess, onFailure, true);
}
