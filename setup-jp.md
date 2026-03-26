# GAS Autopilotセットアップガイド

## このセットアップで何ができるようになるか

**gas-autopilot**スキルと、それが依存するCLIツールをインストールする。このセットアップ完了後、`/gas-autopilot`を呼び出せばClaudeがプロジェクト固有の設定（GASプロジェクト紐付け、Web Appデプロイなど）を自動で案内してくれる。

| ツール | 役割 |
|--------|------|
| **gas-autopilot** | ワークフロー全体を統括するClaude Codeスキル |
| **clasp** | GASコードのpush / pull / バージョン管理 |
| **gws** | スプレッドシートの読み書き（テストデータ投入・結果検証） |

---

## 手順 0: スキルのインストール

このスキルフォルダをClaude Codeのskillsディレクトリに配置する。

---

## 手順 1: claspのインストール

確認:

```bash
clasp --version
```

`3.x`が表示されればスキップ。未インストールの場合:

```bash
npm install -g @google/clasp
```

npmが見つからない場合はNode.jsを先にインストールする（`brew install node`等）。

## 手順 2: gwsのインストール

確認:

```bash
gws --version
```

バージョンが表示されればスキップ。未インストールの場合は以下の順に進める。

### 2-1. gcloud CLIの確認・インストール

gwsのセットアップにはgcloud CLIが必要。

```bash
gcloud --version
```

未インストールの場合:

```bash
# macOS (Homebrew)
brew install --cask google-cloud-sdk

# その他のOS → https://cloud.google.com/sdk/docs/install
```

### 2-2. gcloudの認証

```bash
gcloud auth login
```

ブラウザが開くのでGoogleアカウントで認可する。

### 2-3. gwsのインストール

```bash
curl -fsSL https://github.com/googleworkspace/cli/releases/latest/download/gws-installer.sh | sh
```

確認:

```bash
gws --version
```

## 手順 3: gwsの初期設定（OAuthクライアント作成）

```bash
gws auth setup
```

対話的に以下が行われる:

1. gcloud CLIの検出
2. Googleアカウントの選択
3. GCPプロジェクトの選択 or 作成
4. Workspace APIの有効化（Apps Script API含む）
5. **OAuthクライアントの作成**（手動操作が必要）

### Step 5で手動操作を求められた場合

`gws auth setup`のStep 5でOAuthクライアントの手動作成を求められる。表示される指示に従い:

1. GCPコンソールの認証情報ページを開く
2. **認証情報を作成 → OAuthクライアントID**をクリック
3. アプリケーションの種類: **デスクトップアプリ**
4. 作成後、表示される**Client ID**と**Client Secret**を`gws auth setup`の入力欄に貼り付ける

同時に、**JSONをダウンロード**しておく（`client_secret_*.json`）。手順 6の`gas-auth.py`で使用する。

## 手順 4: gwsの認証

```bash
gws auth login
```

ブラウザが開くので認可する。

### スコープを絞りたい場合

引数なしの`gws auth login`はデフォルトで多数のスコープを要求する。GAS開発に必要なスコープだけに絞る場合:

```bash
gws auth login --scopes "https://www.googleapis.com/auth/spreadsheets,https://www.googleapis.com/auth/script.projects,https://www.googleapis.com/auth/script.deployments,https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform"
```

**注意:** `--scopes`の値は**ダブルクォートで囲った1つの文字列**として渡すこと。改行や複数引数に分割すると失敗する。

認証状態の確認:

```bash
gws auth status
```

## 手順 5: claspの認証

```bash
clasp login
```

ブラウザが開くのでGoogleアカウントで認可する。認証済みかどうかは`clasp push`の成否で確認する（clasp 3.xに`--status`オプションはない）。

## 手順 6: OAuth認証（拡張スコープ）

claspのデフォルトOAuthスコープには`spreadsheets`が含まれない。[templates/gas-auth.py](templates/gas-auth.py)で拡張スコープの認証を行う。

確認:

```bash
python3 --version
```

Python 3が見つからない場合は先にインストールする（`brew install python`等）。

```bash
python3 gas-auth.py <手順3でダウンロードしたclient_secret_*.jsonのパス>
```

ブラウザが開くので認可する。成功すると`~/.clasprc.json`が更新される。

## 手順 7: スキルの有効化確認

Claude Codeのセッションを新しく開始し、`/gas-autopilot`と入力してスキルが呼び出せることを確認する。呼び出せればセットアップ完了。

GASプロジェクトとの紐付けやWeb Appデプロイは、スキル起動時にClaudeが自動で案内する。

---

## Tips

### clasp 3.xの注意点

- `clasp open`は廃止。GASエディタはURLで直接開く
- `clasp pull`は`.gs`を`.js`にリネームする場合がある。pull後に`.js`を削除して`.gs`のみ維持すること
- `clasp deploy`はWeb Appデプロイではなくライブラリデプロイを作成する。Web Appの初回デプロイはGASエディタから行うこと

### gwsの注意点

- `--params`はシングルクォートJSONを受け付けない環境がある。ダブルクォートをエスケープして渡す

```bash
# NGになる場合
gws sheets spreadsheets get --params '{"spreadsheetId":"ID"}'

# OK
gws sheets spreadsheets get --params "{\"spreadsheetId\":\"ID\"}"
```

### clasp runが使えない理由

`clasp run`はcontainer-boundスクリプト（スプレッドシートにバインドされたGAS）では動作しない（Scripts APIが404を返す）。そのためWeb Appデプロイ + gas-run.shを使用する。standaloneスクリプトであれば`clasp run`は使用可能。

### OAuthクライアントの差し替え

gwsのOAuthクライアントを変更したい場合:

```bash
cp ~/.config/gws/client_secret.json ~/.config/gws/client_secret.json.bak
cp <新しいclient_secret_*.json> ~/.config/gws/client_secret.json
gws auth logout
gws auth login
```
