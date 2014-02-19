fs = require 'fs'

radedit = require 'radedit'
app = radedit.app
log = radedit.log
io = radedit.io
App = radedit.App


app.get '/', (request, response) ->
	response.view 'index',
		appPath: radedit.appPath
		apps: JSON.stringify getAppList()


app.get '/config', (request, response) ->
	name = request.query.name
	port = request.query.port
	appObject = radedit.apps[name]
	if appObject
		appConfig = getAppConfig appObject
	else
		appConfig = 
			port: port
			globals: 'log, app, io, fs, http, https'
			configLanguage: 'CoffeeScript'
			scriptingLanguage: 'CoffeeScript'
			templateEngine: 'Jade'
			frontEndLibrary: 'jQuery'
			modelViewLibrary: 'Angular'
			stylesheetLanguage: 'Less'
			uiFramework: 'Bootstrap'
			whitespace: 'tabs'
			tabWidth: '4'
			theme: 'RadEdit'
	response.view 'config',
		appPath: radedit.appPath
		app: JSON.stringify appConfig


app.get '/save-config', (request, response) ->
	config = request.query
	name = config.name
	if name
		appObject = radedit.apps[name]
		if appObject
			appObject.updateConfig config
		else
			radedit.apps[name] = App.make config
	response.redirect '/'


getAppList = ->
	appList = []
	for own name, appObject of radedit.apps
		config = getAppConfig appObject
		config.isOn = appObject.isOn
		appList.push config
	return appList

getAppConfig = (appObject) ->
	config = JSON.parse JSON.stringify appObject.config
	config.name = appObject.name
	return config


daemonActions =
	start: 'started'
	stop: 'stopped'

routeDaemonAction = (action, status) ->
	app.get "/#{action}", (request, response) ->
		appName = request.query.app
		a = radedit.apps[appName]
		if a
			a[action]()
			io.sockets.emit "radedit:#{status}", appName
		response.send {}

for own action, status of daemonActions
	routeDaemonAction action, status

