{EventEmitter} = require 'events'
{BrowserWindow, ipcMain} = require 'electron'

module.exports =
class MapRenderer extends EventEmitter
	@windowOptions:
		width: 800
		height: 600

	@unique = 0

	constructor: (@editor) ->
		@window = new BrowserWindow @MapRenderer.windowOptions
		@id = MapRenderer.unique++

		@loaded = no
		@window.loadURL "file://#{__dirname}/renderer/index.htm"
		@focus()

		@send = (name) -> console.warning name, 'event ignored (too early)'

		@window.on 'did-finish-load', =>
			@loaded = yes
			@send = @window.webContents.send.bind @window.webContents
			@redraw()

		@window.on 'closed', (e) =>
			@emit 'will-close', e

		@editor.on 'modified', (modified) =>
			@setIsModified modified

	focus: -> @window.show()
	setCHRMap: (@chrMap) -> @redraw()
	setCHRData: (@chrData) -> @redraw()
	onIPC: (name, fn) -> ipcMain.on "#{name}--#{@id}", fn

	setTitle: (uri) ->
		if process.platform is 'darwin'
			@window.setRepresentedFilename uri
		else
			@window.setTitle uri

	setIsModified: (modified = yes) ->
		if process.platform is 'darwin'
			@window.setDocumentEdited modified

	redraw: ->
		return if not @loaded
		@send 'nesmap', @editor
		if @chrMap then @send 'chr-map', @chrMap
		if @chrData then @send 'chr-data', @chrData

