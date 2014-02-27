maxPort = 8000

populateApps = (apps) ->
	setHtml $apps, getHtml getFirstChild $apps
	forEach apps, (app) ->
		$row = addElement $apps, 'tr'
		$row._APP = app
		app._ROW = $row
		apps[app.name] = app
		$name = addElement $row, 'td'
		setText $name, app.name
		$port = addElement $row, 'td'
		$link = addElement $port, 'a'
		$link.href = "http://localhost:#{app.port}/"
		setText $link, app.port
		$controls = addElement $row, 'td._CONTROLS'
		maxPort = Math.max maxPort, app.port

		forEach ['_START', '_FOLDER', '_CONFIG', '_DELETE'], (icon) ->
			$icon = addElement $controls, "i.#{icon}._CONTROL"
			$icon.app = app
			setHtml $icon, icons[icon]
		
		showAppStatus app

showAppStatus = (app) ->
	$row = app._ROW
	$icons = $$ 'i._START', $row
	$icon = $icons[0]
	$links = $$ 'a', $row
	$link = $links[0]
	flipClass $link, '_DISABLED', not app.isOn
	removeClass $icon, '_SPIN'
	setHtml $icon, if app.isOn then icons._STOP else icons._START


socketOn "radedit:apps", populateApps


apps = window.apps
$apps = $ '_APPS'

if apps
	populateApps apps

	iconActions =
		_FOLDER: 'edit'
		_CONFIG: 'config'
		_DELETE: 'delete'


delegate $apps, 'i._CONTROL', 'click', ($event, $parent, $icon) ->
	app = $icon.app

	callApp = (action, callback) ->
		url = "/#{action}?app=#{app.name}"
		getJson url, (json) ->
			callback json

	firstClass = ($icon.className.split ' ')[0]

	if firstClass is '_START'
		action = if app.isOn then 'stop' else 'start'
		setHtml $icon, icons._LOADING
		addClass $icon, '_SPIN'
		app.isOn = not app.isOn
		callApp action, (json) ->

	else
		action = iconActions[firstClass]
		if action
			window.location = "/#{action}?app=#{escape(app.name)}"

bind '_CREATE_APP', 'click', ->
	window.location = '/config?port=' + (maxPort + 1)


showConfigForm = (config) ->
	config.oldName = config.name
	$elements = $configForm.elements
	forEach $elements, ($element) ->
		name = $element.name
		value = config[name]
		if value and value.join
			value = value.join ', '
		valueOf $element, value
	setText '_CONFIG_HEADING', if config.name then "Configure App: #{config.name}" else "Create App"
	setText '_SAVE_CONFIG', if config.name then "Save Configuration" else "Save New App"


bind '_SAVE_CONFIG', 'click', ->
	values = []
	forEach $configForm.elements, ($element) ->
		if $element.name
			values.push $element.name + '=' + escape valueOf $element
	window.location = '/save-config?' + values.join '&'


$configForm = $ '_CONFIG_FORM'
app = window.app
if app
	showConfigForm app