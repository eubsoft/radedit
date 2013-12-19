# Icons are specified as:
#	key: [
#		[strokeColor, fillColor, svgPath]
#		...
#   ]
icons =
	folder: [
		['ed8', 'b92', 'M1.5,5.5v11h17v-11h-17l2-3h5l2,3z']
	]
	file: [
		['fff', '999', 'M5.5,0.5v17h13v-12l-5-5v5h5l-5-5z']
	]
	save: [
		['47c', '03a', 'M2.5,2.5v13l2,2h13v-15z']
		['ccc', '999', 'M5.5,2.5v6h9v-6z']
		['ccc', '666', 'M6.5,12.5v5h7v-5zM8.5,14.5h1v2h-1z']
	]
	console: [
		['bbb', '000', 'M1.5,3.5v13h17v-13z']
		['fff', '000', 'M3.5,6.5l3,2l-3,2l3-2zM8.5,11.5h4z']
	]
	search: [
		['555', '', 'M12.5,11.5h1.5l5,5l-1.5,1.5l-5,-5zM4.5,8.5c0,6,9,6,9,0c0-6-9-6-9,0z']
	]
	db: [
		['bcd', '567', 'M2.5,4.5c0,4,15,4,15,0c0-4-15-4-15,0v11c0,4,15,4,15,0v-11c0,4-15,4-15,0z']
	]
	add: [
		['cfc', '090', 'M7.5,7.5v-4h5v4h4v5h-4v4h-5v-4h-4v-5z']
	]
	delete: [
		['fdd', '900', 'M3.5,7l3,3l-3,3l3.5,3.5l3-3l3,3l3.5-3.5l-3-3l3-3l-3.5-3.5l-3,3l-3-3z']
	]
	minus: [
		['aaa', '444', 'M5.5,7.5l4,6l4-6l-4,1z']
	]
	plus: [
		['aaa', '444', 'M7.5,5.5l6,4l-6,4l1-4z']
	]
	settings: [
		['ccc', '666', 'M8.9,1.5h2.2l0.7,4.1l3.5,-2.5l1.5,1.5l-2.5,3.5l4.1,0.7v2.2l-4.1,0.7l2.5,3.5l-1.5,1.5l-3.5,-2.5l-0.7,4.1h-2.2l-0.7-4.1l-3.5,2.5l-1.5-1.5l2.5-3.5l-4.1-0.7v-2.2l4.1,-0.7l-2.5-3.5l1.5-1.5l3.5,2.5z M7.5,10c0,3.33,5,3.33,5,0c0-3.33-5-3.33-5,0z']
	]
	on: [
		['dfd', '080', 'M2.5,10c0,10,15,10,15,0c0-10-15-10-15,0z']
		['dfd', '050', 'M5.5,12c1,4,8,4,9,0c-1,3-8,3-9,0zM9,6.5c0-0.5,2-0.5,2,0c0,4.5,6.5,3.5,6.5,0c0-1-6.5-1-6.5,0c0-0.5-2-0.5-2,0c0-1-6.5-1-6.5,0c0,3.5,6.5,4.5,6.5,0z']
	]
	off: [
		['fdd', '800', 'M2.5,10c0,10,15,10,15,0c0-10-15-10-15,0z']
		['fdd', '500', 'M5.5,12c1,4,8,4,9,0c-1,3-8,3-9,0zM9,6.5c0-0.5,2-0.5,2,0c0,4.5,6.5,3.5,6.5,0c0-1-6.5-1-6.5,0c0-0.5-2-0.5-2,0c0-1-6.5-1-6.5,0c0,3.5,6.5,4.5,6.5,0z']
	]
	waiting: [
		['ffd', '880', 'M2.5,10c0,10,15,10,15,0c0-10-15-10-15,0z']
		['ffd', '550', 'M5.5,12c1,4,8,4,9,0c-1,3-8,3-9,0zM9,6.5c0-0.5,2-0.5,2,0c0,4.5,6.5,3.5,6.5,0c0-1-6.5-1-6.5,0c0-0.5-2-0.5-2,0c0-1-6.5-1-6.5,0c0,3.5,6.5,4.5,6.5,0z']
	]
	empty: []


# Convert icons to SVG HTML.
for own key, paths of icons
	html = '<svg>'
	for path in paths
		fill = if path[1] then '#' + path[1] else 'transparent'
		html += '<path stroke="#' + path[0] + '" fill="' + fill + '" d="' + path[2] + '" stroke-linejoin="round"></path>'
	html += '</svg>'
	icons[key] = html

icons.tree = icons.folder
icons.status = icons.waiting
