fs = require 'fs'
http = require 'http'
spawn = require('child_process').spawn

radedit = require 'radedit'
log = radedit.log


module.exports = class App

	constructor: (@name) ->
		app = @
		@readConfig (config) ->
			app.port = config.port or 1337
			portSuffix = if app.port is 80 then "" else ":#{app.port}"
			app.baseUrl = "http://localhost#{portSuffix}"
			app.monitor()

	readConfig: (callback) ->
		root = process.radeditRoot
		path = "#{root}/#{@name}/config/config.json"
		fs.readFile path, (err, content) ->
			try
				config = JSON.parse '' + content
			catch
				config = {}
			callback config
	
	start: ->
		app = @
		root = process.radeditRoot
		path = "#{root}/#{@name}"
		@process = spawn 'node', ['app'],
			cwd: path
		@isOn = true
		@process.on 'exit', ->
			app.isOn = false
			app.process = null
	
	stop: ->
		if @process
			@isOn = false
			@process.kill()

	monitor: ->
		app = @
		pingTimeout = null
		finishPing = (isOn) ->
			clearTimeout pingTimeout
			app.setStatus isOn
			pingTimeout = setTimeout ->
				startPing()
			, 1e3
		startPing = ->
			url = "#{app.baseUrl}/ping"
			request = http.get url, (response) ->
				finishPing true
			request.on 'error', ->
				finishPing false
		startPing()


	setStatus: (isOn) ->
		if @isOn isnt isOn
			status = if isOn then "running" else "stopped"
			log "App #{@name} is #{status} at #{@baseUrl}"
		@isOn = isOn


