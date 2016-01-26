{EventEmitter} = require 'events'
{ipcRenderer} = require 'electron'

window.Renderer =
class Renderer extends EventEmitter
	constructor: (@tiles, @canvas, @cursor) ->
		@zoom = 2
		@selectedAttribute = -1
		@ctx = @canvas.getContext '2d'
		@ctxCursor = @cursor.getContext '2d'
		@ctxTiles = @tiles.getContext '2d'

		@setSelectedTile 0

		ipcRenderer.once 'id', (e, nid) =>
			@id = nid
			@send = (name, args...) =>
				ipcRenderer.send.apply ipcRenderer, ["#{name}--#{@id}"].concat args
			ipcRenderer.on 'mirrors', (e, @mirrors) =>
				@emit 'mirrors', @mirrors
				@redraw()
			ipcRenderer.on 'nesmap', (e, @nesmap) =>
				@emit 'nesmap', @nesmap
				@emitChrData()
				@redraw()
			ipcRenderer.on 'chr-map', (e, @chrMap) => @redraw()
			ipcRenderer.on 'chr-data', (e, @chrData) =>
				@emitChrData()
				@redraw()

			Keys.on 'cmd-s', =>
				console.debug 'saving'
				@send 'save'

	emitChrData: ->
		if @chrData? and @nesmap?
			@emit 'chr-data', @chrData, @nesmap

	send: (name, args...) ->
		ipcRenderer.send.apply ipcRenderer, ["#{name}--#{@id}"].concat args

	setNametableMirroring: (mirroring) -> @send 'mirroring', mirroring

	setChrPages: (values) -> @send 'chr-pages', values

	redraw: ->
		return if not @canRedraw()

		@ctx.translate 0.5, 0

		@refreshDimensions()
		@clear()
		@drawGuides()
		@clearMirroredPages()
		@redrawTiles()

	clear: ->
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height

	refreshDimensions: ->
		pageUnits = @getPageUnits()

		width = pageUnits[0] * @zoom * 32 * 8
		height = pageUnits[1] * @zoom * 30 * 8

		for c in [@canvas, @cursor]
			c.style.width = "#{c.width = width}px"
			c.style.height = "#{c.height = height}px"

		@tiles.style.width = "#{width}px"
		@tiles.style.height = "#{height}px"
		@tiles.width = pageUnits[0] * 32 * 8
		@tiles.height = pageUnits[1] * 30 * 8

	getPageUnits: ->
		pageLayout = @getNametableLayout()
		(pageLayout[i] = (if v is -1 then 0 else 1)) for v, i in pageLayout

		width = (pageLayout[0] || pageLayout[2]) + (pageLayout[1] || pageLayout[3])
		height = (pageLayout[0] || pageLayout[1]) + (pageLayout[2] || pageLayout[3])

		return [width, height]

	setZoom: (@zoom) -> @redraw()

	getMirroring: -> @mirrors?[@nesmap?.nametableMirroring]

	getNametableLayout: ->
		mirroring = @getMirroring().mirror
		pages = []
		for page in mirroring
			pages.push (if page in pages then -1 else page)
		return pages

	canRedraw: -> @mirrors? and @nesmap? and @chrMap? and @chrData?

	drawGrid: (style, dashes, count, spacing, pageUnits = @getPageUnits(), pages = @getNametableLayout()) ->
		@ctx.beginPath()
		for x in [0...(pageUnits[0] * count[0])]
			px = x * @zoom * spacing + 0.5
			@ctx.moveTo px, 0
			@ctx.lineTo px, @canvas.height
		for y in [0...(pageUnits[1] * count[1])]
			py = y * @zoom * spacing + 0.5
			@ctx.moveTo 0, py
			@ctx.lineTo @canvas.width, py
		@ctx.strokeStyle = style
		@ctx.lineWidth = 1
		@ctx.setLineDash dashes
		@ctx.stroke()

	drawGuides: ->
		pageLayout = @getNametableLayout()
		pageUnits = @getPageUnits()

		# tiles
		@drawGrid '#282828', [1, 1], [32, 30], 8, pageUnits, pageLayout

		# attribute groups
		@drawGrid '#404', [2, 1], [16, 15], 16, pageUnits, pageLayout

		# page guides
		@ctx.beginPath()
		@ctx.moveTo @zoom * 32 * 8 + 0.5, 0
		@ctx.lineTo @zoom * 32 * 8 + 0.5, @canvas.height
		@ctx.moveTo 0.5, @zoom * 30 * 8 + 0.5
		@ctx.lineTo @canvas.width, @zoom * 30 * 8 + 0.5
		@ctx.strokeStyle = '#069'
		@ctx.lineWidth = 1
		@ctx.setLineDash []
		@ctx.stroke()

		# NTSC guide
		@ctx.beginPath()
		@ctx.moveTo 0, @zoom * 16 + 0.5
		@ctx.lineTo @canvas.width, @zoom * 16 + 0.5
		@ctx.moveTo 0, @canvas.height - @zoom * 16 + 0.5
		@ctx.lineTo @canvas.width, @canvas.height - @zoom * 16 + 0.5
		@ctx.strokeStyle = '#F00'
		@ctx.lineWidth = 1
		@ctx.setLineDash []
		@ctx.stroke()

	clearMirroredPages: ->
		pageLayout = @getNametableLayout()
		for x in [0...2]
			for y in [0...2]
				i = y * 2 + x
				if pageLayout[i] is -1
					cx = x * @zoom * 32 * 8
					cy = y * @zoom * 30 * 8
					cw = (x + 1) * @zoom * 32 * 8 - 1
					ch = (y + 1) * @zoom * 30 * 8 - 1

					@ctx.clearRect cx, cy, cw, ch
					@ctxCursor.clearRect cx, cy, cw, ch

	clearCursor: ->
		@selectedAttribute = null
		@ctxCursor.clearRect 0, 0, @cursor.width, @cursor.height

	translateMouseCoords: (x, y) ->
		x = Math.floor x / @zoom
		y = Math.floor y / @zoom

		absTileX = Math.floor x / 8
		absTileY = Math.floor y / 8

		pageX = Math.floor absTileX / 32
		pageY = Math.floor absTileY / 30
		page = @getMirroring().mirror[pageY * 2 + pageX]

		tileX = absTileX % 32
		tileY = absTileY % 30
		tile = tileY * 32 + tileX

		attributeX = Math.floor tileX / 2
		attributeY = Math.floor tileY / 2
		attribute = attributeY * 16 + attributeX

		return {
			x, y
			absTileX, absTileY
			pageX, pageY, page
			tileX, tileY, tile
			attributeX, attributeY, attribute
		}

	mouseOverTile: (x, y, select = 'tile') ->
		@clearCursor()

		coords = @translateMouseCoords x, y

		@ctxCursor.fillStyle = 'rgba(255, 255, 255, 0.1)'

		switch select
			when 'tile'
				@ctxCursor.fillRect coords.absTileX * 8 * @zoom, coords.absTileY * 8 * @zoom, 8 * @zoom, 8 * @zoom
			when 'attribute'
				absAttrX = coords.pageX * 16 + coords.attributeX
				absAttrY = coords.pageY * 15 + coords.attributeY
				@ctxCursor.fillRect absAttrX * 16 * @zoom, absAttrY * 16 * @zoom, 16 * @zoom, 16 * @zoom
				@selectedAttribute = coords

		@clearMirroredPages()

	mouseClickTile: (x, y, select = 'tile') ->
		return if select isnt 'tile' # derp, don't judge me.
		coords = @translateMouseCoords x, y
		@send 'tile', coords.page, coords.tile, @selectedTile
		@nesmap.nametables[coords.page][coords.tile] = @selectedTile
		@redrawTiles()

	setPalette: (palette) -> @send 'palette', palette

	setSelectedAttribute: (val) ->
		return if not @selectedAttribute
		@send 'attribute', @selectedAttribute.page, @selectedAttribute.attributeX, @selectedAttribute.attributeY, val

		clusterX = Math.floor @selectedAttribute.tileX / 4
		clusterY = Math.floor @selectedAttribute.tileY / 4
		cluster = clusterY * 8 + clusterX

		subAttrX = @selectedAttribute.attributeX % 2
		subAttrY = @selectedAttribute.attributeY % 2
		subAttr = subAttrY * 2 + subAttrX

		current = @nesmap.attributes[@selectedAttribute.page][cluster]

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

		@nesmap.attributes[@selectedAttribute.page][cluster] = newAttr
		@redrawTiles()

	redrawTiles: ->
		@clearTiles()
		@drawTiles()

	clearTiles: ->
		@ctxTiles.clearRect 0, 0, @tiles.width, @tiles.height

	drawTiles: ->
		layout = @getNametableLayout()
		mirroring = @getMirroring().mirror

		for pageX in [0...2]
			for pageY in [0...2]
				page = pageY * 2 + pageX

				position = layout[page]
				continue if position is -1

				img = @ctxTiles.createImageData 32 * 8, 30 * 8
				table = @nesmap.nametables[page]

				for tileY in [0...30]
					for tileX in [0...32]
						@drawTile img.data, mirroring[page], tileX, tileY

				@ctxTiles.putImageData img, pageX * 32 * 8, pageY * 30 * 8

	drawTile: (data, page, tileX, tileY) ->
		attrClusterX = Math.floor tileX / 4
		attrClusterY = Math.floor tileY / 4

		attrX = (Math.floor tileX / 2) % 2
		attrY = (Math.floor tileY / 2) % 2

		attrCluster = attrClusterY * 8 + attrClusterX
		attr = attrY * 2 + attrX

		tile = @nesmap.nametables[page][tileY * 32 + tileX]

		offset = (@nesmap.chrSwapping[Math.floor tile / 64] * 1024) + ((tile % 64) * 16)

		for py in [0...8]
			attrByte = @nesmap.attributes[page][attrCluster]
			attrBits = attrByte >> (attr * 2) & 3

			byte1 = @chrData[offset + py]
			byte2 = @chrData[offset + py + 8]

			for px in [0...8]
				b1 = byte1 >> (7 - px) & 1
				b2 = byte2 >> (7 - px) & 1
				b = (b2 << 1) | b1
				b |= attrBits << 2

				colorByte = @nesmap.palette[b]
				continue if colorByte is 0

				colorOffset = (tileY * 8 + py) * 1024 + (tileX * 8 + px) * 4

				color = nesPalette[colorByte]
				for i in [0...3]
					data[colorOffset + i] = color[i]
				data[colorOffset + 3] = 255

	setSelectedTile: (@selectedTile) ->
