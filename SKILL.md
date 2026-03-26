---
name: gas-autopilot
description: Autonomous GAS development skill — code, deploy, test, and fix in a self-driving loop. Uses clasp for code management, Web App + gas-run.sh for auto-deploy/execution, and gws for spreadsheet read/write. Triggers on "GAS", "Apps Script", "spreadsheet automation", "clasp", "gws sheets".
---

# GAS Autopilot

Autonomous GAS development via clasp + gws CLI.

## Reference

| File | Description |
|------|-------------|
| [setup-en.md](setup-en.md) | Setup guide (English) |
| [setup-jp.md](setup-jp.md) | Setup guide (Japanese) |
| [gws-reference.md](gws-reference.md) | gws command reference & tips |
| [gws-formatting.md](gws-formatting.md) | Sheet formatting & management |
| [templates/doGet.js](templates/doGet.js) | Web App handler template |
| [templates/gas-run.sh](templates/gas-run.sh) | CLI wrapper (automates push + deploy + execution) |
| [templates/gas-auth.py](templates/gas-auth.py) | OAuth authentication helper |

## Setup Check (required — every session)

### Step 1: Verify CLI tools

```bash
clasp --version    # Not installed → npm install -g @google/clasp
gws --version      # Not installed → see setup guide
```

If not installed, refer to setup-en.md (or setup-jp.md) and guide the user through installation.

### Step 2: Check project config (`.gas-autopilot.json`)

Look for `.gas-autopilot.json` in the project directory (same level as `.clasp.json`).

**If found:** Read it and use the values (`scriptId`, `webappUrl`, `webappDeployId`, `spreadsheetId`) for the rest of the session. Proceed to the development workflow.

**If NOT found:** Run the interactive setup below. **Do NOT proceed to the development workflow until this is complete.**

#### Interactive setup flow:

**a. Get Script ID**

Check if `.clasp.json` exists in the project directory.

- **`.clasp.json` exists** → Read `scriptId` from it automatically.
- **`.clasp.json` does NOT exist** → Ask the user:
  - "Do you have an existing GAS project, or do you want to create a new one?"
  - **Existing project** → Guide: "Open GAS editor → copy the script ID from the URL (`https://script.google.com/home/projects/<SCRIPT_ID>/edit`) → provide it here." Then run `clasp clone <scriptId>`.
  - **New project** → Guide: "Create a new Google Spreadsheet → Extensions → Apps Script → copy the script ID from the URL → provide it here." Then run `clasp clone <scriptId>`.

**b. Set up the project**

Perform the following automatically or guide the user:

1. Add `oauthScopes` and `webapp` section to `appsscript.json` if not present:
   ```json
   "oauthScopes": [
     "https://www.googleapis.com/auth/spreadsheets",
     "https://www.googleapis.com/auth/script.external_request"
   ],
   "webapp": {
     "executeAs": "USER_DEPLOYING",
     "access": "MYSELF"
   }
   ```
2. Add the doGet handler from `templates/doGet.js` to the project if not present.
3. Run `clasp push --force`.
4. Copy `templates/gas-run.sh` to the project directory and run `chmod +x gas-run.sh`.

**c. Auto-deploy Web App**

Run `./gas-run.sh setup` to automatically create the initial Web App deployment via Apps Script API.

The command outputs JSON to stdout with `scriptId`, `webappUrl`, and `webappDeployId`. Parse it and use these values for the config file.

If the command fails, check:
- Apps Script API is enabled in the GCP project
- OAuth scopes are correct (re-run `gas-auth.py` if needed)
- `appsscript.json` has the `webapp` section (added in step b)

**d. Authorize Web App (first time only)**

After the deploy, the user must open the `webappUrl` in a browser once to complete Google's OAuth consent.

Tell the user:

> First-time authorization is required for the Web App. Please open the following URL in your browser:
>
> `<webappUrl>`
>
> **Permissions granted:**
> - **Read/write spreadsheets** — Required for GAS functions to operate on spreadsheets
> - **Connect to external services** — Required for GAS scripts to make HTTP requests
>
> **Why this is needed:** gas-run.sh executes GAS functions via the Web App. For security, Google requires consent to the script's requested permissions on first access. This authorization is one-time only — after that, gas-run.sh can execute functions automatically.
>
> **Access scope:** Your own account only (not exposed to third parties).

After authorization, verify with `./gas-run.sh testConfig` (or any allowed function). If it returns JSON with `"ok": true`, the setup is complete.

**e. Get Spreadsheet URL**

Ask the user: "What is the URL of the target spreadsheet?"

Extract `spreadsheetId` from the URL automatically (the string after `/d/` and before the next `/`).

**f. Create config file**

Write `.gas-autopilot.json` to the project directory with all collected values:

```json
{
  "scriptId": "<from setup output>",
  "webappUrl": "<from setup output>",
  "webappDeployId": "<from setup output>",
  "spreadsheetUrl": "<user provided>",
  "spreadsheetId": "<extracted from URL>"
}
```

Also recommend adding `.gas-autopilot.json` to `.gitignore`.

## Principles

### Use gws for all spreadsheet operations

Test data injection, cell updates, data verification — **all spreadsheet operations go through gws**. No manual GAS editor operations needed.

When running gws commands, use the `spreadsheetId` from `.gas-autopilot.json`.

**Syntax rule:** `--params` does not accept single-quoted JSON. Escape double quotes instead.

```bash
# Read
gws sheets spreadsheets values get --params "{\"spreadsheetId\":\"<spreadsheetId>\", \"range\":\"Sheet1!A1:E10\"}" --format csv

# Write
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"<spreadsheetId>\",\"range\":\"Sheet1!A1\",\"valueInputOption\":\"USER_ENTERED\"}" \
  --json "{\"values\":[[\"value\"]]}"

# Clear
gws sheets spreadsheets values clear --params "{\"spreadsheetId\":\"<spreadsheetId>\", \"range\":\"Sheet1!A2:Z\"}"
```

**Important formatting rules:**
- When copying a table from an existing sheet, **always copy formatting (colors, borders, number formats) as well**
- When creating a new table, **apply styles to the header row**
- After structural changes to a table, **always clear leftover formatting from the old range**

Details: [gws-reference.md](gws-reference.md) (command reference & tips) / [gws-formatting.md](gws-formatting.md) (formatting & sheet management)

### Temporary files go in `temp/`

When testing gws commands or creating temporary test files, use the `temp/` directory at the skill repository root. This directory is gitignored and safe for ephemeral artifacts.

### Never skip test execution

Never report "done" without running tests. Always pass these gates:

1. **Test case design** → user approval
2. **Test execution** → all PASS confirmed
3. **Completion report** includes test results

## Development Workflow

### Phase 1: Project Setup

```bash
clasp clone <scriptId>           # Existing project
clasp create --type sheets       # New project
```

### Phase 2: Requirements → Test Case Design → Plan

**Before writing code, always do the following first:**

1. Check current spreadsheet state with gws
2. Organize requirements and **design test cases first**
3. Present implementation plan and test cases for user approval

**Presentation format:**

```
## Implementation Plan

{What to change and how, concisely}

## Test Cases (E2E: gws sheet ops → GAS execution → gws result verification)

| # | Step | Operation | Expected Result |
|---|------|-----------|-----------------|
| 1 | Pre-check | gws read target range | {current state} |
| 2 | Inject test data | gws update target cells | Cell update success |
| 3 | Run GAS | ./gas-run.sh deploy <fn> | ok: true |
| 4 | Verify result | gws read output range | {expected output} |
| 5 | Cleanup | gws restore + re-run GAS | Original state restored |

Proceed with this plan and test cases?
```

**Get user approval before proceeding to Phase 3.**

### Phase 3: Implementation → Auto-Verification Loop

#### 3-1. Code Implementation

Implement code based on user instructions.

**Do not create test-only functions in GAS.** All tests use gws + production functions.

#### 3-2. Deploy → E2E Test Execution

Test flow — verify in a way that mirrors real user operations:

```
1. gws: check spreadsheet pre-state
2. gws: inject test data (cell changes, row additions, etc.)
3. ./gas-run.sh deploy <production function>: push + deploy + execute
4. gws: read output (changelog, snapshots, etc.) and compare with expected values
5. gws: restore test data (cleanup)
6. Re-run GAS if needed to restore snapshots
```

**On deploy failure:** Do NOT silently continue. Stop immediately, report the error to the user, and ask how to proceed. Common causes: expired OAuth tokens, incorrect Web App URL, missing scopes.

#### 3-3. Auto-Fix Loop

On test failure, **repeat autonomously without asking user**:

```
Test failure → error analysis → code fix → ./gas-run.sh deploy <fn> → gws verify
```

- Up to **5 times**. Report to user if exceeded
- **If test cases themselves need changes**, ask user first

#### 3-4. All Tests Pass → Completion Report

**Never report "done" without test results.** Use this format:

```
## Test Results: All N PASS

| # | Verification | Method | Result |
|---|-------------|--------|--------|
| 1 | {what was checked} | gws values get ... | PASS (expected: X, actual: X) |

(If fixes were made) Changes:
- {what was fixed and how}
```

### Phase 4: Deploy Management

```bash
clasp deployments                  # List deployments
./gas-run.sh deploy                # push + auto-deploy
./gas-run.sh deploy <functionName> # push + deploy + run function
./gas-run.sh <functionName>        # Run function only
```

`gas-run.sh setup` handles the initial Web App deployment. After that, `gas-run.sh deploy` auto-updates via Apps Script API.

## Command Reference

| Action | Command |
|--------|---------|
| Initial Web App deploy | `./gas-run.sh setup` |
| Edit → deploy → run | `./gas-run.sh deploy <fn>` |
| Deploy only | `./gas-run.sh deploy` |
| Run with existing deploy | `./gas-run.sh <fn>` |
| View logs | `clasp logs` |
| Read spreadsheet | `gws sheets spreadsheets values get ...` |
| Write spreadsheet | `gws sheets spreadsheets values update ...` |
| Clear spreadsheet | `gws sheets spreadsheets values clear ...` |
| Re-authenticate OAuth | `python3 gas-auth.py <creds.json>` |
