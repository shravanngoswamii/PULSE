#!/usr/bin/env bash
# Reads network.env and writes it into PULSE/.env and PULSE-CC/.env
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/network.env"

if [ ! -f "$SRC" ]; then
  echo "ERROR: network.env not found in project root."
  exit 1
fi

API_BASE_URL=$(grep -E '^API_BASE_URL=' "$SRC" | cut -d= -f2- || true)
API_HOST=$(grep -E '^API_HOST=' "$SRC" | cut -d= -f2 || true)
API_PORT=$(grep -E '^API_PORT=' "$SRC" | cut -d= -f2 || true)

if [ -n "$API_BASE_URL" ]; then
  ENV_CONTENT="API_BASE_URL=$API_BASE_URL"
  echo "  Mode: Cloud (API_BASE_URL=$API_BASE_URL)"
else
  ENV_CONTENT="API_HOST=$API_HOST
API_PORT=$API_PORT"
  echo "  Mode: LAN (API_HOST=$API_HOST:$API_PORT)"
fi

echo "$ENV_CONTENT" > "$SCRIPT_DIR/PULSE/.env"
echo "$ENV_CONTENT" > "$SCRIPT_DIR/PULSE-CC/.env"

echo "Synced network.env -> PULSE/.env and PULSE-CC/.env"
