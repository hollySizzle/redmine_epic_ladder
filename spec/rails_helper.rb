# frozen_string_literal: true

# ========================================
# CRITICAL: Rails読み込み前にDATABASE_URL削除
# ========================================
# DATABASE_URLが設定されているとdatabase.ymlが無視され、
# test環境でもdevelopment DBに接続してしまう
if ENV['DATABASE_URL']
  puts "\n⚠️  [WARNING] DATABASE_URL detected: #{ENV['DATABASE_URL']}"
  puts "⚠️  Removing to use database.yml (test environment)...\n"
  ENV.delete('DATABASE_URL')
end

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
    # Coverage output to tmp/test_artifacts/coverage
    coverage_dir File.expand_path('../../../tmp/test_artifacts/coverage', __dir__)

    add_filter '/spec/'
    add_filter '/test/'
    add_group 'Controllers', 'app/controllers'
    add_group 'Services', 'app/services'
    add_group 'JavaScript', 'assets/javascripts'
  end
end

# DatabaseCleaner 設定（system spec で別プロセスからデータを見えるようにする）
require 'database_cleaner/active_record'

# CRITICAL: Rails環境を読み込む前に必ずRAILS_ENV=testを設定
# これがないとdevelopment DBが破壊される
ENV['RAILS_ENV'] = 'test' unless ENV['RAILS_ENV']

# Redmineルートディレクトリを特定（プラグインディレクトリから2階層上）
REDMINE_ROOT = File.expand_path('../../..', __dir__)

# カレントディレクトリをRedmineルートに変更（相対パス解決のため）
Dir.chdir(REDMINE_ROOT) unless Dir.pwd == REDMINE_ROOT

# Redmineのrails_helperまたは標準のrails_helper設定
begin
  require File.join(REDMINE_ROOT, 'spec/rails_helper')
rescue LoadError
  # Redmineのrails_helperがない場合の基本設定
  # Railsアプリケーションが確実にロードされるようにする
  require File.join(REDMINE_ROOT, 'config/environment')
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
    # i18n バックエンドを初期化
    I18n.backend.load_translations

    # 組み込みグループを作成（User.current.roles で必須）
    GroupAnonymous.load_instance rescue nil
    GroupNonMember.load_instance rescue nil

    # Group が存在しない場合のみ default data をロード
    if defined?(Group) && Group.count == 2  # 組み込みグループのみ存在
      puts "\n[INFO] Loading Redmine default data..."
      # 言語を環境変数で指定（対話式入力を回避）
      ENV['REDMINE_LANG'] = 'en'
      # Rake task を直接実行
      require 'rake'
      Rails.application.load_tasks
      Rake::Task['redmine:load_default_data'].invoke
      puts "[INFO] Default data loaded successfully\n"
    end

    # === 選択肢A: Eager loading で Redmine::I18n を強制的に読み込む ===
    puts "\n[INFO] Forcing Redmine::I18n to be included in ActionView::Base..."

    # Redmine コアの Helper を確実にロード
    require 'application_helper'

    # ActionView::Base に Redmine::I18n を強制的に include
    unless ActionView::Base.included_modules.include?(Redmine::I18n)
      ActionView::Base.send(:include, Redmine::I18n)
      puts "[INFO] ✅ Redmine::I18n included in ActionView::Base"
    else
      puts "[INFO] ✅ Redmine::I18n already included in ActionView::Base"
    end

    # ApplicationHelper にも確認
    unless ApplicationHelper.included_modules.include?(Redmine::I18n)
      ApplicationHelper.send(:include, Redmine::I18n)
      puts "[INFO] ✅ Redmine::I18n included in ApplicationHelper"
    else
      puts "[INFO] ✅ Redmine::I18n already included in ApplicationHelper"
    end

    puts "[INFO] Redmine::I18n setup completed\n"
  end

  # DatabaseCleaner 設定
  config.use_transactional_fixtures = false

  config.before(:suite) do
    # CRITICAL: test環境以外では絶対に実行しない（development DB保護）
    unless Rails.env.test?
      raise "DatabaseCleaner must only run in test environment! Current: #{Rails.env}"
    end

    # DATABASE_URL が設定されている環境でも許可
    DatabaseCleaner.allow_remote_database_url = true

    # Redmine default data を保護しながら truncation
    # users, projects, issues などは削除するが、roles, trackers, issue_statuses は保護
    protected_tables = %w[
      roles
      trackers
      issue_statuses
      enumerations
      workflows
      custom_fields
      settings
      groups_users
    ]

    DatabaseCleaner.strategy = :truncation, { except: protected_tables }
    DatabaseCleaner.clean_with(:truncation, { except: protected_tables })
  end

  config.around(:each) do |example|
    protected_tables = %w[
      roles
      trackers
      issue_statuses
      enumerations
      workflows
      custom_fields
      settings
      groups_users
    ]

    if example.metadata[:type] == :system
      # System spec: 別プロセス（Railsサーバー）から見えるように truncation 使用
      # default data テーブルは保護
      DatabaseCleaner.strategy = :truncation, { except: protected_tables }
    else
      # 通常の spec: 高速な transaction 使用
      DatabaseCleaner.strategy = :transaction
    end

    # 組み込みグループを再作成（truncation 前に必須 - サーバーが参照する）
    if example.metadata[:type] == :system
      GroupAnonymous.load_instance rescue nil
      GroupNonMember.load_instance rescue nil
    end

    DatabaseCleaner.cleaning do
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

# Pure Playwright Ruby Client（Capybara 不使用）
require 'playwright'

# System テストで Pure Playwright を使用（サーバー共有モード）
RSpec.configure do |config|
  # サーバーを全テストで共有（高速化）
  config.before(:suite) do
    if RSpec.configuration.files_to_run.any? { |f| f.include?('spec/system') }
      @shared_server_port = ENV['TEST_PORT'] || 3001

      # 既存のプロセスをクリーンアップ
      system("lsof -ti:#{@shared_server_port} | xargs kill -9 2>/dev/null")
      sleep 0.5

      puts "\n[INFO] 共有 Rails サーバーを起動中（ポート: #{@shared_server_port}）..."

      @shared_server_pid = fork do
        ENV['RAILS_ENV'] = 'test'
        ENV.delete('DATABASE_URL')  # 確実にdatabase.ymlを使用
        exec("bundle exec rails s -p #{@shared_server_port} -e test > log/test_server.log 2>&1")
      end

      # サーバー起動待機（/login は User.current なしでレンダリング可能）
      max_wait = 30
      start_time = Time.now
      loop do
        break if system("curl -s http://localhost:#{@shared_server_port}/login > /dev/null 2>&1")
        if Time.now - start_time > max_wait
          Process.kill('TERM', @shared_server_pid) rescue nil
          raise "Rails server failed to start within #{max_wait} seconds"
        end
        sleep 0.5
      end

      puts "[INFO] ✅ Rails サーバー起動完了（PID: #{@shared_server_pid}）\n"

      # グローバル変数に保存
      $shared_server_port = @shared_server_port
      $shared_server_pid = @shared_server_pid
    end
  end

  config.after(:suite) do
    if $shared_server_pid
      puts "\n[INFO] 共有 Rails サーバーを停止中（PID: #{$shared_server_pid}）..."
      Process.kill('TERM', $shared_server_pid) rescue nil
      Process.wait($shared_server_pid) rescue nil
      puts "[INFO] ✅ Rails サーバー停止完了\n"
    end
  end

  config.around(:each, type: :system) do |example|
    server_port = $shared_server_port || 3001

    # Playwright でブラウザ起動（サーバーは共有）
    Playwright.create(playwright_cli_executable_path: File.expand_path('../node_modules/.bin/playwright', __dir__)) do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        @playwright_page = browser.new_page(baseURL: "http://localhost:#{server_port}")
        @playwright_page.context.set_default_timeout(10000)

        begin
          # テスト実行
          example.run
        ensure
          # デバッグ情報保存（失敗時）
          if example.exception
            timestamp = Time.now.to_i
            base_filename = "#{example.full_description.parameterize}_#{timestamp}"

            # 1. スクリーンショット保存
            screenshot_dir = Rails.root.join('tmp', 'test_artifacts', 'screenshots')
            FileUtils.mkdir_p(screenshot_dir)
            screenshot_path = screenshot_dir.join("#{base_filename}.png")
            @playwright_page.screenshot(path: screenshot_path.to_s)
            puts "\n[Screenshot] #{screenshot_path}"

            # 2. HTML保存
            html_dir = Rails.root.join('tmp', 'test_artifacts', 'html')
            FileUtils.mkdir_p(html_dir)
            html_path = html_dir.join("#{base_filename}.html")
            File.write(html_path, @playwright_page.content)
            puts "[HTML] #{html_path}"

            # 3. ページ情報保存
            info_dir = Rails.root.join('tmp', 'test_artifacts', 'info')
            FileUtils.mkdir_p(info_dir)
            info_path = info_dir.join("#{base_filename}.txt")
            page_info = <<~INFO
              Test: #{example.full_description}
              URL: #{@playwright_page.url}
              Title: #{@playwright_page.title}
              Timestamp: #{Time.now}
              Error: #{example.exception.class.name}: #{example.exception.message}
            INFO
            File.write(info_path, page_info)
            puts "[Info] #{info_path}"
          end
        end
      end
    end
  end

  # @playwright_page をテストから参照できるようにする
  config.before(:each, type: :system) do
    # @playwright_page は around ブロックで設定される
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