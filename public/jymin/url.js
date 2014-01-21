/**
 * Get the current location host.
 */
var getHost = function() {
	return location.host;
};

/**
 * Get the base of the current URL.
 */
var getBaseUrl = function() {
	return location.protocol + '//' + getHost();
};

/**
 * Get the query parameters from a URL.
 */
var getQueryParams = function(url) {
	url = url || location.href;
	var query = url.substr(url.indexOf('?') + 1);
	var pairs = query.split('&');
	query = {};
	forEach(pairs, function (pair) {
		var eqPos = pair.indexOf('=');
		var name = pair.substr(0, eqPos);
		var value = pair.substr(eqPos + 1);
		query[name] = value;
	});
	return query;
};

