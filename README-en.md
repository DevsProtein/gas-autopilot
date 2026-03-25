[日本語](README.md) | [English](README-en.md)

# gas-autopilot — Claude Code Skill for GAS

A Claude Code skill that fully automates GAS development: code → deploy → test → fix, in an autonomous loop.

## What it does

1. Auto-deploys GAS code to your spreadsheet (clasp push + Web App deploy)
2. Auto-tests via CLI (reads/writes spreadsheet cells included)
3. Auto-detects errors and fixes code, then re-tests (up to 5 times)

**Develop GAS without ever opening the GAS editor or spreadsheet.**

## Prerequisites

| Tool | Install |
|------|---------|
| [clasp](https://github.com/google/clasp) | `npm install -g @google/clasp` |
| [gws](https://github.com/googleworkspace/cli) | [Installation](https://github.com/googleworkspace/cli#installation) |
| [Claude Code](https://claude.ai/code) | |

## Setup

```bash
git clone https://github.com/DevsProtein/gas-autopilot.git
```

Tell Claude "Set up following setup-en.md" and it will guide you through the process.

After setup, prefix your GAS-related prompts with `/gas-autopilot`.

## Warning

- **Use a test spreadsheet** — Claude directly reads and writes cells.

## License

MIT
