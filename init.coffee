radedit = require 'radedit'
caller = module.parent.parent.filename.replace /\\/g, '/'

radedit.radeditPath = __dirname
radedit.appPath = caller.replace /\/[^\/]+$/, ''
radedit.stage = process.env.NODE_ENV or 'dev'

configPath = "#{radedit.appPath}/config/config.json"
try
	radedit.config = require configPath
	radedit.log = require './app/log'
catch e
	radedit.config = {}
	radedit.log = require './app/log'
	radedit.log.warn "No config found at #{configPath}"


shouldContinue = true
forever = require 'forever'
command = caller.replace /^.*[\/]/, ''
for arg in process.argv

	if arg is 'start'
		radedit.log "Starting '#{command}' with forever."
		forever.start command,
			options: []
			watch: false
			minUptime: 1000
			append: false
			silent: false
			command: 'node'
			sourceDir: radedit.appPath
			watchIgnore: []
			watchIgnorePatterns: []
			spawnWith:
				cwd: radedit.appPath
				env: process.env
		shouldContinue = false

	if arg is 'stop'
		radedit.log "Stopping '#{command}' with forever."
		shouldContinue = false


if shouldContinue

	modules = ['auth', 'app', 'io', 'db', 'shrinker', 'search', 'loader']
	modules.forEach (name) ->
		radedit[name] = require './app/' + name

	exposeGlobals = radedit.config.exposeGlobals or []
	exposeGlobals.forEach (name) ->
		if radedit[name]
			global[name] = radedit[name]
		else
			try
				globalModule = require(name)
				global[name] = globalModule
			catch e
				radedit.log.warn "Module '#{name}' cannot be exposed because it is not installed."

