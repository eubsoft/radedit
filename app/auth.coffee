module.exports = (request, response, next) ->
	#response.cookie 'u', 'Sam|Eubank|sameubank@gmail.com', {signed: true}
	next()
