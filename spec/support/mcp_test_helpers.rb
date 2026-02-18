# frozen_string_literal: true

# MCP Tool テスト用ヘルパー
# Tracker重複エラーを回避するため、find_or_create_by!を使用
module McpTestHelpers
  extend ActiveSupport::Concern

  # Epic Tracker を取得または作成
  def find_or_create_epic_tracker
    Tracker.find_or_create_by!(name: EpicLadder::TrackerHierarchy.tracker_names[:epic]) do |t|
      t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
    end
  end

  # Feature Tracker を取得または作成
  def find_or_create_feature_tracker
    Tracker.find_or_create_by!(name: EpicLadder::TrackerHierarchy.tracker_names[:feature]) do |t|
      t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
    end
  end

  # UserStory Tracker を取得または作成
  def find_or_create_user_story_tracker
    Tracker.find_or_create_by!(name: EpicLadder::TrackerHierarchy.tracker_names[:user_story]) do |t|
      t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
    end
  end

  # Task Tracker を取得または作成
  def find_or_create_task_tracker
    Tracker.find_or_create_by!(name: EpicLadder::TrackerHierarchy.tracker_names[:task]) do |t|
      t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
    end
  end

  # Bug Tracker を取得または作成
  def find_or_create_bug_tracker
    Tracker.find_or_create_by!(name: EpicLadder::TrackerHierarchy.tracker_names[:bug]) do |t|
      t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
    end
  end

  # Test Tracker を取得または作成
  def find_or_create_test_tracker
    Tracker.find_or_create_by!(name: EpicLadder::TrackerHierarchy.tracker_names[:test]) do |t|
      t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
    end
  end

  # 全Tracker種別を取得または作成
  def setup_all_trackers
    {
      epic: find_or_create_epic_tracker,
      feature: find_or_create_feature_tracker,
      user_story: find_or_create_user_story_tracker,
      task: find_or_create_task_tracker,
      bug: find_or_create_bug_tracker,
      test: find_or_create_test_tracker
    }
  end
end

RSpec.configure do |config|
  config.include McpTestHelpers
end
