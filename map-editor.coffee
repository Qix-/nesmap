fs = require 'fs'
{EventEmitter} = require 'events'
MapRenderer = require './map-renderer'

module.exports =
class MapEditor extends EventEmitter
	constructor: ->
		super

		@initNesmap()
		@renderer = new MapRenderer @

	getURI: -> @uri
	loadCHRMap: (map) -> @renderer.setCHRMap map
	loadCHRData: (data) -> @renderer.setCHRData data
	focus: -> @renderer.focus()

	openNesmap: (@uri) ->
		@renderer.setTitle @uri
		fs.readFile @uri, (err, data) =>
			if err
				console.error err.stack
				console.log 'the above error means nothing if this is a new file'
				@initNesmap()
			else
				@loadNesmap data

			@renderer.redraw()

	initNesmap: ->
		@nametables = ((0 for [0...960]) for [0...4])
		@nametableMirroring = 0
		@palette = (0 for [0...16])
		@attributes = ((0 for [0...64]) for [0...4])
		@chrSwapping = (null for [0...4])
		@renderer?.redraw()

	loadNesmap: (data) ->
		json = JSON.parse data
		(@[k] = v) for k, v of json

	saveNesmap: (cb) ->
		obj = JSON.stringify {
			@nametableMirroring
			@chrSwapping
			@palette
			@attributes
			@nametables
		}

		fs.writeFile @uri, obj, cb
