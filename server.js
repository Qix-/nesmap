'use strict';

var express = require('express');
var fs = require('fs');

var app = express();

app.get('/*', express.static(__dirname));

app.listen(parseInt(process.argv[2] || 12345, 10));
