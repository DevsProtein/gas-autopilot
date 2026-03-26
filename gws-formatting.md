# 書式操作・シート管理リファレンス

`values update` はデータのみ。書式の操作には `batchUpdate` を使う。

## 重要ルール

- 既存シートの表をコピーする際は、**必ず書式（配色・罫線・数値書式）もコピーする**
- 新規に表を作成する場合、**ヘッダー行にスタイルを適用する**
- テーブルの構造変更（列の追加/削除、範囲の縮小）を行った場合、**旧範囲にはみ出た書式の残骸を必ずクリアする**（`values clear` はデータのみで書式は残る。書式リセットには `batchUpdate` の `repeatCell` を使う）

## シートの新規作成

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"addSheet\":{\"properties\":{\"title\":\"新シート名\"}}}]}"
```

## 範囲の書式コピー（配色・罫線・数値書式を維持）

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"copyPaste\":{\"source\":{\"sheetId\":SRC_SHEET_ID,\"startRowIndex\":0,\"endRowIndex\":10,\"startColumnIndex\":0,\"endColumnIndex\":5},\"destination\":{\"sheetId\":DEST_SHEET_ID,\"startRowIndex\":0,\"endRowIndex\":10,\"startColumnIndex\":0,\"endColumnIndex\":5},\"pasteType\":\"PASTE_FORMAT\"}}]}"
```

**pasteType の種類:**

| pasteType | コピーされる内容 |
|-----------|---------------|
| `PASTE_FORMAT` | 背景色・罫線・フォント・数値書式・配置 |
| `PASTE_CONDITIONAL_FORMATTING` | 条件付き書式 |
| `PASTE_NORMAL` | データ＋書式すべて |
| `PASTE_VALUES` | 値のみ（数式は計算結果に変換） |
| `PASTE_FORMULA` | 数式のみ |
| `PASTE_NO_BORDERS` | 罫線以外の書式＋データ |
| `PASTE_DATA_VALIDATION` | 入力規則のみ |

## 列幅のコピー

列幅は `PASTE_FORMAT` に含まれない。`updateDimensionProperties` で個別に設定する。

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"updateDimensionProperties\":{\"range\":{\"sheetId\":SHEET_ID,\"dimension\":\"COLUMNS\",\"startIndex\":0,\"endIndex\":1},\"properties\":{\"pixelSize\":150},\"fields\":\"pixelSize\"}}]}"
```

元シートの列幅は `get` で取得できる:
```bash
gws sheets spreadsheets get \
  --params "{\"spreadsheetId\":\"ID\",\"fields\":\"sheets(properties(sheetId,title),data(columnMetadata(pixelSize)))\"}" 2>/dev/null
```

## 表のコピー手順（まとめ）

既存シートの表を別シートにコピーする場合は、以下の順で実行する:

1. `addSheet` で新シートを作成
2. `values update` でデータ・数式を書き込み（セル参照は行番号を調整）
3. `copyPaste` + `PASTE_FORMAT` で書式をコピー
4. `copyPaste` + `PASTE_CONDITIONAL_FORMATTING` で条件付き書式をコピー
5. `updateDimensionProperties` で列幅を設定

## 書式リセット（データ＋書式の完全クリア）

`values clear` はデータのみクリアし、背景色・罫線・フォント等の書式は残る。
テーブルの列削除や範囲縮小で不要になったセルは、書式もリセットすること。

```bash
# 書式をデフォルトに戻す（データはクリアされない）
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"repeatCell\":{\"range\":{\"sheetId\":SHEET_ID,\"startRowIndex\":START_ROW,\"endRowIndex\":END_ROW,\"startColumnIndex\":START_COL,\"endColumnIndex\":END_COL},\"cell\":{\"userEnteredFormat\":{}},\"fields\":\"userEnteredFormat\"}}]}"
```

データと書式の両方をクリアする場合は、`values clear` → `repeatCell` を組み合わせる。

**構造変更時のチェックリスト:**

| 変更内容 | クリア対象 |
|---------|----------|
| 列を減らした | 旧テーブルの右端からはみ出た列（ヘッダー行 + データ行） |
| 行を減らした | 旧テーブルの下端からはみ出た行 |
| テーブルを移動した | 移動元の全範囲 |

**注意:** リセット対象は「不要になった範囲のみ」に限定する。テーブル内の書式まで消さないよう範囲を正確に指定すること。

## 新規テーブルのヘッダー行スタイリング

新規に表を作成する場合、ヘッダー行に以下のスタイルを適用する。

```bash
gws sheets spreadsheets batchUpdate \
  --params "{\"spreadsheetId\":\"ID\"}" \
  --json "{\"requests\":[{\"repeatCell\":{\"range\":{\"sheetId\":SHEET_ID,\"startRowIndex\":HEADER_ROW,\"endRowIndex\":HEADER_ROW+1,\"startColumnIndex\":0,\"endColumnIndex\":COL_COUNT},\"cell\":{\"userEnteredFormat\":{\"backgroundColor\":{\"red\":0.25,\"green\":0.25,\"blue\":0.25},\"textFormat\":{\"bold\":true,\"fontFamily\":\"Meiryo\",\"fontSize\":9,\"foregroundColor\":{\"red\":1,\"green\":1,\"blue\":1}},\"horizontalAlignment\":\"CENTER\",\"verticalAlignment\":\"MIDDLE\",\"wrapStrategy\":\"WRAP\",\"borders\":{\"top\":{\"style\":\"SOLID\",\"width\":1},\"bottom\":{\"style\":\"SOLID\",\"width\":1},\"left\":{\"style\":\"SOLID\",\"width\":1},\"right\":{\"style\":\"SOLID\",\"width\":1}}}},\"fields\":\"userEnteredFormat\"}}]}"
```

スタイル仕様:

| 項目 | 値 |
|------|-----|
| 背景色 | ダークグレー `rgb(0.25, 0.25, 0.25)` = `#404040` |
| 文字色 | 白 `rgb(1, 1, 1)` |
| フォント | Meiryo 9pt 太字 |
| 配置 | 中央揃え・上下中央 |
| 罫線 | 四辺実線 |
| 折り返し | WRAP |
