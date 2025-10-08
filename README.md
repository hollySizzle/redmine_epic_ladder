# Redmine Epic Grid Plugin

Epic→Feature→UserStory→Task/Test階層制約とVersion管理を統合したEpic Gridシステム

## デプロイ手順

### 前提条件
- Docker環境でRedmineが稼働していること
- プラグインディレクトリが`./app/plugins`としてマウントされていること
- ビルド済みファイル(`assets/build/kanban_bundle.js`)がGitリポジトリに含まれていること

### 本番環境へのデプロイ

```bash
# 1. プラグインディレクトリに移動
cd /app/IntranetApps/containers/202501_redmine/app/plugins/redmine_epic_grid

# 2. 最新コードを取得
git pull

# 3. ビルド済みファイルをpublicディレクトリにコピー
docker exec redmine cp \
  /usr/src/redmine/plugins/redmine_epic_grid/assets/build/kanban_bundle.js \
  /usr/src/redmine/public/plugin_assets/redmine_epic_grid/kanban_bundle.js

# 4. Redmineコンテナを再起動
docker compose restart redmine
```

### 重要な注意事項

- **`rake assets:precompile`は不要**: ビルド済みファイルがGitに含まれているため、プリコンパイルは必要ありません
- **コンテナ内でのnpmビルドは不可**: 本番コンテナにNode.js/npmがインストールされていないため、ビルドは開発環境で実行してください
- **ブラウザキャッシュのクリア**: デプロイ後はスーパーリロード(Ctrl+Shift+R / Cmd+Shift+R)を推奨

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
