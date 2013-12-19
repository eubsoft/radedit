global.fs = require 'fs'
global.jade = require 'jade'
global.events = require 'events'
global.coffee = require 'coffee-script'

global.isDevMode = true
global.isWindows = /\bwin/i.test process.platform
global.startTime = new Date

global.loader =
	tree: {}
	cache: {}
	views: {}
	public: {}

APP_RESTART_DELAY = 10
CLIENT_REFRESH_DELAY = 50
PUBLIC_FILE_COMPILE_DELAY = 5
DIR_WALK_INTERVAL = 1000

mime =
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


getRel = (path) ->
	if path.substr(0, documentRoot.length) is documentRoot
		return path.substr documentRoot.length + 1
	else
		return path.replace modulesPattern, '../node_modules/'

getExtension = (file) ->
	return file.replace /.*\./, ''

loader.getMime =
getMime = (path) ->
	return mime[getExtension path]



modulesPattern = /^.*[\/\\]node_modules[\/\\]/
publicPattern = /(^|[\/\\])public[\/\\]/
viewsPattern = /(^|[\/\\])views[\/\\]/

moduleRoot = __dirname.replace /[\/\\]app$/, ''
publicRel = getRel moduleRoot + '/public'

publicAssets =
	"/radedit.css": [
		"css/editor.css"
		"css/codemirror.css"
	],
	"/radedit.js": [
		"jymin/logging.js"
		"jymin/strings.js"
		"jymin/collections.js"
		"jymin/dom.js"
		"jymin/events.js"
		"jymin/forms.js"
		"jymin/ajax.js"
		"jymin/md5.js"
		"jymin/io.js"
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
		"editor/menu.coffee"
		"editor/refresh.coffee"
		"editor/tree.coffee"
		"editor/console.coffee"
		"editor/search.coffee"
		"editor/editor.coffee"
	]

for href, components of publicAssets
	for componentRel, index in components
		components[index] = publicRel + '/' + componentRel
	config.public[href] = components

modifiedTimes = {}

ignorePattern = '.\n' + fs.readFileSync documentRoot + '/.gitignore'
ignorePattern = ignorePattern.replace /(^\s|\s+$)/, ''
ignorePattern = ignorePattern.replace /\./g, '\\.'
ignorePattern = ignorePattern.replace /\*/g, '.*'
ignorePattern = ignorePattern.replace /\s+/g, '|'
ignorePattern = ignorePattern.replace /\|node_modules/g, ''
ignorePattern = new RegExp "^(#{ignorePattern})$"

loader.loadFiles =
loadFiles = (path) ->
	path = path or documentRoot
	walk path, checkFile, checkDir
	buildTree()
	setTimeout(->
		loadFiles path
	, DIR_WALK_INTERVAL)

# Load all files
setImmediate ->
	loadFiles moduleRoot
	loadFiles documentRoot


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

loader.loadFile =
loadFile = (path, isReload) ->
	rel = getRel path

	if isReload
		log "Updated: #{path}"

	# Load public files.
	if publicPattern.test rel
		fs.readFile path, (err, content) ->
			loadPublic path, content
			type = getMime(path) or 'text/html'
			href = rel.replace modulesPattern, ''
			href = href.replace publicPattern, '$1'
			href = href.replace /\.html$/, ''
			href = href.replace /\.coffee$/, '.js'
			routePublic '/' + href, content
			search.update rel, content

	# Load jade views for the server.
	else if getExtension(rel) is 'jade'
		# Load dependent views
		loadView = (name, path) ->
			fs.readFile path, (err, content) ->
				view = jade.compile(content,
					filename: path
				)
				loader.views[name] = view
				loader.views[name].path = path
				refreshClients 'views'
				search.update rel, content

		name = rel.replace /\.jade$/, ''
		name = name.replace modulesPattern, ''
		name = name.replace viewsPattern, '$1'
		loadView name, path

		for otherName of loader.views
			if otherName isnt name
				loadView otherName, loader.views[otherName].path

	# Load modules
	else
		if isWindows
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
				else if isReload
					return restartApp path
			else
					loadModule path
		
		fs.readFile path, (err, content) ->
			search.update rel, content


# Recursively walk a directory, calling functions on each file and directory.
walk = (dir, fileCallback, dirCallback) ->
	fs.readdir dir, (err, files) ->
		dirCallback dir, files if dirCallback
		if err
			return
		files.forEach (filename) ->
			if not ignorePattern.test filename
				path = dir + '/' + filename
				fs.stat path, (err, stat) ->
					isDirectory = stat.isDirectory()
					if isDirectory
						walk path, fileCallback, dirCallback
					else
						fileCallback path, stat if fileCallback


publicAssets =
	content: {}
	parents: {}
	groups: {}
	timeouts: {}


loadPublic = (path, content) ->
	if /\.coffee$/.test path
		try
			content = coffee.compile('' + content)
			content = content.replace(/^\(function\(\) \{/, '')
			content = content.replace(/\}\)\.call\(this\);[\r\n]*$/, '')
		catch e
			log.debug "Can't compile #{path}"
			log.error e
	rel = getRel path
	publicAssets.content[rel] = content
	if groups = publicAssets.parents[rel]
		for group in groups
			clearTimeout publicAssets.timeouts[group]
			publicAssets.timeouts[group] = setTimeout( ->
				compilePublic group
			, PUBLIC_FILE_COMPILE_DELAY)


compilePublic = (group) ->
	files = config.public[group]
	code = ''
	for file in files
		code += "/* FILE: #{file} */\n"
		code += publicAssets.content[file]
	publicAssets.content[group] = code
	routePublic group, code
	clearTimeout publicAssets.timeouts[group]


routePublic = (href, content) ->
	type = getMime(href) or 'text/html'
	app.get href, (request, response) ->
		response.set "Content-Type", type
		response.send content
	refreshClients 'public'


mapPublicAssets = ->
	groups = config.public
	for group, files of groups
		for file in files
			list = publicAssets.parents[file] or (publicAssets.parents[file] = [])
			list.push group if list.indexOf(group) < 0


mapPublicAssets()
