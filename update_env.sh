#!/usr/bin/env bash
set -e

REPO="/home/nfs/twenty"

# Server .env
SERVER_ENV="$REPO/packages/twenty-server/.env"
if [ ! -f "$SERVER_ENV" ]; then
  cp "$REPO/packages/twenty-server/.env.example" "$SERVER_ENV"
fi

# Ensure settings
grep -q '^PORT=' "$SERVER_ENV" && sed -i 's|^PORT=.*|PORT=3010|' "$SERVER_ENV" || echo 'PORT=3010' >> "$SERVER_ENV"
grep -q '^SERVER_URL=' "$SERVER_ENV" && sed -i 's|^SERVER_URL=.*|SERVER_URL=http://localhost:3010|' "$SERVER_ENV" || echo 'SERVER_URL=http://localhost:3010' >> "$SERVER_ENV"
grep -q '^FRONTEND_URL=' "$SERVER_ENV" && sed -i 's|^FRONTEND_URL=.*|FRONTEND_URL=http://localhost:3011|' "$SERVER_ENV" || echo 'FRONTEND_URL=http://localhost:3011' >> "$SERVER_ENV"
grep -q '^PG_DATABASE_URL=' "$SERVER_ENV" && sed -i 's|^PG_DATABASE_URL=.*|PG_DATABASE_URL=postgres://postgres:postgres@localhost:5432/default|' "$SERVER_ENV" || echo 'PG_DATABASE_URL=postgres://postgres:postgres@localhost:5432/default' >> "$SERVER_ENV"
grep -q '^REDIS_URL=' "$SERVER_ENV" && sed -i 's|^REDIS_URL=.*|REDIS_URL=redis://localhost:6379|' "$SERVER_ENV" || echo 'REDIS_URL=redis://localhost:6379' >> "$SERVER_ENV"

# Front .env
FRONT_ENV="$REPO/packages/twenty-front/.env"
if [ ! -f "$FRONT_ENV" ]; then
  cp "$REPO/packages/twenty-front/.env.example" "$FRONT_ENV"
fi
grep -q '^REACT_APP_PORT=' "$FRONT_ENV" && sed -i 's|^REACT_APP_PORT=.*|REACT_APP_PORT=3011|' "$FRONT_ENV" || echo 'REACT_APP_PORT=3011' >> "$FRONT_ENV"
grep -q '^REACT_APP_SERVER_BASE_URL=' "$FRONT_ENV" && sed -i 's|^REACT_APP_SERVER_BASE_URL=.*|REACT_APP_SERVER_BASE_URL=http://localhost:3010|' "$FRONT_ENV" || echo 'REACT_APP_SERVER_BASE_URL=http://localhost:3010' >> "$FRONT_ENV"

echo "=== Server .env (top 20 lines) ==="
head -n 20 "$SERVER_ENV"
echo "=== Front .env ==="
cat "$FRONT_ENV"
