'use strict';

var fs = require('fs');
var path = require('path');

if (process.argv.length !== 5) {
	console.error('usage: <palette> <in> <out>');
	process.exit(1);
}

var paletteRaw = fs.readFileSync(path.resolve(process.argv[2]));
var raw = fs.readFileSync(path.resolve(process.argv[3]), 'utf8');

var palette = {};

if (paletteRaw.length < 3 * 4 * 16) {
	throw new Error('palette file is not the correct size; did you pass in the right file?');
}
for (var i = 0, idx = 0; i < (3 * 4 * 16); i += 3, idx++) {
	palette[[paletteRaw[i], paletteRaw[i + 1], paletteRaw[i + 2]]] = idx;
}

for (var k in palette) {
	if (palette.hasOwnProperty(k)) {
		var v = palette[k];
		if (v === 0x0D || (v & 0x0F) >= 0x0E) {
			palette[k] = 0x1F;
		}
	}
}

var pattern = /^([\t\s]*)\{\{PALETTE\}\}[\s\t]*$/m;
var match = raw.match(pattern);
if (!match) {
	throw new Error('palette tag not found in input file.');
}

var paletteString = '';
for (var rgb in palette) {
	if (palette.hasOwnProperty(rgb)) {
		paletteString += (match[1] || '') + palette[rgb] + ': [ ' + rgb + ' ],\n';
	}
}

var newCode = '/* AUTO GENERATED JAVASCRIPT - DO NOT EDIT! Modify the original, not this. */\n';
newCode += raw.replace(pattern, paletteString);

fs.writeFileSync(path.resolve(process.argv[4]), newCode, 'utf8');
