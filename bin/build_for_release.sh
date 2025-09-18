#!/bin/bash

# Redmine React Gantt Chart プラグイン配布用ビルドスクリプト

set -e  # エラー時に停止

echo "=== Redmine React Gantt Chart 配布用ビルド開始 ==="

# 作業ディレクトリの確認
if [ ! -f "package.json" ]; then
  echo "エラー: package.json が見つかりません。プラグインのルートディレクトリで実行してください。"
  exit 1
fi

# 1. 依存関係の確認とインストール
echo "1. 依存関係の確認中..."
if [ ! -d "node_modules" ]; then
  echo "   Node.js依存関係をインストール中..."
  npm install
else
  echo "   依存関係OK"
fi

# 2. 本番ビルドの実行
echo "2. 本番ビルドの実行中..."
npm run build-production

if [ ! -f "assets/javascripts/react_gantt_chart/dist/bundle.js" ]; then
  echo "エラー: ビルドが失敗しました。bundle.js が生成されませんでした。"
  exit 1
fi

# 3. assets/buildディレクトリの準備
echo "3. 配布用ディレクトリの準備中..."
mkdir -p assets/build

# 4. ビルド成果物のコピー
echo "4. ビルド成果物のコピー中..."
cp assets/javascripts/react_gantt_chart/dist/bundle.js assets/build/

# ファイルサイズの確認
BUNDLE_SIZE=$(du -h assets/build/bundle.js | cut -f1)
echo "   bundle.js サイズ: $BUNDLE_SIZE"

# 5. 配布用パッケージの作成（オプション）
if [ "$1" = "--package" ]; then
  echo "5. 配布パッケージの作成中..."
  
  # 一時ディレクトリを作成
  TEMP_DIR=$(mktemp -d)
  PLUGIN_NAME="redmine_react_gantt_chart"
  
  # 必要なファイルをコピー
  cp -r . "$TEMP_DIR/$PLUGIN_NAME"
  
  # 不要なファイルを削除
  cd "$TEMP_DIR/$PLUGIN_NAME"
  rm -rf node_modules/
  rm -rf .git/
  rm -rf .gitignore
  rm -rf assets/javascripts/react_gantt_chart/dist/
  rm -rf assets/javascripts/react_gantt_chart/__tests__/
  rm -rf vibes/
  rm -rf _dev/
  
  # アーカイブを作成
  cd "$TEMP_DIR"
  tar czf "${PLUGIN_NAME}_release.tar.gz" "$PLUGIN_NAME"
  
  # 元のディレクトリに移動
  mv "${PLUGIN_NAME}_release.tar.gz" "$OLDPWD/"
  
  # 一時ディレクトリを削除
  rm -rf "$TEMP_DIR"
  
  echo "   配布パッケージ作成完了: ${PLUGIN_NAME}_release.tar.gz"
fi

echo "=== ビルド完了 ==="
echo "配布用アセット: assets/build/bundle.js ($BUNDLE_SIZE)"
echo ""
echo "インストール手順:"
echo "1. Redmineの plugins/ ディレクトリにこのプラグインを配置"
echo "2. bundle exec rails db:migrate RAILS_ENV=production"
echo "3. Redmineを再起動"
echo ""
echo "注意: ユーザーはNode.js環境なしで即座に利用可能です。"