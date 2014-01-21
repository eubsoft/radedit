menuToggles =
	debug: '_FULL_SOURCE'
	autoSave: '_AUTO_SAVE'


createMenuToggle = (key, value) ->
	$element = $ value
	$element.checked = getCookie key
	
	bind $element, 'click', ->
		setCookie key, valueOf $element


for own key, value of menuToggles
	createMenuToggle key, value

