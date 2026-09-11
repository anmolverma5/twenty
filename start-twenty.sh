#!/usr/bin/env bash
# ============================================================
# start-twenty.sh — Twenty CRM dev launcher (no Docker)
# Runs: PostgreSQL · Redis · twenty-server (NestJS) · twenty-front (Vite)
# Ports: Server=3010  Frontend=3011
# ============================================================
set -euo pipefail

TWENTY_DIR="/home/nfs/twenty"
LOG_DIR="$TWENTY_DIR/.logs"
mkdir -p "$LOG_DIR"

NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0 --silent 2>/dev/null || true

export YARN_CACHE_FOLDER="$TWENTY_DIR/.yarn-cache"
export TMPDIR="$TWENTY_DIR/.tmp"
mkdir -p "$YARN_CACHE_FOLDER" "$TMPDIR"

echo "======================================================"
echo "  Twenty CRM – native dev launcher"
echo "======================================================"

# ── PostgreSQL ─────────────────────────────────────────────
echo "[1/5] Starting PostgreSQL …"
if ! pg_isready -q 2>/dev/null; then
  sudo service postgresql start
  sleep 3
fi
if ! pg_isready -q 2>/dev/null; then
  echo "ERROR: PostgreSQL did not start" && exit 1
fi
echo "      ✓ PostgreSQL ready"

# Create role/database if missing
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='postgres'" | grep -q 1 || \
  sudo -u postgres createuser -s postgres
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='default'" | grep -q 1 || \
  sudo -u postgres createdb -O postgres default
# Ensure password
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" >/dev/null

echo "      ✓ Database 'default' ready"

# ── Redis ──────────────────────────────────────────────────
echo "[2/5] Starting Redis …"
if ! redis-cli ping 2>/dev/null | grep -q PONG; then
  sudo service redis-server start
  sleep 2
fi
redis-cli ping | grep -q PONG && echo "      ✓ Redis ready" || { echo "ERROR: Redis failed"; exit 1; }

# ── Build shared libs (incremental; cached by Nx) ──────────
echo "[3/5] Building shared packages …"
cd "$TWENTY_DIR"
./node_modules/.bin/nx run-many -t build -p twenty-shared twenty-utils twenty-ui twenty-emails 2>&1 | tail -5
echo "      ✓ Shared packages built"

# ── Server DB init / migrate ───────────────────────────────
echo "[4/5] Initialising database …"
cd "$TWENTY_DIR/packages/twenty-server"
if [ ! -f ".db-init-done" ]; then
  echo "      Running first-time setup (takes ~1 min) …"
  node ../../node_modules/.bin/ts-node \
    --project tsconfig.json \
    -r tsconfig-paths/register \
    src/database/scripts/setup-db.ts 2>&1 | tail -10 || true
  node dist/command/command.js database:init 2>/dev/null || true
  touch .db-init-done
fi
echo "      ✓ Database ready"

# ── Launch server ──────────────────────────────────────────
echo "[5/5] Starting twenty-server (port 3010) …"
cd "$TWENTY_DIR"
nohup ./node_modules/.bin/nx run twenty-server:start 2>&1 > "$LOG_DIR/server.log" &
SERVER_PID=$!
echo "      PID $SERVER_PID – tail: $LOG_DIR/server.log"

echo ""
echo "      Waiting for server to be ready …"
for i in $(seq 1 30); do
  if curl -sf http://localhost:3010/healthz 2>/dev/null | grep -q ok; then
    break
  fi
  sleep 2
done

# ── Launch frontend ────────────────────────────────────────
echo "[+]  Starting twenty-front (port 3011) …"
nohup ./node_modules/.bin/nx run twenty-front:start 2>&1 > "$LOG_DIR/front.log" &
FRONT_PID=$!
echo "      PID $FRONT_PID – tail: $LOG_DIR/front.log"

echo ""
echo "======================================================"
echo "  Twenty CRM is starting:"
echo "    Frontend : http://localhost:3011"
echo "    API      : http://localhost:3010"
echo "    GraphQL  : http://localhost:3010/graphql"
echo "    Logs     : $LOG_DIR/"
echo "======================================================"
echo "  Press Ctrl+C to stop all services"
echo ""

# Keep alive and forward logs
wait $SERVER_PID $FRONT_PID
