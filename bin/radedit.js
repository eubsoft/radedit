#!/usr/bin/env node

require('coffee-script');
try {
	require('coffee-script/register');	
}
catch (e) {
	// TODO: Nag to update CoffeeScript.
}
require('./radedit-cli');