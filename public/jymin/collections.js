/**
 * Iterate over an array, and call a function on each item.
 */
var forEach = function(array, callback) {
    if (array) {
        for (var index = 0, length = array.length; index < length; index++) {
            var result = callback(array[index], index, array);
            if (result === false) {
                break;
            }
        }
    }
};

/**
 * Iterate over an array, and call a function on each item.
 */
var forIn = function(object, callback) {
    if (object) {
        for (var key in object) {
            var result = callback(object[key], key, object);
            if (result === false) {
                break;
            }
        }
    }
};

/**
 * "Extend" an object by decorating it with properties from an "extensions" object.
 */
var extendObject = function(object, extensions) {
    if (object && extensions) {
        for (var property in extensions) {
            object[property] = extensions[property];
        }
    }
    return object;
};