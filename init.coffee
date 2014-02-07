radedit = require 'radedit'
fs = require 'fs'
caller = module.parent.parent.filename.replace /\\/g, '/'

radedit.radeditPath = __dirname
radedit.appPath = caller.replace /\/[^\/]+$/, ''
radedit.stage = process.env.NODE_ENV or 'dev'
radedit.config = {}
radedit.log = require './app/log'

shouldContinue = true
forever = require 'forever'
script = caller.replace /^.*[\/]/, ''
command = process.argv[2]
logPath = radedit.appPath + '/logs'
pidPath = logPath + '/forever.pid'

readPid = (callback) ->
	fs.readFile pidPath, (err, content) ->
		if err
			callback 0
		else
			callback '' + content

writePid = (pid) ->
	fs.mkdir logPath, (err) ->
		if err and not /EEXIST/.test err
			radedit.log.warn "Could not create log directory: #{logPath}"
			throw err
		fs.writeFile pidPath, pid, (err) ->
			if err
				radedit.log.warn "Could not create pid file: #{pidPath}"
				throw err

tryToKill = (pid) ->
	try
		process.kill pid

deletePid = ->
	fs.unlink pidPath, (err) ->
		# Ignore error.

if command is 'start'
	radedit.log "Starting '#{script}' with forever."
	forever.startServer process
	spawned = forever.start script,
		options: []
		watch: false
		minUptime: 1000
		append: false
		silent: true
		command: 'node'
		sourceDir: radedit.appPath
		watchIgnore: []
		watchIgnorePatterns: []
		spawnWith:
			cwd: radedit.appPath
			env: process.env
	readPid (pid) ->
		tryToKill pid
		writePid process.pid	
	shouldContinue = false

else if command is 'stop'
	radedit.log "Stopping '#{script}' with forever."
	readPids (pid) ->
		tryToKill pid
		deletePid()
	shouldContinue = false

else if command
	radedit.error "Unrecognized command: #{command}"


if shouldContinue

	configPath = "#{radedit.appPath}/config/config.json"
	try
		radedit.config = require configPath
	catch e
		message = e.message
		if /SyntaxError/.test message
			radedit.log.error "Syntax error in #{configPath}"
			process.exit()
		else if /Cannot find module/.test message
			radedit.log.warn "No config found at #{configPath}"	

	modules = ['log', 'auth', 'app', 'io', 'db', 'shrinker', 'search', 'loader']
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

