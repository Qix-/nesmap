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
		this.ctx = this.canvas.getContext('2d');
		this.backgroundPlane = 1; // 0 = left, 1 = right
		this.verticalScroll = 0;
		this.zoom = 3;
		this.palettes = [[], []];
		this.attributes = [[], []];
		this.names = [[]];
		this.chrData = [];

		for (var i = 0; i < 16; i++) {
			this.palettes[0].push(0);
			this.palettes[1].push(0);
		}

		for (var i = 0; i < 64; i++) {
			this.attributes[0].push(0);
			this.attributes[1].push(0);
		}

		for (var i = 0; i < 960; i++) {
			for (var j = 0; j < this.names.length; j++) {
				this.names[j].push(0);
			}
		}
	};

	STLKRenderer.prototype = {
		invalidate: function () {
			var pixelArray = this.makePixelArray();
			// TODO overlay drawing

			// Handle zooming
			var zoomWidth = pixelArray.width * this.zoom;
			var zoomHeight = pixelArray.height * this.zoom;

			this.canvas.width = pixelArray.width;
			this.canvas.height = pixelArray.height;
			this.canvas.style.width = zoomWidth + 'px';
			this.canvas.style.height = zoomHeight + 'px';
			this.ctx.putImageData(pixelArray, 0, 0);
		},

		makePixelArray: function() {
			var totalWidth = 256;
			var totalHeight = 240;
			totalWidth *= this.verticalScroll ? 1 : this.names.length;
			totalHeight *= this.verticalScroll ? this.names.length : 1;

			var imageData = this.ctx.createImageData(totalWidth, totalHeight);

			for (var y = 0; y < totalHeight; y++) {
				for (var x = 0; x < totalWidth; x++) {
					var i = (y * totalWidth + x) * 4;
					imageData.data[i] = Math.floor(Math.random() * 256);
					imageData.data[i + 1] = Math.floor(Math.random() * 256);
					imageData.data[i + 2] = Math.floor(Math.random() * 256);
					imageData.data[i + 3] = Math.floor(Math.random() * 256);
				}
			}

			return imageData;
		},

		getPixel: function(x, y) {},

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
