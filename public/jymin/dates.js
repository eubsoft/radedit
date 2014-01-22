/**
 * Get Unix epoch seconds from a date.
 */
var getTime = function(date) {
	date = date || new Date();
	return date.getTime();
};
