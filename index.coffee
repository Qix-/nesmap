fs = require 'fs'
{app} = require 'electron'
MapEditor = require './map-editor'

if process.argv.length < 4
	console.error 'usage: map-editor <sprites.chr> <chr-listings.s> [map.nesmap...]'
	process.exit 1

documents = []
chrMap = fs.readFileSync process.argv[3], 'utf8'
chrData = fs.readFileSync process.argv[2]

fs.watchFile process.argv[3], {interval: 2000, persistent: false}, ->
	console.log "refreshing CHR map: #{process.argv[3]}"
	chrMap = fs.readFileSync process.argv[3], 'utf8'
	for document in documents
		document.loadCHRMap chrMap

fs.watchFile process.argv[2], {interval: 2000, persistent: false}, ->
	console.log "refreshing CHR data: #{process.argv[2]}"
	chrData = fs.readFileSync process.argv[2]
	for document in documents
		document.loadCHRData chrData

initNewDocument = (uri) ->
	for document in documents
		if document.getURI() is uri
			document.focus()
			return

	console.log "opening NESMAP document: #{uri}"
	doc = new MapEditor uri
	documents.push doc
	doc.on 'closed', ->
		documents.splice (documents.indexOf doc), 1

	doc.openNesmap uri
	doc.loadCHRMap chrMap
	doc.loadCHRData chrData

app.on 'open-file', (e, uri) ->
	e.preventDefault()
	initNewDocument uri

app.on 'window-all-closed', ->
	if process.platform isnt 'darwin' then app.quit()

app.on 'ready', ->
	# If there are any on the command line, open them!
	(initNewDocument uri) for uri in process.argv.slice 4
