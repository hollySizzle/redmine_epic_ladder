# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# 📚 Reference E2E Test - 新規 E2E テスト作成時の参考実装
# ============================================================
#
# このテストは以下のパターンを提供します:
#
# 1. プロジェクト作成 (let(:project))
# 2. ユーザー作成と権限設定 (let(:user), before(:each))
# 3. テストデータ作成 (Epic, Feature, Version)
# 4. ログインフロー
# 5. ページ遷移と要素確認
#
# 新規テストを作成する場合:
# - このファイルをコピーして編集
# - プロジェクト/ユーザー設定はそのまま使用
# - データ作成とアサーション部分のみ変更
#
# テスト失敗時:
# 1. まずこのテストを実行して環境確認
#    → 成功: あなたのテストコードに問題
#    → 失敗: 環境設定に問題 (rails_helper.rb, DB, Groups など)
#
# 2. スクリーンショット確認
#    → tmp/test_artifacts/screenshots/ (最新ファイル)
#
# 3. Rails ログ確認
#    → tail -50 log/test.log
#
# 詳細は vibes/docs/rules/backend_testing.md を参照
# ============================================================

RSpec.describe 'Kanban Simple E2E', type: :system do
  let(:project) { create(:project, identifier: 'simple-e2e-test', name: 'Simple E2E Test Project') }
  let(:user) { create(:user, login: 'e2e_user', admin: true) }
  let(:epic_tracker) { Tracker.find_or_create_by!(name: 'Epic') { |t| t.default_status = IssueStatus.first } }
  let(:feature_tracker) { Tracker.find_or_create_by!(name: 'Feature') { |t| t.default_status = IssueStatus.first } }
  let(:version1) { create(:version, project: project, name: 'Version 1.0') }
  let(:version2) { create(:version, project: project, name: 'Version 2.0') }

  before(:each) do
    # プロジェクト設定
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
    project.enabled_modules.create!(name: 'kanban') unless project.module_enabled?('kanban')

    # ユーザー権限設定
    role = Role.find_or_create_by!(name: 'Manager') do |r|
      r.permissions = [
        :view_issues,
        :add_issues,
        :edit_issues,
        :manage_versions,
        :view_kanban,
        :manage_kanban
      ]
      r.assignable = true
    end
    Member.create!(user: user, project: project, roles: [role])

    # テストデータ作成: Epic 1個、Feature 2個
    @epic = create(:issue,
                   project: project,
                   tracker: epic_tracker,
                   subject: 'E2E Test Epic',
                   author: user)

    @feature1 = create(:issue,
                       project: project,
                       tracker: feature_tracker,
                       subject: 'E2E Feature 1',
                       parent: @epic,
                       fixed_version: version1,
                       author: user)

    @feature2 = create(:issue,
                       project: project,
                       tracker: feature_tracker,
                       subject: 'E2E Feature 2',
                       parent: @epic,
                       fixed_version: version2,
                       author: user)
  end

  describe 'Basic E2E Flow' do
    it 'should login, navigate to kanban, and display grid with test data' do
      # Step 1: ログイン
      @playwright_page.goto('/login', timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      @playwright_page.fill('input[name="username"]', user.login)
      @playwright_page.fill('input[name="password"]', 'password123')
      @playwright_page.click('input#login-submit')

      # ログイン成功確認
      @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)

      # Step 2: カンバンページに移動
      @playwright_page.goto("/projects/#{project.identifier}/kanban", timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: カンバングリッド表示確認
      @playwright_page.wait_for_selector('#kanban-root', timeout: 15000)

      # React アプリケーションのマウント待機
      @playwright_page.wait_for_selector('.epic-version-grid', timeout: 15000)

      # Step 4: データ表示確認
      # Epic が表示されているか
      epic_element = @playwright_page.query_selector("text='E2E Test Epic'")
      expect(epic_element).not_to be_nil

      # Feature が表示されているか
      feature1_element = @playwright_page.query_selector("text='E2E Feature 1'")
      expect(feature1_element).not_to be_nil

      feature2_element = @playwright_page.query_selector("text='E2E Feature 2'")
      expect(feature2_element).not_to be_nil

      # Step 5: グリッド構造確認
      grid_element = @playwright_page.query_selector('.epic-version-grid')
      expect(grid_element).not_to be_nil

      puts "\n✅ Simple E2E Test Passed: Kanban board displayed with test data"
    end
  end
end
