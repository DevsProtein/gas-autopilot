# gws コマンドリファレンス

gws CLI を使ったスプレッドシート操作のリファレンス。
`spreadsheetId` は `.gas-autopilot.json` から取得する。

## 構文ルール

**`--params` はシングルクォート JSON を受け付けない。ダブルクォートをエスケープして渡す。**

```bash
# NG
gws sheets spreadsheets values get --params '{"spreadsheetId":"ID","range":"Sheet1!A1:E10"}'

# OK
gws sheets spreadsheets values get --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:E10\"}"
```

## スプレッドシートの情報取得

```bash
gws sheets spreadsheets get --params "{\"spreadsheetId\":\"ID\"}"
```

## 読み取り

```bash
# 基本（JSON 出力）
gws sheets spreadsheets values get \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:E10\"}"

# CSV 形式（grep やパイプで加工しやすい）
gws sheets spreadsheets values get \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:E10\"}" \
  --format csv
```

## 書き込み

```bash
# 単一セル
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1\",\"valueInputOption\":\"USER_ENTERED\"}" \
  --json "{\"values\":[[\"値\"]]}"

# 複数セル（2x3 の例）
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:C2\",\"valueInputOption\":\"USER_ENTERED\"}" \
  --json "{\"values\":[[\"A1\",\"B1\",\"C1\"],[\"A2\",\"B2\",\"C2\"]]}"

# 数値として書き込み（書式を適用しない）
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1\",\"valueInputOption\":\"RAW\"}" \
  --json "{\"values\":[[12345]]}"
```

## クリア

```bash
# 範囲のデータをクリア（書式は残る）
gws sheets spreadsheets values clear \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A2:Z\"}"
```

## Tips

### range の書き方

| 記法 | 意味 |
|------|------|
| `Sheet1!A1:E10` | A1 から E10 まで |
| `Sheet1!A:A` | A列全体 |
| `Sheet1!1:1` | 1行目全体 |
| `Sheet1!A2:Z` | A2 から Z列の最終行まで |
| `Sheet1` | シート全体 |

シート名にスペースや記号が含まれる場合はシングルクォートで囲む: `'シート名'!A1:E10`

### valueInputOption

| オプション | 説明 |
|-----------|------|
| `USER_ENTERED` | ユーザーが入力したように解釈される（数式・日付を認識） |
| `RAW` | 入力値をそのまま保存（文字列として扱う） |

### --format オプション

| フォーマット | 用途 |
|------------|------|
| `json` | デフォルト。構造化データとして扱う場合 |
| `csv` | grep / awk / パイプ処理に便利 |
| `table` | 人間が読みやすいテーブル表示 |
| `yaml` | YAML 形式 |
