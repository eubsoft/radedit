assert = require "assert-plus"
Directory = require '../../models/Directory'

describe "Models/Directory", ->
	describe "#construct", ->
		it "should return a string with the directory name", ->
			d = new Directory 'testdir', null
