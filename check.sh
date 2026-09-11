#!/usr/bin/env bash
set -e
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0 2>/dev/null || true

echo "=== Node & Yarn ==="
node -v
yarn -v

echo "=== Check twenty-server project.json targets ==="
if [ -f /home/nfs/twenty/packages/twenty-server/project.json ]; then
  cat /home/nfs/twenty/packages/twenty-server/project.json | grep -E '"(build|start|database|typeorm|migration)' | head -30
elif [ -f /home/nfs/twenty/packages/twenty-server/package.json ]; then
  cat /home/nfs/twenty/packages/twenty-server/package.json | grep -E '"(build|start|database|typeorm|migration)' | head -30
fi

echo "=== Check root package.json scripts ==="
grep -E '"(start|build|db|database)' /home/nfs/twenty/package.json | head -30
