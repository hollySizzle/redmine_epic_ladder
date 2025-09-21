# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class KanbanTrackerHierarchyTest < ActiveSupport::TestCase
  # 基本的なフィクスチャのみ
  fixtures :trackers

  def test_basic_tracker_access
    # 基本的なトラッカーアクセステスト
    assert Tracker.count > 0, 'トラッカーが存在すること'
  end

  def test_valid_parent_with_actual_trackers
    # 実際のトラッカーを使用した階層制約テスト
    task_tracker = Tracker.find_by(name: 'Task') || Tracker.create!(name: 'Task')
    user_story_tracker = Tracker.find_by(name: 'UserStory') || Tracker.create!(name: 'UserStory')
    feature_tracker = Tracker.find_by(name: 'Feature') || Tracker.create!(name: 'Feature')

    # 正常な親子関係：Task → UserStory
    assert Kanban::TrackerHierarchy.valid_parent?(task_tracker, user_story_tracker),
           'Task should be allowed to have UserStory as parent'

    # 不正な関係：Task → Feature（UserStoryを飛ばす）
    refute Kanban::TrackerHierarchy.valid_parent?(task_tracker, feature_tracker),
           'Task should not be allowed to have Feature as direct parent'

    # nil安全性テスト
    refute Kanban::TrackerHierarchy.valid_parent?(nil, user_story_tracker),
           'nil tracker should not be valid'
    refute Kanban::TrackerHierarchy.valid_parent?(task_tracker, nil),
           'nil parent should not be valid'
  end

  def test_allowed_children_returns_correct_tracker_names
    # 各トラッカーの許可された子要素を確認
    assert_equal ['Feature'], Kanban::TrackerHierarchy.allowed_children('Epic')
    assert_equal ['UserStory'], Kanban::TrackerHierarchy.allowed_children('Feature')
    assert_equal ['Task', 'Test', 'Bug'], Kanban::TrackerHierarchy.allowed_children('UserStory')
    assert_equal [], Kanban::TrackerHierarchy.allowed_children('Task')
    assert_equal [], Kanban::TrackerHierarchy.allowed_children('Test')
  end

  def test_hierarchy_level_calculation
    # 階層レベルの正確性を確認
    assert_equal 1, Kanban::TrackerHierarchy.level('Epic')
    assert_equal 2, Kanban::TrackerHierarchy.level('Feature')
    assert_equal 3, Kanban::TrackerHierarchy.level('UserStory')
    assert_equal 4, Kanban::TrackerHierarchy.level('Task')
    assert_equal 4, Kanban::TrackerHierarchy.level('Test')
    assert_equal 4, Kanban::TrackerHierarchy.level('Bug')
  end
end