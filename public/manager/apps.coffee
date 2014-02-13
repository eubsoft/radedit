populateApps = (apps) ->
	maxPort = 8000
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

		forEach ['_FOLDER', '_SETTINGS', '_START'], (icon) ->
			$icon = addElement $controls, "i.#{icon}._CONTROL"
			$icon.app = app
			setHtml $icon, icons[icon]
		
		showAppStatus app

	$row = addElement $apps, 'tr'
	forEach ['name', 'port'], (fieldName) ->
		$cell = addElement $row, 'td'
		$input = addElement $cell, "input##{fieldName}._CELL"
		if fieldName is 'port'
			valueOf $input, maxPort + 1
	$cell = addElement $row, 'td._CONTROLS'
	$icon = addElement $cell, 'i#_ADD._CONTROL'
	setHtml $icon, icons._ADD

showAppStatus = (app) ->
	$row = app._ROW
	$icons = $$ 'i._START', $row
	$icon = $icons[0]
	newIcon = if app.isOn then '_STOP' else '_START'
	setHtml $icon, icons[newIcon]

listenForStatus = (status) ->
	socketOn "radedit:#{status}", (appName) ->
		app = apps[appName]
		if app
			app.isOn = status is 'started'
			showAppStatus app


apps = window.apps
$apps = $ '_APPS'

if apps
	populateApps apps
	
	daemonActions =
		start: 'started'
		stop: 'stopped'

	for own action, status of daemonActions
		listenForStatus status


delegate $apps, 'i._CONTROL', 'click', ($event, $parent, $icon) ->
	app = $icon.app

	callApp = (action, callback) ->
		url = "/#{action}?app=#{app.name}"
		getJson url, (json) ->
			callback json

	if hasClass $icon, '_START'
		action = if app.isOn then 'stop' else 'start'
		callApp action, (json) ->
			log json
		app.isOn = not app.isOn
		log app.isOn
		showAppStatus app

	else if hasClass $icon, '_SETTINGS'
		callApp 'config', (json) ->
			log json

	else if hasClass $icon, '_FOLDER'
		window.location = "/edit?app=#{app.name}"

bind '_ADD', 'click', ->
	name = escape getValue 'name'
	port = escape getValue 'port'
	url = "/create?name=#{name}&port=#{port}"
	getJson url, (json) ->
		# App created.


socketOn "radedit:apps", (apps) ->
	window.apps = apps
	populateApps apps
