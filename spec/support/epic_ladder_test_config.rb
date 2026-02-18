# frozen_string_literal: true

# テスト専用のプラグイン設定
# 本番でハードコードされたトラッカー名を使うとテストが失敗するように設計
module EpicLadderTestConfig
  # テスト専用トラッカー名（本番では使わない名前）
  TRACKER_NAMES = {
    epic: 'Epic-for-test',
    feature: 'Feature-for-test',
    user_story: 'UserStory-for-test',
    task: 'Task-for-test',
    test: 'Test-for-test',
    bug: 'Bug-for-test'
  }.freeze

  # テスト環境のプラグイン設定をセットアップ
  def self.setup!
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => TRACKER_NAMES[:epic],
      'feature_tracker' => TRACKER_NAMES[:feature],
      'user_story_tracker' => TRACKER_NAMES[:user_story],
      'task_tracker' => TRACKER_NAMES[:task],
      'test_tracker' => TRACKER_NAMES[:test],
      'bug_tracker' => TRACKER_NAMES[:bug]
    }

    # TrackerHierarchyのキャッシュをクリア
    EpicLadder::TrackerHierarchy.clear_cache!
  end

  # ヘルパーメソッド
  def epic_tracker_name
    TRACKER_NAMES[:epic]
  end

  def feature_tracker_name
    TRACKER_NAMES[:feature]
  end

  def user_story_tracker_name
    TRACKER_NAMES[:user_story]
  end

  def task_tracker_name
    TRACKER_NAMES[:task]
  end

  def test_tracker_name
    TRACKER_NAMES[:test]
  end

  def bug_tracker_name
    TRACKER_NAMES[:bug]
  end
end

# RSpec設定
RSpec.configure do |config|
  # テストヘルパーメソッドを有効化
  config.include EpicLadderTestConfig

  # テストスイート開始時にプラグイン設定を初期化
  config.before(:suite) do
    EpicLadderTestConfig.setup!
  end
end
