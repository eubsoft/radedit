db.define 'radedit_file',
	rel: String
	content: String
	modified: Number

db.define 'radedit_tree',
	string: String

db.model 'radedit_tree', (model) ->
	return
	model.one (err, tree) ->
		if tree
			fs.treeString = tree.string
			log 
		else
			model.create
				id: 1
				string: ''
