# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# 📚 Reference E2E Test - 新規 E2E テスト作成時の参考実装
# ============================================================
#
# 【重要】現在の段階ではMSW（Mock Service Worker）起動を前提とする
# - フロントエンドはMSWモックデータで動作
# - 実データベースとの連携は今後の課題
#
# このテストは以下のパターンを提供します:
#
# 1. プロジェクト作成 (let(:project))
# 2. ユーザー作成と権限設定 (let(:user), before(:each))
# 3. MSWモックデータの表示確認
# 4. ログインフロー
# 5. ページ遷移と要素確認
#
# 新規テストを作成する場合:
# - このファイルをコピーして編集
# - プロジェクト/ユーザー設定はそのまま使用
# - アサーション部分をMSWモックデータに合わせる
#
# テスト失敗時:
# 1. まずこのテストを実行して環境確認
#    → 成功: あなたのテストコードに問題
#    → 失敗: 環境設定に問題 (rails_helper.rb, DB, Groups など)
#
# 2. スクリーンショット確認
#    → tmp/test_artifacts/screenshots/ (最新ファイル)
#
# 3. HTML確認
#    → tmp/test_artifacts/html/ (最新ファイル)
#
# 4. Rails ログ確認
#    → tail -50 log/test.log
#
# 詳細は vibes/docs/rules/backend_testing.md を参照
# ============================================================

RSpec.describe 'Kanban Simple E2E', type: :system do
  let(:project) { create(:project, identifier: 'simple-e2e-test', name: 'Simple E2E Test Project') }
  let(:user) { create(:user, login: 'e2e_user', admin: true) }

  before(:each) do
    # プロジェクト設定（モジュール有効化のみ）
    # 注: データはMSWモックから取得するため、Issue作成は不要
    project.enabled_modules.create!(name: 'epic_grid') unless project.module_enabled?('epic_grid')

    # ユーザー権限設定
    role = Role.find_or_create_by!(name: 'Manager') do |r|
      r.permissions = [
        :view_issues,
        :add_issues,
        :edit_issues,
        :manage_versions,
        :view_epic_grid,
        :manage_epic_grid
      ]
      r.assignable = true
    end
    Member.create!(user: user, project: project, roles: [role])
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
      @playwright_page.goto("/projects/#{project.identifier}/epic_grid", timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: カンバングリッド表示確認
      @playwright_page.wait_for_selector('#kanban-root', timeout: 15000)

      # React アプリケーションのマウント待機
      # Loading状態が終わるまで待つ（最大30秒）
      @playwright_page.wait_for_function(
        "() => !document.body.textContent.includes('Loading grid data')",
        timeout: 30000
      ) rescue nil

      # Step 4: MSWモックデータ表示確認
      # Epic が表示されているか（MSWモックデータ）
      epic1_element = @playwright_page.query_selector("text='施設・ユーザー管理'")
      expect(epic1_element).not_to be_nil

      epic2_element = @playwright_page.query_selector("text='開診スケジュール'")
      expect(epic2_element).not_to be_nil

      # Feature が表示されているか（MSWモックデータ）
      feature_element = @playwright_page.query_selector("text='登録画面'")
      expect(feature_element).not_to be_nil

      # User Story が表示されているか（MSWモックデータ）
      user_story_element = @playwright_page.query_selector("text='US#101 ユーザー登録フォーム'")
      expect(user_story_element).not_to be_nil

      # Step 5: グリッド構造確認
      grid_element = @playwright_page.query_selector('.epic-version-grid')
      expect(grid_element).not_to be_nil

      # FeatureCardGrid が存在するか
      feature_grid = @playwright_page.query_selector('.feature-card-grid')
      expect(feature_grid).not_to be_nil

      # UserStoryGrid が存在するか
      user_story_grid = @playwright_page.query_selector('.user-story-grid')
      expect(user_story_grid).not_to be_nil

      puts "\n✅ Simple E2E Test Passed: Kanban board displayed with test data"
    end
  end
end
