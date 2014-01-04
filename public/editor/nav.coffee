$nav = $ '_NAV'

# Populate the nav.
navButtons = ['_MENU', '_TREE', '_CONSOLE', '_SAVE']
for key in navButtons
	extra = if key is 'save' then '._DISABLED' else '._TOGGLE'
	$item = addElement $nav, 'div#' + key + '__BUTTON._NAV' + extra
	setHtml $item, icons[key]

# Last button to be clicked.
$lastClickedButton = null

# When a nav item is clicked, toggle it and turn all others off.
delegate $nav, 'div._NAV', 'click', (event, $nav, $clickedButton) ->
	if not hasClass $clickedButton, '_DISABLED'
		$lastClickedButton = $clickedButton
		turnOn = not hasClass $clickedButton, '_ON'
		$$buttons = getChildren $nav
		for $button in $$buttons
			flipButton $button, if $button == $clickedButton then turnOn else false

		if $clickedButton.id is '_SAVE__BUTTON'
			saveFile()


# Turn a button on or off.
flipButton = ($button, turnOn) ->
	if hasClass $button, '_TOGGLE'
		flipClass $button, '_ON', turnOn
		$area = $ $button.id.replace '__BUTTON', ''
		if $area
			flipClass $area, '_ON', turnOn
			if turnOn and $area is $console
				scrollConsole()
				removeClass $button, '_ERROR'

# Turn the active area off.
hideMenuArea = ->
	if $lastClickedButton
		flipButton $lastClickedButton

# Enable or disable the save button
enableSaveButton = (enable) ->
	flipClass '_SAVE__BUTTON', '_DISABLED', not enable

# Show the status of the connection: (on|off|waiting)
showConnectionStatus = (status) ->
	# TODO: Make the nav button (or something) show yellow or red when the connection is broken.

# TODO: User preferences.
$avatar = addElement $nav, 'img#_AVATAR'
$avatar.src = 'http://gravatar.com/avatar/4a4c0726ea748003742f5d5dbd1cbad1?s=40'

enableSaveButton false
