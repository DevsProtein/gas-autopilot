# Formatting & Sheet Management Reference

`values update` handles data only. Use `batchUpdate` for formatting operations.

## Important Rules

- When copying a table from an existing sheet, **always copy formatting (colors, borders, number formats) as well**
- When creating a new table, **apply styles to the header row**
- When modifying table structure (adding/removing columns, shrinking range), **always clear leftover formatting from the old range** (`values clear` only clears data, not formatting. Use `batchUpdate` with `repeatCell` to reset formatting)

## Create New Sheet

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"addSheet\":{\"properties\":{\"title\":\"NewSheetName\"}}}]}"
```

## Copy Range Formatting (preserves colors, borders, number formats)

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"copyPaste\":{\"source\":{\"sheetId\":SRC_SHEET_ID,\"startRowIndex\":0,\"endRowIndex\":10,\"startColumnIndex\":0,\"endColumnIndex\":5},\"destination\":{\"sheetId\":DEST_SHEET_ID,\"startRowIndex\":0,\"endRowIndex\":10,\"startColumnIndex\":0,\"endColumnIndex\":5},\"pasteType\":\"PASTE_FORMAT\"}}]}"
```

**pasteType options:**

| pasteType | What is copied |
|-----------|---------------|
| `PASTE_FORMAT` | Background color, borders, font, number format, alignment |
| `PASTE_CONDITIONAL_FORMATTING` | Conditional formatting rules |
| `PASTE_NORMAL` | All data + formatting |
| `PASTE_VALUES` | Values only (formulas converted to results) |
| `PASTE_FORMULA` | Formulas only |
| `PASTE_NO_BORDERS` | Formatting (except borders) + data |
| `PASTE_DATA_VALIDATION` | Data validation rules only |

## Copy Column Widths

Column widths are not included in `PASTE_FORMAT`. Set them individually with `updateDimensionProperties`.

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"updateDimensionProperties\":{\"range\":{\"sheetId\":SHEET_ID,\"dimension\":\"COLUMNS\",\"startIndex\":0,\"endIndex\":1},\"properties\":{\"pixelSize\":150},\"fields\":\"pixelSize\"}}]}"
```

Get column widths from the source sheet:
```bash
gws sheets spreadsheets get \
  --params "{\"spreadsheetId\":\"ID\",\"fields\":\"sheets(properties(sheetId,title),data(columnMetadata(pixelSize)))\"}" 2>/dev/null
```

## Table Copy Procedure (Summary)

When copying a table from an existing sheet to another, execute in this order:

1. `addSheet` to create the new sheet
2. `values update` to write data/formulas (adjust row references as needed)
3. `copyPaste` + `PASTE_FORMAT` to copy formatting
4. `copyPaste` + `PASTE_CONDITIONAL_FORMATTING` to copy conditional formatting
5. `updateDimensionProperties` to set column widths

## Format Reset (full clear of data + formatting)

`values clear` only clears data — background colors, borders, fonts, etc. remain.
Cells that become unnecessary after table column removal or range shrinking must have their formatting reset as well.

```bash
# Reset formatting to default (data is not cleared)
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"repeatCell\":{\"range\":{\"sheetId\":SHEET_ID,\"startRowIndex\":START_ROW,\"endRowIndex\":END_ROW,\"startColumnIndex\":START_COL,\"endColumnIndex\":END_COL},\"cell\":{\"userEnteredFormat\":{}},\"fields\":\"userEnteredFormat\"}}]}"
```

To clear both data and formatting, combine `values clear` + `repeatCell`.

**Checklist for structural changes:**

| Change | Area to clear |
|--------|--------------|
| Reduced columns | Columns beyond the old table's right edge (header + data rows) |
| Reduced rows | Rows beyond the old table's bottom edge |
| Moved table | Entire original range |

**Note:** Only reset the range that is no longer needed. Specify ranges precisely to avoid clearing formatting within the active table.

## New Table Header Row Styling

When creating a new table, apply the following style to the header row.

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"repeatCell\":{\"range\":{\"sheetId\":SHEET_ID,\"startRowIndex\":HEADER_ROW,\"endRowIndex\":HEADER_ROW+1,\"startColumnIndex\":0,\"endColumnIndex\":COL_COUNT},\"cell\":{\"userEnteredFormat\":{\"backgroundColor\":{\"red\":0.25,\"green\":0.25,\"blue\":0.25},\"textFormat\":{\"bold\":true,\"fontFamily\":\"Meiryo\",\"fontSize\":9,\"foregroundColor\":{\"red\":1,\"green\":1,\"blue\":1}},\"horizontalAlignment\":\"CENTER\",\"verticalAlignment\":\"MIDDLE\",\"wrapStrategy\":\"WRAP\",\"borders\":{\"top\":{\"style\":\"SOLID\",\"width\":1},\"bottom\":{\"style\":\"SOLID\",\"width\":1},\"left\":{\"style\":\"SOLID\",\"width\":1},\"right\":{\"style\":\"SOLID\",\"width\":1}}}},\"fields\":\"userEnteredFormat\"}}]}"
```

Style spec:

| Property | Value |
|----------|-------|
| Background | Dark gray `rgb(0.25, 0.25, 0.25)` = `#404040` |
| Text color | White `rgb(1, 1, 1)` |
| Font | Meiryo 9pt bold |
| Alignment | Center horizontal, middle vertical |
| Borders | Solid on all sides |
| Wrap | WRAP |
