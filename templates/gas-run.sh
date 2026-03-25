#!/bin/bash
# Execute GAS functions via Web App
#
# Usage:
#   ./gas-run.sh <functionName>        — Run a function
#   ./gas-run.sh deploy                — push + create version + update Web App deploy
#   ./gas-run.sh deploy <functionName> — deploy then run a function
#
# Setup:
#   1. Replace the variables below with your project values
#   2. chmod +x gas-run.sh
#   3. Run gas-auth.py for OAuth authentication

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBAPP_URL="<Web App URL>"           # From GAS editor deploy screen
WEBAPP_DEPLOY_ID="<Deploy ID>"       # String between /s/ and /exec in Web App URL
SCRIPT_ID="<Script ID>"              # scriptId from .clasp.json
CLASPRC="$HOME/.clasprc.json"

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
