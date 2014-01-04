express = require 'express'
http = require 'http'

radedit = require 'radedit'
config = radedit.config
log = radedit.log

app = module.exports = express()
app.use express.cookieParser config.cookieSecret
app.use radedit.auth

app.listener = app.listen config.port


app.get '/ping', (request, response) ->
	response.json {}


http.ServerResponse.prototype.view = (viewName, context) ->
	request = this.req
	context = context or {}	
	view = radedit.loader.views[viewName]
	if view
		if request.cookies.debug
			context.vTag = 'debug'
			@send (view) context
		else
			context.vTag = radedit.loader.vTag
			@send (view.min or view) context
