# GAS Autopilotセットアップガイド

## このセットアップで何ができるようになるか

Claude Codeに**gas-autopilot**スキルを導入し、GAS開発を自律的に行えるようにする。コード実装→デプロイ→テスト→修正のループをClaudeが自動で回してくれる。

以下のCLIツールを連携させ、**GASの開発・実行・検証をターミナルから完結**できる環境を構築する。

| ツール | 役割 |
|--------|------|
| **gas-autopilot** | ワークフロー全体を統括するClaude Codeスキル |
| **clasp** | GASコードのpush / pull / バージョン管理 |
| **gws** | スプレッドシートの読み書き（テストデータ投入・結果検証） |
| **gas-run.sh** | push → Web Appデプロイ更新 → 関数実行を1コマンドで自動化 |
| **gas-auth.py** | clasp / gas-run.shに必要な拡張OAuthスコープの認証 |

---

## 手順 0: スキルのインストール

このスキルフォルダをClaude Codeのskillsディレクトリに配置する。

---

## 手順 1: claspのインストール 

確認:

```bash
clasp --version
```

`3.x` が表示されればスキップ。未インストールの場合:

```bash
npm install -g @google/clasp
```

npm が見つからない場合は Node.js を先にインストールする（`brew install node` 等）。

## 手順 2: gws のインストール

確認:

```bash
gws --version
```

バージョンが表示されればスキップ。未インストールの場合は以下の順に進める。

### 2-1. gcloud CLI の確認・インストール

gws のセットアップには gcloud CLI が必要。

```bash
gcloud --version
```

未インストールの場合:

```bash
# macOS (Homebrew)
brew install --cask google-cloud-sdk

# その他の OS → https://cloud.google.com/sdk/docs/install
```

### 2-2. gcloud の認証

```bash
gcloud auth login
```

ブラウザが開くので Google アカウントで認可する。

### 2-3. gws のインストール

```bash
curl -fsSL https://github.com/googleworkspace/cli/releases/latest/download/gws-installer.sh | sh
```

確認:

```bash
gws --version
```

## 手順 3: gws の初期設定（OAuth クライアント作成）

```bash
gws auth setup
```

対話的に以下が行われる:

1. gcloud CLI の検出
2. Google アカウントの選択
3. GCP プロジェクトの選択 or 作成
4. Workspace API の有効化（Apps Script API 含む）
5. **OAuth クライアントの作成**（手動操作が必要）

### Step 5 で手動操作を求められた場合

`gws auth setup` の Step 5 で OAuth クライアントの手動作成を求められる。表示される指示に従い:

1. GCP コンソールの認証情報ページを開く
2. **認証情報を作成 → OAuth クライアント ID** をクリック
3. アプリケーションの種類: **デスクトップアプリ**
4. 作成後、表示される **Client ID** と **Client Secret** を `gws auth setup` の入力欄に貼り付ける

同時に、**JSON をダウンロード**しておく（`client_secret_*.json`）。手順 9 の `gas-auth.py` で使用する。

## 手順 4: gws の認証

```bash
gws auth login
```

ブラウザが開くので認可する。

### スコープを絞りたい場合

引数なしの `gws auth login` はデフォルトで多数のスコープを要求する。GAS 開発に必要なスコープだけに絞る場合:

```bash
gws auth login --scopes "https://www.googleapis.com/auth/spreadsheets,https://www.googleapis.com/auth/script.projects,https://www.googleapis.com/auth/script.deployments,https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform"
```

**注意:** `--scopes` の値は**ダブルクォートで囲った1つの文字列**として渡すこと。改行や複数引数に分割すると失敗する。

認証状態の確認:

```bash
gws auth status
```

## 手順 5: clasp の認証

```bash
clasp login
```

ブラウザが開くので Google アカウントで認可する。認証済みかどうかは `clasp push` の成否で確認する（clasp 3.x に `--status` オプションはない）。

## 手順 6: GAS プロジェクトの準備

```bash
# 既存プロジェクトをクローン
clasp clone <scriptId>

# または新規作成（スプレッドシートにバインド）
clasp create --type sheets --title "プロジェクト名"
```

これで `.clasp.json` と `appsscript.json` が作成される。

## 手順 7: appsscript.json に oauthScopes を追加

Web App 経由で `SpreadsheetApp.openById()` を使うにはスコープの明示が必要。`appsscript.json` に以下を追加する:

```json
{
  "timeZone": "Asia/Tokyo",
  "dependencies": {},
  "oauthScopes": [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/script.external_request"
  ],
  "exceptionLogging": "STACKDRIVER",
  "runtimeVersion": "V8"
}
```

**注意:** `getActiveSpreadsheet()` は Web App 経由では使えない（バインドコンテキストがないため）。**必ず `SpreadsheetApp.openById()` を使うこと。**

## 手順 8: doGet ハンドラの追加

プロジェクトの `.gs` ファイルに [templates/doGet.js](templates/doGet.js) の内容を追加する。`allowedFunctions` には実行したい関数を列挙する。

追加後に push して GAS 側に反映する:

```bash
clasp push --force
```

## 手順 9: Web App デプロイ（GAS エディタから・初回のみ）

1. GAS エディタを開く: `https://script.google.com/home/projects/<scriptId>/edit`
2. **デプロイ → 新しいデプロイ**
3. 種類: **ウェブアプリ**
4. 次のユーザーとして実行: **自分**
5. アクセス: **自分のみ**
6. **デプロイ** をクリック

表示される **Web App URL** を控える（デプロイ ID は URL の `/s/` と `/exec` の間の文字列）。

**注意:** 初回デプロイ時にスコープの認可ダイアログが表示される。許可すること。

## 手順 10: gas-run.shの配置と設定ファイル

[templates/gas-run.sh](templates/gas-run.sh)をプロジェクトディレクトリにコピーする:

```bash
chmod +x gas-run.sh
```

gas-run.shは同ディレクトリの`.gas-autopilot.json`から設定を読み込む。このファイルは`/gas-autopilot`スキルを初回起動したときに**Claudeが自動作成**する。手動で作成する場合:

```json
{
  "scriptId": "<.clasp.jsonから取得>",
  "webappUrl": "<手順9のWeb App URL>",
  "webappDeployId": "<URLの/s/と/execの間の文字列>",
  "spreadsheetUrl": "<スプレッドシートのURL>",
  "spreadsheetId": "<URLから抽出>"
}
```

`.gas-autopilot.json`は`.gitignore`への追加を推奨。

## 手順 11: OAuth 認証（拡張スコープ）

clasp のデフォルト OAuth スコープには `spreadsheets` が含まれない。[templates/gas-auth.py](templates/gas-auth.py) で拡張スコープの認証を行う。

確認:

```bash
python3 --version
```

Python 3 が見つからない場合は先にインストールする（`brew install python` 等）。

```bash
python3 gas-auth.py <手順3でダウンロードした client_secret_*.json のパス>
```

ブラウザが開くので認可する。成功すると `~/.clasprc.json` が更新される。

## 手順 12: 動作確認

```bash
./gas-run.sh deploy testConfig
```

`{"ok": true, "function": "testConfig", "result": null}` が返ればCLIツールの準備は完了。

## 手順 13: スキルの有効化確認

Claude Codeのセッションを新しく開始し、`/gas-autopilot`と入力してスキルが呼び出せることを確認する。呼び出せればセットアップ完了。

---

## Tips

### clasp 3.x の注意点

- `clasp open` は廃止。GAS エディタは URL で直接開く
- `clasp pull` は `.gs` を `.js` にリネームする場合がある。pull 後に `.js` を削除して `.gs` のみ維持すること
- `clasp deploy` は Web App デプロイではなくライブラリデプロイを作成する。Web App の初回デプロイは GAS エディタから行うこと

### gws の注意点

- `--params` はシングルクォート JSON を受け付けない環境がある。ダブルクォートをエスケープして渡す

```bash
# NG になる場合
gws sheets spreadsheets get --params '{"spreadsheetId":"ID"}'

# OK
gws sheets spreadsheets get --params "{\"spreadsheetId\":\"ID\"}"
```

### clasp run が使えない理由

`clasp run` は container-bound スクリプト（スプレッドシートにバインドされた GAS）では動作しない（Scripts API が 404 を返す）。そのため Web App デプロイ + gas-run.sh を使用する。standalone スクリプトであれば `clasp run` は使用可能。

### OAuth クライアントの差し替え

gws の OAuth クライアントを変更したい場合:

```bash
cp ~/.config/gws/client_secret.json ~/.config/gws/client_secret.json.bak
cp <新しい client_secret_*.json> ~/.config/gws/client_secret.json
gws auth logout
gws auth login
```
