# Redmine Epic Grid Plugin

Epic→Feature→UserStory→Task/Test階層制約とVersion管理を統合したEpic Gridシステム

## インストール手順

開発環境で､ npm run build:prod  をじっこうすること

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

### 🛠️ 手動デプロイ (必要に応じて)

自動デプロイが失敗した場合のみ、以下を実行：

```bash
# ビルド済みファイルを配信
bundle exec rake redmine_epic_grid:deploy
```

## 開発環境でのビルド

JavaScriptファイルを変更した場合:

```bash
# プラグインルートディレクトリで実行
cd /path/to/redmine_epic_grid
npm run build

# または、開発サーバーを起動
npm run dev
```

ビルド成果物は自動的に以下に出力されます:
- `assets/build/kanban_bundle.js` (Gitで管理)
- `assets/javascripts/epic_grid/dist/kanban_bundle.js` (Gitで無視)

## トラブルシューティング

### 最新の変更が反映されない場合

1. **ビルドファイルが更新されているか確認**:
   ```bash
   ls -lh assets/build/kanban_bundle.js
   ```

2. **コンテナ内のpublicファイルを確認**:
   ```bash
   docker exec redmine ls -lh /usr/src/redmine/public/plugin_assets/redmine_epic_grid/
   ```

3. **手動でコピーを再実行**:
   ```bash
   docker exec redmine cp \
     /usr/src/redmine/plugins/redmine_epic_grid/assets/build/kanban_bundle.js \
     /usr/src/redmine/public/plugin_assets/redmine_epic_grid/kanban_bundle.js
   ```

4. **ブラウザのハードリフレッシュ**: Ctrl+Shift+R (Windows/Linux) / Cmd+Shift+R (Mac)

### API 403エラーが発生する場合

`BaseApiController`で`skip_before_action :check_if_login_required`が設定されているか確認してください。
これにより、Railsの標準認証をスキップし、API専用の認証処理が動作します。
