# gws Command Reference

Reference for spreadsheet operations using the gws CLI.
`spreadsheetId` is retrieved from `.gas-autopilot.json`.

## Syntax Rules

**`--params` does not accept single-quoted JSON. Escape double quotes instead.**

```bash
# NG
gws sheets spreadsheets values get --params '{"spreadsheetId":"ID","range":"Sheet1!A1:E10"}'

# OK
gws sheets spreadsheets values get --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:E10\"}"
```

## Get Spreadsheet Info

```bash
gws sheets spreadsheets get --params "{\"spreadsheetId\":\"ID\"}"
```

## Read

```bash
# Basic (JSON output)
gws sheets spreadsheets values get \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:E10\"}"

# CSV format (convenient for grep and pipe processing)
gws sheets spreadsheets values get \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:E10\"}" \
  --format csv
```

## Write

```bash
# Single cell
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1\",\"valueInputOption\":\"USER_ENTERED\"}" \
  --json "{\"values\":[[\"value\"]]}"

# Multiple cells (2x3 example)
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1:C2\",\"valueInputOption\":\"USER_ENTERED\"}" \
  --json "{\"values\":[[\"A1\",\"B1\",\"C1\"],[\"A2\",\"B2\",\"C2\"]]}"

# Write as raw value (no format interpretation)
gws sheets spreadsheets values update \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A1\",\"valueInputOption\":\"RAW\"}" \
  --json "{\"values\":[[12345]]}"
```

## Clear

```bash
# Clear data in range (formatting is preserved)
gws sheets spreadsheets values clear \
  --params "{\"spreadsheetId\":\"ID\",\"range\":\"Sheet1!A2:Z\"}"
```

## Tips

### Range notation

| Notation | Meaning |
|----------|---------|
| `Sheet1!A1:E10` | From A1 to E10 |
| `Sheet1!A:A` | Entire column A |
| `Sheet1!1:1` | Entire row 1 |
| `Sheet1!A2:Z` | From A2 to last row of column Z |
| `Sheet1` | Entire sheet |

Wrap sheet names containing spaces or special characters in single quotes: `'Sheet Name'!A1:E10`

### valueInputOption

| Option | Description |
|--------|-------------|
| `USER_ENTERED` | Interpreted as if typed by a user (recognizes formulas and dates) |
| `RAW` | Stored as-is (treated as string) |

### --format option

| Format | Use case |
|--------|----------|
| `json` | Default. For structured data processing |
| `csv` | Convenient for grep / awk / pipe processing |
| `table` | Human-readable table display |
| `yaml` | YAML format |
