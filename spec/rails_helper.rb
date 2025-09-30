# frozen_string_literal: true

# factory_girl を無効化（他プラグインのテストは実行しないため）
ENV['DISABLE_FACTORY_GIRL'] = '1'

# FactoryBot を先に読み込む（Redmine rails_helper より前）
require 'factory_bot_rails'

# factory_girl の ActiveSupport::Deprecation.warn をパッチ（Rails 7.2+ では private method）
module ActiveSupport
  class Deprecation
    class << self
      def warn(message = nil, callstack = nil)
        return if @silenced
        # 警告をログに出力（エラーにしない）
        Rails.logger.warn("[DEPRECATION] #{message}") if Rails.logger && message
      end
    end
  end
end

# SimpleCov設定（カバレッジ測定）
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter '/test/'
    add_group 'Controllers', 'app/controllers'
    add_group 'Services', 'app/services'
    add_group 'JavaScript', 'assets/javascripts'
  end
end

# Redmineのrails_helperまたは標準のrails_helper設定
begin
  require File.expand_path('../../../spec/rails_helper', __dir__)
rescue LoadError
  # Redmineのrails_helperがない場合の基本設定
  require 'rails/test_help'
  require 'rspec/rails'
end

# FactoryBot ファクトリー読み込み（Redmine rails_helper の後）
FactoryBot.definition_file_paths = [
  File.expand_path('factories', __dir__)
]
FactoryBot.reload

# プラグイン固有の設定
RSpec.configure do |config|
  # FactoryBot サポート（明示的にinclude）
  config.include FactoryBot::Syntax::Methods

  # プラグインのフィクスチャパスを追加
  config.fixture_paths ||= []
  config.fixture_paths << File.expand_path('fixtures', __dir__)

  # メール送信を無効化（テスト高速化・i18nエラー回避）
  config.before(:suite) do
    ActionMailer::Base.perform_deliveries = false
    ActionMailer::Base.raise_delivery_errors = false
  end

  config.before(:each) do
    ActionMailer::Base.perform_deliveries = false
    ActionMailer::Base.raise_delivery_errors = false
    # Redmine設定でもメール通知を無効化
    Setting.notified_events = []
  end

  # Redmine default data をテスト前にロード
  config.before(:suite) do
    # Group が存在しない場合のみ default data をロード
    if defined?(Group) && Group.count == 0
      puts "\n[INFO] Loading Redmine default data..."
      # 言語を環境変数で指定（対話式入力を回避）
      ENV['REDMINE_LANG'] = 'en'
      # Rake task を直接実行
      require 'rake'
      Rails.application.load_tasks
      Rake::Task['redmine:load_default_data'].invoke
      puts "[INFO] Default data loaded successfully\n"
    end
  end

  # トランザクショナルテスト（default data を保護）
  config.use_transactional_fixtures = true
  
  # パフォーマンステスト用の設定
  config.before(:each, :performance) do
    # ログレベルを下げてパフォーマンスを向上
    Rails.logger.level = Logger::ERROR if Rails.logger
  end
  
  config.after(:each, :performance) do
    # ログレベルを元に戻す
    Rails.logger.level = Logger::DEBUG if Rails.logger
  end
  
  # テスト用のユーザーとプロジェクトを準備
  config.before(:each) do
    # テスト用プロジェクトの準備
    @test_project ||= begin
      project = Project.find_or_create_by(identifier: 'test-gantt-project') do |p|
        p.name = 'Test Gantt Project'
        p.description = 'Test project for Gantt chart'
        p.status = Project::STATUS_ACTIVE
      end
      
      # ガントチャートモジュールを有効化
      project.enabled_modules.find_or_create_by(name: 'react_gantt_chart')
      
      # トラッカーを追加
      if project.trackers.empty?
        tracker = Tracker.find_or_create_by(name: 'Test Task') do |t|
          t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
        end
        project.trackers << tracker unless project.trackers.include?(tracker)
      end
      
      project
    end
    
    # テスト用ユーザーの準備
    @test_user ||= begin
      user = User.find_or_create_by(login: 'test_gantt_user') do |u|
        u.firstname = 'Test'
        u.lastname = 'User'
        u.mail = 'test@example.com'
        u.admin = false
        u.status = User::STATUS_ACTIVE
      end
      
      # プロジェクトにメンバーとして追加
      role = Role.find_or_create_by(name: 'Test Role') do |r|
        r.permissions = [:view_issues, :add_issues, :edit_issues, :delete_issues, :view_react_gantt_chart]
        r.assignable = true
      end
      
      member = Member.find_or_initialize_by(user: user, project: @test_project)
      member.roles = [role] unless member.roles.include?(role)
      member.save!
      
      user
    end
  end
  
  # ヘルパーモジュールを読み込み
  Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }
  
  # Include custom helpers
  config.include PerformanceHelpers
  config.include GanttTestHelpers
  
  # RSpec Benchmark設定
  config.include RSpec::Benchmark::Matchers if defined?(RSpec::Benchmark)
end

# Shoulda Matchers設定
if defined?(Shoulda::Matchers)
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end

# Factory Bot 初期化（重複だが明示的に）
RSpec.configure do |config|
  config.before(:suite) do
    FactoryBot.definition_file_paths = [
      File.expand_path('factories', __dir__)
    ]
    FactoryBot.reload
  end
end

# Capybara Playwright driver 設定
require 'capybara/playwright'
Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: true,
    playwright_cli_executable_path: File.expand_path('../node_modules/.bin/playwright', __dir__)
  )
end

# System テストで Playwright を使用
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright
  end
end

# Timecop設定
if defined?(Timecop)
  RSpec.configure do |config|
    config.after(:each) do
      Timecop.return
    end
  end
end