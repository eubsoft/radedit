radedit = require 'radedit'
app = radedit.app
config = radedit.config

app.get '/radedit/config', (request, response) ->
	response.view 'radedit/config', config