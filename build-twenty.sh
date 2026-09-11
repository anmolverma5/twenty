#!/usr/bin/env bash
# ============================================================
# build-twenty.sh — Build Twenty CRM workspace (no Docker)
# Builds all packages needed to run the full stack.
# Run once after yarn install; incremental rebuilds are cached.
# ============================================================
set -euo pipefail

TWENTY_DIR="/home/nfs/twenty"
cd "$TWENTY_DIR"

NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0 --silent 2>/dev/null || true

# Move Nx cache and temp to J: (keeps C: free)
export NX_CACHE_DIRECTORY="$TWENTY_DIR/.nx-cache"
export TMPDIR="$TWENTY_DIR/.tmp"
mkdir -p "$NX_CACHE_DIRECTORY" "$TMPDIR"

NX="./node_modules/.bin/nx"

echo "======================================================"
echo "  Building Twenty CRM workspace"
echo "======================================================"

echo "[1/4] Building twenty-utils …"
$NX run twenty-utils:build 2>&1 | tail -5
echo "      ✓ twenty-utils"

echo "[2/4] Building twenty-shared …"
$NX run twenty-shared:build 2>&1 | tail -5
echo "      ✓ twenty-shared"

echo "[3/4] Building twenty-ui and twenty-emails …"
$NX run-many -t build -p twenty-ui twenty-emails --parallel=2 2>&1 | tail -8
echo "      ✓ twenty-ui / twenty-emails"

echo "[4/4] Building twenty-server …"
# NestJS build uses nest CLI which can take 5-10 min first time
$NX run twenty-server:build 2>&1 | tail -10
echo "      ✓ twenty-server"

echo ""
echo "======================================================"
echo "  Build complete! Run ./start-twenty.sh to launch."
echo "======================================================"
