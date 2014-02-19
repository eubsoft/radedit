assert = require "assert-plus"
File = require '../../models/File'

describe "Models/File", ->
	describe "#construct", ->
		it "should return a string with the filename", ->
			f = new File 'testdir/test-file', null
			jsonStr = JSON.stringify f
			assert.ok ((jsonStr.indexOf 'test-file') >= 0)
