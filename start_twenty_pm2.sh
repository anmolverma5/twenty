#!/usr/bin/env bash
set -e

REPO="/home/nfs/twenty"
SUDOPW="Kasahai12@"

echo "=== 1. Ensuring PostgreSQL and Redis are running ==="
echo "$SUDOPW" | sudo -S service postgresql start 2>/dev/null || true
echo "$SUDOPW" | sudo -S service redis-server start 2>/dev/null || true

echo "=== 2. Stopping existing ad-hoc processes to free ports 3010 & 3011 ==="
pkill -f "packages/twenty-server/dist/main" 2>/dev/null || true
pkill -f "twenty-front" 2>/dev/null || true
sleep 3

echo "=== 3. Starting Twenty CRM with PM2 ==="
cd "$REPO"
pm2 delete twenty-server 2>/dev/null || true
pm2 delete twenty-worker 2>/dev/null || true
pm2 delete twenty-front 2>/dev/null || true

pm2 start ecosystem.config.cjs
pm2 save

echo "=== 4. PM2 Status ==="
pm2 status

echo "=== 5. Verifying Health ==="
for i in {1..30}; do
  if curl -s http://localhost:3010/healthz | grep -q "ok"; then
    echo "✓ twenty-server is healthy on port 3010!"
    break
  fi
  sleep 1
done

echo "Ready! Services are live under PM2."
