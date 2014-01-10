var caller = module.parent.filename;

var radedit = module.exports = function (appName) {
	console.log('TODO: Create RadEdit app "' + appName + '"');
};

if (!/[\/\\]node_modules[\/\\]radedit[\/\\]/.test(caller)) {

	radedit.radeditPath = __dirname;
	radedit.appPath = caller.replace(/[\/\\][^\/\\]+$/, '');
	radedit.config = require(radedit.appPath + '/config/config.json');
	radedit.stage = process.env.NODE_ENV || 'dev';

	require("coffee-script");
	var modules = [
		'log', // Used by everything.
		'auth', // Load before app, used as middleware.
		'app',
		'io', // Load after app, uses app.listener.
		'db',
		'shrinker', // Used by loader.
		'search', // Used by loader.
		'loader' // Load after everything.
		];

	modules.forEach(function (name) {
		radedit[name] = require('./app/' + name);
	});

	var exposeGlobals = radedit.config.exposeGlobals || [];
	exposeGlobals.forEach(function (name) {
		if (radedit[name]) {
			global[name] = radedit[name];
		}
		else {
			try {
				var globalModule = require(name);
				global[name] = globalModule;
			}
			catch (e) {
				radedit.log.warn("Module '" + name + "' can't be exposed because it doesn't exist.");
			}
		}
	});
}

