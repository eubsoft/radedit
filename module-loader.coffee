###
The Module Loader loads RadEdit's config and core modules.
###

# External dependencies.
fs = require 'fs'

# Modules will be properties of the RadEdit package.
radedit = require 'radedit'

# The calling module is in the application's base dir.
caller = module.parent.parent.filename.replace /\\/g, '/'
radedit.appPath = caller.replace /\/[^\/]+$/, ''

# In some cases, we need to know where "radedit" lives.
radedit.radeditPath = __dirname

# Allow RadEdit to be run as "dev", "stage", "prod", whatever.
radedit.stage = process.env.NODE_ENV or 'dev'

logPath = "#{radedit.appPath}/logs"
configPath = "#{radedit.appPath}/config/config"


# RadEdit manager writes a config, so it should be there.
try
	radedit.config = require configPath

# Someone may have called require('radedit') outside an app.
catch e
	# An empty config allows the logger to work.
	radedit.config = {}
	radedit.log = require './lib/log'

	radedit.log.error "Problem parsing config at #{configPath}"
	radedit.log.error e.message
	process.exit()

# Allow the CLI to override which port RadEdit Manager uses.
if process.radeditPort
	radedit.config.port = process.radeditPort


# Core RadEdit modules are loaded in order.
modules = [
	'log',
	'auth',
	'app',
	'io',
	'db',
	'shrinker',
	'templater',
	'search',
	'loader',
	'error404']

# Each module becomes a property of the "radedit" package.
modules.forEach (name) ->
	radedit[name] = require './lib/' + name
	if name is 'log'
		radedit.log.info "Starting application from #{radedit.appPath}"


# An optional config array can globalize modules.
globals = radedit.config.globals or []
globals.forEach (name) ->

	# RadEdit modules can be globalized.
	if radedit[name]
		global[name] = radedit[name]

	# And npm-installed modules can be globalized.
	else
		try
			globalModule = require(name)
			global[name] = globalModule
		catch e
			radedit.log.warn "Module '#{name}' cannot be exposed because it is not installed."


pidFilePath = "#{logPath}/app.pid"
fs.mkdir logPath, (err) ->
	fs.writeFile pidFilePath, process.pid, (err) ->