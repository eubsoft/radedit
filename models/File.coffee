fs = require 'fs'
DependencyNode = require './DependencyNode'

module.exports = class File extends DependencyNode
	constructor : (@path, @parent) ->
		console.log "Building File for #{@path}"
		fs.readFile @path, (err, contents) =>
			@contents = contents
	toJson : ->
		return {
			type: "File",
			path: @path
		}