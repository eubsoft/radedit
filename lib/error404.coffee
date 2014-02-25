radedit = require 'radedit'
app = require 'radedit/lib/app'
loader = require 'radedit/lib/loader'
log = require 'radedit/lib/log'

app.use (request, response) ->
	if loader.loaded
		response.status 404
		response.view 'error404'
	else
		loader.onReady ->
			app.handle request, response
