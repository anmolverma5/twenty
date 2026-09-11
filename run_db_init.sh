#!/usr/bin/env bash
set -e
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0

cd /home/nfs/twenty
export YARN_CACHE_FOLDER="/home/nfs/twenty/.yarn-cache"
export NX_CACHE_DIRECTORY="/home/nfs/twenty/.nx-cache"
export TMPDIR="/home/nfs/twenty/.tmp"

echo "=== Running database:init twenty-server ==="
./node_modules/.bin/nx database:init twenty-server

echo "=== Checking core schema after init ==="
psql -h localhost -p 5432 -U postgres -d default -t -c "SELECT nspname FROM pg_catalog.pg_namespace WHERE nspname IN ('core', 'public');"
