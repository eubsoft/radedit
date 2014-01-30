express = require 'express'
http = require 'http'

radedit = require 'radedit'
config = radedit.config
log = radedit.log

app = module.exports = express()
app.use express.cookieParser config.cookieSecret
app.use radedit.auth
app.use app.router

app.listener = app.listen config.port


app.get '/ping', (request, response) ->
	response.json
		ok: true

# Override express's native routing to make app[method] overwrite.
['get', 'post'].forEach (method) ->
	app._router[method] = (path) ->
		# Remove the old route if present.
		map = this.map[method]
		for route, index in map
			if route.path is path
				route.callbacks = []

		# Map the route.
		args = [method].concat [].slice.call arguments
		this.route.apply this, args
		return this

http.ServerResponse.prototype.view = (viewName, context) ->
	request = this.req
	context = context or {}
	context.viewName = viewName
	view = radedit.loader.views[viewName]
	if view
		if request.cookies.debug
			context.vTag = 'debug'
			@send (view) context
		else
			context.vTag = radedit.loader.vTag
			@send (view.min or view) context
