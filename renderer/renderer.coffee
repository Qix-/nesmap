{EventEmitter} = require 'events'
{ipcRenderer} = require 'electron'

window.Renderer =
class Renderer extends EventEmitter
	constructor: (@canvas) ->
		@zoom = 6
		@ctx = @canvas.getContext '2d'

		ipcRenderer.once 'id', (e, nid) =>
			@id = nid
			@send = (name, args...) =>
				ipcRenderer.send.apply ipcRenderer, ["#{name}--#{@id}"].concat args
			ipcRenderer.on 'mirrors', (e, @mirrors) =>
			ipcRenderer.on 'nesmap', (e, @nesmap) => @redraw()
			ipcRenderer.on 'chr-map', (e, @chrMap) => @redraw()
			ipcRenderer.on 'chr-data', (e, @chrData) => @redraw()

	send: (name, args...) ->
		ipcRenderer.send.apply ipcRenderer, ["#{name}--#{@id}"].concat args

	redraw: ->
		return if not @canRedraw()
		@refreshDimensions()
		@clear()

	clear: ->
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
		@ctx.fillStyle = '#111'
		@ctx.fillRect 0, 0, @canvas.width, @canvas.height

	refreshDimensions: ->
		pageLayout = @getNametableLayout()
		(pageLayout[i] = (if v is -1 then 0 else 1)) for v, i in pageLayout
		console.debug pageLayout

		width = (pageLayout[0] || pageLayout[2]) + (pageLayout[1] || pageLayout[3])
		height = (pageLayout[0] || pageLayout[1]) + (pageLayout[2] || pageLayout[3])

		width *= @zoom * 32 * 8
		height *= @zoom * 30 * 8

		@canvas.style.width = "#{@canvas.width = width}px"
		@canvas.style.height = "#{@canvas.height = height}px"

	getMirroring: -> @mirrors?[@nesmap?.nametableMirroring]
	getNametableLayout: ->
		mirroring = @getMirroring().mirror
		pages = []
		for page in mirroring
			pages.push (if page in pages then -1 else page)
		return pages

	canRedraw: -> @mirrors? and @nesmap? and @chrMap? and @chrData?
