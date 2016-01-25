colorString = require 'color-string'

{EventEmitter} = require 'events'

window.PaletteSelector = class PaletteSelector extends EventEmitter
	constructor: (@container) ->
		super

		@swatches = [].slice.call @container.querySelectorAll 'swatch'
		@selector = @container.querySelector 'selector'

		@initColors()

		@setPalette [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

		@swatches.forEach (swatch, i) =>
			return if i % 4 is 0
			swatch.addEventListener 'click', =>
				@selectSwatch i

		@clearSelected()

	initColors: ->
		@colorSwatches = []
		@selector.innerHTML = ''

		[0...64].forEach (i) =>
			swatch = document.createElement 'swatch'
			@colorSwatches.push swatch

			if i is 0
				swatch.classList.add 'transparent'
			else if nesPalette[i]
				swatch.style.background = colorString.to.rgb nesPalette[i]
			else
				swatch.classList.add 'removed'

			if nesPalette[i]
				swatch.addEventListener 'click', =>
					@selectColor i

			@selector.appendChild swatch

	selectColor: (color) ->
		if @selected is -1
			throw new Error 'color selected, but no swatch selected'

		@setSelected color
		@palette[@selected] = color
		@setPalette @palette
		@emit 'palette', @palette

	setSelected: (color) ->
		@clearSelectedColor()
		@colorSwatches[color].classList.add 'selected'

	clearSelectedColor: ->
		for swatch in @colorSwatches
			swatch.classList.remove 'selected'

	selectSwatch: (i) ->
		return if i % 4 is 0

		@clearSelected()
		@swatches[i].classList.add 'selected'
		@selected = i
		@setSelected @palette[@selected]
		@showSelector on

	clearSelected: ->
		@selected = -1
		@showSelector off
		for swatch in @swatches
			swatch.classList.remove 'selected'

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

	showSelector: (show = on) ->
		@selector.style.display = (if show then null else 'none')
