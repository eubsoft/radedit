global.fs = require 'fs'
global.events = require 'events'
tracer = require 'tracer'
colors = require 'colors'

symbols =
	log: '\u279C'
	trace: '\u271A'
	debug: '\u2756'
	warn: '\u2731'
	info: '\u2714'
	error: '\u2716'

escapedRoot = documentRoot.replace /([^\d\w])/ig, '\\$1'
pathPattern = new RegExp escapedRoot + '[\\\\\\/]([^\\)\\s]+)', 'g'

colorConsole = tracer.colorConsole(
	filters: 
		log: colors.default
		trace: colors.cyan
		debug: colors.magenta
		info: colors.green
		warn: colors.yellow
		error: colors.red
	dateformat: 'hh:MM:ss'
	format: '{{timestamp}} {{symbol}} {{message}}'
	preprocess: (data) ->
		data.symbol = symbols[data.title]
	transport: (data) ->
		console.log data.output
		output = data.output
		if data.title isnt 'log'
			output = data.output.substr 5, data.output.length - 10
		output = output.replace '<', '&lt;'
		output = output.replace pathPattern, '<a>$1</a>'
		addLine [data.title, output]
)


global.log = colorConsole.log
for own method of symbols
	log[method] = colorConsole[method]

log.error = (err) ->
	colorConsole.error if err and err.stack then err.stack else err

log.lines = []

addLine = (line) ->
	if log.lines.length > 999
		log.lines.shift()
	log.lines.push line
	process.emit 'radedit:log', [line]

process.on 'uncaughtException', (err) ->
	log.error err
