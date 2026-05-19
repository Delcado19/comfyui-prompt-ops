#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if ! command -v node >/dev/null 2>&1; then
    echo "Node.js was not found. Install Node.js 20 or newer, then run this file again." >&2
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "npm was not found. Install Node.js with npm, then run this file again." >&2
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
fi

echo "Starting Prompt Library Admin..."
echo "Open http://127.0.0.1:5177"
exec npm run admin
