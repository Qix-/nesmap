{EventEmitter} = require 'events'
{ipcRenderer} = require 'electron'

window.Renderer =
class Renderer extends EventEmitter
	constructor: (@canvas) ->
		@zoom = 2
		@ctx = @canvas.getContext '2d'

		ipcRenderer.once 'id', (e, nid) =>
			@id = nid
			@send = (name, args...) =>
				ipcRenderer.send.apply ipcRenderer, ["#{name}--#{@id}"].concat args
			ipcRenderer.on 'mirrors', (e, @mirrors) =>
				@emit 'mirrors', @mirrors
				@redraw()
			ipcRenderer.on 'nesmap', (e, @nesmap) =>
				@emit 'nesmap', @nesmap
				@redraw()
			ipcRenderer.on 'chr-map', (e, @chrMap) => @redraw()
			ipcRenderer.on 'chr-data', (e, @chrData) => @redraw()

			Keys.on 'cmd-s', =>
				console.debug 'saving'
				@send 'save'

	send: (name, args...) ->
		ipcRenderer.send.apply ipcRenderer, ["#{name}--#{@id}"].concat args

	setNametableMirroring: (mirroring) ->
		@nesmap.nametableMirroring = mirroring
		@redraw()

	redraw: ->
		return if not @canRedraw()

		@ctx.translate 0.5, 0

		@refreshDimensions()
		@clear()
		@drawGuides()
		@clearMirroredPages()

	clear: ->
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
		@ctx.fillStyle = '#111'
		@ctx.fillRect 0, 0, @canvas.width, @canvas.height

	refreshDimensions: ->
		pageUnits = @getPageUnits()

		width = pageUnits[0] * @zoom * 32 * 8
		height = pageUnits[1] * @zoom * 30 * 8

		@canvas.style.width = "#{@canvas.width = width}px"
		@canvas.style.height = "#{@canvas.height = height}px"

	getPageUnits: ->
		pageLayout = @getNametableLayout()
		(pageLayout[i] = (if v is -1 then 0 else 1)) for v, i in pageLayout
		console.debug pageLayout

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

		# attribute clusters
		@drawGrid '#933', [2, 1], [8, 8], 32, pageUnits, pageLayout

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
					@ctx.clearRect x * @zoom * 32 * 8, y * @zoom * 30 * 8, (x + 1) * @zoom * 32 * 8 - 1, (y + 1) * @zoom * 30 * 8 - 1
