###
The RadEdit CLI starts the RadEdit Manager, which allows a
user to create, configure and start RadEdit applications.
###

options = module.exports = require 'commander'
options
	.option '-p, --port [port]', 'Port from which the RadEdit manager will be served'
	.option '-r, --root [root]', 'Document root for apps (defaults to current working directory)'
	.parse process.argv

# Kindly thank users for being here.
console.log "Thank you for choosing RadEdit! \u263A"
console.log ""
require './poetry'
console.log ""

# Allow the CLI to override which port RadEdit uses.
if options.port
	process.radeditPort = options.port

process.isRadedit = true
process.radeditRoot = options.root or process.cwd()

	
setImmediate ->
	require './apps'