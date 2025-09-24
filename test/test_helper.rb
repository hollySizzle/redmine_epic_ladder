# frozen_string_literal: true

# factory_girl無効化（他プラグインの依存関係を回避）
# 環境変数による制御でRedmine標準テスト手法に完全準拠
ENV['DISABLE_FACTORY_GIRL'] = '1' unless ENV.key?('DISABLE_FACTORY_GIRL')

# ActiveSupport::Deprecationのwarnメソッドをパッチ（factory_girl対応）
# factory_girlのdeprecation警告を無効化するシンプルなアプローチ
begin
  require 'active_support/deprecation'

  # Rails 7.2のprivateメソッド問題を回避
  ActiveSupport::Deprecation.class_eval do
    def self.warn(*args)
      # factory_girlの警告を無視
      return if args.first&.include?('factory_girl gem is deprecated')
      # 通常の警告は無視（テスト実行時の煩雑さ回避）
      return
    end
  end
rescue => e
  warn "ActiveSupport::Deprecation patch failed: #{e.message}" if ENV['KANBAN_TEST_DEBUG']
end

# factory_girlライブラリの読み込みを事前に無効化
def disable_factory_libraries
  # factory_girlが読み込まれる前に無効化用のモジュールを定義
  begin
    Object.const_set(:FactoryGirl, Module.new) unless defined?(FactoryGirl)
    FactoryGirl.define_singleton_method(:find_definitions) { }
    FactoryGirl.define_singleton_method(:definition_file_paths) { [] }
  rescue => e
    # 既にfactory_girlが読み込まれている場合は警告のみ
    warn "factory_girl already loaded: #{e.message}" if ENV['KANBAN_TEST_DEBUG']
  end

  begin
    Object.const_set(:FactoryBot, Module.new) unless defined?(FactoryBot)
    FactoryBot.define_singleton_method(:find_definitions) { }
    FactoryBot.define_singleton_method(:definition_file_paths) { [] }
  rescue => e
    # factory_botも同様に処理
    warn "factory_bot already loaded: #{e.message}" if ENV['KANBAN_TEST_DEBUG']
  end
end

# factory_girl無効化を実行
disable_factory_libraries

# Redmine標準のtest_helperを読み込み
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# Redmine標準フィクスチャを使用
# カスタムフィクスチャは読み込まない（Redmine標準のtrackersテーブルを使用）

module Redmine
  class ControllerTest
    setup do
      Setting.text_formatting = 'textile'
    end

    teardown do
      Setting.delete_all
      Setting.clear_cache
      # TrackerHierarchyキャッシュもクリア
      Kanban::TrackerHierarchy.clear_cache! if defined?(Kanban::TrackerHierarchy)
    end
  end
end

# ActiveSupport::TestCaseの拡張
class ActiveSupport::TestCase
  teardown do
    # 各テスト後にプラグイン設定とキャッシュをクリア
    if defined?(Setting) && Setting.respond_to?(:clear_cache)
      Setting.clear_cache
    end

    # TrackerHierarchyキャッシュクリア（設定変更テスト対応）
    if defined?(Kanban::TrackerHierarchy) && Kanban::TrackerHierarchy.respond_to?(:clear_cache!)
      Kanban::TrackerHierarchy.clear_cache!
    end
  end
end