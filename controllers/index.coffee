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
	name = request.query.app
	appObject = radedit.apps[name]
	if appObject
		appConfig = getAppConfig appObject
	else
		appConfig = 
			port: request.query.port
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
	name = config.oldName
	appObject = radedit.apps[name]
	if appObject
		delete config.oldName
		appObject.updateConfig config
	else
		App.make config
	response.redirect '/'
	emitApps()


app.get '/delete', (request, response) ->
	name = request.query.app
	if name
		appObject = radedit.apps[name]
		if appObject
			appObject.delete()
	response.redirect '/'
	emitApps()


getAppList = ->
	appList = []
	for own name, appObject of radedit.apps
		config = getAppConfig appObject
		config.isOn = appObject.isOn
		appList.push config
	return appList


getAppConfig = (appObject) ->
	config = JSON.parse JSON.stringify appObject.config
	return config


daemonActions =
	start: 'started'
	stop: 'stopped'

routeDaemonAction = (action, status) ->
	app.get "/#{action}", (request, response) ->
		appName = request.query.app
		appObject = radedit.apps[appName]
		if appObject
			appObject[action]()
			emitApps()
		response.send {}


emitApps = ->
	io.sockets.emit "radedit:apps", getAppList()


for own action, status of daemonActions
	routeDaemonAction action, status


