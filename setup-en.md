# GAS Autopilot Setup Guide

## What this setup enables

Install the **gas-autopilot** skill and the CLI tools it depends on. After this setup, Claude will handle project-specific configuration (GAS project linking, Web App deploy, etc.) automatically when you first invoke `/gas-autopilot`.

| Tool | Role |
|------|------|
| **gas-autopilot** | Claude Code skill that orchestrates the entire workflow |
| **clasp** | Push / pull / version management of GAS code |
| **gws** | Read/write spreadsheets (test data injection & result verification) |

---

## Step 0: Install the skill

Place this skill folder inside your Claude Code skills directory.

---

## Step 1: Install clasp

Check:

```bash
clasp --version
```

If `3.x` is shown, skip. Otherwise:

```bash
npm install -g @google/clasp
```

If npm is not found, install Node.js first (`brew install node`, etc.).

## Step 2: Install gws

Check:

```bash
gws --version
```

If a version is shown, skip. Otherwise, proceed in order.

### 2-1. Check / install gcloud CLI

gws setup requires gcloud CLI.

```bash
gcloud --version
```

If not installed:

```bash
# macOS (Homebrew)
brew install --cask google-cloud-sdk

# Other OS → https://cloud.google.com/sdk/docs/install
```

### 2-2. Authenticate gcloud

```bash
gcloud auth login
```

A browser will open — authorize with your Google account.

### 2-3. Install gws

```bash
curl -fsSL https://github.com/googleworkspace/cli/releases/latest/download/gws-installer.sh | sh
```

Verify:

```bash
gws --version
```

## Step 3: gws initial setup (OAuth client creation)

```bash
gws auth setup
```

This interactive process will:

1. Detect gcloud CLI
2. Select Google account
3. Select or create a GCP project
4. Enable Workspace APIs (including Apps Script API)
5. **Create an OAuth client** (manual step required)

### When manual operation is required at Step 5

At Step 5 of `gws auth setup`, you may be asked to manually create an OAuth client. Follow the displayed instructions:

1. Open the GCP Console credentials page
2. Click **Create credentials → OAuth client ID**
3. Application type: **Desktop app**
4. After creation, paste the **Client ID** and **Client Secret** into the `gws auth setup` prompt

Also **download the JSON** (`client_secret_*.json`) — it will be used in Step 6 for `gas-auth.py`.

## Step 4: Authenticate gws

```bash
gws auth login
```

A browser will open — authorize.

### To limit scopes

By default, `gws auth login` requests many scopes. To limit to what's needed for GAS development:

```bash
gws auth login --scopes "https://www.googleapis.com/auth/spreadsheets,https://www.googleapis.com/auth/script.projects,https://www.googleapis.com/auth/script.deployments,https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform"
```

**Note:** The `--scopes` value must be passed as **a single double-quoted string**. Do not split across lines or multiple arguments.

Verify:

```bash
gws auth status
```

## Step 5: Authenticate clasp

```bash
clasp login
```

A browser will open — authorize with your Google account. Authentication status is confirmed by whether `clasp push` succeeds (clasp 3.x has no `--status` option).

## Step 6: OAuth authentication (extended scopes)

clasp's default OAuth scopes don't include `spreadsheets`. Use [templates/gas-auth.py](templates/gas-auth.py) for extended scope authentication.

Check:

```bash
python3 --version
```

If Python 3 is not found, install it first (`brew install python`, etc.).

```bash
python3 gas-auth.py <path to client_secret_*.json downloaded in Step 3>
```

A browser will open — authorize. On success, `~/.clasprc.json` is updated.

## Step 7: Verify skill activation

Start a new Claude Code session and type `/gas-autopilot`. If the skill activates, setup is complete.

When you invoke the skill for the first time in a GAS project, Claude will guide you through project-specific setup (cloning, Web App deploy, `.gas-autopilot.json` creation, etc.) automatically.

---

## Tips

### clasp 3.x notes

- `clasp open` is removed. Open GAS editor via URL directly
- `clasp pull` may rename `.gs` to `.js`. Delete `.js` after pull and keep only `.gs`
- `clasp deploy` creates a library deploy, not a Web App deploy. First Web App deploy must be done from GAS editor

### gws notes

- `--params` may not accept single-quoted JSON. Escape double quotes:

```bash
# May fail
gws sheets spreadsheets get --params '{"spreadsheetId":"ID"}'

# OK
gws sheets spreadsheets get --params "{\"spreadsheetId\":\"ID\"}"
```

### Why clasp run doesn't work

`clasp run` does not work for container-bound scripts (GAS bound to spreadsheets) — Scripts API returns 404. That's why this skill uses Web App deploy + gas-run.sh. For standalone scripts, `clasp run` works fine.

### Replacing OAuth client

To change the gws OAuth client:

```bash
cp ~/.config/gws/client_secret.json ~/.config/gws/client_secret.json.bak
cp <new client_secret_*.json> ~/.config/gws/client_secret.json
gws auth logout
gws auth login
```
