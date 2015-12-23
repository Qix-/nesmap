'use strict';

var express = require('express');
var fs = require('fs');
var path = require('path');

var app = express();

app.get('/editor/chr', function (req, res) {
	var chr = fs.readFileSync(path.resolve(__dirname, '../sprites.chr')).toString('base64');
	res.send(chr).status(200);
});

app.get('/*', express.static(__dirname));

app.listen(parseInt(process.argv[2] || 12345, 10));
