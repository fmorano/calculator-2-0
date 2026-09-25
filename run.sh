#!/bin/bash
cd "$(dirname "$0")"
python3 -m http.server 8000 --directory dist >/tmp/calculator2-offline.log 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
sleep 1
xdg-open "http://localhost:8000/simulatorvue/v0/" >/dev/null 2>&1
wait $SERVER_PID
