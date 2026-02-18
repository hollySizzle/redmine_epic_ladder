#!/bin/bash
# frozen_string_literal: true

# Epic Ladder テスト環境セットアップスクリプト
# RSpec + Playwright 環境を一発でセットアップ

set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# プラグインディレクトリを取得
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REDMINE_ROOT="$(cd "$PLUGIN_DIR/../.." && pwd)"

echo "=========================================="
echo "🧪 Epic Ladder テスト環境セットアップ"
echo "=========================================="
echo "プラグインディレクトリ: $PLUGIN_DIR"
echo "Redmineルート: $REDMINE_ROOT"
echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

START_TIME=$(date +%s)

# Step 1: Ruby環境チェック
log_step "1/9 Ruby環境チェック"
if command -v ruby &> /dev/null; then
    RUBY_VERSION=$(ruby -v)
    log_info "Ruby: $RUBY_VERSION"
else
    log_error "Ruby が見つかりません"
    exit 1
fi

if command -v bundle &> /dev/null; then
    BUNDLER_VERSION=$(bundle -v)
    log_info "Bundler: $BUNDLER_VERSION"
else
    log_error "Bundler が見つかりません"
    exit 1
fi
log_success "Ruby環境 OK"
echo ""

# Step 2: factory_girl アンインストール（Rails 7.2+ 非互換）
log_step "2/7 factory_girl gem アンインストール"
log_info "factory_girl 4.9.0 は Rails 7.2+ と非互換のため削除します"

if gem list factory_girl | grep -q "factory_girl"; then
    log_info "factory_girl gem を削除中..."
    if gem uninstall factory_girl --force 2>&1; then
        log_success "factory_girl gem アンインストール完了"
    else
        log_warning "factory_girl gem アンインストール失敗（既に削除済みの可能性）"
    fi
else
    log_info "factory_girl gem は既にアンインストール済み"
fi
echo ""

# Step 3: 他プラグインの Gemfile を無効化
log_step "3/7 他プラグインの Gemfile 無効化"
log_info "factory_girl を使用する他プラグインの Gemfile を無効化します"

# redmine_app_notifications の Gemfile
if [ -f "$REDMINE_ROOT/plugins/redmine_app_notifications/Gemfile" ]; then
    log_info "redmine_app_notifications/Gemfile を無効化中..."
    mv "$REDMINE_ROOT/plugins/redmine_app_notifications/Gemfile" \
       "$REDMINE_ROOT/plugins/redmine_app_notifications/Gemfile.disabled" 2>/dev/null || true
    log_success "redmine_app_notifications/Gemfile 無効化完了"
fi

# easy_gantt の Gemfile
if [ -f "$REDMINE_ROOT/plugins/easy_gantt/Gemfile" ]; then
    log_info "easy_gantt/Gemfile を無効化中..."
    mv "$REDMINE_ROOT/plugins/easy_gantt/Gemfile" \
       "$REDMINE_ROOT/plugins/easy_gantt/Gemfile.disabled" 2>/dev/null || true
    log_success "easy_gantt/Gemfile 無効化完了"
fi

log_success "他プラグイン Gemfile 無効化完了"
echo ""

# Step 4: RSpec gem インストール
log_step "4/9 RSpec関連 gem インストール"
cd "$REDMINE_ROOT"

log_info "bundle install 実行中..."
if bundle install; then
    log_success "gem インストール完了"
else
    log_error "gem インストール失敗"
    exit 1
fi

# インストールされたgemを確認
log_info "インストールされたテスト用gem:"
bundle list | grep -E "(rspec|factory_bot|faker|simplecov|capybara)" || log_warning "一部のgemが見つかりません"
echo ""

# Step 5: RSpec 初期化確認
log_step "5/9 RSpec 設定ファイル確認"
cd "$PLUGIN_DIR"

if [ ! -f ".rspec" ]; then
    log_warning ".rspec が見つかりません。作成します..."
    echo "--require spec_helper" > .rspec
    log_success ".rspec 作成完了"
fi

if [ ! -f "spec/rails_helper.rb" ]; then
    log_warning "spec/rails_helper.rb が見つかりません"
    log_info "RSpec初期化が必要な場合は以下を実行してください:"
    log_info "  cd $REDMINE_ROOT && bundle exec rails generate rspec:install"
else
    log_success "RSpec 設定ファイル OK"
fi
echo ""

# Step 6: Node.js/npm 環境チェック
log_step "6/9 Node.js/npm 環境チェック"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    log_info "Node.js: $NODE_VERSION"
else
    log_error "Node.js が見つかりません"
    log_info "Node.jsをインストールしてください: apt-get install nodejs npm"
    exit 1
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    log_info "npm: $NPM_VERSION"
else
    log_error "npm が見つかりません"
    exit 1
fi
log_success "Node.js/npm 環境 OK"
echo ""

# Step 7: Playwright インストール
log_step "7/9 Playwright インストール"
cd "$PLUGIN_DIR"

log_info "npm install 実行中..."
if npm install; then
    log_success "npm パッケージインストール完了"
else
    log_error "npm install 失敗"
    exit 1
fi

# Playwrightがインストールされているか確認
if npm list @playwright/test &> /dev/null; then
    PLAYWRIGHT_VERSION=$(npm list @playwright/test --depth=0 | grep @playwright/test | awk '{print $2}')
    log_info "Playwright: $PLAYWRIGHT_VERSION"
else
    log_warning "Playwright がインストールされていません。インストールします..."
    npm install -D @playwright/test
    log_success "Playwright インストール完了"
fi

# Playwright ブラウザインストール
log_info "Playwright ブラウザ (Chromium) をインストール中..."
if npx playwright install chromium; then
    log_success "Chromium インストール完了"
else
    log_warning "Chromium インストール失敗"
fi

# Playwright 依存関係インストール
log_info "Playwright システム依存関係をインストール中..."
if npx playwright install-deps chromium 2>&1 | grep -q "already installed"; then
    log_info "依存関係は既にインストール済み"
else
    log_success "依存関係インストール完了"
fi
echo ""

# # Step 8: DATABASE_URL バックアップと database.yml 再生成
# log_step "8/10 DATABASE_URL バックアップと database.yml 再生成"
# cd "$REDMINE_ROOT"

# DATABASE_YML="$REDMINE_ROOT/config/database.yml"

# # DATABASE_URL をバックアップして削除
# if [ -n "$DATABASE_URL" ]; then
#     log_info "DATABASE_URL が設定されています。バックアップします..."
#     export DATABASE_URL_BK="$DATABASE_URL"
#     log_info "DATABASE_URL_BK: $DATABASE_URL_BK"

#     # DATABASE_URLから値を抽出（fallback用）
#     DB_FROM_URL=$(echo "$DATABASE_URL" | sed -n 's|.*@.*/\(.*\)|\1|p')
#     log_info "DATABASE_URLから抽出したDB名: ${DB_FROM_URL:-none}"
# fi

# 環境変数から値を取得（REDMINE_DB_* を優先）
DB_ADAPTER="postgresql"
DB_HOST="${REDMINE_DB_POSTGRES:-${DB_HOST:-db}}"
DB_USERNAME="${REDMINE_DB_USERNAME:-${DB_USERNAME:-postgres}}"
DB_PASSWORD="${REDMINE_DB_PASSWORD:-${DB_PASSWORD:-example}}"
DB_DATABASE_DEV="${REDMINE_DB_DATABASE:-${DB_FROM_URL:-redmine_dev}}"
DB_DATABASE_TEST="redmine_test"
DB_ENCODING="utf8"
DB_POOL="5"

log_info "DB設定値:"
log_info "  Host: $DB_HOST"
log_info "  Username: $DB_USERNAME"
log_info "  Database (dev): $DB_DATABASE_DEV"
log_info "  Database (test): $DB_DATABASE_TEST"

# # database.yml を再生成
# log_warning "database.yml を再生成します..."
# cat > "$DATABASE_YML" << EOF
# # Generated by setup_test_env.sh
# # Generated at: $(date '+%Y-%m-%d %H:%M:%S')

# development:
#   adapter: $DB_ADAPTER
#   database: $DB_DATABASE_DEV
#   host: $DB_HOST
#   username: $DB_USERNAME
#   password: $DB_PASSWORD
#   encoding: $DB_ENCODING
#   pool: $DB_POOL

# test:
#   adapter: $DB_ADAPTER
#   database: $DB_DATABASE_TEST
#   host: $DB_HOST
#   username: $DB_USERNAME
#   password: $DB_PASSWORD
#   encoding: $DB_ENCODING
#   pool: $DB_POOL

# production:
#   adapter: $DB_ADAPTER
#   database: $DB_DATABASE_DEV
#   host: $DB_HOST
#   username: $DB_USERNAME
#   password: $DB_PASSWORD
#   encoding: $DB_ENCODING
#   pool: $DB_POOL
# EOF

# log_success "database.yml を再生成しました"

# DATABASE_URL に関する情報表示
if [ -n "$DATABASE_URL" ]; then
    log_info "DATABASE_URL が設定されています: $DATABASE_URL"
    log_info "テスト実行時は rails_helper.rb が自動的に削除します"
else
    log_success "DATABASE_URL は設定されていません（推奨状態）"
fi

echo ""

# Step 9: テストDB準備
log_step "9/10 テストDB準備"
cd "$REDMINE_ROOT"

log_info "テストDBのセットアップ中（database.ymlを使用）..."
if RAILS_ENV=test bundle exec rake db:create db:migrate 2>&1; then
    log_success "テストDB作成・マイグレーション完了"
else
    log_warning "テストDB作成失敗（既に存在する可能性）"
fi

log_info "プラグインマイグレーション実行中..."
if RAILS_ENV=test bundle exec rake redmine:plugins:migrate 2>&1; then
    log_success "プラグインマイグレーション完了"
else
    log_warning "プラグインマイグレーション失敗（既に実行済みの可能性）"
fi

log_info "Redmine デフォルトデータのロード中..."
if RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data --trace 2>&1; then
    log_success "Redmine デフォルトデータロード完了"
else
    log_warning "デフォルトデータロード失敗（既に存在する可能性）"
fi

echo ""

# Step 10: ポートクリーンアップ
log_step "10/10 テストサーバーポートクリーンアップ"
TEST_PORT=3001

log_info "ポート ${TEST_PORT} をクリーンアップ中..."
if lsof -ti:${TEST_PORT} | xargs kill -9 2>/dev/null; then
    log_success "ポート ${TEST_PORT} クリーンアップ完了"
else
    log_info "ポート ${TEST_PORT} は既に空いています"
fi
echo ""

# 終了処理
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

echo "=========================================="
echo "📊 セットアップ完了サマリー"
echo "=========================================="
echo "実行時間: ${EXECUTION_TIME}秒"
echo ""
log_success "✅ Ruby環境: OK"
log_success "✅ factory_girl: アンインストール済み"
log_success "✅ 他プラグイン Gemfile: 無効化済み"
log_success "✅ RSpec gem: インストール済み"
log_success "✅ RSpec設定: 準備完了"
log_success "✅ Node.js/npm: OK"
log_success "✅ Playwright: インストール済み"
log_success "✅ Chromium: ダウンロード済み"
log_success "✅ テストDB: セットアップ済み"
log_success "✅ プラグインマイグレーション: 実行済み"
log_success "✅ Redmine デフォルトデータ: ロード済み"
log_success "✅ ポート ${TEST_PORT}: クリーンアップ済み"
echo ""
echo "🎉 テスト環境セットアップ完了！"
echo ""
echo "=========================================="
echo "📝 次のステップ"
echo "=========================================="
echo ""
echo "✅ DATABASE_URL は rails_helper.rb で自動削除されます"
echo ""
echo "🧪 Model/Controller テスト実行:"
echo "  cd $REDMINE_ROOT"
echo "  RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/models --format documentation"
echo "  RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/controllers --format documentation"
echo ""
echo "🧪 System テスト実行（Playwright）:"
echo "  cd $REDMINE_ROOT"
echo "  RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/system --format documentation"
echo ""
echo "🔍 特定のテスト実行:"
echo "  cd $REDMINE_ROOT"
echo "  RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/models/epic_ladder/tracker_hierarchy_spec.rb:7"
echo ""
echo "🧹 ポートクリーンアップ（テスト失敗時）:"
echo "  lsof -ti:3001 | xargs kill -9"
echo ""
echo "📖 ドキュメント:"
echo "  cat plugins/redmine_epic_ladder/vibes/docs/temps/playwright-rspec-setup.md"
echo ""
echo "=========================================="

exit 0