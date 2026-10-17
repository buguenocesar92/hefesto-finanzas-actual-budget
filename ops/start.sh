#!/bin/sh
set -eu
node /opt/hefesto/check-data.cjs
exec node /app/app.js
