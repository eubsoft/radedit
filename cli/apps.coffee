fs = require 'fs'
http = require 'http'

radedit = require 'radedit'
app = radedit.app
log = radedit.log

App = require '../models/App'

apps =
radedit.apps =
module.exports = {}

root = process.radeditRoot
fs.readdir root, (err, files) ->
	if err
		throw err
	files.forEach (name) ->
		fs.readFile "#{root}/#{name}/app.js", (err, content) ->
			if /radedit/.test content
				apps[name] = new App name