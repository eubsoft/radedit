fs = require 'fs'
Directory = require './Directory'
File = require './File'

buildDependencyTree = (path, parent, callback) ->
	# Check if the path is compiled.
	# TODO
	# Check if directory
	fs.stat path, (err, stat) =>
		if err
			callback err
		else
			isDir = stat.isDirectory()
			if isDir
				callback null, new Directory path, parent
			else
				callback null, new File path, parent

module.exports = class DependencyNode
	constructor : (@path, @parent) ->
		buildDependencyTree @path, @parent, (err, dirOrFile) =>
			@node = dirOrFile
	toJson : -> return @node?.toJson()
	showTree : -> return JSON.stringify @toJson()
