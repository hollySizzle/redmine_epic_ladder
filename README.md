# Redmine Epic Grid Plugin
## 拡張機能の目的

Redmine は自由(しかもOSS!!)､だが､その自由さと無骨なUIによって､PMは過労死するだろう(少なくとも腱鞘炎にはなる)｡
Epic-Gridは､Redmineにちょっとした秩序とちょっとしたモダンUIをもたらし､PMの離職率を下げることを目的としている｡
そしてEpic-Gridは､スクラム開発､伝統的なウォーターフォール開発にもフィットする｡


### こんなプロジェクトになるとPMは過労死する

PMが傷病休暇になるプロジェクトは大体以下のようなカオス状態になっている｡
少なくとも､PMの1日の仕事がRedmineのチケット管理だけになる｡

- 無限の階層構造
  - あるチケットをクローズしようとしたら､チケットが子チケットを持っていてクローズできない→子チケットを見たらさらに子チケットを持っている→さらにその子チケットも子チケットを持っている→無限ループ
- 超複雑な関連チケット
  - 循環していてチケットがクローズできなくなる
- いったい誰が親チケットの責任を持っているかわからない
- きれいなガントを書いたけれど､スケジュール変更のたびに膨大なチケットの期日を手動で変更しなければならない

### 4種のトラッカーそしてバージョン
PMが決めるべきことはタスクの構造化だ｡
タスクの構造化には､シンプルなスクラム開発式の4階層構造を導入すると平和で､ちょうどよく普遍性がある｡
しかし､もちろんウォーターフォール開発にも適用可能だ｡

導入するトラッカーの概念は以下の通り｡
```
Epic (大分類)
  └─ Feature (分類を行うための中間層)
      └─ User Story (ユーザの要求など､ざっくりとした目標)
          ├─ Task (作業者が実際にやるべきこと)
          ├─ Bug (発生した不具合)
          └─ Test (やるべきテストや検証)
```
理想的にはこんな感じ
```
Epic: ユーザ動線
  └─ Feature: CTA
      └─ User Story: 申込画面を作る
          ├─ Task: 申込フォームのUIを作る
          ├─ Task: バックエンドAPIを作る
          ├─ Bug: 申込フォームのバリデーションが効かない不具合を修正
          └─ Test: 申込完了までのE2Eテストを作る
```
これは概念だ。トラッカーへの役割割り当ては自由で、プロジェクト単位でON/OFFできる。既存プロジェクトにも導入可能である｡
例えば､よりウォーターフォールっぽくUserStoryをトラッカー名"実作業"に割り当て､Task/Bug/Testを使わない､という選択も出来る

あとPMが決めるべきことは"いつまでにやるか"だ
Redmineでのメジャーなタスク期日の管理は､チケット毎に期日を設定する方法だろう｡しかし､チケットの量が多くなるとPMの手首の負担が増える｡
そこで､チケットを束として扱う｡その束のラベルに"いつまでにリリースするか"を書いておけばよい｡これがRedmineのVersion機能だ｡

例えばこんな感じ
```
Version 1.1(リリース予定: 2025-12-31)
└─ User Story: 申込画面を作る
  ├─ Task: 申込フォームのUIを作る
  ├─ Bug: 申込フォームのバリデーションが効かない不具合を修正
  └─ Test: 申込完了までのE2Eテストを作る
└─ User Story: ユーザープロフィール画面を作る
Version 1.2(リリース予定: 2026-1-31)
└─ User Story: Googleでログインできるようにしたい
└─ User Story: アバター画像をアップロードできるようにしたい
```
※ このバージョンを特定の周期で追加すると､まさにスクラム開発のスプリント管理になる｡

もし申込画面のリリースが間に合わなそうならば､User StoryのVersionを1.2に変更すればよい｡

この"タスクの構造化"と"Versionによるリリース管理"をEpic-Gridは支援する｡

### Epic Gridビュー
まず､どの機能をどのタイミングでリリースするかを視覚的に直感的に､そしてチケットIDを暗記しなくてもよいように管理できるUIが必要だ｡

Epic GridビューはReact + Zustandで実装された現代的なUIで、以下の機能を提供する：

- **ドラッグ&ドロップ操作** - チケットを直感的に移動・並び替え
- **階層の可視化** - Epic→Feature→User Story→Task/Testの構造を一目で把握
- **フィルタリング** - Version、担当者、ステータスで絞り込み

### 詳細画面拡張
メンバはプロジェクトを管理することに興味は無い｡メンバはいつだって自分のタスクに集中して早く終わらせたい(それが正解だ)｡
これまで同様に便利なプラグイン(Epic-Gridもそうであってほしい)を導入しても､PMしか使わず､メンバは慣れ親しんだRedmineの詳細画面で作業するだろう｡
そこで､詳細画面には慣れ親しんだRedmineの古き良きUIを維持しつつ､以下の機能を追加する：

- **トラッカー構造に合わせたチケット追加** - User StoryからTask/Bug/Testを素早く追加
- **バージョン変更** - バージョン変更だけで､UserStory配下の開始日･期日を自動更新

慣れたUIはそのままに、必要な機能だけを追加した｡


## インストール手順 (ユーザー向け)

### 🚀 クイックスタート (npm不要)

このプラグインは **npm環境不要** で動作します。ビルド済みファイルがGitリポジトリに含まれているため、以下の手順だけでインストール可能です：

```bash
# 1. Redmineプラグインディレクトリに移動
cd /path/to/redmine/plugins

# 2. プラグインをクローン
git clone https://github.com/your-repo/redmine_epic_grid.git

# 3. Redmine再起動
# Docker環境の場合
docker compose restart redmine

# 通常環境の場合
bundle exec rails s
```

**それだけです！** Redmine起動時に自動的にアセットが配信されます。

### 🐳 Docker環境でのデプロイ手順（推奨）

Docker環境では、確実なデプロイのため以下の手順を推奨します：

```bash
# 1. プラグインディレクトリに移動
cd /app/IntranetApps/containers/202501_redmine/app/plugins/redmine_epic_grid

# 2. 最新コードを取得
git pull

# 3. アセットを手動デプロイ（確実）
docker exec redmine bundle exec rake redmine_epic_grid:deploy

# 4. コンテナ再起動
cd /app/IntranetApps/containers/202501_redmine
docker compose restart redmine

# 5. ブラウザでスーパーリロード
# Windows/Linux: Ctrl + Shift + R
# Mac: Cmd + Shift + R
```

**なぜ手動デプロイが必要？**
- 自動デプロイはタイムスタンプ比較で動作するため、Gitの `git pull` 後にタイムスタンプが期待通り更新されない場合があります
- `rake redmine_epic_grid:deploy` を実行することで、確実に最新のビルドファイルが配信されます

### 📦 自動アセット配信の仕組み

Rails起動時に `assets/build/` から `public/plugin_assets/redmine_epic_grid/` へビルド済みファイルが自動コピーされます。

- ✅ npm環境不要
- ✅ Docker環境不要
- ✅ 手動コピー不要
- ✅ ブラウザキャッシュ対策済み (ハッシュ付きファイル名)

### 🔍 デプロイ状態の確認

```bash
# アセット配信状態を確認
bundle exec rake redmine_epic_grid:status
```

出力例：
```
=== Epic Grid Asset Status ===

Source directory (Git-managed):
  Path: /usr/src/redmine/plugins/redmine_epic_grid/assets/build
  Status: ✅ Exists (5 files)
    - kanban_bundle.8d031bec.js (455 KB, modified: 2025-10-20)
    - asset-manifest.json (0.3 KB)
    ...

Deployment directory (Redmine public):
  Path: /usr/src/redmine/public/plugin_assets/redmine_epic_grid
  Status: ✅ Exists (5 files)

Recommendations:
  ✅ Assets are up to date
```

### 🛠️ 手動デプロイコマンド

```bash
# Docker環境
docker exec redmine bundle exec rake redmine_epic_grid:deploy

# 通常環境
bundle exec rake redmine_epic_grid:deploy
```

---

## 開発者向け情報

### 📝 本番ビルドの作成 (開発者のみ)

プラグインをリリースする前に、**必ず本番ビルドを実行してGitにコミット**してください：

```bash
# 1. 本番用ビルドを実行
npm run build:prod

# 2. ビルドファイルを確認
ls -lh assets/build/kanban_bundle*.js
# → kanban_bundle.8d031bec.js (455 KB) が生成される

# 3. Gitにコミット
git add assets/build/kanban_bundle.*.js assets/build/asset-manifest.json
git commit -m "Release v1.x.x: Update production build"
git tag v1.x.x
git push origin main --tags
```

**重要**: ユーザーはこの本番ビルド (ハッシュ付きファイル) を使用します。

### 🛠️ 開発時のビルド

フロントエンド開発時は開発ビルドを使用：

```bash
# 開発ビルド (デバッグ可能、サイズ大)
npm run dev

# または手動ビルド
npm run build
```

**注意**: 開発ビルドは Git にコミットしないでください (4.9MB と大きい)。

### 📊 ビルドの違い

| ビルドタイプ | コマンド | ファイル名 | サイズ | 用途 |
|------------|---------|-----------|-------|------|
| **開発** | `npm run build` | `kanban_bundle.js` | 4.9 MB | ローカル開発 |
| **本番** | `npm run build:prod` | `kanban_bundle.[hash].js` | 455 KB | Git配布・本番環境 |

---

## トラブルシューティング

### ❌ アセットが配信されない場合

**症状**: ブラウザで JavaScript エラーが発生、またはページが真っ白

**解決策**:

```bash
# 1. アセット配信状態を確認
bundle exec rake redmine_epic_grid:status

# 2. 手動デプロイ
bundle exec rake redmine_epic_grid:deploy

# 3. Rails 再起動
# Docker環境
docker compose restart redmine

# 通常環境
bundle exec rails s
```

### ❌ 最新の変更が反映されない

**症状**: `git pull` したのにブラウザで反映されない

**解決策**:

```bash
# Docker環境の場合
docker exec redmine bundle exec rake redmine_epic_grid:deploy
docker compose restart redmine

# 通常環境の場合
bundle exec rake redmine_epic_grid:deploy
bundle exec rails s

# ブラウザでスーパーリロード
# Windows/Linux: Ctrl + Shift + R
# Mac: Cmd + Shift + R
```

**開発者向け**: コードを変更した場合は本番ビルドを再実行してください
```bash
npm run build:prod
git add assets/build/
git commit -m "Update production build"
```

### ❌ ブラウザキャッシュが残る

**症状**: 古いバージョンのJSファイルが読み込まれる

**原因**: ハッシュ付きファイル名が変わっていない (コード変更なし)

**解決策**:
- 本番ビルド (`npm run build:prod`) はコード変更時にハッシュが自動変更されます
- ハッシュが変われば自動的にキャッシュクリアされます

### API 403エラーが発生する場合

`BaseApiController`で`skip_before_action :check_if_login_required`が設定されているか確認してください。
これにより、Railsの標準認証をスキップし、API専用の認証処理が動作します。

---

## 🤖 MCP Server (AI連携機能)


このプラグインは**Model Context Protocol (MCP)**に対応しており、Claude DesktopなどのAIエージェントから直接タスクを作成できます。

### 🔌 対応クライアント

以下のクライアントに対応しています（すべてHTTP接続）:

- **Claude Desktop** (Pro/Max/Team/Enterprise) - GUI設定で簡単接続
- **Claude Code** - CLIコマンドで接続

HTTP経由でRedmineに接続し、チーム全体で共有可能です。

### 🎯 できること

**Before (従来):**
```
エンジニア: 「カート画面のリファクタリングをしたい」
  ↓ (10分)
  - RedmineでEpic/Feature/User Storyを探す
  - Versionを選択
  - チケットフォーム入力
  ↓
  疲れて諦める
```

**After (MCP Server導入後):**
```
エンジニア: 「カートのリファクタリングタスクを作って」
  ↓ (3秒)
AI (Claude): 「Task #9999を作成しました！」
  ↓
  完了！フロー状態を維持
```

### 📦 共通インストール手順

#### 1. 依存関係のインストール

Redmineルートディレクトリで `bundle install` を実行してください:

```bash
cd /usr/src/redmine  # または /path/to/your/redmine
bundle install
```

プラグイン内の `PluginGemfile` に記載された依存関係（`mcp` gem等）が自動的にインストールされます。

---

### 🌐 HTTP版セットアップ (Claude Desktop)

Claude Desktop (Pro/Max/Team/Enterprise) からHTTP経由でRedmineに接続します。

#### 1. Redmine APIキーの取得

1. Redmineにログイン
2. 右上のアカウントメニュー → 「個人設定」
3. 「APIアクセスキー」セクションで「表示」をクリック
4. 表示されたAPIキーをコピー（例: `a1b2c3d4e5f6...`）

#### 2. Claude Desktopでの設定

1. Claude Desktopを開く
2. 設定 (Settings) → Connectors → Add Connector
3. 以下のように設定:

| 項目 | 値 |
|------|---|
| **Name** | `Redmine Epic Grid` |
| **URL** | `https://your-redmine.com/mcp/rpc` |
| **Authorization Header** | `X-Redmine-API-Key: [Your API Key]` |

**例:**
```
Name: Redmine Epic Grid
URL: https://redmine.example.com/mcp/rpc
Authorization Header: X-Redmine-API-Key: a1b2c3d4e5f6789abcdef0123456789abcdef012
```

#### 3. 接続確認

Claude Desktopで以下のように話しかけてみてください:

```
「利用可能なMCPツールを教えて」
```

成功すると、`create_task_tool` が表示されます！

#### 4. 使用例

```
「sakura-ecプロジェクトで、カートのリファクタリングタスクを作って」
```

Claude が自動的に:
- Taskチケット作成
- 適切な親UserStoryを推論
- Versionを継承

#### ❌ HTTP版トラブルシューティング

**症状:** 「Connection failed」エラー

**解決策:**
1. RedmineサーバーがHTTPSで公開されているか確認
   - Claude Desktopは **HTTPS必須** です
   - ローカル開発環境（HTTP）では接続できません
2. APIキーが正しいか確認
3. Redmineサーバーでエラーログを確認
   ```bash
   tail -f log/development.log
   ```

---

### 💻 Claude Code セットアップ

Claude Code (CLI) からHTTP経由で接続します。

#### 1. Redmine APIキーの取得

Claude Desktopと同じ手順でAPIキーを取得してください（上記参照）。

#### 2. Claude Code CLIで接続

```bash
# 基本的な構文
claude mcp add --transport http redmine_epic_grid \
  https://your-redmine.com/mcp/rpc \
  --header "X-Redmine-API-Key: YOUR_API_KEY"

# 実際の例
claude mcp add --transport http redmine_epic_grid \
  https://redmine.example.com/mcp/rpc \
  --header "X-Redmine-API-Key: a1b2c3d4e5f6789abcdef0123456789abcdef012"

# ローカル開発環境（HTTP）の例
claude mcp add --transport http redmine_epic_grid \
  http://localhost:3000/mcp/rpc \
  --header "X-Redmine-API-Key: YOUR_API_KEY"
```

#### 3. 接続確認

```bash
# 設定したサーバーを確認
claude mcp list

# Claude Code内で確認
/mcp
```

#### 4. 使用例

Claude Code内で以下のように使います:

```
「sakura-ecプロジェクトで、カートのリファクタリングタスクを作って」
```

#### ❌ Claude Code トラブルシューティング

**症状:** 「Connection failed」エラー

**解決策:**
1. Redmineサーバーが起動しているか確認
   ```bash
   curl http://localhost:3000/mcp/rpc \
     -X POST \
     -H "Content-Type: application/json" \
     -H "X-Redmine-API-Key: YOUR_API_KEY" \
     -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
   ```
2. APIキーが正しいか確認
3. URLが正しいか確認（HTTPSかHTTPか）

**症状:** 「Invalid API key」エラー

**解決策:**
- Redmineで新しいAPIキーを生成
- `claude mcp remove redmine_epic_grid` で削除してから再設定

---

### 🛠️ 利用可能なツール（全16ツール）

Epic-Grid MCP Serverは、PMの過労死を防ぐための16のツールを提供します。

#### カテゴリ1: チケット作成ツール（6個）

**Epic階層に沿ったチケット作成**を支援します。

##### 1. `create_epic_tool` - Epic作成

Epic（大分類）を作成します。

**パラメータ:**
- `project_id` (省略可): プロジェクト（省略時はDEFAULT_PROJECT）
- `subject` (必須): Epicの件名
- `description` (省略可): 説明
- `assigned_to_id` (省略可): 担当者ID

**使用例:**
```
ユーザー: 「ユーザー動線のEpicを作って」
→ Epic #1000「ユーザー動線」が作成される
```

##### 2. `create_feature_tool` - Feature作成

Feature（分類を行うための中間層）を作成します。

**パラメータ:**
- `project_id` (省略可): プロジェクト（省略時はDEFAULT_PROJECT）
- `subject` (必須): Featureの件名
- `parent_epic_id` (必須): 親Epic ID
- `description` (省略可): 説明

**使用例:**
```
ユーザー: 「Epic #1000配下にCTAのFeatureを作って」
→ Feature #1001「CTA」が作成される（親: Epic #1000）
```

##### 3. `create_user_story_tool` - UserStory作成

UserStory（ユーザの要求など､ざっくりとした目標）を作成します。

**パラメータ:**
- `project_id` (省略可): プロジェクト（省略時はDEFAULT_PROJECT）
- `subject` (必須): UserStoryの件名
- `parent_feature_id` (必須): 親Feature ID
- `version_id` (省略可): Version ID
- `description` (省略可): 説明

**使用例:**
```
ユーザー: 「Feature #1001配下に申込画面を作るUserStoryを作って、Version 1.1に割り当てて」
→ UserStory #1002「申込画面を作る」が作成される（親: Feature #1001、Version: 1.1）
```

##### 4. `create_task_tool` - Task作成

Task（作業者が実際にやるべきこと）を作成します。自然言語対応。

**パラメータ:**
- `project_id` (省略可): プロジェクト（省略時はDEFAULT_PROJECT）
- `description` (必須): タスクの説明（自然言語OK）
- `parent_user_story_id` (省略可): 親UserStory ID（**省略時は自動推論**）
- `version_id` (省略可): Version ID（省略時は親から継承）

**使用例:**
```
ユーザー: 「カートのリファクタリングタスクを作って」
→ Task #9999が作成される
→ 親UserStory: #123 カート機能改善（自動推論）
→ Version: Sprint 2025-01（親から継承）
```

##### 5. `create_bug_tool` - Bug作成

Bug（発生した不具合）を作成します。自然言語対応。

**パラメータ:** `create_task_tool` と同じ

**使用例:**
```
ユーザー: 「申込フォームのバリデーションが効かないBugを作って」
→ Bug #1003が作成される（親UserStory自動推論）
```

##### 6. `create_test_tool` - Test作成

Test（やるべきテストや検証）を作成します。自然言語対応。

**パラメータ:** `create_task_tool` と同じ

**使用例:**
```
ユーザー: 「申込完了までのE2Eテストを作って」
→ Test #1004が作成される（親UserStory自動推論）
```

---

#### カテゴリ2: Version管理ツール（3個）

**PMの最大の悩み「スケジュール変更」を解決**します。

##### 7. `create_version_tool` - Version作成

Version（リリース予定）を作成します。

**パラメータ:**
- `project_id` (必須): プロジェクトID
- `name` (必須): Version名
- `effective_date` (必須): リリース予定日（YYYY-MM-DD）
- `description` (省略可): 説明
- `status` (省略可): ステータス（open/locked/closed、デフォルト: open）

**使用例:**
```
ユーザー: 「Sprint 2025-02のVersionを作って、リリース日は2025-02-28で」
→ Version「Sprint 2025-02」が作成される（2025-02-28リリース予定）
```

##### 8. `assign_to_version_tool` - チケットをVersionに割り当て

チケット（UserStory推奨）をVersionに割り当て、**配下のTask/Bug/Testも自動的に同じVersionに設定**します。

**パラメータ:**
- `issue_id` (必須): チケットID
- `version_id` (必須): Version ID

**使用例:**
```
ユーザー: 「UserStory #123をVersion 1.2に割り当てて」
→ UserStory #123とその配下5個のTask/Bug/TestがVersion 1.2に設定される
```

##### 9. `move_to_next_version_tool` - 次のVersionに移動（リスケ）

チケットを次のVersionに移動（リスケ）。**配下のTask/Bug/Testも自動的に移動**されます。

**パラメータ:**
- `issue_id` (必須): チケットID

**使用例:**
```
ユーザー: 「UserStory #123を次のVersionに移動して（リスケ）」
→ UserStory #123が Version 1.1 → Version 1.2 に移動
→ 配下のTask/Bug/Testも自動的にVersion 1.2に移動
```

---

#### カテゴリ3: チケット操作ツール（4個）

**AIがコード作業しながらチケット同期**できます。

##### 10. `update_issue_status_tool` - ステータス更新

チケットのステータスを更新します（Open→InProgress→Closed）。

**パラメータ:**
- `issue_id` (必須): チケットID
- `status_name` (必須): ステータス名（例: 'Open', 'In Progress', 'Closed'）

**使用例:**
```
Claude Code: 「Task #9999のバグを修正しました」
→ 自動で update_issue_status_tool(issue_id: 9999, status_name: "Closed")
→ Task #9999がClosedになる
```

##### 11. `add_issue_comment_tool` - コメント追加

チケットにコメント（ノート）を追加します。

**パラメータ:**
- `issue_id` (必須): チケットID
- `comment` (必須): コメント内容

**使用例:**
```
ユーザー: 「このTask、後で見直したいからコメント残しといて」
Claude Code:
  → add_issue_comment_tool(issue_id: 9999, comment: "実装完了。ただし以下の懸念あり:\n- パフォーマンス要検証")
```

##### 12. `update_issue_progress_tool` - 進捗率更新

チケットの進捗率を更新します（0%→50%→100%）。

**パラメータ:**
- `issue_id` (必須): チケットID
- `progress` (必須): 進捗率（0〜100）

**使用例:**
```
Claude Code: 「Task #9999の実装が半分終わりました」
→ update_issue_progress_tool(issue_id: 9999, progress: 50)
```

##### 13. `update_issue_assignee_tool` - 担当者変更

チケットの担当者を変更します。

**パラメータ:**
- `issue_id` (必須): チケットID
- `assigned_to_id` (必須): 担当者ID（nullで担当者解除）

**使用例:**
```
PM: 「Task #9999を田中さん（ID:5）にアサインして」
→ Task #9999の担当者が田中さんになる
```

---

#### カテゴリ4: 検索・参照ツール（3個）

**AIが親UserStoryを推論する精度向上**に役立ちます。

##### 14. `list_user_stories_tool` - UserStory一覧取得

プロジェクト内のUserStory一覧を取得します。

**パラメータ:**
- `project_id` (必須): プロジェクトID
- `version_id` (省略可): Version IDでフィルタ
- `assigned_to_id` (省略可): 担当者IDでフィルタ
- `status` (省略可): ステータスでフィルタ（open/closed）
- `limit` (省略可): 取得件数上限（デフォルト: 50）

**使用例:**
```
ユーザー: 「sakura-ecプロジェクトのUserStory一覧を見せて」
→ UserStory一覧が返却される（subject, status, version, 担当者など）
```

##### 15. `list_epics_tool` - Epic一覧取得

プロジェクト内のEpic一覧を取得します。

**パラメータ:** `list_user_stories_tool` と類似（version_idフィルタなし）

##### 16. `get_project_structure_tool` - プロジェクト構造可視化

プロジェクトのEpic階層構造（Epic→Feature→UserStory）を可視化します。

**パラメータ:**
- `project_id` (必須): プロジェクトID
- `version_id` (省略可): Version IDでフィルタ
- `status` (省略可): ステータスでフィルタ

**使用例:**
```
PM: 「sakura-ecプロジェクトの構造を見せて」
→ Epic→Feature→UserStoryの階層構造がJSON形式で返却される
→ PMがプロジェクト全体を一目で把握できる
```

---

### 🧠 親UserStory自動推論

`create_task_tool`, `create_bug_tool`, `create_test_tool` で `parent_user_story_id` を省略すると、AIが以下のロジックで最適な親UserStoryを推論します:

1. `description`からキーワード抽出（スペース・句読点で分割）
2. プロジェクト内のUserStoryのsubjectと照合
3. 最もキーワードが一致するUserStoryを選択

**例:**
- description: "カートのリファクタリング"
- 推論結果: UserStory #123 "カート機能改善"（"カート"がマッチ）

---

### ⚙️ 環境変数設定

MCPサーバーの動作は環境変数でカスタマイズできます。`.mcp.json` に追加してください。

#### 設定例

```jsonc
{
  "mcpServers": {
    "redmine_epic_grid": {
      "type": "http",
      "url": "http://localhost:8500/mcp/rpc",
      "headers": {
        "X-Redmine-API-Key": "your_api_key_here"
      },
      "env": {
        // アクセス可能なプロジェクトを制限（デフォルト: ""）
        // カンマ区切りで指定: sakura-ec,sakura-mobile
        // 空文字列の場合はすべてのプロジェクトにアクセス可能
        "ALLOWED_PROJECTS": "sakura-ec,sakura-mobile",

        // デフォルトプロジェクト（デフォルト: ""）
        // project_id省略時に使用される（識別子または数値ID）
        "DEFAULT_PROJECT": "sakura-ec",

        // 親UserStory自動推論を有効化（デフォルト: true）
        "AUTO_INFER_PARENT": "true",

        // 推論の確信度閾値 0.0〜1.0（デフォルト: 0.3）
        // 0.3 = 30%以上の一致で推論を採用
        "AUTO_INFER_THRESHOLD": "0.3",

        // 確認が必要な操作（デフォルト: ""）
        // カンマ区切りで指定: move_version, close
        "REQUIRE_CONFIRMATION_FOR": "move_version,close"
      }
    }
  }
}
```

#### 環境変数の説明

| 環境変数 | デフォルト | 説明 | 推奨設定 |
|---------|----------|------|---------|
| `ALLOWED_PROJECTS` | `""` | アクセス可能なプロジェクトをカンマ区切りで指定<br>空文字列の場合はすべてのプロジェクトにアクセス可能<br>例: `"sakura-ec,sakura-mobile"` | 開発: `""`<br>本番: `"project1,project2"` |
| `DEFAULT_PROJECT` | `""` | デフォルトプロジェクト<br>`project_id`省略時に使用される<br>識別子（例: "sakura-ec"）または数値ID（例: "123"）を指定可能 | 開発: `""`<br>本番: `"main-project"` |
| `AUTO_INFER_PARENT` | `true` | Task/Bug/Test作成時に親UserStoryを自動推論 | 開発: `true`<br>本番: `true` |
| `AUTO_INFER_THRESHOLD` | `0.3` | 推論の確信度閾値（0.0〜1.0）<br>0.3 = 30%以上の一致で採用 | 開発: `0.2`<br>本番: `0.5` |
| `REQUIRE_CONFIRMATION_FOR` | `""` | 確認が必要な操作をカンマ区切りで指定<br>- `move_version`: Version移動<br>- `close`: チケットClose | 開発: `""`<br>本番: `"move_version,close"` |

#### 推奨設定パターン

**パターン1: 開発環境（寛容・高速）**
```jsonc
{
  "env": {
    "ALLOWED_PROJECTS": "",
    "DEFAULT_PROJECT": "",
    "AUTO_INFER_PARENT": "true",
    "AUTO_INFER_THRESHOLD": "0.2",
    "REQUIRE_CONFIRMATION_FOR": ""
  }
}
```
- すべてのプロジェクトにアクセス可能
- project_id指定必須（明示的な指定を推奨）
- 親UserStoryを積極的に推論（閾値20%）
- 確認なしで操作実行（素早くテスト可能）

**パターン2: 本番環境（安全・厳格）**
```jsonc
{
  "env": {
    "ALLOWED_PROJECTS": "sakura-ec,sakura-mobile",
    "DEFAULT_PROJECT": "sakura-ec",
    "AUTO_INFER_PARENT": "true",
    "AUTO_INFER_THRESHOLD": "0.5",
    "REQUIRE_CONFIRMATION_FOR": "move_version,close"
  }
}
```
- アクセス可能プロジェクトを制限（意図しない変更を防止）
- デフォルトプロジェクトを設定（project_id省略可能）
- 親UserStory推論は慎重（閾値50%）
- 危険な操作は確認必須（事故防止）

---

### ❌ 共通トラブルシューティング

#### タスク作成権限エラー

**症状:** 「タスク作成権限がありません」エラー

**解決策:**
- Redmineで該当プロジェクトの権限設定を確認
- ユーザーに「課題の追加」権限を付与

---
