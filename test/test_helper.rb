# frozen_string_literal: true

# Redmine標準のtest_helperを読み込み
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# カンバン関連のテストフィクスチャをロード（将来作成予定）
# ActiveRecord::FixtureSet.create_fixtures(File.dirname(__FILE__) + '/fixtures/',
#                                          %i[kanban_boards kanban_columns])

module Redmine
  class ControllerTest
    setup do
      Setting.text_formatting = 'textile'
    end

    teardown do
      Setting.delete_all
      Setting.clear_cache
    end
  end
end