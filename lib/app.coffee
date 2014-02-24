###
The app module configures and starts an express application.
###

# External dependencies.
express = require 'express'
http = require 'http'

# RadEdit dependencies.
radedit = require 'radedit'
config = radedit.config
log = radedit.log

app = module.exports = express()
app.use express.cookieParser config.cookieSecret
app.use express.compress()
app.use radedit.auth
app.use app.router

if not config.port
	config.port = 1337
	log.warn "Defaulting to port #{config.port}."

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
			@end (view) context
		else
			context.vTag = radedit.loader.vTag
			@end (view.min or view) context
	else
		message = "View not found: #{viewName}"
		@end {error: message}
		log.error message
