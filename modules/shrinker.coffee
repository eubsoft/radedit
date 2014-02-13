radedit = require 'radedit'
log = radedit.log

SETUP_DELAY = 1000

shrinker =
module.exports =

	index: 0

	tokens: {}

	chars: 'abcdefghijklmnopqrstuvwxyz'

	newReplacement: ->
		radix = shrinker.chars.length
		replacement = ''
		number = shrinker.index++
		replacement = shrinker.chars[number % radix]
		while number >= radix
			number = Math.floor number / radix - 0.999
			replacement = shrinker.chars[number % radix] + replacement
		return replacement

	shrink: (asset) ->
		# Don't shrink non-textual files.
		if asset.rel and not /^text/.test radedit.loader.getMime asset.rel or ''
			return

		minified = asset.minified
		if minified
			matches = minified.match /[^A-Z0-9](_[A-Z][_A-Z0-9]+)/g
			if matches
				for match in matches
					string = match.substr 2
					tokens = string.split '__'
					for key in tokens
						token = shrinker.tokens[key]
						if not token
							shrinker.tokens[key] =
							token =
								key: key
								count: 0
							if not shrinker.setup
								token.replacement = shrinker.newReplacement()		
						token.count++
		if shrinker.setup
			clearTimeout shrinker.t
			shrinker.t = setTimeout(->
				shrinker.setup()
				delete shrinker.setup
			, SETUP_DELAY)
		else
			shrinker.doShrink asset

	setup: ->
		list = []
		for own key, token of shrinker.tokens
			list.push token
		list.sort (a, b) ->
			return b.count - a.count
		for token in list
			token.replacement = shrinker.newReplacement()
		for own key, asset of radedit.loader.public.assets
			shrinker.doShrink asset
		for own key, view of radedit.loader.views
			shrinker.doShrink view

	doShrink: (asset) ->
		minified = asset.minified
		if minified
			minified = minified.replace /[^A-Z0-9](_[A-Z][_A-Z0-9]+)/g, (found) ->
				start = found[0]
				string = found.substr 2
				tokens = string.split /__/
				for key, index in tokens
					tokens[index] = shrinker.tokens[key].replacement
				return start + tokens.join '_'
			asset.minified = minified
			if asset.afterShrunk
				asset.afterShrunk()
