var caller = module.parent.filename;

if (!/[\/\\]node_modules[\/\\]radedit[\/\\]/.test(caller)) {

	global.documentRoot = caller.replace(/[\/\\][^\/\\]+$/, '');
	global.config = require(documentRoot + '/config/config.json');
	
	require("coffee-script");
	require("./app/log");
	require("./app/server");
	require("./app/db");
	require("./app/auth");
	require("./app/search");
	require("./app/loader");

}
