$menu = getElement 'menu'

# Populate the menu.
menuButtons = ['status', 'tree', 'console', 'save']
for key in menuButtons
	extra = if key is 'save' then '.disabled' else '.toggle'
	item = addElement $menu, 'div#' + key + 'Button.menu' + extra
	setHtml item, icons[key]

# Last button to be clicked.
lastClickedButton = 0

# When a menu item is clicked, toggle it and turn all others off.
delegate $menu, 'div.menu', 'click', (event, menu, clickedButton) ->
	if not hasClass clickedButton, 'disabled'
		lastClickedButton = clickedButton
		turnOn = not hasClass clickedButton, 'on'
		buttons = getChildren menu
		for button in buttons
			flipButton button, if button == clickedButton then turnOn else false

		if clickedButton.id is 'saveButton'
			saveFile()


# Turn a button on or off.
flipButton = (button, turnOn) ->
	if hasClass button, 'toggle'
		flipClass button, 'on', turnOn
		if area = getElement button.id.replace 'Button', ''
			flipClass area, 'on', turnOn
			if turnOn and area is consoleArea
				scrollConsole()
				flipClass button, 'error', false

# Turn the active area off.
hideMenuArea = ->
	if lastClickedButton
		flipButton lastClickedButton

# Enable or disable the save button
enableSaveButton = (enable) ->
	disabled = not enable
	flipClass 'saveButton', 'disabled', disabled

# Show the status of the connection: (on|off|waiting)
$statusButton = getElement 'statusButton'
showConnectionStatus = (status) ->
	setHtml $statusButton, icons[status]

# TODO: User preferences.
$avatar = addElement $menu, 'img#avatar'
$avatar.src = 'http://gravatar.com/avatar/4a4c0726ea748003742f5d5dbd1cbad1?s=40'