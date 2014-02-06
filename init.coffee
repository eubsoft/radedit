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
pidPath = radedit.appPath + '/logs/forever.pid'

readPids = (callback) ->
	fs.readFile pidPath, (err, content) ->
		if err
			throw err
		callback JSON.parse content

writePids = (pids) ->
	fs.writeFile pidPath, JSON.stringify(pids), (err) ->
		if err
			throw err

tryToKill = (pid) ->
	try
		process.kill pid

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
	readPids (pids) ->
		tryToKill pids.forever
		tryToKill pids.app
		writePids
			forever: process.pid
	shouldContinue = false

else if command is 'stop'
	radedit.log "Stopping '#{script}' with forever."
	readPids (pids) ->
		tryToKill pids.forever
		tryToKill pids.app
	shouldContinue = false

else if command
	radedit.error "Unrecognized command: #{command}"



if shouldContinue

	# Update the process ID for the app.
	readPids (pids) ->
		# Kill the other app process if there is one.
		tryToKill pids.app
		pids.app = process.pid
		writePids pids

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

