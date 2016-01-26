{EventEmitter} = require 'events'

chrColors = [
	0
	128
	205
	255
]

class ChrIcon extends EventEmitter
	constructor: ->
		super

		@dom = document.createElement 'canvas'
		@dom.classList.add 'chr-icon'
		@dom.width = @dom.height = 8

		@ctx = @dom.getContext '2d'

		@dom.addEventListener 'click', => @emit 'click'

	setIcon: (arr, offset) ->
		img = @ctx.createImageData 8, 8
		cursor = 0

		for i in [offset...(offset + 8)]
			byte1 = arr[i]
			byte2 = arr[i + 8]
			for j in [0...8]
				b1 = (byte1 >> (7 - j)) & 1
				b2 = (byte2 >> (7 - j)) & 1
				col = chrColors[(b2 << 1) + b1]
				for [0...3]
					img.data[cursor++] = col
				img.data[cursor++] = 255

		@ctx.clearRect 0, 0, 8, 8
		@ctx.putImageData img, 0, 0

window.ChrSelector = class ChrSelector extends EventEmitter
	constructor: (@container) ->
		@icons = []
		[0...256].forEach (i) =>
			icon = new ChrIcon()
			@icons.push icon
			@container.appendChild icon.dom

			icon.on 'click', => @selectIcon i

	clearSelectedIcon: ->
		for icon in @icons
			icon.dom.classList.remove 'selected'

	selectIcon: (i) ->
		@clearSelectedIcon()
		@icons[i].dom.classList.add 'selected'
		@emit 'selected', i

	update: (chrData, nesmap) ->
		tileIndex = 0
		for page in nesmap.chrSwapping
			page *= 1024

			for offset in [page...(page + (1024))] by 16
				icon = @icons[tileIndex++]
				icon.setIcon chrData, offset
