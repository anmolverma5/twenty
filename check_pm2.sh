#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 24.20.0 2>/dev/null || true

which pm2 || echo "pm2 not found in PATH"
npm list -g --depth=0 || true
