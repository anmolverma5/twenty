#!/usr/bin/env bash
set -e

update_repo() {
  REPO="$1"
  echo "Updating $REPO..."
  if [ -d "$REPO" ]; then
    SERVER_ENV="$REPO/packages/twenty-server/.env"
    FRONT_ENV="$REPO/packages/twenty-front/.env"

    if [ -f "$SERVER_ENV" ]; then
      sed -i 's|^SERVER_URL=.*|SERVER_URL=https://twenty-api.vezpec.com|' "$SERVER_ENV"
      grep -q '^SERVER_URL=' "$SERVER_ENV" || echo 'SERVER_URL=https://twenty-api.vezpec.com' >> "$SERVER_ENV"

      sed -i 's|^FRONTEND_URL=.*|FRONTEND_URL=https://twenty.vezpec.com|' "$SERVER_ENV"
      grep -q '^FRONTEND_URL=' "$SERVER_ENV" || echo 'FRONTEND_URL=https://twenty.vezpec.com' >> "$SERVER_ENV"

      sed -i 's|^PORT=.*|PORT=3010|' "$SERVER_ENV"
      grep -q '^PORT=' "$SERVER_ENV" || echo 'PORT=3010' >> "$SERVER_ENV"
      sed -i 's|^NODE_PORT=.*|NODE_PORT=3010|' "$SERVER_ENV" 2>/dev/null || true
    fi

    if [ -f "$FRONT_ENV" ]; then
      sed -i 's|^REACT_APP_SERVER_BASE_URL=.*|REACT_APP_SERVER_BASE_URL=https://twenty-api.vezpec.com|' "$FRONT_ENV"
      grep -q '^REACT_APP_SERVER_BASE_URL=' "$FRONT_ENV" || echo 'REACT_APP_SERVER_BASE_URL=https://twenty-api.vezpec.com' >> "$FRONT_ENV"

      sed -i 's|^REACT_APP_PORT=.*|REACT_APP_PORT=3011|' "$FRONT_ENV"
      grep -q '^REACT_APP_PORT=' "$FRONT_ENV" || echo 'REACT_APP_PORT=3011' >> "$FRONT_ENV"
    fi
  fi
}

update_repo "/home/nfs/twenty"
update_repo "/home/nfs/projects/vezpec-sales-crm"

echo "=== twenty-server .env ==="
grep -E '^(SERVER_URL|FRONTEND_URL|PORT|NODE_PORT|PG_DATABASE_URL|REDIS_URL)' /home/nfs/twenty/packages/twenty-server/.env
echo "=== twenty-front .env ==="
grep -E '^(REACT_APP_SERVER_BASE_URL|REACT_APP_PORT)' /home/nfs/twenty/packages/twenty-front/.env
