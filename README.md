[日本語](README.md) | [English](README-en.md)

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

Claudeに「setup-jp.mdに従ってセットアップして」と伝えれば案内してもらえます。

セットアップ後、`/gas-autopilot`をプロンプトに付けてGAS関連の指示を出してください。

## 注意

- **テスト用のスプレッドシートで使うこと**（Claudeがセルを直接読み書きします）

## ライセンス

MIT
