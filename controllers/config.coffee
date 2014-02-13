radedit = require 'radedit'
app = radedit.app
config = radedit.config

app.get '/config', (request, response) ->
	response.view 'config', config