#!/usr/bin/env python3
"""
OAuth authentication helper with extended scopes for clasp run / gas-run.sh.
clasp's default OAuth scopes don't include spreadsheets, so this script
authenticates with extended scopes and updates ~/.clasprc.json.

Usage:
  python3 gas-auth.py <path to client_secret.json>

Setup:
  1. Create an OAuth client ID (Desktop app) in GCP Console
  2. Download the JSON
  3. Run this script and authorize in browser
"""

import json, sys, os, http.server, urllib.request, urllib.parse, webbrowser, time

SCOPES = [
    # clasp defaults
    "https://www.googleapis.com/auth/script.deployments",
    "https://www.googleapis.com/auth/script.projects",
    "https://www.googleapis.com/auth/script.webapp.deploy",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/service.management",
    "https://www.googleapis.com/auth/logging.read",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
    "https://www.googleapis.com/auth/cloud-platform",
    # Scopes used by GAS scripts
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/script.external_request",
    "https://www.googleapis.com/auth/drive",
]

CLASP_RC = os.path.expanduser("~/.clasprc.json")
REDIRECT_PORT = 18080
REDIRECT_URI = f"http://localhost:{REDIRECT_PORT}"


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <client_secret.json>")
        sys.exit(1)

    with open(sys.argv[1]) as f:
        client_json = json.load(f)
    creds = client_json.get("installed") or client_json.get("web")
    if not creds:
        print("Error: Invalid client_secret.json format")
        sys.exit(1)

    client_id = creds["client_id"]
    client_secret = creds["client_secret"]

    auth_params = urllib.parse.urlencode({
        "client_id": client_id,
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": " ".join(SCOPES),
        "access_type": "offline",
        "prompt": "consent",
    })
    auth_url = f"https://accounts.google.com/o/oauth2/v2/auth?{auth_params}"

    auth_code = [None]

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            auth_code[0] = params.get("code", [None])[0]
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"<html><body><h2>OK</h2><p>Close this tab.</p></body></html>")

        def log_message(self, format, *args):
            pass

    server = http.server.HTTPServer(("localhost", REDIRECT_PORT), Handler)
    print("Opening browser for OAuth authorization...")
    webbrowser.open(auth_url)
    server.handle_request()
    server.server_close()

    if not auth_code[0]:
        print("Error: No authorization code received")
        sys.exit(1)

    print("Exchanging for tokens...")
    token_data = urllib.parse.urlencode({
        "code": auth_code[0],
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": REDIRECT_URI,
        "grant_type": "authorization_code",
    }).encode()
    resp = json.loads(urllib.request.urlopen(
        urllib.request.Request("https://oauth2.googleapis.com/token", data=token_data)).read())

    if "error" in resp:
        print(f"Error: {resp['error']}: {resp.get('error_description', '')}")
        sys.exit(1)

    clasp_rc = {}
    if os.path.exists(CLASP_RC):
        with open(CLASP_RC) as f:
            clasp_rc = json.load(f)

    clasp_rc.setdefault("tokens", {})["default"] = {
        "access_token": resp["access_token"],
        "refresh_token": resp["refresh_token"],
        "scope": resp.get("scope", " ".join(SCOPES)),
        "token_type": "Bearer",
        "expiry_date": int(time.time() * 1000) + 3600000,
        "type": "authorized_user",
        "client_id": client_id,
        "client_secret": client_secret,
    }

    with open(CLASP_RC, "w") as f:
        json.dump(clasp_rc, f, indent=2)

    print(f"Updated {CLASP_RC}")
    print("gas-run.sh should now work with spreadsheets scope.")


if __name__ == "__main__":
    main()
