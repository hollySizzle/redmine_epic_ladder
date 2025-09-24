# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class KanbanTrackerHierarchyTest < ActiveSupport::TestCase
  # 基本的なフィクスチャのみ
  fixtures :trackers

  def test_basic_tracker_access
    # 基本的なトラッカーアクセステスト
    assert Tracker.count > 0, 'トラッカーが存在すること'
  end

  def test_valid_parent_with_japanese_trackers
    # 日本語トラッカーを使用した階層制約テスト
    # Trackerオブジェクトのモックを使用
    task_name = Kanban::TrackerHierarchy.tracker_names[:task]
    user_story_name = Kanban::TrackerHierarchy.tracker_names[:user_story]
    feature_name = Kanban::TrackerHierarchy.tracker_names[:feature]

    # モックTrackerオブジェクトを作成
    task_tracker = Struct.new(:name).new(task_name)
    user_story_tracker = Struct.new(:name).new(user_story_name)
    feature_tracker = Struct.new(:name).new(feature_name)

    # 正常な親子関係：作業 → ユーザストーリ
    assert Kanban::TrackerHierarchy.valid_parent?(task_tracker, user_story_tracker),
           '作業はユーザストーリを親として持てること'

    # 不正な関係：作業 → 機能（ユーザストーリを飛ばす）
    refute Kanban::TrackerHierarchy.valid_parent?(task_tracker, feature_tracker),
           '作業は機能を直接の親として持てないこと'

    # nil安全性テスト
    refute Kanban::TrackerHierarchy.valid_parent?(nil, user_story_tracker),
           'nilトラッカーは無効であること'
    refute Kanban::TrackerHierarchy.valid_parent?(task_tracker, nil),
           'nil親は無効であること'
  end

  def test_allowed_children_returns_correct_japanese_tracker_names
    # 各日本語トラッカーの許可された子要素を確認
    names = Kanban::TrackerHierarchy.tracker_names

    assert_equal [names[:feature]], Kanban::TrackerHierarchy.allowed_children(names[:epic])
    assert_equal [names[:user_story]], Kanban::TrackerHierarchy.allowed_children(names[:feature])
    assert_equal [names[:task], names[:test], names[:bug]], Kanban::TrackerHierarchy.allowed_children(names[:user_story])
    assert_equal [], Kanban::TrackerHierarchy.allowed_children(names[:task])
    assert_equal [], Kanban::TrackerHierarchy.allowed_children(names[:test])
    assert_equal [], Kanban::TrackerHierarchy.allowed_children(names[:bug])
  end

  def test_hierarchy_level_calculation_with_japanese_trackers
    # 日本語トラッカーでの階層レベルの正確性を確認
    names = Kanban::TrackerHierarchy.tracker_names

    assert_equal 1, Kanban::TrackerHierarchy.level(names[:epic])
    assert_equal 2, Kanban::TrackerHierarchy.level(names[:feature])
    assert_equal 3, Kanban::TrackerHierarchy.level(names[:user_story])
    assert_equal 4, Kanban::TrackerHierarchy.level(names[:task])
    assert_equal 4, Kanban::TrackerHierarchy.level(names[:test])
    assert_equal 4, Kanban::TrackerHierarchy.level(names[:bug])
  end

  # 設定機能のテスト - Critical機能100%カバレッジ
  def test_tracker_names_from_default_settings
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # デフォルト設定のテスト
      Setting.plugin_redmine_release_kanban = {}
      Kanban::TrackerHierarchy.clear_cache!

      names = Kanban::TrackerHierarchy.tracker_names
      assert_equal 'Epic', names[:epic], 'デフォルトEpicトラッカー名が正しいこと'
      assert_equal 'Feature', names[:feature], 'デフォルトFeatureトラッカー名が正しいこと'
      assert_equal 'UserStory', names[:user_story], 'デフォルトUserStoryトラッカー名が正しいこと'
      assert_equal 'Task', names[:task], 'デフォルトTaskトラッカー名が正しいこと'
      assert_equal 'Test', names[:test], 'デフォルトTestトラッカー名が正しいこと'
      assert_equal 'Bug', names[:bug], 'デフォルトBugトラッカー名が正しいこと'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end

  def test_tracker_names_from_custom_settings
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # 日本のプロジェクト用カスタム設定のテスト
      Setting.plugin_redmine_release_kanban = {
        'epic_tracker' => 'エピック',
        'feature_tracker' => '機能',
        'user_story_tracker' => 'ユーザストーリ',
        'task_tracker' => '作業',
        'test_tracker' => '評価',
        'bug_tracker' => '不具合'
      }

      Kanban::TrackerHierarchy.clear_cache!
      names = Kanban::TrackerHierarchy.tracker_names

      assert_equal 'エピック', names[:epic], 'カスタムエピックトラッカー名が正しいこと'
      assert_equal '機能', names[:feature], 'カスタム機能トラッカー名が正しいこと'
      assert_equal 'ユーザストーリ', names[:user_story], 'カスタムユーザストーリトラッカー名が正しいこと'
      assert_equal '作業', names[:task], 'カスタム作業トラッカー名が正しいこと'
      assert_equal '評価', names[:test], 'カスタム評価トラッカー名が正しいこと'
      assert_equal '不具合', names[:bug], 'カスタム不具合トラッカー名が正しいこと'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end

  def test_rules_generation_from_custom_settings
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # 設定値から動的ルール生成のテスト
      Setting.plugin_redmine_release_kanban = {
        'epic_tracker' => 'テストエピック',
        'feature_tracker' => 'テスト機能',
        'user_story_tracker' => 'テストユーザストーリ',
        'task_tracker' => 'テスト作業',
        'test_tracker' => 'テスト評価',
        'bug_tracker' => 'テスト不具合'
      }

      Kanban::TrackerHierarchy.clear_cache!
      rules = Kanban::TrackerHierarchy.rules

      # Epic の子・親関係確認
      assert_equal ['テスト機能'], rules['テストエピック'][:children], 'エピックの子要素が正しいこと'
      assert_equal [], rules['テストエピック'][:parents], 'エピックの親要素が空であること'

      # Feature の関係確認
      assert_equal ['テストユーザストーリ'], rules['テスト機能'][:children], '機能の子要素が正しいこと'
      assert_equal ['テストエピック'], rules['テスト機能'][:parents], '機能の親要素が正しいこと'

      # UserStory の関係確認
      assert_equal ['テスト作業', 'テスト評価', 'テスト不具合'], rules['テストユーザストーリ'][:children], 'ユーザストーリの子要素が正しいこと'
      assert_equal ['テスト機能'], rules['テストユーザストーリ'][:parents], 'ユーザストーリの親要素が正しいこと'

      # Task の関係確認
      assert_equal [], rules['テスト作業'][:children], '作業の子要素が空であること'
      assert_equal ['テストユーザストーリ'], rules['テスト作業'][:parents], '作業の親要素が正しいこと'

      # Bug の関係確認（特殊ケース：Feature直下も許可）
      assert_equal [], rules['テスト不具合'][:children], '不具合の子要素が空であること'
      assert_equal ['テストユーザストーリ', 'テスト機能'], rules['テスト不具合'][:parents], '不具合の親要素が正しいこと'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end

  def test_cache_clearing_functionality
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # 初期設定
      Setting.plugin_redmine_release_kanban = { 'epic_tracker' => 'OldEpic' }
      Kanban::TrackerHierarchy.clear_cache!
      original_names = Kanban::TrackerHierarchy.tracker_names

      # 設定変更
      Setting.plugin_redmine_release_kanban = { 'epic_tracker' => 'NewEpic' }

      # キャッシュクリア前（古い値が残っている）
      same_names = Kanban::TrackerHierarchy.tracker_names
      assert_equal original_names[:epic], same_names[:epic], 'キャッシュクリア前は古い値が取得されること'

      # キャッシュクリア後（新しい値が取得される）
      Kanban::TrackerHierarchy.clear_cache!
      new_names = Kanban::TrackerHierarchy.tracker_names
      assert_equal 'NewEpic', new_names[:epic], 'キャッシュクリア後は新しい値が取得されること'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end

  def test_configured_tracker_names_method
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # カスタム設定（一部のみ設定）
      Setting.plugin_redmine_release_kanban = {
        'epic_tracker' => 'カスタムEpic',
        'feature_tracker' => 'カスタムFeature'
      }

      Kanban::TrackerHierarchy.clear_cache!
      configured_names = Kanban::TrackerHierarchy.configured_tracker_names

      # 6つのトラッカー名が含まれることを確認
      assert_equal 6, configured_names.size, '設定されたトラッカー名は6つであること'

      # 設定されたトラッカー名が含まれることを確認
      assert_includes configured_names, 'カスタムEpic', 'カスタムEpicが含まれること'
      assert_includes configured_names, 'カスタムFeature', 'カスタムFeatureが含まれること'

      # デフォルト値も確認（未設定項目）
      assert_includes configured_names, 'UserStory', 'デフォルトUserStoryが含まれること'
      assert_includes configured_names, 'Task', 'デフォルトTaskが含まれること'
      assert_includes configured_names, 'Test', 'デフォルトTestが含まれること'
      assert_includes configured_names, 'Bug', 'デフォルトBugが含まれること'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end

  def test_kanban_tracker_check_method
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # カスタム設定
      Setting.plugin_redmine_release_kanban = {
        'epic_tracker' => 'TestEpic'
      }

      Kanban::TrackerHierarchy.clear_cache!

      # カンバン管理対象のトラッカーかチェック
      assert Kanban::TrackerHierarchy.kanban_tracker?('TestEpic'), 'カスタム設定トラッカーは管理対象であること'
      assert Kanban::TrackerHierarchy.kanban_tracker?('Feature'), 'デフォルト設定トラッカーは管理対象であること'
      refute Kanban::TrackerHierarchy.kanban_tracker?('UnknownTracker'), '未知のトラッカーは管理対象外であること'
      refute Kanban::TrackerHierarchy.kanban_tracker?(nil), 'nilは管理対象外であること'
      refute Kanban::TrackerHierarchy.kanban_tracker?(''), '空文字は管理対象外であること'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end

  def test_level_calculation_with_custom_settings
    # 元の設定を保存
    original_settings = Setting.plugin_redmine_release_kanban

    begin
      # カスタム設定
      Setting.plugin_redmine_release_kanban = {
        'epic_tracker' => 'カスタムEpic',
        'feature_tracker' => 'カスタムFeature',
        'user_story_tracker' => 'カスタムUserStory'
      }

      Kanban::TrackerHierarchy.clear_cache!

      # カスタム設定でのレベル計算確認
      assert_equal 1, Kanban::TrackerHierarchy.level('カスタムEpic'), 'カスタムEpicはレベル1であること'
      assert_equal 2, Kanban::TrackerHierarchy.level('カスタムFeature'), 'カスタムFeatureはレベル2であること'
      assert_equal 3, Kanban::TrackerHierarchy.level('カスタムUserStory'), 'カスタムUserStoryはレベル3であること'

      # デフォルト値（レベル4）
      assert_equal 4, Kanban::TrackerHierarchy.level('Task'), 'Taskはレベル4であること'
      assert_equal 4, Kanban::TrackerHierarchy.level('Test'), 'Testはレベル4であること'
      assert_equal 4, Kanban::TrackerHierarchy.level('Bug'), 'Bugはレベル4であること'

      # 未知のトラッカー
      assert_equal 4, Kanban::TrackerHierarchy.level('UnknownTracker'), '未知のトラッカーはレベル4であること'
    ensure
      # 設定を元に戻す
      Setting.plugin_redmine_release_kanban = original_settings
      Kanban::TrackerHierarchy.clear_cache!
    end
  end
end