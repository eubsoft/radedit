/**
 * This is the entry point for RadEdit applications.
 */

// Load CoffeeScript because the rest of the app is CS.
var coffee = require('coffee-script');

// If on v1.7+, register .coffee as a require-able extension.
if (coffee.register) coffee.register();

// Load the RadEdit module loader.
require('./module-loader');