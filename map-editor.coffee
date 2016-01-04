fs = require 'fs'
{EventEmitter} = require 'events'
MapRenderer = require './map-renderer'

module.exports =
class MapEditor extends EventEmitter
	@Mirroring = [
		# ┌───┬───┐
		# │ 0 │ 1 │
		# ├───┼───┤
		# │ 2 │ 3 │
		# └───┴───┘
		{name: 'One Page (0)', mirror: [0, 0, 0, 0]}
		{name: 'One Page (1)', mirror: [1, 1, 1, 1]}
		{name: 'One Page (2)', mirror: [2, 2, 2, 2]}
		{name: 'One Page (3)', mirror: [3, 3, 3, 3]}
		{name: 'Horizontal Mirror', mirror: [0, 0, 1, 1]}
		{name: 'Vertical Mirror', mirror: [0, 1, 0, 1]}
		{name: '4-Screen', mirror: [0, 1, 2, 3]}
		{name: 'Diagonal', mirror: [0, 1, 1, 0]}
		{name: 'L-Shaped', mirror: [0, 1, 1, 1]}
		{name: '3-Screen Vertical', mirror: [0, 2, 1, 2]}
		{name: '3-Screen Horizontal', mirror: [0, 1, 2, 2]}
		{name: '3-Screen Diagonal', mirror: [0, 1, 1, 2]}
	]

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
		@renderer.redraw()
