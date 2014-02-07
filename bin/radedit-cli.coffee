fs = require 'fs'
colors = require 'colors'
spawn = require('child_process').spawn

radeditPath = require.resolve 'radedit'
radeditPath = radeditPath.replace /index\.js$/, ''
boilerplatesPath = radeditPath + 'boilerplates/'

cli =
module.exports =

	new: (appName) ->

		cp = (rel, callback) ->
			source = boilerplatesPath + rel
			reader = fs.createReadStream source
			destination = appPath + rel
			writer = fs.createWriteStream destination
			reader.on 'error', ->
				console.log "Could not read '#{source}'."
				process.exit()
			writer.on 'error', ->
				console.log "Could not write '#{destination}'."
				process.exit()
			writer.on 'close', callback
			reader.pipe writer

		mkdir = (rel, callback) ->
			path = appPath + rel
			fs.mkdir path, (err) ->
				if err and err.code isnt 'EEXIST'
					console.log "Could not create directory '#{path}'."
				else
					callback err

		cwd = process.cwd().replace /\\/, '/'
		appPath = cwd + appName + '/'
		queue = [
			'.gitignore'
			'app'
			'app.js'
			'config', 
			'config/config.json'
			'controllers'
			'logs'
			'models'
			'public'
			'views'
		]

		dequeue = ->
			rel = queue.shift()
			if rel
				if /\./.test rel
					cp rel, dequeue
				else
					mkdir rel, dequeue
			else
				messages = [
					" "
					"Success!".green
					Array(41).join("-").green
					"\u2714 New app created at #{appPath}".green
					" "
					"Next steps"
					Array(41).join("-")
					"\u279C Go to your app directory:".grey
					"	cd #{appName}"
					" "
					"\u279C Start your app (with forever):".grey
					"	node app start &"
					" "
					"\u279C Configure your app:".grey
					"	http://localhost:1337/radedit/config".blue
					" "
					" "
					"Thank you for using RadEdit! \u263A"
					Array(41).join("-")
					"<limerick>".grey
					"	There once was an app with RadEdit."
					"	Collaborative editing sped it."
					"	Release time was snappy."
					"	The users were happy."
					"	And engineers got massive credit."
					"</limerick>".grey
					" "
				]
				animate = ->
					message = messages.shift()
					if message
						console.log message
						setTimeout animate, 10
				animate()

		dequeue()


args = process.argv
while arg = args.shift()
	if cli[arg]
		cli[arg].apply cli, args
