/**
 * Return a history object. 
 */
var getHistory = function () {
	var history = window.history || {};
	forEach(['push', 'replace'], function (key) {
		var fn = history[key + 'State'];
		history[key] = function (href) {
			if (fn) {
				fn.apply(history, [null, null, href]);
			} else {
				// TODO: Create a backward compatible history push.
			}
		};
	});
	return history;
};

/**
 * Push an item into the history.
 */
var pushHistory = function (href) {
	getHistory().push(href);
};

/**
 * Push an item into the history.
 */
var replaceHistory = function (href) {
	getHistory().replace(href);
};

/**
 * Go back.
 */
var popHistory = function (href) {
	getHistory().back();
};

