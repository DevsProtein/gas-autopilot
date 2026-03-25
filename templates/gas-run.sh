#!/bin/bash
# Execute GAS functions via Web App
#
# Usage:
#   ./gas-run.sh <functionName>        — Run a function
#   ./gas-run.sh deploy                — push + create version + update Web App deploy
#   ./gas-run.sh deploy <functionName> — deploy then run a function
#
# Config is read from .gas-autopilot.json in the same directory.
# If the file doesn't exist, run the gas-autopilot skill setup first.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.gas-autopilot.json"
CLASPRC="$HOME/.clasprc.json"

# --- Load config from .gas-autopilot.json ---
WEBAPP_URL="${WEBAPP_URL:-}"
WEBAPP_DEPLOY_ID="${WEBAPP_DEPLOY_ID:-}"
SCRIPT_ID="${SCRIPT_ID:-}"

if [ -f "$CONFIG_FILE" ]; then
  WEBAPP_URL="${WEBAPP_URL:-$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('webappUrl',''))" 2>/dev/null)}"
  WEBAPP_DEPLOY_ID="${WEBAPP_DEPLOY_ID:-$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('webappDeployId',''))" 2>/dev/null)}"
  SCRIPT_ID="${SCRIPT_ID:-$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('scriptId',''))" 2>/dev/null)}"
fi

if [ -z "$WEBAPP_URL" ] || [ -z "$WEBAPP_DEPLOY_ID" ] || [ -z "$SCRIPT_ID" ]; then
  echo "Error: Missing configuration."
  echo ""
  echo "Expected .gas-autopilot.json at: $CONFIG_FILE"
  echo "Run the gas-autopilot skill setup: type /gas-autopilot in Claude Code."
  exit 1
fi

# --- Helper: Get access token ---
get_token() {
  python3 -c "
import json, urllib.request, urllib.parse
with open('$CLASPRC') as f:
    t = json.load(f)['tokens']['default']
data = urllib.parse.urlencode({
    'client_id': t['client_id'], 'client_secret': t['client_secret'],
    'refresh_token': t['refresh_token'], 'grant_type': 'refresh_token'
}).encode()
r = json.loads(urllib.request.urlopen(urllib.request.Request(
    'https://oauth2.googleapis.com/token', data=data)).read())
print(r['access_token'])
"
}

# --- Helper: Run function via Web App ---
run_function() {
  local fn="$1"
  local token="$2"
  local result
  result=$(curl -sL "${WEBAPP_URL}?fn=${fn}" -H "Authorization: Bearer ${token}")
  echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
}

# --- Deploy command ---
do_deploy() {
  echo "=== clasp push --force ==="
  (cd "$SCRIPT_DIR" && clasp push --force)

  echo ""
  echo "=== clasp version ==="
  local version_output
  version_output=$(cd "$SCRIPT_DIR" && clasp version "auto-deploy $(date +%Y-%m-%d_%H:%M)")
  local version_num
  version_num=$(echo "$version_output" | grep -oE '[0-9]+' | head -1)
  echo "$version_output"

  if [ -z "$version_num" ]; then
    echo "Error: Could not get version number"
    exit 1
  fi

  echo ""
  echo "=== Updating Web App deploy to version ${version_num} ==="
  local token
  token=$(get_token)

  local api_url="https://script.googleapis.com/v1/projects/${SCRIPT_ID}/deployments/${WEBAPP_DEPLOY_ID}"
  local body="{\"deploymentConfig\":{\"versionNumber\":${version_num},\"description\":\"auto-deploy v${version_num}\"}}"

  local resp
  resp=$(curl -s -X PUT "$api_url" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$body")

  if echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if 'deploymentId' in d else 1)" 2>/dev/null; then
    echo "Deploy updated: v${version_num}"
  else
    echo "Error: Deploy update failed"
    echo "$resp" | python3 -m json.tool 2>/dev/null || echo "$resp"
    exit 1
  fi

  echo "$token"
}

# --- Main ---
CMD="${1:-}"
if [ -z "$CMD" ]; then
  echo "Usage:"
  echo "  $0 <functionName>        — Run a function"
  echo "  $0 deploy                — push + deploy"
  echo "  $0 deploy <functionName> — push + deploy + run function"
  exit 1
fi

if [ "$CMD" = "deploy" ]; then
  deploy_output=$(do_deploy)
  token=$(echo "$deploy_output" | tail -1)
  echo "$deploy_output" | sed '$d'

  FN="${2:-}"
  if [ -n "$FN" ]; then
    echo ""
    echo "=== Running ${FN} ==="
    run_function "$FN" "$token"
  fi
else
  TOKEN=$(get_token)
  run_function "$CMD" "$TOKEN"
fi
