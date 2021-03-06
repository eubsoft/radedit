module.exports =
	port: 8000
	publics:
		"/core.css": [
			"public/css/editor.css"
			"public/css/codemirror.css"
		]
		"/core.js": [
			"npm jymin src/closure-head.js"
			"npm jymin src/logging.js"
			"npm jymin src/strings.js"
			"npm jymin src/numbers.js"
			"npm jymin src/url.js"
			"npm jymin src/collections.js"
			"npm jymin src/cookies.js"
			"npm jymin src/dom.js"
			"npm jymin src/events.js"
			"npm jymin src/forms.js"
			"npm jymin src/ajax.js"
			"npm jymin src/history.js"
			"npm jymin src/md5.js"
			"npm jymin src/dates.js"
			"npm jymin src/socket.js"
			"npm jymin src/refresh.js"
			"npm jymin src/dollar.js"
			"npm codemirror lib/codemirror.js"
			"npm codemirror mode/coffeescript/coffeescript.js"
			"npm codemirror mode/css/css.js"
			"npm codemirror mode/jade/jade.js"
			"npm codemirror mode/javascript/javascript.js"
			"public/editor/storage.coffee"
			"public/editor/icons.coffee"
			"public/editor/key-bindings.coffee"
			"public/editor/nav.coffee"
			"public/editor/menu.coffee"
			"public/editor/tree.coffee"
			"public/editor/console.coffee"
			"public/editor/search.coffee"
			"public/editor/editor.coffee"
			"public/manager/manager.coffee"
			"npm jymin src/closure-foot.js"
		]

