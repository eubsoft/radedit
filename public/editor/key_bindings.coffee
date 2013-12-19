altDown = false
ctrlDown = false
shiftDown = false

bind document, 'keydown', (event) ->
	key = event.keyCode
	alt = event.altKey
	ctrl = event.ctrlKey
	shift = event.shiftKey

	if ctrl and key is 83
		saveFile()