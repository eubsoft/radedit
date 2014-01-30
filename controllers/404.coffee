radedit = require 'radedit'
app = radedit.app

app.use (request, response) ->
	response.status 404
	response.view 404
