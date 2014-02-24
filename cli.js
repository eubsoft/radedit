#!/usr/bin/env node

/**
 * This is the entry point for the RadEdit CLI.
 */

// Add the ability to load CoffeeScript files.
require('./coffee-setup');

// Start the Command Line Interface by reading options.
require('./cli/options');

// The CLI eats its own dog food.
require('radedit');
