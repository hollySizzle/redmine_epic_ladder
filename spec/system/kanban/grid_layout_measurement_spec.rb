# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kanban Grid Layout Measurement', type: :system do
  let(:project) { create(:project, identifier: 'test-kanban', name: 'Test Kanban Project') }
  let(:user) { create(:user, login: 'testuser', password: 'password123', admin: true) }
  let(:epic_tracker) { Tracker.find_or_create_by!(name: 'Epic') { |t| t.default_status = IssueStatus.first } }
  let(:feature_tracker) { Tracker.find_or_create_by!(name: 'Feature') { |t| t.default_status = IssueStatus.first } }
  let(:version) { create(:version, project: project, name: 'v1.0') }

  before(:each) do
    # プロジェクト設定
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
    project.enabled_modules.create!(name: 'kanban') unless project.module_enabled?('kanban')

    # ユーザー権限設定
    role = Role.find_or_create_by!(name: 'Manager') do |r|
      r.permissions = [:view_issues, :add_issues, :edit_issues, :manage_versions]
      r.assignable = true
    end
    Member.create!(user: user, project: project, roles: [role])

    # テストデータ作成
    @epic = create(:issue,
                   project: project,
                   tracker: epic_tracker,
                   subject: 'epic テスト',
                   author: user)

    @feature = create(:issue,
                      project: project,
                      tracker: feature_tracker,
                      subject: 'Feature テスト',
                      parent: @epic,
                      fixed_version: version,
                      author: user)

    # Capybara サーバー設定
    Capybara.server = :puma
    Capybara.server_port = 3001
    Capybara.app_host = 'http://localhost:3001'

    # サーバー起動待機
    sleep 1
  end

  after(:each) do
    # Playwright レポートクリーンアップ
    FileUtils.rm_f('/tmp/grid-report.json')
  end

  describe 'Playwright Grid Layout Measurement' do
    it 'executes Playwright measurement and validates results' do
      # Playwright 用の認証情報を環境変数で渡す
      env_vars = {
        'PLAYWRIGHT_BASE_URL' => Capybara.app_host,
        'PLAYWRIGHT_PROJECT_ID' => project.identifier,
        'PLAYWRIGHT_USERNAME' => user.login,
        'PLAYWRIGHT_PASSWORD' => 'password123'
      }

      # Playwright 実行
      playwright_cmd = <<~CMD
        cd #{Rails.root}/plugins/redmine_release_kanban && \
        npx playwright test grid-layout-measurement \
          --reporter=json \
          --output=/tmp/grid-report.json \
          2>&1
      CMD

      result = nil
      output = nil

      Dir.chdir(Rails.root) do
        output = `#{env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')} #{playwright_cmd}`
        result = $?.success?
      end

      # 実行結果確認
      puts "\n=== Playwright Output ==="
      puts output
      puts "========================\n"

      # レポートファイル確認
      expect(File.exist?('/tmp/grid-report.json')).to be(true), "Playwright report not generated"

      # レポート解析
      report = JSON.parse(File.read('/tmp/grid-report.json'))

      # テスト結果検証
      expect(report['suites']).not_to be_empty
      expect(report['suites'].first['specs']).not_to be_empty

      # 成功したテストの数を確認
      passed_tests = report['suites'].first['specs'].count { |spec|
        spec['tests'].any? { |test| test['results'].first['status'] == 'passed' }
      }

      expect(passed_tests).to be > 0, "No Playwright tests passed"
    end

    it 'validates grid structure metrics' do
      # Playwright 実行（簡易版）
      env_vars = {
        'PLAYWRIGHT_BASE_URL' => Capybara.app_host,
        'PLAYWRIGHT_PROJECT_ID' => project.identifier,
        'PLAYWRIGHT_USERNAME' => user.login,
        'PLAYWRIGHT_PASSWORD' => 'password123'
      }

      # Grid構造整合性テストのみ実行
      playwright_cmd = <<~CMD
        cd #{Rails.root}/plugins/redmine_release_kanban && \
        npx playwright test grid-layout-measurement \
          -g "Grid 構造の整合性検証" \
          --reporter=list \
          2>&1
      CMD

      output = `#{env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')} #{playwright_cmd}`
      result = $?.success?

      puts "\n=== Grid Structure Test ==="
      puts output
      puts "===========================\n"

      # 基本的な成功判定
      expect(result).to be(true), "Grid structure test failed:\n#{output}"
    end

    it 'validates no overflow in grid cells' do
      env_vars = {
        'PLAYWRIGHT_BASE_URL' => Capybara.app_host,
        'PLAYWRIGHT_PROJECT_ID' => project.identifier,
        'PLAYWRIGHT_USERNAME' => user.login,
        'PLAYWRIGHT_PASSWORD' => 'password123'
      }

      # オーバーフローテストのみ実行
      playwright_cmd = <<~CMD
        cd #{Rails.root}/plugins/redmine_release_kanban && \
        npx playwright test grid-layout-measurement \
          -g "オーバーフロー検出" \
          --reporter=list \
          2>&1
      CMD

      output = `#{env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')} #{playwright_cmd}`
      result = $?.success?

      puts "\n=== Overflow Test ==="
      puts output
      puts "=====================\n"

      expect(result).to be(true), "Overflow test failed:\n#{output}"
    end

    it 'validates cell positioning accuracy' do
      env_vars = {
        'PLAYWRIGHT_BASE_URL' => Capybara.app_host,
        'PLAYWRIGHT_PROJECT_ID' => project.identifier,
        'PLAYWRIGHT_USERNAME' => user.login,
        'PLAYWRIGHT_PASSWORD' => 'password123'
      }

      # セル配置テストのみ実行
      playwright_cmd = <<~CMD
        cd #{Rails.root}/plugins/redmine_release_kanban && \
        npx playwright test grid-layout-measurement \
          -g "セル配置の正確性検証" \
          --reporter=list \
          2>&1
      CMD

      output = `#{env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')} #{playwright_cmd}`
      result = $?.success?

      puts "\n=== Cell Positioning Test ==="
      puts output
      puts "=============================\n"

      expect(result).to be(true), "Cell positioning test failed:\n#{output}"
    end
  end

  describe 'RSpec-only Grid Measurements (without Playwright)' do
    before(:each) do
      # 実際のブラウザアクセス（Capybara使用）
      driven_by(:selenium_headless)
      login_as(user)
      visit project_kanban_path(project)
    end

    it 'validates basic page load' do
      expect(page).to have_css('.kanban-grid-body')
      expect(page).to have_content('epic テスト')
    end

    it 'checks grid has correct CSS variables' do
      grid = page.find('.kanban-grid-body')
      columns = grid.style('--grid-columns')
      rows = grid.style('--grid-rows')

      expect(columns).not_to be_nil
      expect(rows).not_to be_nil
      expect(columns.to_i).to be > 0
      expect(rows.to_i).to be > 0
    end
  end

  private

  def login_as(user)
    visit '/login'
    fill_in 'username', with: user.login
    fill_in 'password', with: 'password123'
    click_button 'Login'
  end
end