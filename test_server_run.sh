#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0

cd /home/nfs/twenty/packages/twenty-server
NODE_ENV=development node dist/main.js &
SERVER_PID=$!
echo "Started twenty-server PID: $SERVER_PID"

for i in {1..30}; do
  if curl -s http://localhost:3010/healthz | grep -q "ok"; then
    echo "twenty-server is HEALTHY!"
    curl -i http://localhost:3010/healthz
    kill $SERVER_PID
    exit 0
  fi
  sleep 1
done

echo "Timed out waiting for server"
kill $SERVER_PID 2>/dev/null || true
exit 1
