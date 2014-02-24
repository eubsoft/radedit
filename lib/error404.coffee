radedit = require 'radedit'
app = radedit.app
loader = radedit.loader

app.use (request, response) ->
	if loader.loaded
		response.status 404
		response.view 404
	else
		loader.onReady ->
			app.handle request, response
