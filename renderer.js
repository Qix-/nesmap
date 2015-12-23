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
		this.backgroundClear = 0; // 0 = black, 1 = blue, 2 = green, 4 = red; don't use anything else.
		this.zoom = 3;
		this.palettes = [[], []]; // 0 = background (picture), 1 = foreground (sprites)
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
			var I = this.makeImageData();
			this.clearBackground(I);
			this.makePixelArray(I);

			var zoomWidth = I.width * this.zoom;
			var zoomHeight = I.height * this.zoom;

			this.canvas.width = I.width;
			this.canvas.height = I.height;
			this.canvas.style.width = zoomWidth + 'px';
			this.canvas.style.height = zoomHeight + 'px';
			this.ctx.putImageData(I, 0, 0);
		},

		makeImageData: function() {
			var totalWidth = 256;
			var totalHeight = 240;
			totalWidth *= this.verticalScroll ? 1 : this.names.length;
			totalHeight *= this.verticalScroll ? this.names.length : 1;

			var imageData = this.ctx.createImageData(totalWidth, totalHeight);
			return imageData;
		},

		clearBackground: function(I) {
			var pixel;
			switch (this.backgroundClear & 0x07) {
			case 0:
				pixel = STLKPalette[0x1F];
				break;
			case 1:
				pixel = STLKPalette[0x21];
				break;
			case 2:
				pixel = STLKPalette[0x2B];
				break;
			case 4:
				pixel = STLKPalette[0x35];
				break;
			default:
				throw new Error('background clear cannot be ' + this.backgroundClear);
			}

			for (var y = 0; y < I.height; y++) {
				for (var x = 0; x < I.width; x++) {
					var i = (y * I.width + x) * 4;
					I.data[i] = pixel[0];
					I.data[i + 1] = pixel[0];
					I.data[i + 2] = pixel[0];
					I.data[i + 3] = 255;
				}
			}
		},

		makePixelArray: function(I) {
			for (var y = 0; y < I.height; y++) {
				for (var x = 0; x < I.width; x++) {
					var i = (y * I.width + x) * 4;
					var nameID = Math.floor(this.verticalScroll ? y / 240 : x / 256);
					var pixel = this.getPixel(x, y, nameID);
					if (pixel) {
						I.data[i] = pixel[0];
						I.data[i + 1] = pixel[1];
						I.data[i + 2] = pixel[2];
					}
				}
			}
		},

		getPixel: function(x, y, nameID) {
			var tileX = Math.floor(x / 32);
			var tileY = Math.floor(y / 30);
			var attrX = Math.floor(tileX / 4);
			var attrY = Math.floor(tileY / 4);
			var attrQX = tileX % 2;
			var attrQY = tileY % 2;
			var px = x % 8;
			var py = y % 8;

			var spriteIndex = this.getSpriteIndex(tileX, tileY, this.names[nameID]);
			var attribute = this.getAttribute(attrX, attrY, this.attributes[nameID]);
			var attributeBits = this.getAttributeBits(attrQX, attrQY, attribute);

			return this.getPixelColor(px, py, spriteIndex, attributeBits, this.palettes[0], this.backgroundPlane);
		},

		getAttributeBits: function (x, y, attribute) {
			var offset = y * 2 + x;
			return (attribute >> (offset * 2)) & 0x03;
		},

		getSpriteIndex: function (tileX, tileY, name) {
			var offset = tileY * 32 + tileX;
			return name[offset] & 0xFF;
		},

		getAttribute: function (attrX, attrY, attributes) {
			var offset = attrY * 8 + attrX;
			return attributes[offset] & 0xFF;
		},

		getPixelColor: function (px, py, spriteIndex, attributeBits, palette, side) {
			var spriteBytes = this.getSpriteBytes(spriteIndex, side);
			var spriteBits = this.getSpriteBits(px, py, spriteBytes);
			var color = (attributeBits << 2) | spriteBits;
			var colorIndex = palette[color];
			return STLKPalette[colorIndex];
		},

		getSpriteBytes: function (spriteIndex, side) {
			var index = side * 4096 + spriteIndex * 16;
			return this.chrData.slice(index, index + 16);
		},

		getSpriteBits: function (x, y, bytes) {
			var b1 = bytes[y];
			var b2 = bytes[y + 8];
			var bit1 = (b1 >> 7 - x) & 1;
			var bit2 = (b2 >> 7 - x) & 1;
			return (bit2 << 1) | bit1;
		},

		reloadSprites: function (cb) {
			var self = this;
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
					self.chrData = new Uint8Array(base64ToArrayBuffer(resp));
					console.debug('successfully reloaded CHR data from server');

					if (cb) {
						cb();
					}
				}
			});
		}
	};
})();
