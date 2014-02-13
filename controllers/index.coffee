fs = require 'fs'

radedit = require 'radedit'
app = radedit.app
log = radedit.log
io = radedit.io

index =
module.exports =

app.get '/', (request, response) ->
	response.view 'index',
		appPath: radedit.appPath
		apps: JSON.stringify getAppList()

app.get '/config', (request, response) ->
	appName = request.query.app
	a = radedit.apps[appName]
	if a
		a.readConfig (config) ->
			response.send config
	else
		response.send {}

app.get '/create', (request, response) ->
	name = request.query.name
	port = request.query.port
	# TODO: Create an app.

getAppList = ->
	appList = []
	for own name, app of radedit.apps
		appList.push
			name: app.name
			port: app.port
			isOn: app.isOn
	return appList

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

