# Kindles look better if they're zoomed in a bit.
if /Silk/.test navigator.userAgent
	getElementsByTagName('body')[0].style.fontSize = '20px'
	forEach getElementsByTagName('svg'), (element) ->
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
currentRel = null
lineNumber = null
charNumber = null

fetchFile = (rel) ->
	parts = rel.split /:/
	rel = parts[0]
	lineNumber = parts[1]
	charNumber = parts[2]
	socket.emit 'radedit:get', {rel: rel}

saveFile = ->
	if hasClass 'saveButton', 'disabled'
		return
	enableSaveButton false
	socket.emit 'radedit:save', {rel: currentRel}

socket.on 'radedit:got', (json) ->
	flipClass 'treeButton', 'on', 0
	flipClass 'tree', 'on', 0
	rel = json.rel
	code = json.code
	if typeof code is 'undefined'
		code = ''
	extension = rel.replace /^.*\./, ''
	mode = modes[extension] or 'text'

	location.hash = '#' + rel
	document.title = "RadEdit: #{rel}"

	container = getElement 'content'
	editor = CodeMirror(container,
		mode: mode
		smartIndent: true
		indentWithTabs: true
		lineNumbers: true
		autofocus: true
		value: code
	)
	currentRel = rel
	enableSaveButton json.canSave

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
		socket.emit 'radedit:change', {rel: rel, change: change}
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

