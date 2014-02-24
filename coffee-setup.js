// Load CoffeeScript because the CLI uses it.
var coffee = require('coffee-script');

// If on v1.7+, register .coffee as a require-able extension.
if (coffee.register) {
	coffee.register();
}

// Cache compiled CoffeeScript to speed startup.
var cache = require('coffee-cache');
cache.setCacheDir('.cache');
