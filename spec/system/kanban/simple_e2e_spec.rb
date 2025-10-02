# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

RSpec.describe 'Kanban Simple E2E', type: :system do
  let(:project) { create(:project, identifier: 'simple-e2e-test', name: 'Simple E2E Test Project') }
  let(:user) { create(:user, login: 'e2e_user', password: 'testpass123', password_confirmation: 'testpass123', admin: true) }
  let(:epic_tracker) { Tracker.find_or_create_by!(name: 'Epic') { |t| t.default_status = IssueStatus.first } }
  let(:feature_tracker) { Tracker.find_or_create_by!(name: 'Feature') { |t| t.default_status = IssueStatus.first } }
  let(:version1) { create(:version, project: project, name: 'Version 1.0') }
  let(:version2) { create(:version, project: project, name: 'Version 2.0') }

  before(:each) do
    # プロジェクト設定
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
    project.enabled_modules.create!(name: 'release_kanban') unless project.module_enabled?('release_kanban')

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
      @playwright_page.fill('input[name="password"]', 'testpass123')
      @playwright_page.click('input#login-submit')

      # ログイン成功確認
      @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)

      # Step 2: カンバンページに移動
      @playwright_page.goto("/projects/#{project.identifier}/kanban", timeout: 30000)
      @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

      # Step 3: カンバングリッド表示確認
      @playwright_page.wait_for_selector('#kanban-root', timeout: 15000)

      # ページ内容を確認
      page_content = @playwright_page.content
      puts "\n=== Page HTML (first 1000 chars) ==="
      puts page_content[0..1000]

      # React アプリケーションのマウント待機
      # エラーメッセージがあるか確認
      error_element = @playwright_page.query_selector('.error, .flash.error')
      if error_element
        error_text = @playwright_page.evaluate("el => el.textContent", arg: error_element)
        puts "\n⚠️ Error found on page: #{error_text}"
      end

      @playwright_page.wait_for_selector('.kanban-grid-body', timeout: 15000)

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
      grid_element = @playwright_page.query_selector('.kanban-grid-body')
      expect(grid_element).not_to be_nil

      puts "\n✅ Simple E2E Test Passed: Kanban board displayed with test data"
    end
  end
end
