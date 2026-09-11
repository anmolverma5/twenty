#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0

cd /home/nfs/twenty
./node_modules/.bin/nx run twenty-front:start &
FRONT_PID=$!
echo "Started twenty-front PID: $FRONT_PID"

for i in {1..40}; do
  if curl -s http://localhost:3011 | grep -q "<html\|<!DOCTYPE\|vite"; then
    echo "twenty-front is HEALTHY!"
    curl -s http://localhost:3011 | head -n 15
    kill $FRONT_PID
    exit 0
  fi
  sleep 1
done

echo "Timed out waiting for front"
kill $FRONT_PID 2>/dev/null || true
exit 1
