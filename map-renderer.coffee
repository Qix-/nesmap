{EventEmitter} = require 'events'
{BrowserWindow, ipcMain} = require 'electron'
Mirroring = require './mirroring'

module.exports =
class MapRenderer extends EventEmitter
	@windowOptions:
		width: 800
		height: 600

	@unique: 0

	constructor: (@editor) ->
		@window = new BrowserWindow MapRenderer.windowOptions
		@id = MapRenderer.unique++

		@loaded = no

		@send = (name) -> console.warning name, 'event ignored (too early)'

		@window.webContents.on 'did-finish-load', =>
			console.log 'sending initial payload to', @id
			@loaded = yes
			@send = @window.webContents.send.bind @window.webContents
			@send 'id', @id
			@send 'mirrors', Mirroring
			@redraw()

		@window.on 'closed', (e) =>
			@emit 'will-close', e

		@editor.on 'modified', (modified) =>
			@setIsModified modified

		@onIPC 'save', =>
			console.log 'saving...'
			@editor.saveNesmap => console.log "saved to #{@editor.uri}"

		@onIPC 'mirroring', (e, mirroring) =>
			@editor.nametableMirroring = mirroring
			@redraw()

		@onIPC 'chr-pages', (e, pages) =>
			@editor.chrSwapping = pages
			@redraw()

		@onIPC 'palette', (e, palette) =>
			@editor.palette = palette
			@redraw()

		@window.loadURL "file://#{__dirname}/renderer/index.htm"
		@focus()

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

