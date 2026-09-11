#!/usr/bin/env bash
# Run this inside Ubuntu-J WSL to start all Twenty CRM services
# Usage: bash /home/nfs/twenty/setup-and-start.sh
set -euo pipefail

SUDOPW="Kasahai12@"
REPO="/home/nfs/twenty"
LOG_DIR="$REPO/.logs"
mkdir -p "$LOG_DIR"

echo "=============================================="
echo "  Twenty CRM — Full Setup & Launch"
echo "=============================================="

# ── Load Node 24.20.0 ──────────────────────────────
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh" --no-use 2>/dev/null || true
nvm use 24.20.0 --silent 2>/dev/null || true
echo "[node] $(node --version)"

export YARN_CACHE_FOLDER="$REPO/.yarn-cache"
export NX_CACHE_DIRECTORY="$REPO/.nx-cache"
export TMPDIR="$REPO/.tmp"
mkdir -p "$YARN_CACHE_FOLDER" "$NX_CACHE_DIRECTORY" "$TMPDIR"

NX="$REPO/node_modules/.bin/nx"

# ── 1. PostgreSQL 18 ───────────────────────────────
echo ""
echo "[1/5] Starting PostgreSQL 18..."
echo "$SUDOPW" | sudo -S service postgresql start 2>/dev/null || true
sleep 3

# Set postgres password
echo "$SUDOPW" | sudo -S -u postgres psql \
  -c "ALTER USER postgres WITH PASSWORD 'postgres';" 2>/dev/null || true

# Create databases
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres \
  -tc "SELECT 1 FROM pg_database WHERE datname='default'" 2>/dev/null \
  | grep -q 1 || PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres default
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres \
  -tc "SELECT 1 FROM pg_database WHERE datname='test'" 2>/dev/null \
  | grep -q 1 || PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres test 2>/dev/null || true

echo "    ✓ PostgreSQL ready (databases: default, test)"

# ── 2. Redis ───────────────────────────────────────
echo ""
echo "[2/5] Starting Redis..."
echo "$SUDOPW" | sudo -S service redis-server start 2>/dev/null || true
sleep 2
redis-cli -h localhost -p 6379 ping 2>/dev/null | grep -q PONG \
  && echo "    ✓ Redis ready" \
  || echo "    ! Redis may not be running, continuing..."

# ── 3. Fix .env files ──────────────────────────────
echo ""
echo "[3/5] Configuring .env files..."
cd "$REPO"

# Server
if [ ! -f "packages/twenty-server/.env" ]; then
  cp packages/twenty-server/.env.example packages/twenty-server/.env
fi
sed -i 's|^PG_DATABASE_URL=.*|PG_DATABASE_URL=postgres://postgres:postgres@localhost:5432/default|' packages/twenty-server/.env
sed -i 's|^REDIS_URL=.*|REDIS_URL=redis://localhost:6379|' packages/twenty-server/.env
grep -q '^PORT=' packages/twenty-server/.env \
  || echo 'PORT=3010' >> packages/twenty-server/.env
sed -i 's|^PORT=.*|PORT=3010|' packages/twenty-server/.env
grep -q '^SERVER_URL=' packages/twenty-server/.env \
  || echo 'SERVER_URL=http://localhost:3010' >> packages/twenty-server/.env
sed -i 's|^NODE_PORT=.*|NODE_PORT=3010|' packages/twenty-server/.env 2>/dev/null || true

# Front
if [ ! -f "packages/twenty-front/.env" ]; then
  cp packages/twenty-front/.env.example packages/twenty-front/.env
fi
sed -i 's|^REACT_APP_SERVER_BASE_URL=.*|REACT_APP_SERVER_BASE_URL=http://localhost:3010|' packages/twenty-front/.env
grep -q '^REACT_APP_PORT=' packages/twenty-front/.env \
  || echo 'REACT_APP_PORT=3011' >> packages/twenty-front/.env
sed -i 's|^REACT_APP_PORT=.*|REACT_APP_PORT=3011|' packages/twenty-front/.env

echo "    ✓ .env configured (server:3010, front:3011)"

# ── 4. Build twenty-server ─────────────────────────
echo ""
echo "[4/5] Building Twenty (first run takes 5-15 min, subsequent runs ~30s)..."
cd "$REPO"

echo "    Building shared packages..."
$NX run-many -t build \
  -p twenty-utils twenty-shared twenty-ui twenty-emails \
  --parallel=4 --output-style=static 2>&1 | tail -4

echo "    Building twenty-server (NestJS)..."
$NX run twenty-server:build --output-style=static 2>&1 | tail -8

echo "    ✓ Build complete"

# ── 5. DB Init ─────────────────────────────────────
echo ""
echo "[5/5] Database schema..."

schema_exists() {
  PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d default -t \
    -c "SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname='core'" \
    2>/dev/null | grep -q 1
}

if schema_exists; then
  echo "    ✓ Schema already initialised"
else
  echo "    Running database init (migrations + seed)..."
  cd "$REPO"
  $NX run twenty-server:database:init 2>&1 | tail -15
  echo "    ✓ Database initialised"
fi

# ── Launch ─────────────────────────────────────────
echo ""
echo "=============================================="
echo "  🚀 Launching Twenty CRM"
echo "=============================================="
echo ""
echo "  Frontend  → http://localhost:3011"
echo "  API       → http://localhost:3010"
echo "  GraphQL   → http://localhost:3010/graphql"
echo ""
echo "  Login: tim@apple.dev / Applecar2025!"
echo ""

cd "$REPO"

# Launch server
echo "Starting twenty-server..."
nohup bash -c "source $NVM_DIR/nvm.sh && nvm use 24.20.0 --silent && \
  cd $REPO && \
  NX_CACHE_DIRECTORY=$REPO/.nx-cache \
  NX_DAEMON=false \
  $NX run twenty-server:start" \
  > "$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!
echo "  server PID=$SERVER_PID → tail -f $LOG_DIR/server.log"

# Wait for server
echo "  Waiting for server health..."
for i in $(seq 1 90); do
  if curl -sf "http://localhost:3010/healthz" 2>/dev/null | grep -q ok; then
    echo "  ✓ Server is up!"
    break
  fi
  sleep 2
  [ "$i" -eq 90 ] && echo "  ⚠ Timeout — check $LOG_DIR/server.log"
done

# Launch frontend
echo "Starting twenty-front (Vite HMR)..."
nohup bash -c "source $NVM_DIR/nvm.sh && nvm use 24.20.0 --silent && \
  cd $REPO && \
  NX_CACHE_DIRECTORY=$REPO/.nx-cache \
  $NX run twenty-front:start" \
  > "$LOG_DIR/front.log" 2>&1 &
FRONT_PID=$!
echo "  front  PID=$FRONT_PID → tail -f $LOG_DIR/front.log"

echo ""
echo "  ✓ All services launched!"
echo "  → Open http://localhost:3011"
echo ""
echo "  To stop:"
echo "    kill $SERVER_PID $FRONT_PID"
echo ""

# Tail server log to keep terminal alive
tail -f "$LOG_DIR/server.log"
