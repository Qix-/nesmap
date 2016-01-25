colorString = require 'color-string'

{EventEmitter} = require 'events'

window.PaletteSelector = class PaletteSelector extends EventEmitter
	constructor: (@container) ->
		super

		@swatches = [].slice.call @container.querySelectorAll 'swatch'

		@setPalette [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

	setPalette: (@palette) ->
		for color, i in @palette
			continue if i % 4 is 0

			swatch = @swatches[i]

			if color is 0
				swatch.style.background = 'transparent'
				swatch.classList.add 'transparent'
			else
				swatch.classList.remove 'transparent'
				swatch.style.background = colorString.to.rgb nesPalette[color]
