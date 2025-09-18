# frozen_string_literal: true

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

# プラグイン固有の設定
RSpec.configure do |config|
  # プラグインのフィクスチャパスを追加
  config.fixture_path = File.expand_path('fixtures', __dir__)
  
  # トランザクショナルテスト
  config.use_transactional_fixtures = true
  
  # データベースクリーナー設定
  config.before(:suite) do
    require 'database_cleaner/active_record' if defined?(DatabaseCleaner)
    DatabaseCleaner.strategy = :transaction if defined?(DatabaseCleaner)
    DatabaseCleaner.clean_with(:truncation) if defined?(DatabaseCleaner)
  end
  
  config.around(:each) do |example|
    if defined?(DatabaseCleaner)
      DatabaseCleaner.cleaning do
        example.run
      end
    else
      example.run
    end
  end
  
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

# Factory Bot設定
if defined?(FactoryBot)
  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
    
    config.before(:suite) do
      FactoryBot.find_definitions
    end
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