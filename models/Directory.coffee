fs = require 'fs'
DependencyNode = require './DependencyNode'

module.exports = class Directory extends DependencyNode
	constructor : (@path, @parent) ->
		@children = []
		console.log "Building Directory for #{@path}"
		fs.readdir @path, (err, files) =>
			if (err)
				console.error err
			files.forEach (filename) =>
				filepath = "#{@path}/#{filename}"
				###
				node = new DependencyNode filepath, @
				@children.push (new DependencyNode filepath, @)
				###
	toJson: ->
		childJsons = []
		childJsons.push child.toJson() for child in @children
		return {
			type: "Directory"
			path: @path
			children: childJsons
		}
