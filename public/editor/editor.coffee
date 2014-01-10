# Time to wait before requesting a missing transform.
TRANSFORM_SEQUENCE_TIMEOUT = 2500

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
	currentFile["EDITS#{currentFile.version}"] =
	currentFile.edits = []
	if not currentFile.transforms
		currentFile.transforms = {}

incrementVersion = ->
	currentFile.version++
	startRevising()
	enableSaveButton true


socketOn 'radedit:got', (json) ->
	currentFile = json
	startRevising()
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

		currentFile.edits.push [
			from
			removed.length
			text
		]

		socketEmit 'radedit:change',
			rel: rel
			version: currentFile.version
			edits: currentFile.edits
		, true

		enableSaveButton true


socketOn 'radedit:changed', (json) ->

	if json.rel isnt currentFile.rel
		return log "Ignoring changes for #{json.rel} because the current file is #{currentFile.rel}."

	currentFile.transforms["TRANSFORM#{json.version}"] = json

	integrateTransforms()


# Recursively integrate the next transform(s) in the version sequence.
integrateTransforms = ->

	# Check for the transform that brings the current version to the next.
	transform = currentFile.transforms["TRANSFORM#{currentFile.version}"]

	# If the next transform exists, integrate it.
	if transform
		# Cancel any requests for missing transforms.
		clearTimeout integrateTransforms.sequenceTimeout

		# If an emission ID exists, the transform came from this client.
		if transform.EID
			# TODO: Remove this transform from the unconfirmed list.

		# If the emission came from another client, we must apply it.
		else
			# Apply the transform's edits in order.
			for edit in transform.edits

				# Edits are [start, length, text].
				doc = editor.doc
				text = edit[2]
				change =
					from: edit[0]
					to: edit[0] + edit[1]
				pos = peek = 0
				line = -1

				# Convert "from" and "to" boundaries from string position to line and character.
				for own key, boundary of change
					while peek <= boundary
						pos = peek
						peek += doc.getLine(++line).length + 1
					change[key] = {line: line, ch: boundary - pos}
		
				# TODO: If unconfirmed edits exist, apply offsets.
		
				change.replacement = text
				doc.replaceRange change.replacement, change.from, change.to, 'io'

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
				delete currentFile.transforms["TRANSFORM#{currentFile.version}"]

		# A gap indicates a missing transform that we may need to request.
		if hasGapInSequence
			# Cancel any previous timeouts.
			clearTimeout integrateTransforms.sequenceTimeout
			# Set a timeout to request the missing transform.
			integrateTransforms.sequenceTimeout = setTimeout(->
				log "We haven't received the transform for version #{currentFile.version}."
				# TODO: Request the missing transform.
			, TRANSFORM_SEQUENCE_TIMEOUT)


rel = location.hash.substr 1
fetchFile rel if rel

# Hide the menu when the editor is clicked.
delegate document, '.CodeMirror', 'mousedown', hideMenuArea

