#!/usr/bin/env node
var coffee = require('coffee-script');
if (coffee.register) coffee.register();
require('./cli');
