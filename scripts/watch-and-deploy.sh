#!/bin/bash
# webpackのwatch結果を自動でplugin_assetsにデプロイ

TARGET_DIR="/usr/src/redmine/public/plugin_assets/redmine_epic_grid"
SOURCE_DIR="assets/build"

echo "👀 Watching $SOURCE_DIR for changes..."
echo "📦 Will copy to $TARGET_DIR"

# 初回コピー
cp $SOURCE_DIR/*.js $SOURCE_DIR/*.json $TARGET_DIR/ 2>/dev/null || true
echo "✅ Initial deployment completed"

# ファイル変更を監視
LAST_MTIME=0

while true; do
  # kanban_bundle.jsのmtimeを取得
  if [ -f "$SOURCE_DIR/kanban_bundle.js" ]; then
    CURRENT_MTIME=$(stat -c %Y "$SOURCE_DIR/kanban_bundle.js" 2>/dev/null || stat -f %m "$SOURCE_DIR/kanban_bundle.js" 2>/dev/null)

    if [ "$CURRENT_MTIME" != "$LAST_MTIME" ]; then
      LAST_MTIME=$CURRENT_MTIME

      # すべてのJS/JSONファイルをコピー
      cp $SOURCE_DIR/*.js $SOURCE_DIR/*.json $TARGET_DIR/ 2>/dev/null || true
      echo "🔄 [$(date +%H:%M:%S)] Deployed updates to plugin_assets"
    fi
  fi

  sleep 1
done
