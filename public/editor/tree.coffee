toggleTree = ->
	toggleClass 'treeButton', 'on'
	toggleClass 'tree', 'on'

class Node
	constructor: (@parent, @name = '') ->
	add: () ->
		child = new Node this
		@children = [] if not @children
		@children.push child
		return child

socket.on 'radedit:tree', (treeString) ->
	node = new Node
	for character in treeString
		if character is '/'
			node = node.add()
		else if character is '|'
			node = node.parent.add()
		else if character is '\\' 
			node = node.parent
			if node.children[0].name is ''
				node.children = []
		else
			node.name += character
	setHtml 'tree', treeHtml node


treeHtml = (node) ->
	inside = ''
	if node.children
		type = 'folder'
		if node.children.length
			mode = 'plus'
			for child in node.children
				inside += treeHtml child if child.children
			for child in node.children
				inside += treeHtml child if not child.children
		else
			mode = 'empty'
		expander = "<i class=plus>" + icons[mode] + "</i>"
	else
		expander = ''
		type = 'file'
	icon = "<i class=#{type}>" + icons[type] + "</i>"
	if node.name
		return "<div class=#{type}><div class=item>#{expander}#{icon}#{node.name}</div><div class=tree>#{inside}</div></div>"
	else
		return inside


delegate 'tree', 'div.item', 'click', (event, element, target) ->
	icon = firstChild target
	tree = nextSibling target
	toggleClass tree, 'on'

	# When a file is clicked, load it.
	if hasClass icon, 'file'
		rel = getText target
		while true
			target = getParent getParent target
			if hasClass target, 'area'
				break
			rel = (getText previousSibling target) + '/' + rel
		fetchFile rel

	# Grandchildren only exist in non-empty folders.
	else if firstChild firstChild icon
		sign = if hasClass tree, 'on' then 'minus' else 'plus'
		setHtml icon, icons[sign]
