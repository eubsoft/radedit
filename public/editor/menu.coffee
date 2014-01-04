$fullSource = $ '_FULL_SOURCE'
$fullSource.checked = getCookie 'debug'

bind $fullSource, 'click', ->
	setCookie 'debug', valueOf $fullSource