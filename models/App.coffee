fs = require 'fs'
http = require 'http'
spawn = require('child_process').spawn

radedit = require 'radedit'
log = require 'radedit/lib/log'

STARTUP_GRACE_PERIOD = 1e4
MONITOR_PING_DELAY = 1e3

###
An app is managed by RadEdit.
###
module.exports = class App

	###
	Create the app and start monitoring it.
	###
	constructor: (@name, @config) ->
		root = process.radeditRoot
		@path = "#{root}/#{@name}"
		@config = @config or @readConfig()
		@port = @config.port or @config.port = 8000
		portSuffix = if @port is 80 then "" else ":#{@port}"
		@baseUrl = "http://localhost#{portSuffix}"

		# Assume the app is off before we've checked it.
		@isOn = @stayOn = false
		@pid = null
		@pidPath = "#{@path}/logs/app.pid"

		# Try to read the pid file for the app.
		fs.readFile @pidPath, (err, content) =>
			if not err
				pid = ('' + content) * 1

				# Send a test kill signal to check if the app is running.
				try
					process.kill pid, 0
					@pid = pid
					@isOn = @stayOn = true
					log "App #{@name} is running with PID #{pid} from a previous invocation."
	
				# If the app left a pid file behind, it wants to be running.
				catch
					log "App #{@name} died with PID #{pid} and will be restarted."
					@start()

		# Whether the app is on or not, monitor it via ping.
		@monitor()


	readConfig: =>
		path = "#{@path}/config/config"
		try
			return require path
		catch
			return {}


	updateConfig: (config, callback) =>
		configLanguage = @config.configLanguage or 'JSON'
		extensions =
			CoffeeScript: 'coffee'
			JavaScript: 'js'
			JSON: 'json'
		extension = extensions[configLanguage]
		root = process.radeditRoot
		path = "#{@path}/config/config.#{extension}"
		fs.unlink path, =>
			if config.globals
				config.globals = config.globals.split /[^a-z0-9]+/
			else
				config.globals = []
			# TODO: Create publics if they don't exist.
			for own key, value of config
				@config[key] = value
			text = JSON.stringify @config, null, '\t'
			if config.configLanguage is 'CoffeeScript'
				# TODO: Use a proper Coffee.stringify because this isn't perfect.
				text = text.replace /([\{\[,]\s+)"([a-z0-9]+)":/ig, '$1$2:'
				text = text.replace /,\n/g, '\n'
				text = text.replace /[\{\}]/g, ''
				text = text.replace /\n\s*\n/g, '\n'
			if config.configLanguage isnt 'JSON'
				text = 'module.exports =\n' + text
			extension = extensions[config.configLanguage]
			path = "#{@path}/config/config.#{extension}"
			text = @applyWhitespace text
			fs.writeFile path, text, (err) =>
				if err
					throw err
				if callback
					callback()

	applyWhitespace: (code) ->
		if @config.whitespace is 'spaces'
			spaces = (new Array(@config.tabWidth * 1 + 1)).join ' '
			code = code.replace /\t/g, spaces
		return code


	###
	Start an app, and keep it running.
	###
	start: ->
		# Delay monitoring to allow for startup time.
		@stayOn = false
		setTimeout ->
			@stayOn = true
		, STARTUP_GRACE_PERIOD

		# Spawn the child process.
		@process = spawn 'node', ['app'],
			cwd: @path

		@isOn = true
		radedit.log "Started app #{@name} at #{@baseUrl}"

		# If the app dies, we can restart it.
		@process.on 'exit', =>
			log "Process for app #{@name} exited."
			@isOn = false
			@process = null
			if @stayOn
				@start()

		@process.on 'close', =>
			log "Process for app #{@name} closed."

	###
	Stop an app if there's a running process or a pid.
	###
	stop: ->
		@stayOn = stopped = false

		if @process
			@process.kill()
			stopped = true
		else if @pid
			try
				process.kill @pid
				stopped = true

		if stopped
			radedit.log "Stopped app #{@name} at #{@baseUrl}"

		@isOn = false
		@pid = @process = null
		fs.unlink @pidPath, ->


	###
	Monitor the app by pinging it.
	###
	monitor: ->
		pingTimeout = null

		# When a ping has finished, process the success or failure.		
		finishPing = (isOn) =>

			# If we got a response, we don't want to think we timed out.
			clearTimeout pingTimeout

			# Set the app's status to on or off.
			@setStatus isOn

			# If an app is running, we want it to stay running.
			if isOn
				@stayOn = true

			# If an app was supposed to stay running and it's not, start it.
			if @stayOn and not isOn
				log.warn "App #{@name} stopped unexpectedly."
				@start()

			# If we can't listen to the process directly, keep pinging it.
			if not @process
				pingTimeout = setTimeout ->
					startPing()
				, MONITOR_PING_DELAY
				
		# Ping an app and either get a response or an error.
		startPing = =>
			url = "#{@baseUrl}/ping"
			request = http.get url, (response) =>
				finishPing true
			request.on 'error', =>
				finishPing false

		# Start monitoring.
		startPing()


	###
	Set an application's status to on or off, depending on whether it is known to be running.
	###
	setStatus: (isOn) ->
		if @isOn isnt isOn
			status = if isOn then "running" else "stopped"
			# TODO: Display a more appropriate ping failure message.
			log "App #{@name} is #{status} at #{@baseUrl}"
		@isOn = isOn


	###
	Create a new app via factory method.
	###
	@make: (config, callback) ->
		newApp = null
		name = config.name
		root = process.radeditRoot
		appPath = "#{root}/#{name}"
		boilerplatesPath = "#{radedit.radeditPath}/boilerplates"
		log "Creating app #{name}"

		cp = (rel, callback) =>
			source = "#{boilerplatesPath}/#{rel}"
			reader = fs.createReadStream source
			destination = "#{appPath}/#{rel}".replace /\/_/, '/'
			writer = fs.createWriteStream destination
			log.trace "Copying #{source} to #{destination}"
			reader.on 'error', ->
				log.error "Could not read '#{source}'."
			writer.on 'error', ->
				log.error "Could not write '#{destination}'."
			writer.on 'close', callback
			reader.pipe writer

		mkdir = (rel, callback) =>
			path = "#{appPath}/#{rel}"
			log.trace "Making directory #{path}"
			fs.mkdir path, (err) ->
				if err and err.code isnt 'EEXIST'
					console.log "Could not create directory '#{path}'."
				else
					callback err

		# TODO: Replace this with a walk mechanism like the loader.
		queue = [
			''
			'_.gitignore'
			'_.radignore'
			'app'
			'app.js'
			'config'
			'controllers'
			'lib'
			'logs'
			'models'
			'public'
			'views'
			'views/error404.jade' # TODO: Allow for other template engines.
		]

		dequeue = ->
			rel = queue.shift()
			if rel?
				if /\./.test rel
					cp rel, dequeue
				else
					mkdir rel, dequeue
			else
				newApp.updateConfig config
				if callback
					callback()

		dequeue()

		newApp = new App name, config
