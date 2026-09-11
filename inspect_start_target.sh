#!/usr/bin/env bash
echo "=== twenty-server start targets ==="
grep -A 15 '"start":' /home/nfs/twenty/packages/twenty-server/project.json

echo "=== twenty-front start targets ==="
grep -A 15 '"start":' /home/nfs/twenty/packages/twenty-front/project.json
