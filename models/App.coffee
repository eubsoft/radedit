fs = require 'fs'
http = require 'http'
spawn = require('child_process').spawn

radedit = require 'radedit'
log = radedit.log


module.exports = class App


	constructor: (@name, @config) ->
		@config = @config or @readConfig()
		@port = @config.port or @config.port = 8000
		portSuffix = if @port is 80 then "" else ":#{@port}"
		@baseUrl = "http://localhost#{portSuffix}"
		@monitor()


	readConfig: =>
		root = process.radeditRoot
		path = "#{root}/#{@name}/config/config"
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
		path = "#{root}/#{@name}/config/config.#{extension}"
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
			path = "#{root}/#{@name}/config/config.#{extension}"
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

	start: ->
		root = process.radeditRoot
		path = "#{root}/#{@name}"
		@process = spawn 'node', ['app'],
			cwd: path
		@isOn = true
		@process.on 'exit', =>
			@isOn = false
			@process = null


	stop: ->
		if @process
			@isOn = false
			@process.kill()


	monitor: ->
		pingTimeout = null
		finishPing = (isOn) =>
			clearTimeout pingTimeout
			@setStatus isOn
			pingTimeout = setTimeout ->
				startPing()
			, 1e3
		startPing = =>
			url = "#{@baseUrl}/ping"
			request = http.get url, (response) =>
				finishPing true
			request.on 'error', =>
				finishPing false
		startPing()


	setStatus: (isOn) ->
		if @isOn isnt isOn
			status = if isOn then "running" else "stopped"
			log "App #{@name} is #{status} at #{@baseUrl}"
		@isOn = isOn


	@make: (config, callback) ->
		newApp = null
		name = config.name
		root = process.radeditRoot
		boilerplatesPath = "#{radedit.radeditPath}/boilerplates"
		log "Creating app #{name}"

		cp = (rel, callback) ->
			source = "#{boilerplatesPath}/#{rel}"
			reader = fs.createReadStream source
			destination = "#{root}/#{name}/#{rel}".replace /\/_/, '/'
			writer = fs.createWriteStream destination
			# log "Copying #{source} to #{destination}"
			reader.on 'error', ->
				console.log "Could not read '#{source}'."
			writer.on 'error', ->
				console.log "Could not write '#{destination}'."
			writer.on 'close', callback
			reader.pipe writer

		mkdir = (rel, callback) ->
			path = "#{root}/#{name}/#{rel}"
			# log "Making directory #{path}"
			fs.mkdir path, (err) ->
				if err and err.code isnt 'EEXIST'
					console.log "Could not create directory '#{path}'."
				else
					callback err

		queue = [
			''
			'_.gitignore'
			'app'
			'app.js'
			'config'
			'controllers'
			'lib'
			'logs'
			'models'
			'public'
			'views'
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
