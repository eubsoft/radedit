MAX_CONSOLE_LINES = 1000

consoleArea = getElement 'console'

scrollConsole = ->
	consoleArea.scrollTop = consoleArea.scrollHeight

consoleLineCount = 0
socket.on 'radedit:log', (lines) ->
	previousLineCount = consoleLineCount
	forEach lines, (line) ->
		if ++consoleLineCount > MAX_CONSOLE_LINES
			removeElement firstChild consoleArea
		className = line[0]
		innerText = line[1]
		line = addElement consoleArea, 'pre'
		setClass line, className
		setText line, innerText
		links = getElementsByTagName 'a', line
		if className is 'error' and previousLineCount
			flipClass 'consoleButton', 'error', true
	scrollConsole()

delegate consoleArea, 'a', 'click', (event, element, target) ->
	rel = getText(target).replace /\\/g, '/'
	fetchFile rel
	hideMenuArea()
