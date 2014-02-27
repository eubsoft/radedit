assert = require "assert-plus"
DependencyNode = require '../../models/DependencyNode'

describe "DependencyNode", ->
	describe "#read", ->
		it "should return a string with the node name", ->
			# d = new DependencyNode 'testdir', null
