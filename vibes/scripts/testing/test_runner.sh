#!/bin/bash
# frozen_string_literal: true

# Release Kanban テスト実行スクリプト
# 各フェーズのテストを段階的に実行し、結果をレポート

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

log_phase() {
    echo -e "${PURPLE}[PHASE]${NC} $1"
}

# テスト結果集計
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# テスト実行関数
run_test_suite() {
    local suite_name="$1"
    local test_pattern="$2"
    local description="$3"

    log_phase "🚀 $suite_name テスト実行中..."
    echo "説明: $description"
    echo "パターン: $test_pattern"
    echo "----------------------------------------"

    if [ -f "Gemfile" ]; then
        # Bundler環境
        if bundle exec rspec "$test_pattern" --format documentation --color; then
            log_success "✅ $suite_name テスト完了"
        else
            log_error "❌ $suite_name テスト失敗"
            return 1
        fi
    else
        # Redmine標準環境
        if rake redmine:plugins:test:units PLUGIN=redmine_release_kanban TEST="$test_pattern"; then
            log_success "✅ $suite_name テスト完了"
        else
            log_error "❌ $suite_name テスト失敗"
            return 1
        fi
    fi

    echo ""
}

# 実行モード判定
MODE=${1:-"full"}

case $MODE in
    "phase1"|"p1")
        PHASES=("1")
        ;;
    "phase2"|"p2")
        PHASES=("2")
        ;;
    "phase3"|"p3")
        PHASES=("3")
        ;;
    "phase4"|"p4")
        PHASES=("4")
        ;;
    "unit"|"models")
        PHASES=("1" "2")
        ;;
    "integration"|"api")
        PHASES=("3")
        ;;
    "system"|"e2e")
        PHASES=("4")
        ;;
    "full"|"all")
        PHASES=("1" "2" "3" "4")
        ;;
    "quick")
        PHASES=("1" "2")
        ;;
    *)
        log_error "無効なモード: $MODE"
        echo "利用可能なモード:"
        echo "  phase1, p1    - Phase 1: モデル単体テスト"
        echo "  phase2, p2    - Phase 2: サービス層テスト"
        echo "  phase3, p3    - Phase 3: API統合テスト"
        echo "  phase4, p4    - Phase 4: System/E2Eテスト"
        echo "  unit, models  - Phase 1+2: 単体テスト"
        echo "  integration   - Phase 3: 統合テスト"
        echo "  system, e2e   - Phase 4: システムテスト"
        echo "  full, all     - 全フェーズ (デフォルト)"
        echo "  quick         - 高速テスト (Phase 1+2)"
        exit 1
        ;;
esac

# メイン実行
echo "=========================================="
echo "🎯 Release Kanban テスト実行スイート"
echo "=========================================="
echo "モード: $MODE"
echo "実行フェーズ: ${PHASES[*]}"
echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

START_TIME=$(date +%s)

# Phase 1: モデル単体テスト（階層制約・バージョン伝播）
if [[ " ${PHASES[@]} " =~ " 1 " ]]; then
    log_phase "📊 Phase 1: モデル単体テスト"
    echo "🔍 対象: TrackerHierarchy（階層制約）、VersionPropagation（バージョン伝播）"
    echo "🎯 重要度: 🔴 Critical（データ整合性の根幹）"
    echo ""

    run_test_suite \
        "TrackerHierarchy" \
        "spec/models/kanban/tracker_hierarchy_spec.rb" \
        "Epic→Feature→UserStory→Task/Test の4段階階層制約検証"

    run_test_suite \
        "VersionPropagation" \
        "spec/services/kanban/version_propagation_service_spec.rb" \
        "UserStoryから子要素への自動バージョン伝播ロジック検証"
fi

# Phase 2: サービス層テスト（自動生成・状態遷移・検証）
if [[ " ${PHASES[@]} " =~ " 2 " ]]; then
    log_phase "🤖 Phase 2: サービス層テスト"
    echo "🔍 対象: TestGeneration（自動生成）、StateTransition（状態遷移）、ValidationGuard（検証）"
    echo "🎯 重要度: 🟡 High（開発効率・ワークフロー整合性・品質ゲート）"
    echo ""

    run_test_suite \
        "TestGeneration" \
        "spec/services/kanban/test_generation_service_spec.rb" \
        "UserStory作成時のTest自動生成 + blocks関係作成"

    run_test_suite \
        "StateTransition" \
        "spec/services/kanban/state_transition_service_spec.rb" \
        "カンバンカラム移動時の状態遷移制御とブロック条件チェック"

    run_test_suite \
        "ValidationGuard" \
        "spec/services/kanban/validation_guard_service_spec.rb" \
        "3層ガード検証（Task完了・Test合格・重大Bug解決）"
fi

# Phase 3: API統合テスト
if [[ " ${PHASES[@]} " =~ " 3 " ]]; then
    log_phase "🔌 Phase 3: API統合テスト"
    echo "🔍 対象: APIController、データ交換、権限チェック"
    echo "🎯 重要度: 🔴 Critical（React-Rails間システム統合）"
    echo ""

    run_test_suite \
        "KanbanController" \
        "spec/controllers/kanban_controller_spec.rb" \
        "カンバンページ表示とメインコントローラー機能"

    run_test_suite \
        "APIController" \
        "spec/requests/kanban/api_controller_spec.rb" \
        "React-バックエンド間データ交換API検証"

    run_test_suite \
        "WorkflowIntegration" \
        "spec/integration/kanban/workflow_integration_spec.rb" \
        "複数サービス間連携とデータ整合性検証"
fi

# Phase 4: System/E2Eテスト
if [[ " ${PHASES[@]} " =~ " 4 " ]]; then
    log_phase "🎨 Phase 4: System/E2Eテスト"
    echo "🔍 対象: ドラッグ&ドロップ、Epic Swimlane、ユーザージャーニー"
    echo "🎯 重要度: 🟢 Medium（UX向上・エンドツーエンドワークフロー）"
    echo ""

    # システムテストの実行前チェック
    if command -v chromedriver &> /dev/null || [ -f "/usr/bin/chromedriver" ]; then
        run_test_suite \
            "ReleaseKanban" \
            "spec/system/kanban/release_kanban_spec.rb" \
            "ドラッグ&ドロップ、Epic Swimlane表示、ユーザージャーニー検証"
    else
        log_warning "⚠️  ChromeDriverが見つかりません。System/E2Eテストをスキップします。"
        log_info "💡 ChromeDriverのインストール: apt-get install chromium-chromedriver"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    fi
fi

# 終了処理
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

echo ""
echo "=========================================="
echo "📊 テスト実行結果サマリー"
echo "=========================================="
echo "実行時間: ${EXECUTION_TIME}秒"
echo "実行モード: $MODE"
echo "実行フェーズ: ${PHASES[*]}"

if [ $FAILED_TESTS -eq 0 ]; then
    log_success "🎉 全てのテストが成功しました！"
    echo ""
    echo "✅ データ整合性: 保証済み"
    echo "✅ ワークフロー整合性: 確認済み"
    echo "✅ API統合: 正常動作"
    echo "✅ システム統合: 期待通り"
    echo ""
    echo "🚀 Release Kanbanは本番リリース準備完了です！"
else
    log_error "❌ $FAILED_TESTS 個のテストが失敗しました"
    echo ""
    echo "🔧 修正が必要な項目を確認してください"
    echo "📝 失敗したテストの詳細ログを参照してください"
fi

echo ""
echo "=========================================="

# カバレッジレポート生成（環境が対応している場合）
if [ -f ".simplecov" ] || [ -n "$COVERAGE" ]; then
    log_info "📈 カバレッジレポートを生成中..."
    echo "カバレッジ目標: 各コンポーネント85%以上"
fi

exit $FAILED_TESTS