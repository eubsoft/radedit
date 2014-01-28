# Time to wait before requesting a missing transform.
TRANSFORM_SEQUENCE_TIMEOUT = 2500

EDITOR_HISTORY_DELAY = 500
VERSION_INDEX = 3

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
	socketEmit 'radedit:get', {rel: rel}, true
	removeClass '_TREE__BUTTON', '_ON'
	removeClass '_TREE', '_ON'
	removeClass '_LOADING', '_HIDDEN'

saveFile = ->
	if hasClass '_SAVE__BUTTON', '_DISABLED'
		return
	enableSaveButton false
	socket.emit 'radedit:save', {rel: currentFile.rel}

startRevising = ->
	if not currentFile.editNumber
		currentFile.editNumber = 0
	if not currentFile.edits
		currentFile.edits = {}
	if not currentFile.transforms
		currentFile.transforms = {}

incrementVersion = ->
	currentFile.version++
	startRevising()
	enableSaveButton true


gotFile = (json, isInitialLoad) ->
	currentFile = json
	currentFile.edits = {}
	startRevising()
	rel = json.rel
	code = json.code
	if typeof code is 'undefined'
		code = ''
	extension = rel.replace /^.*\./, ''
	mode = modes[extension] or 'text'

	$container = $ '_CONTENT'
	editor = CodeMirror($container,
		mode: mode
		smartIndent: true
		indentWithTabs: true
		lineNumbers: true
		autofocus: true
		showCursorWhenSelecting: true
		value: code
	)
	enableSaveButton json.canSave
	addClass '_LOADING', '_HIDDEN'

	editor.on 'beforeChange', (cm, change) ->
		for text, i in change.text
			change.text[i] = text.replace '  ', '\t'

	editor.on 'change', (cm, change) ->
		processEditorChange change

	processEditorChange = (change) ->
		if change.origin is 'io'
			return
		log change
		from = 0
		to = change.from.line - 1
		if to > -1
			for i in [0..to]
				from += editor.doc.getLine(i).length + 1
		from += change.from.ch
		text = removed = ''
		text += change.text.join '\n'
		removed += change.removed.join '\n'

		if change.next
			# TODO: Apply a transformation to the next change.
			processEditorChange change.next

		edit = [
			from
			removed.length
			text
			currentFile.version
			currentFile.editNumber++
		]
		data =
			rel: rel
			edit: edit

		if getCookie 'autoSave'
			data.autoSave = true

		socketEmit 'radedit:edit', data, true
		currentFile.edits["e#{data.EID}"] = edit

		enableSaveButton true


	editor.on 'scroll', (cm) ->
		setEditorUrl()

	editor.on 'cursorActivity', ->
		setEditorUrl()

	document.title = "RadEdit: #{rel}"
	shouldPushHistory = not isInitialLoad
	setTimeout ->
		doSetEditorUrl shouldPushHistory
	, 0


# Scroll the editor to a specified pixel offset.
scrollEditorTo = (x, y) ->
	# Ensure that we are scrolling to integer locations.
	editor.scrollTo x * 1, y * 1
	# Trigger a redraw to ensure lines are rendered in the viewport.
	editor.setSize()


# Return a line number and character number from a comma-delimited pair.
getLineAndCharacter = (commaPair) ->
	if commaPair
		lineAndCharacter = commaPair.split(',')
		lineAndCharacter =
			line: lineAndCharacter[0] * 1
			ch: lineAndCharacter[1] * 1


setEditorSelection = (anchor, head) ->
	if anchor or head
		anchor = getLineAndCharacter anchor
		head = getLineAndCharacter head
		editor.setSelection anchor, head


setEditorUrl = (shouldPushHistory) ->
	clearTimeout setEditorUrl.T
	setEditorUrl.T = setTimeout ->
		doSetEditorUrl shouldPushHistory
	, EDITOR_HISTORY_DELAY

doSetEditorUrl = (shouldPushHistory) ->
	clearTimeout setEditorUrl.T
	doc = editor.doc
	sel = doc.sel or {}
	anchor = sel.anchor
	head = sel.head
	x = forceNumber doc.scrollLeft
	y = forceNumber doc.scrollTop
	href = location.protocol + '//' + location.host
	href += "/radedit?rel=#{currentFile.rel}"
	href += "&x=#{x}&y=#{y}"
	if anchor
		href += '&a=' + "#{anchor.line},#{anchor.ch}"
	if head
		href += '&h=' + "#{head.line},#{head.ch}"
	if href isnt location.href
		if shouldPushHistory
			pushHistory href
		else
			replaceHistory href


socketOn 'radedit:got', gotFile


socketOn 'radedit:edited', (json) ->

	if json.rel isnt currentFile.rel
		return log "Ignoring changes for #{json.rel} because the current file is #{currentFile.rel}."

	transform = json.edit
	version = transform[VERSION_INDEX]
	currentFile.transforms["v#{version}"] = transform

	# The emission ID is used to identify previous edits.
	if json.EID
		transform.EID = json.EID

	integrateTransforms()


# Recursively integrate the next transform(s) in the version sequence.
integrateTransforms = ->

	# Check for the transform that brings the current version to the next.
	transform = currentFile.transforms["v#{currentFile.version}"]

	# If the next transform exists, integrate it.
	if transform
		
		# Cancel any requests for missing transforms.
		clearTimeout integrateTransforms.sequenceTimeout

		# If the transform came from this client, remove it from unconfirmed edits.
		if transform.EID
			delete currentFile.edits["e#{transform.EID}"]
			
		# If the emission came from another client, we must apply it.
		else

			# Apply unconfirmed edits before applying the transform.
			for own key, edit of currentFile.edits
				applyTransformToEdit edit, transform

			# Edits are [start, length, text].
			doc = editor.doc
			text = transform[2]
			change =
				from: transform[0]
				to: transform[0] + transform[1]
			pos = peek = 0
			line = -1

			# Convert "from" and "to" boundaries from string position to line and character.
			for own key, boundary of change
				try
					while peek <= boundary
						pos = peek
						string = doc.getLine ++line
						peek += string.length + 1
				catch e
					log e
				change[key] = {line: line, ch: boundary - pos}

			change.replacement = text
			doc.replaceRange change.replacement, change.from, change.to, 'io'

			# Transform unconfirmed edits to be relative to the new version.
			for own key, edit of currentFile.edits
				applyTransformToEdit transform, edit

		# Each transform in the sequence brings us one version forward.
		incrementVersion()

		# Check for more transforms in the sequence.
		integrateTransforms()

	# If we don't have a transform, we can request it if necessary.
	else
		# Check for gaps in the sequence.
		hasGapInSequence = false
		for own transform of currentFile.transforms
			# There's no current transform, so future transforms are evidence of a gap.
			if transform.version > currentFile.version
				hasGapInSequence = true
			# Past transforms have already been integrated, so they can be deleted.
			if transform.version < currentFile.version
				delete currentFile.transforms["v#{currentFile.version}"]

		# A gap indicates a missing transform that we may need to request.
		if hasGapInSequence
			# Cancel any previous timeouts.
			clearTimeout integrateTransforms.sequenceTimeout
			# Set a timeout to request the missing transform.
			integrateTransforms.sequenceTimeout = setTimeout(->
				log "We haven't received the transform for version #{currentFile.version}."
				# TODO: Request the missing transform.
			, TRANSFORM_SEQUENCE_TIMEOUT)


applyTransformToEdit = (transform, edit) ->
	start = transform[0]
	deleted = transform[1]
	end = start + deleted
	inserted = transform[2].length
	# If the transform started left of the edit, adjust.
	if start <= edit[0]
		# If the transform finished left of the edit, shift the edit.
		if end <= edit[0]
			edit[0] += inserted - deleted
		# If the transform encloses the edit, nullify the edit.
		else if end >= edit[0] + edit[1]
			edit[1] = 0
			edit[2] = ''
		# TODO: What if the transform partially encloses the edit?
		else
			log "WARNING: Unhandled transformation (partially enclosed)."


file = window.file
if file
	query = getQueryParams()
	isInitialLoad = true
	gotFile file, isInitialLoad
	scrollEditorTo query.x, query.y
	setEditorSelection query.a, query.h

bind window, 'popstate', ->
	rel = getQueryParams().rel
	if rel isnt currentFile.rel
		fetchFile rel

# Hide the menu when the editor is clicked.
delegate document, '.CodeMirror', 'mousedown', hideMenuArea

