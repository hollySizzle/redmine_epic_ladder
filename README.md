# Redmine Epic Grid Plugin

Epic→Feature→UserStory→Task/Test階層制約とVersion管理を統合したEpic Gridシステム

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
