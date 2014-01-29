toggleTree = ->
	toggleClass '_TREE__BUTTON', '_ON'
	toggleClass '_TREE', '_ON'

class Node
	constructor: (@parent, @name = '') ->
	add: () ->
		child = new Node this
		@children = [] if not @children
		@children.push child
		return child

socketOn 'radedit:tree', (treeString) ->
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
	setHtml '_TREE', treeHtml node


treeHtml = (node) ->
	inside = ''
	if node.children
		type = '_FOLDER'
		if node.children.length
			mode = '_PLUS'
			for child in node.children
				inside += treeHtml child if child.children
			for child in node.children
				inside += treeHtml child if not child.children
		else
			mode = '_EMPTY'
		expander = "<i class=_PLUS>" + icons[mode] + "</i>"
	else
		expander = ''
		type = '_FILE'
	icon = "<i class=#{type}>" + icons[type] + "</i>"
	if node.name
		return "<div class=#{type}><div class=_ITEM>#{expander}#{icon}#{node.name}</div><div class=_TREE>#{inside}</div></div>"
	else
		return inside


delegate '_TREE', 'div._ITEM', 'click', (event, $element, $target) ->
	$icon = getFirstChild $target
	$tree = getNextSibling $target
	toggleClass $tree, '_ON'

	# When a file is clicked, load it.
	if hasClass $icon, '_FILE'
		rel = getText $target
		while true
			$target = getParent getParent $target
			if hasClass $target, '_AREA'
				break
			rel = (getText previousSibling $target) + '/' + rel
		fetchFile rel

	# Grandchildren only exist in non-empty folders.
	else if getFirstChild getFirstChild $icon
		sign = if hasClass $tree, '_ON' then '_MINUS' else '_PLUS'
		setHtml $icon, icons[sign]
