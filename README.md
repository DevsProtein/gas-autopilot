# gas-autopilot — Claude Code Skill for GAS

Claude CodeにGAS開発を丸投げするスキル。コード実装→デプロイ→テスト→修正を自律的にループする。

## 何ができるか

1. Claudeが書いたGASを自動でスプレに反映（clasp push + デプロイ）
2. Claudeが勝手にテスト（スプレの読み書きも含めて全自動）
3. エラーや要件未達を検知して、勝手に修正→再テスト（最大5回）

**GASエディタもスプレッドシートも一度も開かずに開発が完結する。**

## 前提ツール

| ツール | インストール |
|--------|-------------|
| [clasp](https://github.com/google/clasp) | `npm install -g @google/clasp` |
| [gws](https://github.com/googleworkspace/cli) | [インストール手順](https://github.com/googleworkspace/cli#installation) |
| [Claude Code](https://claude.ai/code) | |

## 導入

```bash
git clone https://github.com/DevsProtein/gas-autopilot.git
```

Claudeに「setup.mdに従ってセットアップして」と伝えれば案内してもらえます。

セットアップ後、`/gas-autopilot`をプロンプトに付けてGAS関連の指示を出してください。

## 注意

- **テスト用のスプレッドシートで使うこと**（Claudeがセルを直接読み書きします）

## ライセンス

MIT

---

## English

A Claude Code skill that fully automates GAS development: code → deploy → test → fix, in an autonomous loop.

### What it does

1. Auto-deploys GAS code to your spreadsheet (clasp push + Web App deploy)
2. Auto-tests via CLI (reads/writes spreadsheet cells included)
3. Auto-detects errors and fixes code, then re-tests (up to 5 times)

**Develop GAS without ever opening the GAS editor or spreadsheet.**

### Prerequisites

| Tool | Install |
|------|---------|
| [clasp](https://github.com/google/clasp) | `npm install -g @google/clasp` |
| [gws](https://github.com/googleworkspace/cli) | [Installation](https://github.com/googleworkspace/cli#installation) |
| [Claude Code](https://claude.ai/code) | |

### Setup

```bash
git clone https://github.com/DevsProtein/gas-autopilot.git
```

Tell Claude "Set up following setup.md" and it will guide you through the process.

After setup, prefix your GAS-related prompts with `/gas-autopilot`.

### Warning

- **Use a test spreadsheet** — Claude directly reads and writes cells.

### License

MIT
