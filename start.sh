#!/bin/bash
PORT="$1"
[ -z "$PORT" ] && PORT="12345"
open "http://127.0.0.1:$PORT"
node ./server.js $PORT
