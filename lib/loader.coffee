###
The loader module recursively loads directory contents.
###

# External dependencies.
fs = require 'fs'
events = require 'events'
coffee = require 'coffee-script'
uglify = require 'uglify-js'
clean = require 'clean-css'
clean = new clean

# RadEdit dependencies.
radedit = require 'radedit'
app = radedit.app
config = radedit.config
appPath = radedit.appPath
io = radedit.io
log = radedit.log
search = radedit.search
templater = radedit.templater

APP_RESTART_DELAY = 10
CLIENT_REFRESH_DELAY = 50
DIR_WALK_INTERVAL = 1000


class Loader

	waitingCount: 0
	loaded: false

	tree: {}
	cache: {}
	views: {}
	public: {}

	isWindows: /\bwin/i.test process.platform
	startTime: new Date
	vTag: 0

	mimes:
		coffee: 'text/coffeescript'
		css: 'text/css'
		html: 'text/html'
		js: 'text/javascript'
		jade: 'text/jade'
		json: 'text/json'
		md: 'text/markdown'
		sql: 'text/sql'
		txt: 'text/plain'
		xml: 'text/xml'
		png: 'image/png'
		jpg: 'image/jpg'
		gif: 'image/gif'
		ico: 'image/x-icon'

	queue: []

	onReady: (callback) ->
		if @waitingCount
			@queue.push callback
		else
			process.nextTick callback

	updateVTag: ->
		chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
		number = Math.round (new Date).getTime() / 1000
		radix = chars.length
		vTag = chars[number % radix]
		while number >= radix
			number = Math.floor number / radix - 0.999
			vTag = chars[number % radix] + vTag
		@vTag = vTag

	loadFile: (path, content) ->
		if @loaded
			log "Updated: #{path}"
			@updateVTag()
		processFile = @processFile
		lintFile path, content, (content) ->
			processFile path, content

	resolvePath: (path) ->
		parts = path.split ' '
		if parts[0] is 'npm'
			name = parts[1]
			path = require.resolve name
			path = path.replace /\\/g, '/'
			middle = "/node_modules/#{name}/"
			path = path.split middle
			path = path[0] + middle + parts[2]

module.exports =
loader = new Loader


getRel = (path) ->
	if path.substr(0, appPath.length) is appPath
		return path.substr appPath.length + 1
	else
		return path


getExtension = (file) ->
	return file.replace /.*\./, ''


loader.getMime =
getMime = (path) ->
	return loader.mimes[getExtension path]


modulesPattern = /^.*[\/\\]node_modules[\/\\]/
publicPattern = /(^|[\/\\])public[\/\\]/
viewsPattern = /(^|[\/\\])views[\/\\]/

moduleRoot = __dirname.replace /[\/\\]modules$/, ''
moduleRoot = moduleRoot.replace /\\/g, '/'
publicRel = getRel moduleRoot + '/public'



expandPublics = ->

	for href, components of config.publics
		for componentRel, index in components
			parts = componentRel.split ' '
			if parts[0] is 'npm'
				path = loader.resolvePath componentRel
				scheduleLoading = (path) ->
					process.nextTick ->
						expandPublics[path] = true
						loader.loadFile path
				scheduleLoading path
				components[index] = getRel path
		config.publics[href] = components

config.publics = config.publics or {}
expandPublics()


modifiedTimes = {}

ignorePattern = '. '
try
	ignorePattern += fs.readFileSync appPath + '/.radignore'
catch e
	ignorePattern += '*-MIN.jade .cache .git boilerplates logs node_modules test'

ignorePattern = ignorePattern.replace /(^\s|\s+$)/, ''
ignorePattern = ignorePattern.replace /\./g, '\\.'
ignorePattern = ignorePattern.replace /\*/g, '.*'
ignorePattern = ignorePattern.replace /\s+/g, '|'
ignorePattern += '|.*-MIN\.jade'
ignorePattern += '|\.git'
ignorePattern += '|\.cache'
ignorePattern += '|node_modules'
ignorePattern += '|test'
ignorePattern = new RegExp "^(#{ignorePattern})$"


loader.loadFiles =
loadFiles = (path) ->
	path = path or appPath
	walk path, checkFile, checkDir
	buildTree()

	# Check for changes every so often.
	loader.onReady ->
		setTimeout(->
			loadFiles path
		, DIR_WALK_INTERVAL)

# Load all files
process.nextTick ->
	loadFiles appPath


class Node
	constructor: (@rel) ->
		@name = @rel.replace /.*\//, ''

getNode = (rel) ->
	node = loader.tree[rel]
	if not node
		node = loader.tree[rel] = new Node rel
	return node

loader.buildTree =
buildTree = ->
	string = treeString loader.tree['']
	if string isnt loader.treeString
		loader.treeString = string
		io.sockets.emit 'radedit:tree', string

treeString = (node, maxDepth = 100) ->
	if node
		string = node.name
		if node.files and maxDepth
			maxDepth--
			string += '/'
			string += (treeString file, maxDepth for file in node.files).join '|'
			string += '\\'
		string


checkFile = (path, stat) ->
	modifiedTime = stat.mtime.getTime()
	previousTime = modifiedTimes[path]
	recentlyModified = modifiedTime > previousTime

	if recentlyModified or not previousTime
		modifiedTimes[path] = modifiedTime
		loader.loadFile path, previousTime


checkDir = (path, files) ->
	rel = getRel path
	dir = getNode rel
	dir.files = []
	for filename in files
		if not ignorePattern.test filename
			dir.files.push getNode rel + (if rel then '/' else '') + filename


refreshClients = (changed) ->
	clearTimeout refreshClients.t
	refreshClients.t = setTimeout(->
		io.sockets.emit 'refresh', changed
	, CLIENT_REFRESH_DELAY)


restartApp = (path) ->
	log.warn "Stopping app for change in #{path}"
	stopsRemaining = 0
	if radedit.apps
		for own appName, appObject of radedit.apps
			if appObject.process
				stopsRemaining++
				appObject.process.on 'exit', ->
					stopsRemaining--
					if stopsRemaining is 0
						process.exit()
				appObject.stop()
	if stopsRemaining is 0
		setTimeout ->
			process.exit()
		, APP_RESTART_DELAY



loadModule = (path) ->
	delete require.cache[path]
	require path
	refreshClients 'module'


lintFile = (path, content, callback) ->
	doLinting = (err, content) ->
		if err
			throw err
		extension = getExtension path
		# TODO: Add linting.
		callback content

	if typeof content is 'string'
		doLinting null, content
	else
		incrementWaitingCount()
		fs.readFile path, (err, content) ->
			if err
				decrementWaitingCount()
				return log.warn "Failed to read path: #{path}"
			doLinting err, content
			decrementWaitingCount()

templateExtensionPattern = /\.(jade)$/

loader.processFile =
processFile = (path, content) ->
	rel = getRel path
	if expandPublics[path] or publicPattern.test rel
		loadPublic path, content

	# Load views for the server.
	else if templateExtensionPattern.test rel
		# Load dependent views
		loadView = (name, path, oldView) ->
			code = if oldView then oldView.code else '' + content

			# "AUTOROUTE" comments cause views to route based on view name.
			autoPattern = /^\/\/-?\s*AUTOROUTE\s*/
			if autoPattern.test code
				code = code.replace autoPattern, ''
				href = '/' + name.replace /(^|\/)index$/, '$1'
				app.get href, (request, response) ->
					response.view name

			view = templater.compile code, path
			view.path = path
			view.code = code
			view.minified = code

			view.afterShrunk = ->
				minPath = path.replace templateExtensionPattern, '-MIN.$1'
				minCode = view.minified.replace /(include|extends) (\S+)/g, '$1 $2-MIN'
				fs.writeFile minPath, minCode, (err) ->
					if err
						throw err
					view.min = templater.compile minCode, minPath

			loader.views[name] = view

			loader.onReady ->
				radedit.shrinker.shrink view
			refreshClients rel

		name = rel.replace /\.jade$/, ''
		name = name.replace modulesPattern, ''
		name = name.replace viewsPattern, '$1'
		loadView name, path

		for own otherName, view of loader.views
			if otherName isnt name
				loadView otherName, view.path, view

	# Load modules
	else
		if /(js|coffee|iced)$/.test path
			# If it's not the first time, we may need to reload or restart.
			modulePath = if loader.isWindows then path.replace /\//g, '\\' else path
			module = require.cache[modulePath]
			if module
				# Reloadable modules have an unload function.
				if module.exports.unload
					module.exports.unload()
					loadModule modulePath
				# Non-reloadable modules require an application restart.
				else if loader.loaded
					return restartApp path
			else
				loadModule modulePath

	# Update the search index.
	loader.onReady ->
		search.update rel, content


incrementWaitingCount = ->
	loader.waitingCount++

decrementWaitingCount = ->
	loader.waitingCount--
	if not loader.waitingCount
		loader.queue.forEach process.nextTick
		loader.queue = []
		loader.loaded = true


# Recursively walk a directory, calling functions on each file and directory.
walk = (dir, fileCallback, dirCallback) ->
	incrementWaitingCount()
	fs.readdir dir, (err, files) ->
		if err
			decrementWaitingCount()
			return log.warn "Failed to read directory: #{dir}"
		if dirCallback
			dirCallback dir, files
		files.forEach (filename) ->
			if not ignorePattern.test filename
				path = dir + '/' + filename
				incrementWaitingCount()
				fs.stat path, (err, stat) ->
					if err
						decrementWaitingCount()
						return log.warn "Failed to stat path: #{path}"
					isDirectory = stat.isDirectory()
					if isDirectory
						walk path, fileCallback, dirCallback
					else if fileCallback
						fileCallback path, stat
					decrementWaitingCount()
		decrementWaitingCount()


loader.public =
	assets: {}
	parents: {}
	pending: {}


createPublicAsset = (rel, content) ->
	extension = getExtension rel
	minified = null
	if extension is 'coffee' or extension is 'js'
		minified = minifyJs '' + content
	if extension is 'css'
		minified = clean.minify '' + content
	asset =
		rel: rel
		content: content
		minified: minified
	loader.onReady ->
		radedit.shrinker.shrink asset
	return asset


minifyJs = (js) ->
	try
		result = uglify.minify js, {fromString: true}
		return result.code
	catch e
		return js


loadPublic = (path, content) ->
	rel = getRel path
	extension = getExtension path
	if extension is 'coffee'
		try
			noClosure = /^#NOCLOSURE/.test content
			content = coffee.compile '' + content
			if noClosure
				content = content.replace /^\(function\(\) \{/, ''
				content = content.replace /\}\)\.call\(this\);[\r\n]*$/, ''
		catch e
			log.debug "Can't compile #{path}"
			log.error e

	asset = createPublicAsset rel, content
	loader.public.assets[rel] = asset

	if groups = loader.public.parents[rel]
		groups.forEach (group) ->
			loader.public.pending[group] = true
			loader.onReady ->
				for own group, isPending of loader.public.pending
					delete loader.public.pending[group]
					compilePublic group

	type = getMime(path) or 'text/html'
	href = rel.replace modulesPattern, ''
	href = href.replace publicPattern, '$1'
	href = href.replace /\.html$/, ''
	href = href.replace /\.coffee$/, '.js'
	href = '/' + href
	routePublic href, rel

	return asset


compilePublic = (group) ->
	extension = getExtension group
	files = config.publics[group]
	code = ''
	for file in files
		asset = loader.public.assets[file]
		if asset
			code += "/* FILE: #{file} */\n"
			code += asset.content + '\n'
		else
			log.warn 'Asset not found: ' + file
			code += "/* FILE NOT FOUND: #{file} */\n"

	asset = createPublicAsset group, code
	loader.public.assets[group] = asset
	routePublic group, group


routePublic = (href, assetKey) ->
	asset = loader.public.assets[assetKey]
	type = getMime(href) or 'text/html'

	app.get href, (request, response) ->
		response.set "Content-Type", type
		if request.cookies.debug
			response.send asset.content
		else
			response.send asset.minified or asset.content

	taggedHref = href.replace /\.([a-z]+)$/, '.*.$1'
	app.get taggedHref, (request, response) ->
		response.set 'Content-Type', type
		if request.cookies.debug
			response.send asset.content
		else
			future = new Date(Date.now() + 1e11)
			response.setHeader 'Expires', future.toUTCString()
			response.send asset.minified or asset.content

	refreshClients href


mapPublicAssets = ->
	groups = config.publics
	for group, files of groups
		for file in files
			list = loader.public.parents[file]
			if not list
				list = loader.public.parents[file] = []
			if list.indexOf group < 0
				list.push group


loader.updateVTag()
mapPublicAssets()

