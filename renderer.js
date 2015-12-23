'use strict';

(function () {
	// http://stackoverflow.com/a/21797381
	function base64ToArrayBuffer(base64) {
		var binary_string = window.atob(base64);
		var len = binary_string.length;
		var bytes = new Uint8Array(len);
		for (var i = 0; i < len; i++) {
			bytes[i] = binary_string.charCodeAt(i);
		}
		return bytes.buffer;
	}

	window.STLKRenderer = function (canvas) {
		this.canvas = document.querySelector(canvas);
		this.screens = [];
		this.backgroundPlane = 1; // 0 = left, 1 = right
		this.attributes = [[], []];
		this.chrData = [];
	};

	STLKRenderer.prototype = {
		invalidate: function () {
			this.canvas.innerHTML = '';
			// TODO
		},

		reloadSprites: function (cb) {
			reqwest({
				url: '/editor/chr'
				, method: 'get'
				, error: function (err) {
					console.error('could not reload CHR data: ', err);
					if (cb) {
						cb(err);
					}
				}
				, success: function (resp) {
					this.chrData = new Uint8Array(base64ToArrayBuffer(resp));
					console.debug('successfully reloaded CHR data from server');

					if (cb) {
						cb();
					}
				}
			});
		}
	};
})();
