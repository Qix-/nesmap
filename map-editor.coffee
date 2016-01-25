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
		@chrSwapping = (0 for [0...4])
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

	setAttribute: (page, x, y, val) ->
		clusterX = Math.floor x / 2
		clusterY = Math.floor y / 2
		cluster = clusterY * 8 + clusterX

		subAttrX = x % 2
		subAttrY = y % 2
		subAttr = subAttrY * 2 + subAttrX

		current = @attributes[page][cluster]

		val &= 3
		val <<= 2 * subAttr # XXX we might need to flip the bits if this doesn't end up being correct.

		# oh god I love bitwise logic :D
		# the below replaces the new value bits with the existing attribute
		# bits:
		#
		# 1. (above) shift the new bits to their target position (refer to NES docs)
		# 2. shift 11b to the position of the new bits
		# 3. XOR with 0xFF, which effectively NOT's the bits ensuring any bits
		#    to the left are also 1
		# 4. AND that value with the current value, setting the target bit locations
		#    to 0
		# 5. OR the new value in
		#
		# Tadaa!
		newAttr = ((0xFF ^ (3 << (2 * subAttr))) & current) | val

		@attributes[page][cluster] = newAttr
