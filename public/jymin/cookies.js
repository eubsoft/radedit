/**
 * Return all cookies.
 */
function getAllCookies() {
	var str = document.cookie;
	var decode = decodeURIComponent;
	var obj = {};
	var pairs = str.split(/ *; */);
	var pair;
	if ('' == pairs[0]) return obj;
	for (var i = 0; i < pairs.length; ++i) {
		pair = pairs[i].split('=');
		obj[decode(pair[0])] = decode(pair[1]);
	}
	return obj;
}

/**
 * Get cookie by name.
 */
function getCookie(name) {
	return getAllCookies()[name];
}

/**
 * Set a cookie.
 */
function setCookie(name, value, options) {
	options = options || {};
	var encode = encodeURIComponent;
	var str = encode(name) + '=' + encode(value);
	if (null == value) {
		options.maxage = -1;
	}
	if (options.maxage) {
		options.expires = new Date(+new Date + options.maxage);
	}
	if (options.path) str += ';path=' + options.path;
	if (options.domain) str += ';domain=' + options.domain;
	if (options.expires) str += ';expires=' + options.expires.toUTCString();
	if (options.secure) str += ';secure';
	document.cookie = str;
}

/**
 * Delete a cookie.
 */
function deleteCookie(name) {
	setCookie(name, null);
}
