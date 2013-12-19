orm = require 'orm'
global.db  = orm.connect config.db
if not db.models
	db.models = {}

# Allow callbacks to run on successful connect.
db.connect = (callback) ->
	if db.connected
		callback()
	else
		db.once 'connected', callback

# Try to connect.
# On success emit "connected".
db.connect (err) ->
	if err
		log.error err
		throw err
	else
		log.info 'Database connected.'
		db.connected = true
		db.emit 'connected'


# Overwrite the ORM's "define" to emit events.
define = db.define
db.define = (modelName) ->
	define.apply db, arguments
	# Signal that the model has been defined.
	db.emit 'defined:' + modelName

# Use a model once connected.
db.model = (modelName, callback) ->
	model = db.models[modelName]
	if model
		callback model
	else
		args = arguments
		db.once 'defined:' + modelName, ->
			db.model.apply db, args


# Set up commonly used PostgreSQL/RedShift database field types.
populateFieldTypes = (db) ->

	class db.Text extends String

	class db.Integer extends Number

populateFieldTypes db
