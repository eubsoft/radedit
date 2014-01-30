#NOCLOSURE

$searchBox = addElement $nav, '#_SEARCH_BOX'
$searchBoxInner = addElement $searchBox, 'div'
setHtml $searchBoxInner, icons._SEARCH
$searchInput = addElement $searchBoxInner, 'input'
$searchResults = $ '_SEARCH_RESULTS'

bind $searchBox, 'click', ->
	$searchInput.focus()
	$searchInput.select()

bind $searchInput, 'focus', ->
	clearTimeout($searchInput.t)
	flipSearch true

bind $searchInput, 'blur', ->
	$searchInput.t = setTimeout(->
		flipSearch false
	, 9)

flipSearch = (turnOn) ->
	flipClass $searchInput, '_FOCUS', turnOn
	flipClass $searchResults, '_HIDDEN', not turnOn
	if turnOn
		hideMenuArea()

searchQuery = 0

bind $searchInput, 'keyup mouseup', ->
	searchQuery = valueOf $searchInput
	socketEmit 'radedit:search', searchQuery

socketOn 'radedit:searched', (results) ->
	removeChildren $searchResults
	for result in results
		html = result.rel.replace searchQuery, "<b>#{searchQuery}</b>"
		$line = addElement $searchResults, 'div'
		setHtml $line, html

delegate $searchResults, 'div', 'mousedown', (event, $element, $target) ->
	fetchFile getText $target