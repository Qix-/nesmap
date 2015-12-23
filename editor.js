'use strict';

window.STLKEditor = function(canvas, bottom, side) {
	var editor = window.editor = {
		renderer: new STLKRenderer(canvas)
	};

	// get initial sprite data
	editor.renderer.reloadSprites(function (err) {
		if (err) {
			return alert('Could not load spritesheet: ' + err + '\n\nDid you build?');
		}

		// XXX DEBUG
		for (var i = 0; i < 16; i++) {
			editor.renderer.palettes[0][i] = i;
		}
		editor.renderer.invalidate();
	});
};
