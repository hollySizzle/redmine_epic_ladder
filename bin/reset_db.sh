#!/bin/bash
# 🌸 桜商店カンバン開発環境データベース完全リセットスクリプト 🌸
#
# 実行: ./bin/reset_db.sh
#
# このスクリプトは以下を順次実行します:
# 1. db:drop - データベースを削除
# 2. db:create - データベースを再作成
# 3. db:migrate - 基本マイグレーションを実行
# 4. redmine:plugins:migrate - プラグインマイグレーションを実行
# 5. db:seed - 基本シードデータを投入
# 6. カンバンテストデータ投入 - 桜商店データを投入

set -e  # エラーが発生したら即座に終了

# 色付きメッセージ用の関数
print_header() {
    echo "🌸 =========================================="
    echo "🌸 $1"
    echo "🌸 =========================================="
}

print_step() {
    echo ""
    echo "📋 ステップ: $1"
    echo "----------------------------------------"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ エラー: $1"
}

print_warning() {
    echo "⚠️  警告: $1"
}

# Redmineのルートディレクトリに移動
REDMINE_ROOT="/usr/src/redmine"
KANBAN_PLUGIN_ROOT="/usr/src/redmine/plugins/redmine_epic_grid"

if [ ! -d "$REDMINE_ROOT" ]; then
    print_error "Redmineのルートディレクトリが見つかりません: $REDMINE_ROOT"
    exit 1
fi

cd "$REDMINE_ROOT"

print_header "桜商店カンバン開発環境データベース完全リセット開始"

# 環境確認
print_step "実行環境確認"
echo "現在のディレクトリ: $(pwd)"
echo "Railsバージョン: $(rails -v 2>/dev/null || echo '取得失敗')"
echo "実行環境: ${RAILS_ENV:-development}"

# 開発環境以外での実行を防止
if [ "${RAILS_ENV}" != "" ] && [ "${RAILS_ENV}" != "development" ]; then
    print_error "このスクリプトは開発環境(development)でのみ実行可能です"
    print_error "現在の環境: ${RAILS_ENV}"
    exit 1
fi

# # 確認プロンプト
# echo ""
# read -p "⚠️  開発環境のデータベースが完全に削除されます。続行しますか？ (y/N): " -n 1 -r
# echo ""
# if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#     print_warning "処理をキャンセルしました"
#     exit 0
# fi

# ステップ0: データベース環境を明示的に設定
print_step "0. データベース環境設定 (db:environment:set)"
if bin/rails db:environment:set RAILS_ENV=development 2>/dev/null; then
    print_success "データベース環境をdevelopmentに設定しました"
else
    print_warning "環境設定コマンドが失敗しましたが、処理を続行します"
    print_warning "（初回実行時やdb:dropが必要な場合は正常な挙動です）"
fi

# ステップ0.5: データベース接続を強制終了
print_step "0.5. データベース接続の強制終了"
echo "データベース接続中のプロセスを確認中..."

# データベース設定を読み込み
DB_NAME="redmine_dev"
DB_CONFIG="/usr/src/redmine/config/database.yml"

# PostgreSQL経由でプロセス一覧を取得
echo "PostgreSQL側から接続プロセスを確認します..."
PSQL_OUTPUT=$(RAILS_ENV=development rails runner "
  conn = ActiveRecord::Base.connection
  results = conn.execute(\"
    SELECT pid, usename, application_name, client_addr, state, query_start
    FROM pg_stat_activity
    WHERE datname = 'redmine_dev' AND pid <> pg_backend_pid()
  \")
  puts '接続プロセス一覧:'
  results.each do |row|
    puts \"  PID: #{row['pid']}, User: #{row['usename']}, App: #{row['application_name']}, State: #{row['state']}\"
  end
  puts \"Total: #{results.count}件\"
" 2>&1)

echo "$PSQL_OUTPUT"

# PostgreSQL経由でプロセスを終了
TERMINATE_OUTPUT=$(RAILS_ENV=development rails runner "
  conn = ActiveRecord::Base.connection
  results = conn.execute(\"
    SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = 'redmine_dev' AND pid <> pg_backend_pid()
  \")
  terminated_count = results.count
  puts \"#{terminated_count}個の接続を終了しました\"
" 2>&1)

echo "$TERMINATE_OUTPUT"

# プロセス終了を待つ
sleep 2

print_success "データベース接続プロセスの終了処理完了"

# ステップ1: データベース削除
print_step "1. データベース削除 (db:drop)"
if RAILS_ENV=development rake db:drop; then
    print_success "データベース削除完了"
else
    print_error "データベース削除に失敗しました"
    exit 1
fi

# ステップ2: データベース作成
print_step "2. データベース作成 (db:create)"
if RAILS_ENV=development rake db:create; then
    print_success "データベース作成完了"
else
    print_error "データベース作成に失敗しました"
    exit 1
fi

# ステップ3: マイグレーション実行
print_step "3. マイグレーション実行 (db:migrate)"
if RAILS_ENV=development rake db:migrate; then
    print_success "基本マイグレーション実行完了"
else
    print_error "基本マイグレーション実行に失敗しました"
    exit 1
fi

# ステップ3.5: プラグインマイグレーション実行
print_step "3.5. プラグインマイグレーション実行 (redmine:plugins:migrate)"
if RAILS_ENV=development rake redmine:plugins:migrate; then
    print_success "プラグインマイグレーション実行完了"
else
    print_error "プラグインマイグレーション実行に失敗しました"
    exit 1
fi

# ステップ4: 基本シードデータ投入
print_step "4. 基本シードデータ投入 (db:seed)"
if [ -f "db/seeds.rb" ]; then
    if RAILS_ENV=development rake db:seed; then
        print_success "基本シードデータ投入完了"
    else
        print_warning "基本シードデータ投入に失敗しましたが、処理を続行します"
    fi
else
    print_warning "db/seeds.rbが存在しないため、基本シードデータ投入をスキップします"
fi

# ステップ5: カンバンテストデータ投入（分割seed実行）
print_step "5. 桜商店カンバンテストデータ投入"

# 5-1: 基礎データ投入
print_step "5-1. 基礎データ投入 (01_base_data.rb)"
SEED_FILE="$KANBAN_PLUGIN_ROOT/db/seeds/01_base_data.rb"
if [ -f "$SEED_FILE" ]; then
    if RAILS_ENV=development rails runner "$SEED_FILE"; then
        print_success "[1/5] 基礎データ投入完了"
    else
        print_error "[1/5] 基礎データ投入に失敗しました"
        exit 1
    fi
else
    print_error "シードファイルが見つかりません: $SEED_FILE"
    exit 1
fi

# 5-2: プロジェクト・メンバー投入
print_step "5-2. プロジェクト・メンバー投入 (02_projects.rb)"
SEED_FILE="$KANBAN_PLUGIN_ROOT/db/seeds/02_projects.rb"
if [ -f "$SEED_FILE" ]; then
    if RAILS_ENV=development rails runner "$SEED_FILE"; then
        print_success "[2/5] プロジェクト・メンバー投入完了"
    else
        print_error "[2/5] プロジェクト・メンバー投入に失敗しました"
        exit 1
    fi
else
    print_error "シードファイルが見つかりません: $SEED_FILE"
    exit 1
fi

# 5-3: バージョン投入
print_step "5-3. バージョン投入 (03_versions.rb)"
SEED_FILE="$KANBAN_PLUGIN_ROOT/db/seeds/03_versions.rb"
if [ -f "$SEED_FILE" ]; then
    if RAILS_ENV=development rails runner "$SEED_FILE"; then
        print_success "[3/5] バージョン投入完了"
    else
        print_error "[3/5] バージョン投入に失敗しました"
        exit 1
    fi
else
    print_error "シードファイルが見つかりません: $SEED_FILE"
    exit 1
fi

# 5-4: Issue階層構造投入
print_step "5-4. Issue階層構造投入 (04_issues.rb)"
SEED_FILE="$KANBAN_PLUGIN_ROOT/db/seeds/04_issues.rb"
if [ -f "$SEED_FILE" ]; then
    if RAILS_ENV=development rails runner "$SEED_FILE"; then
        print_success "[4/5] Issue階層構造投入完了"
    else
        print_error "[4/5] Issue階層構造投入に失敗しました"
        exit 1
    fi
else
    print_error "シードファイルが見つかりません: $SEED_FILE"
    exit 1
fi

# 5-5: バージョン最終化
print_step "5-5. バージョン最終化 (05_finalize_versions.rb)"
SEED_FILE="$KANBAN_PLUGIN_ROOT/db/seeds/05_finalize_versions.rb"
if [ -f "$SEED_FILE" ]; then
    if RAILS_ENV=development rails runner "$SEED_FILE"; then
        print_success "[5/5] バージョン最終化完了"
    else
        print_error "[5/5] バージョン最終化に失敗しました"
        exit 1
    fi
else
    print_error "シードファイルが見つかりません: $SEED_FILE"
    exit 1
fi

print_success "桜商店カンバンテストデータ投入完了（全5ステップ）"

# 完了報告
print_header "🎉 データベースリセット完了！"
echo ""
echo "📊 完了したタスク:"
echo "  ✅ データベース削除・再作成"
echo "  ✅ 基本マイグレーション実行"
echo "  ✅ プラグインマイグレーション実行"
echo "  ✅ 基本シードデータ投入"
echo "  ✅ 桜商店カンバンテストデータ投入"
echo ""
echo "🌸 桜商店ECサイト開発チームのデータでカンバンをお楽しみください！"
echo ""
echo "🚀 Redmineサーバーを起動するには:"
echo "  cd $REDMINE_ROOT"
echo "  RAILS_ENV=development rails server -b 0.0.0.0 -p 3000"
echo ""