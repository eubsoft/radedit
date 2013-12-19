express = require 'express'
global.app = express()
app.use express.cookieParser config.cookieSecret
app.use require './auth'

global.io = require('socket.io').listen(app.listen(config.port), {log: false})

log.info "Listening on port #{config.port}."

methods =
	get: app.get
	post: app.post

route = (method, href, callback) ->
	existingRoute = null
	routes = app.routes[method] or []
	routes.forEach (route, i) ->
		existingRoute = route	if route.path is href

	if existingRoute
		existingRoute.callbacks = [callback]
	else
		methods[method].apply app, [href, callback]

app.get = (href, callback) ->
	route 'get', href, callback

app.post = (href, callback) ->
	route 'post', href, callback


app.get '/ping', (request, response) ->
	response.send {}


http = require 'http'
http.ServerResponse.prototype.view = (viewName, context) ->
	view = loader.views[viewName]
	@send view context


io.connect = (callback) ->
	io.sockets.on 'connection', callback

io.connect (socket) ->

	socket.on 'error', (error) ->
		log error