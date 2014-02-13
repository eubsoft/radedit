#!/usr/bin/env node

/**
 * This is the entry point for the RadEdit CLI.
 */

// Load CoffeeScript because the CLI uses it.
var coffee = require('coffee-script');

// If on v1.7+, register .coffee as a require-able extension.
if (coffee.register) coffee.register();

// Start the Command Line Interface by reading options.
require('./cli/options');

// The CLI eats its own dog food.
require('radedit');
