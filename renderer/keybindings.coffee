{EventEmitter} = require 'events'

reg = /^(?:(shift|ctrl|alt|cmd)(?:\-(shift|ctrl|alt|cmd)(?:\-(shift|ctrl|alt|cmd)(?:\-(shift|ctrl|alt|cmd))?)?)?)?(?:\-?(.))?$/

window.Keys =
	emitter: new EventEmitter

	attach: ->
		window.addEventListener 'keydown', (e) =>
			code = @generateCode e
			@emitter.emit code

	getKey: (code) -> (String.fromCharCode parseInt (code.substring 2), 16).toLowerCase() if code.substring(0, 2) is 'U+'

	generateCode: (e) -> "#{e.repeat and '*' or ''}#{e.metaKey and 'cmd-' or ''}#{e.ctrlKey and 'ctrl-' or ''}#{e.altKey and 'alt-' or ''}#{e.shiftKey and 'shift-' or ''}#{(@getKey e.keyIdentifier) or ''}".replace /\-+$/, ''

	parseCode: (code, opts) ->
		return if not code
		if code in ['ctrl', 'alt', 'cmd', 'shift']
			opts[code] = on
		else
			opts.key = code

	fixCode: (str) ->
		if typeof str is 'object' and str.constructor.name isnt 'String'
			if process.platform not in str and 'default' not in str
				throw new Error "platform binding not present for #{process.platform} and no default specified"
			str = str[process.platform] || str.default

		opts = {}
		matches = str.match reg
		if not matches then throw new Error "invalid keybinding string: #{str}"
		(@parseCode matches[i], opts) for i in [1..5]
		return "#{opts.cmd and 'cmd-' or ''}#{opts.ctrl and 'ctrl-' or ''}#{opts.alt and 'alt-' or ''}#{opts.shift and 'shift-' or ''}#{opts.key || ''}".replace /\-+$/, ''

	on: (name, fn) ->
		repeat = false
		if name[0] is '*'
			repeat = true
			name = name.substring 1
			@emitter.on "*#{(@fixCode name.toLowerCase())}", fn
		@emitter.on (@fixCode name.toLowerCase()), fn
	once: (name, fn) ->
		if name[0] is '*'
			console.warning 'cannot use repeat operator for .once():', name
			name = name.substring 1
		@emitter.once (@fixCode name.toLowerCase()), fn
