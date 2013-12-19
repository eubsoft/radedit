searchBox = addElement 'menu', '#searchBox'
searchBox = addElement searchBox, 'div'
setHtml searchBox, icons.search
searchInput = addElement searchBox, 'input'
searchResults = getElement 'search'

bind searchBox, 'click', ->
	searchInput.focus()
	searchInput.select()

bind searchInput, 'focus', ->
	clearTimeout(searchInput.t)
	flipSearch true

bind searchInput, 'blur', ->
	searchInput.t = setTimeout(->
		flipSearch false
	, 9)

flipSearch = (turnOn) ->
	flipClass searchInput, 'focus', turnOn
	flipClass searchResults, 'hidden', not turnOn
	if turnOn
		hideMenuArea()

searchQuery = 0

bind searchInput, 'keyup mouseup', ->
	searchQuery = valueOf searchInput
	socket.emit 'radedit:search', valueOf searchInput

socket.on 'radedit:searched', (results) ->
	removeChildren searchResults
	for result in results
		
		html = result.rel.replace searchQuery, "<b>#{searchQuery}</b>"
		line = addElement searchResults, 'div'
		setHtml line, html

delegate searchResults, 'div', 'mousedown', (event, element, target) ->
	fetchFile getText target