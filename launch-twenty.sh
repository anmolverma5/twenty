#!/usr/bin/env bash
# =============================================================================
# launch-twenty.sh — Twenty CRM complete launcher (no Docker)
#
# Ubuntu 26.04 / PostgreSQL 18 / Redis 8 / Node 24.20.0
#
# Run from repo root inside Ubuntu-J WSL:
#   bash /home/nfs/twenty/launch-twenty.sh
#
# First run:  ~10 min (NestJS compile + DB init)
# Subsequent: ~30 sec (incremental rebuild, cached)
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
REPO_ROOT="$(pwd)"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; CYN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${BLU}▶ $*${NC}"; }
ok()    { echo -e "${GRN}✓ $*${NC}"; }
warn()  { echo -e "${YLW}⚠ $*${NC}"; }
fail()  { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
sep()   { echo -e "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

sep
echo -e "${CYN}  Twenty CRM — native dev launcher (PG18 · Redis8 · Node24)${NC}"
sep

# ── Node / nvm ────────────────────────────────────────────────────────────────
info "Loading Node 24.20.0 …"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" --no-use
nvm use 24.20.0 --silent 2>/dev/null || nvm use default --silent 2>/dev/null
NODE_VER=$(node --version)
ok "Node $NODE_VER"

# Redirect all caches to J: (keep C: free)
export YARN_CACHE_FOLDER="$REPO_ROOT/.yarn-cache"
export NX_CACHE_DIRECTORY="$REPO_ROOT/.nx-cache"
export TMPDIR="$REPO_ROOT/.tmp"
mkdir -p "$YARN_CACHE_FOLDER" "$NX_CACHE_DIRECTORY" "$TMPDIR"

LOG_DIR="$REPO_ROOT/.logs"
mkdir -p "$LOG_DIR"

NX="$REPO_ROOT/node_modules/.bin/nx"

# ── 1. PostgreSQL 18 ─────────────────────────────────────────────────────────
sep
info "[1/5] PostgreSQL 18 …"

PG_VERSION="18"

pg_is_up() {
  PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres \
    -c "SELECT 1" -d postgres &>/dev/null 2>&1
}

if pg_is_up; then
  ok "PostgreSQL already running"
else
  info "Starting PostgreSQL $PG_VERSION cluster …"
  sudo pg_ctlcluster "$PG_VERSION" main start 2>/dev/null || \
    sudo service postgresql start 2>/dev/null || true
  sleep 3
  # Set postgres password
  sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" \
    2>/dev/null || true
  for i in $(seq 1 15); do
    pg_is_up && break
    sleep 1
  done
  pg_is_up || fail "PostgreSQL did not start"
  ok "PostgreSQL running on :5432"
fi

# Create databases
info "Ensuring databases exist …"
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -tc \
  "SELECT 1 FROM pg_database WHERE datname='default'" \
  2>/dev/null | grep -q 1 || \
  PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres default
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -tc \
  "SELECT 1 FROM pg_database WHERE datname='test'" \
  2>/dev/null | grep -q 1 || \
  PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres test 2>/dev/null || true
ok "Databases 'default' and 'test' ready"

# ── 2. Redis ──────────────────────────────────────────────────────────────────
sep
info "[2/5] Redis 8 …"

redis_is_up() {
  redis-cli -h localhost -p 6379 ping 2>/dev/null | grep -q PONG
}

if redis_is_up; then
  ok "Redis already running"
else
  info "Starting Redis …"
  sudo service redis-server start 2>/dev/null || \
    redis-server --daemonize yes --logfile "$LOG_DIR/redis.log" 2>/dev/null || true
  sleep 2
  redis_is_up || fail "Redis did not start"
  ok "Redis running on :6379"
fi

# ── 3. Environment files ──────────────────────────────────────────────────────
sep
info "[3/5] Verifying .env files …"
cd "$REPO_ROOT"

# Server env — keep existing customised .env, only create if missing
if [ ! -f "packages/twenty-server/.env" ]; then
  cp packages/twenty-server/.env.example packages/twenty-server/.env
  warn "Created packages/twenty-server/.env from example"
fi

# Patch PG_DATABASE_URL for PG18 (same port, just ensure correct)
sed -i 's|^PG_DATABASE_URL=.*|PG_DATABASE_URL=postgres://postgres:postgres@localhost:5432/default|' \
  packages/twenty-server/.env
sed -i 's|^REDIS_URL=.*|REDIS_URL=redis://localhost:6379|' \
  packages/twenty-server/.env
# Make sure PORT is set to 3010
grep -q '^PORT=' packages/twenty-server/.env || echo 'PORT=3010' >> packages/twenty-server/.env
sed -i 's|^PORT=.*|PORT=3010|' packages/twenty-server/.env
grep -q '^SERVER_URL=' packages/twenty-server/.env || echo 'SERVER_URL=http://localhost:3010' >> packages/twenty-server/.env

# Front env
if [ ! -f "packages/twenty-front/.env" ]; then
  cp packages/twenty-front/.env.example packages/twenty-front/.env
fi
sed -i 's|^REACT_APP_SERVER_BASE_URL=.*|REACT_APP_SERVER_BASE_URL=http://localhost:3010|' \
  packages/twenty-front/.env
grep -q '^REACT_APP_PORT=' packages/twenty-front/.env || echo 'REACT_APP_PORT=3011' >> packages/twenty-front/.env
sed -i 's|^REACT_APP_PORT=.*|REACT_APP_PORT=3011|' packages/twenty-front/.env

ok ".env files configured (server:3010 · front:3011)"

# ── 4. Build twenty-server ────────────────────────────────────────────────────
sep
info "[4/5] Building twenty-server (NestJS) …"
info "  ↳ First run takes 5–10 min; subsequent runs use Nx cache"

# Build dependency chain: shared libs first, then server
$NX run-many -t build \
  -p twenty-utils twenty-shared twenty-ui twenty-emails \
  --parallel=4 --output-style=static 2>&1 | tail -6

info "  ↳ Compiling twenty-server …"
$NX run twenty-server:build --output-style=static 2>&1 | tail -10

ok "twenty-server built"

# ── 5. DB Init (first time only) ─────────────────────────────────────────────
sep
info "[5/5] Database schema …"

schema_exists() {
  PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d default -t \
    -c "SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname='core'" \
    2>/dev/null | grep -q 1
}

if schema_exists; then
  ok "Schema already initialised — skipping migrations"
else
  info "  ↳ Running first-time database init (migrations + seed) …"
  cd "$REPO_ROOT/packages/twenty-server"
  node dist/database/scripts/setup-db.js 2>&1 | tail -5 || true
  cd "$REPO_ROOT"
  $NX run twenty-server:database:init 2>&1 | tail -10
  ok "Database schema initialised"
fi

# ── 6. Launch all services ────────────────────────────────────────────────────
sep
echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRN}  🚀  Launching Twenty CRM${NC}"
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYN}Frontend  →  http://localhost:3011${NC}"
echo -e "  ${CYN}API       →  http://localhost:3010${NC}"
echo -e "  ${CYN}GraphQL   →  http://localhost:3010/graphql${NC}"
echo -e "  ${CYN}Logs      →  $LOG_DIR/${NC}"
echo ""
echo -e "  Default login: ${YLW}tim@apple.dev${NC} / ${YLW}Applecar2025!${NC}"
echo ""

# Use Twenty's own concurrently-based start script
cd "$REPO_ROOT"

# Start server in background first
info "Starting twenty-server (watch mode) …"
nohup bash -c "cd $REPO_ROOT && $NX run twenty-server:start 2>&1" \
  > "$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!
echo "  server PID=$SERVER_PID  |  tail -f $LOG_DIR/server.log"

# Wait for server health
info "Waiting for server to be healthy …"
for i in $(seq 1 60); do
  if curl -sf "http://localhost:3010/healthz" 2>/dev/null | grep -q ok; then
    ok "Server ready at http://localhost:3010"
    break
  fi
  [ "$i" -eq 60 ] && warn "Server health check timed out — check $LOG_DIR/server.log"
  sleep 2
done

# Start frontend dev server
info "Starting twenty-front (Vite HMR) …"
nohup bash -c "cd $REPO_ROOT && $NX run twenty-front:start 2>&1" \
  > "$LOG_DIR/front.log" 2>&1 &
FRONT_PID=$!
echo "  front  PID=$FRONT_PID  |  tail -f $LOG_DIR/front.log"

echo ""
ok "Both services launched. Open http://localhost:3011 in your browser."
echo ""
echo "  To stop:  kill $SERVER_PID $FRONT_PID"
echo "  Logs:     tail -f $LOG_DIR/server.log"
echo "            tail -f $LOG_DIR/front.log"
echo ""

# Keep terminal alive, stream server log
wait $SERVER_PID
