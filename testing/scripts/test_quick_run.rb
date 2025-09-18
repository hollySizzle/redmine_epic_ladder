#!/usr/bin/env ruby
# frozen_string_literal: true

# 簡単なテスト実行スクリプト - 次回以降の開発で再利用可能
# Usage: ruby test_quick_run.rb [test_type]
#   test_type: controller, performance, all (default: all)

require 'pathname'

plugin_root = Pathname.new(__FILE__).parent.parent.realpath
test_type = ARGV[0] || 'all'

# Redmineのルートディレクトリに移動
Dir.chdir('/usr/src/redmine') do
  puts "=== Gantt Chart Plugin Test Runner ==="
  puts "Plugin: #{plugin_root}"
  puts "Test Type: #{test_type}"
  puts "=" * 40
  
  # 環境設定
  env_vars = {
    'RAILS_ENV' => 'test',
    'DEBUG_TESTS' => '1',
    'PERFORMANCE_LOG' => '1'
  }
  
  # テストタイプに応じた実行
  case test_type
  when 'controller'
    command = "bundle exec rspec #{plugin_root}/spec/controllers/ --format documentation"
  when 'performance'
    command = "bundle exec rspec #{plugin_root}/spec/requests/ --format documentation --tag performance"
  when 'all'
    command = "bundle exec rspec #{plugin_root}/spec/ --format documentation"
  else
    puts "Unknown test type: #{test_type}"
    puts "Available types: controller, performance, all"
    exit 1
  end
  
  # 環境変数設定とコマンド実行
  env_string = env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')
  full_command = "#{env_string} #{command}"
  
  puts "Executing: #{full_command}"
  puts "-" * 40
  
  exec(full_command)
end