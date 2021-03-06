#NOCLOSURE

# Icons are specified as:
#	key: [
#		[strokeColor, fillColor, svgPath]
#		...
#	]
icons =
	_FOLDER: [
		['ed8', 'b92', 'M1.5,5.5v11h17v-11h-17l2-3h5l2,3z']
	]
	_FILE: [
		['fff', '999', 'M5.5,0.5v17h13v-12l-5-5v5h5l-5-5z']
	]
	_SAVE: [
		['47c', '03a', 'M2.5,2.5v13l2,2h13v-15z']
		['ccc', '999', 'M5.5,2.5v6h9v-6z']
		['ccc', '666', 'M6.5,12.5v5h7v-5zM8.5,14.5h1v2h-1z']
	]
	_CONSOLE: [
		['bbb', '000', 'M1.5,3.5v13h17v-13z']
		['fff', '000', 'M3.5,6.5l3,2l-3,2l3-2zM8.5,11.5h4z']
	]
	_SEARCH: [
		['555', '', 'M11.5,11h1.5l5,5l-1.5,1.5l-5,-5zM3.5,8c0,6,9,6,9,0c0-6-9-6-9,0z']
	]
	_DB: [
		['bcd', '567', 'M2.5,4.5c0,4,15,4,15,0c0-4-15-4-15,0v11c0,4,15,4,15,0v-11c0,4-15,4-15,0z']
	]
	_ADD: [
		['7e7', '090', 'M7.5,7.5v-4h5v4h4v5h-4v4h-5v-4h-4v-5z']
	]
	_DELETE: [
		['fcc', 'b00', 'M3.5,7l3,3l-3,3l3.5,3.5l3-3l3,3l3.5-3.5l-3-3l3-3l-3.5-3.5l-3,3l-3-3z']
	]
	_START: [
		['7e7', '090', 'M3.5,17.5v-15l14,7.5z']
	]
	_STOP: [
		['f88', 'b00', 'M3.5,3.5h13v13h-13z']
	]
	_MINUS: [
		['aaa', '444', 'M5.5,7.5l4,6l4-6l-4,1z']
	]
	_PLUS: [
		['aaa', '444', 'M7.5,5.5l6,4l-6,4l1-4z']
	]
	_CONFIG: [
		['ccc', '666', 'M8.2,0.5h3.6l0.4,2.6l2.5,1.4l2.6-1.3l2,3.4l-2.1,1.6v3.6l2.1,1.6l-2,3.4l-2.6-1.3l-2.5,1.4l-0.4,2.6h-3.6l-0.4-2.6l-2.5-1.4l-2.6,1.3l-2-3.4l2.1-1.6v-3.6l-2.1-1.6l2-3.4l2.6,1.3l2.5-1.4zM6.5,10c0,4.67,7,4.67,7,0c0-4.67-7-4.67-7,0z']
	]
	_MENU: [
		['aaa', '888', 'M3,4.5c-1.3,0-1.3,2,0,2h14c1.3,0,1.3-2,0-2zm0,5c-1.3,0-1.3,2,0,2h14c1.3,0,1.3-2,0-2zm0,5c-1.3,0-1.3,2,0,2h14c1.3,0,1.3-2,0-2z']
	]
	_LOADING: [
		['aaa', '666', 'M2.5,12c1,8,14,8,15,1h-3c-0.5,4-8.5,4-9,-1h2l-3.5-3l-3.5,3zM17.5,8c-1-8-14-8-15,-1h3c0.5-4,8.5-4,9,1h-2l3.5,3l3.5-3z']
	]
	_RADEDIT: [
		['000', 'c70', 'M0.5,10c0,12.6,19,12.6,19,0c0-12.6-19-12.6-19,0z']
		['000', '000', 'M4.5,12c1,5,10,5,11,0c-1,4-10,4-11,0z']
		['000', '25b', 'M9,5c0-0.5,2-0.5,2,0c0,6.5,8.5,4.5,8.5,0c0-1.5-8.5-1.5-8.5,0c0-0.5-2-0.5-2,0c0-1.5-8.5-1.5-8.5,0c0,4.5,8.5,6.5,8.5,0z']
	]
	_TRASH: [
		['f99', '900', 'M3.5,6.5v9c0,3.5,13,3.5,13,0v-9c0,2.5-13,2.5-13,0zM2.5,5c0,4,15,4,15,0c0-4-15-4-15,0M6.5,5c0-2,7-2,7,0c0-2-7-2-7,0zM5.5,9.5v6.2zM8.5,10v6.5zM11.5,10v6.5zM14.5,9.5v6.2z']
	]
	_EMPTY: []


# Convert icons to SVG HTML.
for own key, paths of icons
	html = '<svg>'
	for path in paths
		fill = if path[1] then '#' + path[1] else 'transparent'
		html += '<path stroke="#' + path[0] + '" fill="' + fill + '" d="' + path[2] + '" stroke-linejoin="round"></path>'
	html += '</svg>'
	icons[key] = html

icons._TREE = icons._FOLDER
icons._STATUS = icons._WAITING
