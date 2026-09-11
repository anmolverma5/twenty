#!/usr/bin/env bash
set -e

echo "=== Check build dirs ==="
ls -la /home/nfs/twenty/packages/twenty-server/dist 2>/dev/null || echo "twenty-server/dist not found"
ls -la /home/nfs/twenty/packages/twenty-ui/dist 2>/dev/null || echo "twenty-ui/dist not found"
ls -la /home/nfs/twenty/packages/twenty-shared/dist 2>/dev/null || echo "twenty-shared/dist not found"

echo "=== Check ports 3000, 3001, 3010, 3011 ==="
ss -tulpn | grep -E ':(3000|3001|3010|3011|5432|6379)\b' || true

echo "=== Check running node processes ==="
pgrep -fl node || true
