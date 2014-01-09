radedit = require 'radedit'
log = radedit.log

# TODO: Save the search index to db (not just in-memory).

global.search =
	update: ->
		args = arguments
		setTimeout(->
			update.apply search, args
		, 100)

terms = {}
termCount = 0
files = {}
fileCount = 0


newTerm = (text) ->
	++termCount
	term =
		matches: 0
		files: []


newFile = (rel, content) ->
	++fileCount
	
	if fileCount % 25 is 0
		log "#{fileCount} files in search index."

	file =
		rel: rel
		content: content
		matches: 0
		terms: []


update = (rel, content) ->
	if !/^text/.test radedit.loader.getMime rel
		return

	file = files[rel]
	if file
		# TODO: Unload file from index before reloading it.
	else
		file = files[rel] = newFile rel, '' + content

	filename = rel.replace /(^.*\/|\..*$)/g, ''

	tokens = tokenize content
	tokens = tokenize rel, tokens, 0.5, 1.5
	tokens = tokenize filename, tokens, 10

	for own text, count of tokens

		file.matches += count
		file.terms.push
			text: text
			matches: count

	file.terms.sort matchesDescending

	for own text, count of tokens

		term = terms[text]
		if not term
			term = terms[text] = newTerm text
		term.matches += count
		term.files.push
			rel: rel
			frequency: count / file.matches
		term.files.sort frequencyDescending


tokenize = (content, counts, importance, multiplier) ->
	content += ''
	counts = counts or {}
	importance = importance or 1
	multiplier = multiplier or 1
	tokens = content.split /[^a-z0-9]+/i
	for token in tokens
		if token
			incrementValue counts, token.toUpperCase(), importance
			words = token.replace /_/g, ' '
			words = words.replace /([a-z])([A-Z])/g, '$1 $2'
			words = words.replace /([0-9])([a-z])/ig, '$1 $2'
			words = words.replace /([a-z])([0-9])/ig, '$1 $2'
			words = words.split ' '
			if words.length > 1
				for word in words
					incrementValue counts, word.toUpperCase(), importance
			importance *= multiplier
	return counts


search.find =
find = (query, callback) ->
	tokens = tokenize query
	pivot = ''
	fewest = Number.MAX_VALUE
	candidates = []
	results = []
	for own text, count of tokens
		term = terms[text]
		if not term
			return false
		else if term.matches < fewest
			pivot = text
			fewest = term.matches
			candidates = term.files
	for candidate in candidates
		file = files[candidate.rel]
		results.push
			rel: candidate.rel
	callback results


incrementValue = (object, key, amount) ->
	count = object[key] or 0
	object[key] = count + (amount or 1)


frequencyDescending = (a, b) ->
	b.frequency - a.frequency

matchesDescending = (a, b) ->
	b.matches - a.matches


radedit.io.connect (socket) ->

	socket.on 'radedit:search', (query) ->
		find query, (results) ->
			socket.emit 'radedit:searched', results
			