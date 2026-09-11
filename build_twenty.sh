#!/usr/bin/env bash
set -e
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0

cd /home/nfs/twenty
export YARN_CACHE_FOLDER="/home/nfs/twenty/.yarn-cache"
export NX_CACHE_DIRECTORY="/home/nfs/twenty/.nx-cache"
export TMPDIR="/home/nfs/twenty/.tmp"
mkdir -p "$YARN_CACHE_FOLDER" "$NX_CACHE_DIRECTORY" "$TMPDIR"

NX="./node_modules/.bin/nx"

echo "=== Building shared packages ==="
$NX run-many -t build -p twenty-utils twenty-shared twenty-ui twenty-emails --parallel=4 --output-style=static

echo "=== Building twenty-server ==="
$NX run twenty-server:build --output-style=static

echo "=== Build finished successfully ==="
