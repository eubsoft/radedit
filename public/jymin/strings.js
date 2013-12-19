/**
 * The protocol is used to reference HTTP/HTTPS URLs.
 * If we're inside a local file (debugging a unit test), we want to override and use HTTP for generated URLs.
 */
var PROTOCOL = location.protocol.replace(/file/, 'http');

/**
 * The User Agent string is used to test browser-specific support for some features.
 */
var USER_AGENT = navigator.userAgent.toLowerCase();

/**
 * Return true if it's a string.
 */
function isString(object) {
    return typeof object == 'string';
}

/**
 * Trim the whitespace from a string.
 */
function trim(string) {
    return ('' + string).replace(/^\s+|\s+$/g, '');
}

/**
 * Return true if the string contains the given substring.
 */
function containsString(string, substring) {
    return ('' + string).indexOf(substring) > -1;
}

/**
 * Return a string, with asterisks replaced by values from a replacements array.
 */
function decorateString(string, replacements) {
    string = '' + string;
    forEach(replacements, function(replacement) {
        string = string.replace('*', replacement);
    });
    return string;
}

/**
 * Reduce a string to its alphabetic characters.
 */
function alphabetics(string) {
    return ('' + string).replace(/[^a-z]/ig, '');
}

/**
 * Reduce a string to its numeric characters.
 */
function numerics(string) {
    return ('' + string).replace(/[^0-9]/g, '');
}

/**
 * Serialize an object to a string.
 */
function serialize(obj, delimiter) {
    var objType = obj.constructor.name;
    delimiter = delimiter || '&';

    if (objType == 'Array') {
        return obj.join(delimiter);
    } else if (objType == 'Object') {
        var serializedArray = [];
        forIn(obj, function(val, key) {
            serializedArray.push(key + '=' + val);
        });

        return serialize(serializedArray);
    }
}

/**
 * Returns a query string generated by serializing an object and joined using a delimiter (defaults to '&')
 */
function getQueryString(query, delimiter) {
    delimiter = delimiter || '&';
    var queryParams = [];

    forEach(query, function(value, key) {
        queryParams.push(key + '=' + value);
    });

    return queryParams.join(delimiter);
}

/**
 * Return the browser version if the browser name matches or zero if it doesn't.
 */
function getBrowserVersionOrZero(browserName) {
    var match = new RegExp(browserName + '[ /](\\d+(\\.\\d+)?)', 'i').exec(USER_AGENT);
    return match ? +match[1] : 0;
}
