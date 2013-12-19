module.exports = (req, res, next) ->
	#log req.headers.cookie
	res.cookie 'u', 'Sam|Eubank|sameubank@gmail.com', {signed: true}
	next()
