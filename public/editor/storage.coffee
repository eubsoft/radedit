localStorage = window.localStorage

getValue = (key) ->
	return JSON.parse localStorage.getItem key

setValue = (key, value) ->
	return localStorage.setItem key, JSON.stringify value
