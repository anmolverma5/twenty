#!/usr/bin/env bash
grep -A 15 '"worker"' /home/nfs/twenty/packages/twenty-server/project.json || true
grep -A 15 '"start:worker"' /home/nfs/twenty/packages/twenty-server/project.json || true
