MAX_CONSOLE_LINES = 1000

$console = $ '_CONSOLE'
$consoleButton = $ '_CONSOLE__BUTTON'

consoleClasses =
	log: '_LOG'
	trace: '_TRACE'
	debug: '_DEBUG'
	info: '_INFO'
	warn: '_WARN'
	error: '_ERROR'

scrollConsole = ->
	$console.scrollTop = $console.scrollHeight

consoleLineCount = 0
socketOn 'radedit:log', (lines) ->
	previousLineCount = consoleLineCount
	forEach lines, (line) ->
		if ++consoleLineCount > MAX_CONSOLE_LINES
			removeElement getFirstChild $console
		className = consoleClasses[line[0]]
		innerText = line[1]
		line = addElement $console, 'pre'
		setClass line, className
		setText line, innerText
		links = $$ 'a', line
		if className is 'error' and previousLineCount
			addClass $consoleButton, '_ERROR'
	scrollConsole()

delegate $console, 'a', 'click', (event, $element, $target) ->
	rel = getText($target).replace /\\/g, '/'
	fetchFile rel
	hideMenuArea()
