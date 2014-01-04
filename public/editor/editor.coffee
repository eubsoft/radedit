# Kindles look better if they're zoomed in a bit.
if /Silk/.test navigator.userAgent
	document.body.style.fontSize = '20px'
	forEach $$('svg'), (element) ->
		element.style.zoom = '180%'

modes =
	coffee: 'coffeescript'
	css: 'css'
	html: 'htmlmixed'
	jade: 'jade'
	js: 'javascript'
	json: 'javascript'
	less: 'less'
	project: 'xml'
	sas: 'sass'
	sql: 'sql'
	xml: 'xml'

editor = null
currentFile = null
lineNumber = null
charNumber = null
files = {}

fetchFile = (rel) ->
	parts = rel.split /:/
	rel = parts[0]
	lineNumber = parts[1]
	charNumber = parts[2]
	socket.emit 'radedit:get', {rel: rel}
	removeClass '_TREE__BUTTON', '_ON'
	removeClass '_TREE', '_ON'
	removeClass '_LOADING', '_HIDDEN'

saveFile = ->
	if hasClass '_SAVE__BUTTON', '_DISABLED'
		return
	enableSaveButton false
	socket.emit 'radedit:save', {rel: currentFile.rel}

socket.on 'radedit:got', (json) ->
	currentFile = json
	currentFile.revision = 0
	rel = json.rel
	code = json.code
	if typeof code is 'undefined'
		code = ''
	extension = rel.replace /^.*\./, ''
	mode = modes[extension] or 'text'

	location.hash = '#' + rel
	document.title = "RadEdit: #{rel}"

	$container = $ '_CONTENT'
	editor = CodeMirror($container,
		mode: mode
		smartIndent: true
		indentWithTabs: true
		lineNumbers: true
		autofocus: true
		value: code
	)
	enableSaveButton json.canSave
	addClass '_LOADING', '_HIDDEN'

	editor.on 'beforeChange', (cm, change) ->
		for text, i in change.text
			change.text[i] = text.replace '  ', '\t'

	editor.on 'change', (cm, change) ->
		if change.origin is 'io'
			return
		from = 0
		to = change.from.line - 1
		if to > -1
			for i in [0..to]
				from += editor.doc.getLine(i).length + 1
		from += change.from.ch
		text = removed = ''
		while change
			text += change.text.join '\n'
			removed += change.removed.join '\n'
			change = change.next
		change = [
			from
			removed.length
			text
		]
		socket.emit 'radedit:change',
			rel: rel
			change: change
			revision: currentFile.revision++
		enableSaveButton true

socket.on 'radedit:changed', (json) ->
	doc = editor.doc
	change = json.change
	text = change[2]
	change =
		from: change[0]
		to: change[0] + change[1]
	pos = peek = 0
	line = -1
	for own key, boundary of change
		while peek <= boundary
			pos = peek
			peek += doc.getLine(++line).length + 1
		change[key] = {line: line, ch: boundary - pos}
	change.replacement = text
	doc.replaceRange change.replacement, change.from, change.to, 'io'
	enableSaveButton true


rel = location.hash.substr 1
fetchFile rel if rel

# Hide the menu when the editor is clicked.
delegate document, '.CodeMirror', 'mousedown', hideMenuArea

