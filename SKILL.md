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
| [templates/doGet.js](templates/doGet.js) | Web App handler template |
| [templates/gas-run.sh](templates/gas-run.sh) | CLI wrapper (automates push + deploy + execution) |
| [templates/gas-auth.py](templates/gas-auth.py) | OAuth authentication helper |

## Setup Check (required — every session)

Verify at the start of each session. **If not installed, refer to setup-en.md (or setup-jp.md) and guide the user through installation.**

```bash
clasp --version    # Not installed → npm install -g @google/clasp
gws --version      # Not installed → see setup guide
```

If already set up:
1. Does `clasp push` succeed? (auth check)
2. Does `./gas-run.sh` exist with placeholders replaced?

## Principles

### Use gws for all spreadsheet operations

Test data injection, cell updates, data verification — **all spreadsheet operations go through gws**. No manual GAS editor operations needed.

```bash
# Read
gws sheets spreadsheets values get --params "{\"spreadsheetId\":\"ID\", \"range\":\"Sheet1!A1:E10\"}" --format csv

# Write
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1\",\"valueInputOption\":\"USER_ENTERED\"}" \
  --json "{\"values\":[[\"value\"]]}"

# Clear
gws sheets spreadsheets values clear --params "{\"spreadsheetId\":\"ID\", \"range\":\"Sheet1!A2:Z\"}"
```

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

**Note:** First Web App deploy must be done from GAS editor (once only). After that, `gas-run.sh deploy` auto-updates via Apps Script API.

## Command Reference

| Action | Command |
|--------|---------|
| Edit → deploy → run | `./gas-run.sh deploy <fn>` |
| Deploy only | `./gas-run.sh deploy` |
| Run with existing deploy | `./gas-run.sh <fn>` |
| View logs | `clasp logs` |
| Read spreadsheet | `gws sheets spreadsheets values get ...` |
| Write spreadsheet | `gws sheets spreadsheets values update ...` |
| Clear spreadsheet | `gws sheets spreadsheets values clear ...` |
| Re-authenticate OAuth | `python3 gas-auth.py <creds.json>` |
