jade = require 'jade'
radedit = require 'radedit'
log = radedit.log

module.exports =

	compile: (code, path) ->
		try
			view = jade.compile code, {filename: path}
		catch e
			log.debug "Error in template: #{path}"
			throw e
			
