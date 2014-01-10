fs = require 'fs'
jade = require 'jade'
events = require 'events'
coffee = require 'coffee-script'
uglify = require 'uglify-js'
clean = require 'clean-css'
clean = new clean

radedit = require 'radedit'
app = radedit.app
config = radedit.config
appPath = radedit.appPath
io = radedit.io
log = radedit.log
search = radedit.search

APP_RESTART_DELAY = 10
CLIENT_REFRESH_DELAY = 50
PUBLIC_FILE_COMPILE_DELAY = 5
DIR_WALK_INTERVAL = 1000

loader =
module.exports =

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
		if loader.waitingCount
			loader.queue.push callback
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
		loader.vTag = vTag


getRel = (path) ->
	if path.substr(0, appPath.length) is appPath
		return path.substr appPath.length + 1
	else
		return path.replace modulesPattern, '../node_modules/'


getExtension = (file) ->
	return file.replace /.*\./, ''


loader.getMime =
getMime = (path) ->
	return loader.mimes[getExtension path]



modulesPattern = /^.*[\/\\]node_modules[\/\\]/
publicPattern = /(^|[\/\\])public[\/\\]/
viewsPattern = /(^|[\/\\])views[\/\\]/

moduleRoot = __dirname.replace /[\/\\]app$/, ''
publicRel = getRel moduleRoot + '/public'

radeditPublic =
	"/radedit.css": [
		"css/editor.css"
		"css/codemirror.css"
	],
	"/radedit.js": [
		"jymin/io.js"
		"jymin/closure_head.js"
		"jymin/logging.js"
		"jymin/strings.js"
		"jymin/collections.js"
		"jymin/cookies.js"
		"jymin/dom.js"
		"jymin/events.js"
		"jymin/forms.js"
		"jymin/ajax.js"
		"jymin/md5.js"
		"jymin/dollar.js"
		"codemirror/codemirror.js"
		"codemirror/coffeescript.js"
		"codemirror/css.js"
		#"codemirror/htmlmixed.js"
		"codemirror/jade.js"
		"codemirror/javascript.js"
		"codemirror/less.js"
		#"codemirror/sass.js"
		#"codemirror/sql.js"
		#"codemirror/xml.js"
		"editor/storage.coffee"
		"editor/icons.coffee"
		"editor/key_bindings.coffee"
		"editor/nav.coffee"
		"editor/socket.coffee"
		"editor/menu.coffee"
		"editor/tree.coffee"
		"editor/console.coffee"
		"editor/search.coffee"
		"editor/editor.coffee"
		"jymin/closure_foot.js"
	]

for href, components of radeditPublic
	for componentRel, index in components
		components[index] = publicRel + '/' + componentRel
	config.public[href] = components

modifiedTimes = {}

ignorePattern = '.\n' + fs.readFileSync appPath + '/.gitignore'
ignorePattern = ignorePattern.replace /(^\s|\s+$)/, ''
ignorePattern = ignorePattern.replace /\./g, '\\.'
ignorePattern = ignorePattern.replace /\*/g, '.*'
ignorePattern = ignorePattern.replace /\s+/g, '|'
ignorePattern = ignorePattern.replace /\|node_modules/g, ''
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
	loadFiles moduleRoot
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
		loadFile path, previousTime


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
	log.warn "Critical file changed (#{path}). Restarting app."
	setTimeout process.exit, APP_RESTART_DELAY


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
		wait()
		fs.readFile path, (err, content) ->
			if err
				unwait()
				return log.warn "Failed to read path: #{path}"
			doLinting err, content
			unwait()


loader.loadFile =
loadFile = (path, reloadContent) ->
	rel = getRel path

	if reloadContent
		log "Updated: #{path}"
		loader.updateVTag()

	# Load public files.
	if publicPattern.test rel
		lintFile path, reloadContent, (content) ->
			content = loadPublic path, content
			type = getMime(path) or 'text/html'
			href = rel.replace modulesPattern, ''
			href = href.replace publicPattern, '$1'
			href = href.replace /\.html$/, ''
			href = href.replace /\.coffee$/, '.js'
			href = '/' + href
			asset = createPublicAsset href, content
			routePublic href, rel

	# Load jade views for the server.
	else if getExtension(rel) is 'jade'
		# Load dependent views
		loadView = (name, path, shouldUpdate) ->
			if path
				lintFile path, reloadContent, (content) ->
					content = '' + content
					view = jade.compile content, {filename: path}
					view.path = path
					view.minified = content
					view.afterShrunk = ->
						minPath = path.replace /\.jade$/, '.min.jade'
						minCode = view.minified.replace /(^|\n)(\s+include\s+\S+)/g, '$1$2.min'
						view.min = jade.compile minCode, {filename: minPath}
					loader.views[name] = view
					loader.onReady ->
						radedit.shrinker.shrink view
					refreshClients 'views'
					if shouldUpdate
						loader.onReady ->
							search.update rel, content

		name = rel.replace /\.jade$/, ''
		name = name.replace modulesPattern, ''
		name = name.replace viewsPattern, '$1'
		loadView name, path, true

		for own otherName of loader.views
			if otherName isnt name
				loadView otherName, loader.views[otherName].path

	# Load modules
	else
		if loader.isWindows
			path = path.replace /\//g, '\\'
		if /(coffee|js|json)$/.test path
			# If it's not the first time, we may need to reload or restart.
			module = require.cache[path]
			if module
				# Reloadable modules have an unload function.
				if module.exports.unload
					module.exports.unload()
					loadModule path
				# Non-reloadable modules require an application restart.
				else if reloadContent
					return restartApp path
			else
					loadModule path

		lintFile path, reloadContent, (content) ->
			loader.onReady ->
				search.update rel, content

wait = ->
	loader.waitingCount++

unwait = ->
	loader.waitingCount--
	if not loader.waitingCount
		loader.queue.forEach process.nextTick
		loader.queue = []

# Recursively walk a directory, calling functions on each file and directory.
walk = (dir, fileCallback, dirCallback) ->
	wait()
	fs.readdir dir, (err, files) ->
		if err
			unwait()
			return log.warn "Failed to read directory: #{dir}"
		if dirCallback
			dirCallback dir, files
		files.forEach (filename) ->
			if not ignorePattern.test filename
				path = dir + '/' + filename
				wait()
				fs.stat path, (err, stat) ->
					if err
						unwait()
						return log.warn "Failed to stat path: #{path}"
					isDirectory = stat.isDirectory()
					if isDirectory
						walk path, fileCallback, dirCallback
					else if fileCallback
						fileCallback path, stat
					unwait()
		unwait()


loader.public =
	assets: {}
	parents: {}
	groups: {}
	timeouts: {}


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
			content = coffee.compile '' + content
			content = content.replace /^\(function\(\) \{/, ''
			content = content.replace /\}\)\.call\(this\);[\r\n]*$/, ''
		catch e
			log.debug "Can't compile #{path}"
			log.error e

	asset = createPublicAsset rel, content
	loader.public.assets[rel] = asset
	if /jymin/.test rel
		something = true # TODO: Figure out why removing this fucks things up.
	if groups = loader.public.parents[rel]
		groups.forEach (group) ->
			clearTimeout loader.public.timeouts[group]
			loader.public.timeouts[group] = setTimeout(->
				clearTimeout loader.public.timeouts[group]
				compilePublic group
			, PUBLIC_FILE_COMPILE_DELAY)
	return asset

compilePublic = (group) ->
	extension = getExtension group
	files = config.public[group]
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

	refreshClients 'public'


mapPublicAssets = ->
	groups = config.public
	for group, files of groups
		for file in files
			list = loader.public.parents[file]
			if not list
				list = loader.public.parents[file] = []
			if list.indexOf group < 0
				list.push group


loader.updateVTag()
mapPublicAssets()
