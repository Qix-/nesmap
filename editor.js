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

		editor.renderer.invalidate();
	});
};
