# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# 📚 Reference E2E Test - 新規 E2E テスト作成時の参考実装
# ============================================================
#
# このテストは以下のパターンを提供します:
#
# 1. プロジェクトとトラッカーのセットアップ (setup_epic_ladder_project)
# 2. ユーザー作成 (setup_admin_user)
# 3. テストデータ作成 (FactoryBot)
# 4. ログインフロー (login_as)
# 5. カンバンページ遷移 (goto_kanban)
# 6. 要素確認 (expect_text_visible, verify_kanban_structure)
#
# 新規テストを作成する場合:
# - このファイルをコピーして編集
# - ヘルパーメソッドを活用してコードを簡潔に
# - アサーション部分を実装したい機能に合わせる
#
# テスト失敗時:
# 1. スクリーンショット確認 → tmp/test_artifacts/screenshots/
# 2. HTML確認 → tmp/test_artifacts/html/
# 3. Rails ログ確認 → tail -50 log/test.log
#
# 詳細は vibes/docs/rules/backend_testing.md を参照
# ============================================================

RSpec.describe 'Kanban Simple E2E', type: :system, js: true do
  # ヘルパーを使ったセットアップ
  let!(:project) { setup_epic_ladder_project(identifier: 'simple-e2e-test', name: 'Simple E2E Test Project') }
  let!(:user) { setup_admin_user(login: 'e2e_user') }

  before(:each) do
    # プロジェクトに既に紐づいているトラッカーを取得
    epic_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:epic] }
    feature_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:feature] }
    user_story_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:user_story] }

    # バージョン作成
    @version1 = create(:version, project: project, name: 'v1.0.0')

    # テストデータ作成（トラッカーを明示的に渡してFactoryBotの重複作成を回避）
    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic 1')
    @epic2 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic 2')
    @feature1 = create(:issue, project: project, tracker: feature_tracker, parent: @epic1, fixed_version: @version1, subject: 'Test Feature 1')
    @user_story1 = create(:issue, project: project, tracker: user_story_tracker, parent: @feature1, subject: 'Test User Story 1')
  end

  describe 'Basic E2E Flow' do
    it 'should login, navigate to kanban, and display grid with test data' do
      # Step 1: ログイン（ヘルパー使用）
      login_as(user)

      # Step 2: カンバンページに移動（ヘルパー使用）
      goto_kanban(project)

      # Step 3: 実バックエンドデータ表示確認（ヘルパー使用）
      expect_text_visible('Test Epic 1')
      expect_text_visible('Test Epic 2')
      expect_text_visible('v1.0.0')
      expect_text_visible('Test Feature 1')
      expect_text_visible('Test User Story 1')

      # Step 4: グリッド構造確認（ヘルパー使用）
      verify_kanban_structure

      puts "\n✅ Simple E2E Test Passed: Kanban board displayed with test data"
    end
  end
end
