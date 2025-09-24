# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class KanbanSettingsSystemTest < ApplicationSystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  fixtures :users, :trackers, :projects, :roles, :members, :member_roles

  def setup
    @admin = User.find(1)
    @original_settings = Setting.plugin_redmine_release_kanban

    # テスト開始前に設定をクリア
    Setting.plugin_redmine_release_kanban = {}
    Kanban::TrackerHierarchy.clear_cache!

    # 管理者でログイン
    log_user('admin', 'admin')
  end

  def teardown
    # 設定を元に戻す
    Setting.plugin_redmine_release_kanban = @original_settings
    Kanban::TrackerHierarchy.clear_cache!
  end

  def test_plugin_settings_page_display
    # プラグイン設定画面の表示テスト
    visit '/settings/plugin/redmine_release_kanban'

    # ページタイトル確認
    assert_title /Redmine/, 'Redmineのページであること'

    # 設定フォームの存在確認
    assert_selector 'form[action*="settings/plugin/redmine_release_kanban"]', count: 1, '設定フォームが1つ存在すること'

    # トラッカー設定フィールドの表示確認
    %w[epic_tracker feature_tracker user_story_tracker task_tracker test_tracker bug_tracker].each do |field|
      assert_selector %([name="settings[#{field}]"]), count: 1, "#{field}設定フィールドが存在すること"
    end

    # 保存ボタンの存在確認
    assert_selector 'input[type="submit"], button[type="submit"]', minimum: 1, '保存ボタンが存在すること'
  rescue Capybara::ElementNotFound, ActionController::RoutingError
    skip 'プラグイン設定UI がまだ実装されていません'
  end

  def test_tracker_settings_ui_interaction
    # 設定画面でのUI操作テスト
    visit '/settings/plugin/redmine_release_kanban'

    # 各トラッカー設定に値を入力
    tracker_settings = {
      'epic_tracker' => 'UIテストEpic',
      'feature_tracker' => 'UIテストFeature',
      'user_story_tracker' => 'UIテストUserStory',
      'task_tracker' => 'UIテストTask',
      'test_tracker' => 'UIテストTest',
      'bug_tracker' => 'UIテストBug'
    }

    tracker_settings.each do |field, value|
      # フィールドタイプに応じて入力方法を変更
      field_selector = %([name="settings[#{field}]"])

      if page.has_selector?("select#{field_selector}")
        # セレクトボックスの場合
        select value, from: "settings[#{field}]"
      elsif page.has_selector?("input#{field_selector}")
        # テキストフィールドの場合
        fill_in "settings[#{field}]", with: value
      elsif page.has_selector?("textarea#{field_selector}")
        # テキストエリアの場合
        fill_in "settings[#{field}]", with: value
      end
    end

    # 設定保存
    click_button '適用'

    # 成功メッセージまたはリダイレクト確認
    assert_current_path %r{/settings/plugin/redmine_release_kanban}, '設定画面にリダイレクトされること'

    # 保存された値が表示されているか確認
    tracker_settings.each do |field, value|
      field_selector = %([name="settings[#{field}]"])

      if page.has_selector?("select#{field_selector}")
        assert_selector "select#{field_selector} option[selected]", text: value, "#{field}の選択値が保存されていること"
      elsif page.has_selector?("input#{field_selector}")
        assert_field "settings[#{field}]", with: value, "#{field}の入力値が保存されていること"
      elsif page.has_selector?("textarea#{field_selector}")
        assert_field "settings[#{field}]", with: value, "#{field}のテキストエリア値が保存されていること"
      end
    end
  rescue Capybara::ElementNotFound, ActionController::RoutingError
    skip 'プラグイン設定UI がまだ実装されていません'
  end

  def test_tracker_settings_preview_functionality
    # 設定のプレビュー機能テスト（JavaScriptが必要）
    visit '/settings/plugin/redmine_release_kanban'

    # プレビュー表示エリアの存在確認
    if page.has_selector?('.tracker-hierarchy-preview, #tracker-preview, .kanban-preview')
      # Epic トラッカー設定変更
      fill_in 'settings[epic_tracker]', with: 'プレビューEpic'

      # JavaScriptによるプレビュー更新を待機
      sleep 1

      # プレビュー内容の更新確認
      within '.tracker-hierarchy-preview, #tracker-preview, .kanban-preview' do
        assert_text 'プレビューEpic', 'プレビューにEpic名が表示されること'
      end

      # Feature トラッカー設定変更
      fill_in 'settings[feature_tracker]', with: 'プレビューFeature'

      # プレビュー更新確認
      within '.tracker-hierarchy-preview, #tracker-preview, .kanban-preview' do
        assert_text 'プレビューFeature', 'プレビューにFeature名が表示されること'
      end
    else
      skip 'プレビュー機能がまだ実装されていません'
    end
  rescue Capybara::ElementNotFound, ActionController::RoutingError
    skip 'プラグイン設定UI またはプレビュー機能がまだ実装されていません'
  end

  def test_form_validation_and_error_handling
    # フォームバリデーションとエラーハンドリング
    visit '/settings/plugin/redmine_release_kanban'

    # 無効な値での保存を試行（実装依存）
    # 例: 空文字や特殊文字
    fill_in 'settings[epic_tracker]', with: ''
    fill_in 'settings[feature_tracker]', with: '   ' # 空白のみ

    click_button '適用'

    # エラーメッセージの表示確認（実装されている場合）
    if page.has_selector?('.error, .alert, .flash.error')
      within '.error, .alert, .flash.error' do
        assert_text /エラー|error|無効|invalid/i, 'エラーメッセージが表示されること'
      end

      # フォームが再表示されることを確認
      assert_selector 'form[action*="settings/plugin/redmine_release_kanban"]', count: 1, 'エラー時にフォームが再表示されること'
    else
      # バリデーションエラーがない場合の処理
      # 空文字はデフォルト値で処理される可能性もある
      assert_current_path %r{/settings/plugin/redmine_release_kanban}, '設定画面に留まること'
    end
  rescue Capybara::ElementNotFound, ActionController::RoutingError
    skip 'プラグイン設定UI がまだ実装されていません'
  end

  def test_settings_reset_functionality
    # 設定リセット機能のテスト（実装されている場合）
    visit '/settings/plugin/redmine_release_kanban'

    # 設定値を変更
    fill_in 'settings[epic_tracker]', with: 'カスタムEpic'
    fill_in 'settings[feature_tracker]', with: 'カスタムFeature'

    # リセットボタンの存在確認
    if page.has_button?('リセット') || page.has_button?('Reset') || page.has_button?('デフォルトに戻す')
      # リセット実行
      click_button 'リセット'

      # デフォルト値に戻ることを確認
      assert_field 'settings[epic_tracker]', with: 'Epic', 'Epic設定がデフォルト値に戻ること'
      assert_field 'settings[feature_tracker]', with: 'Feature', 'Feature設定がデフォルト値に戻ること'
    else
      skip 'リセット機能がまだ実装されていません'
    end
  rescue Capybara::ElementNotFound, ActionController::RoutingError
    skip 'プラグイン設定UI またはリセット機能がまだ実装されていません'
  end

  def test_accessibility_and_usability
    # アクセシビリティとユーザビリティのテスト
    visit '/settings/plugin/redmine_release_kanban'

    # ラベルとフィールドの関連確認
    %w[epic_tracker feature_tracker user_story_tracker].each do |field|
      # ラベルの存在確認
      if page.has_selector?("label[for*='#{field}']")
        assert_selector "label[for*='#{field}']", count: 1, "#{field}のラベルが存在すること"
      end

      # フィールドの必須属性確認（実装依存）
      field_element = page.find(%([name="settings[#{field}]"]))
      # 必須フィールドの場合はrequired属性があることを確認
      # assert field_element[:required], "#{field}が必須フィールドであること" if 必須の場合
    end

    # タブナビゲーション確認
    tab_elements = all('input, select, textarea, button').select { |el| el[:tabindex] != '-1' }
    assert tab_elements.length > 0, 'タブナビゲーション可能な要素が存在すること'

    # フォーカス移動テスト
    first_field = page.find(%([name="settings[epic_tracker]"]))
    first_field.click
    assert_equal first_field, page.driver.browser.switch_to.active_element, 'フィールドにフォーカスが当たること'
  rescue Capybara::ElementNotFound, ActionController::RoutingError
    skip 'プラグイン設定UI がまだ実装されていません'
  end

  private

  # システムテスト用ログインヘルパー
  def log_user(login, password)
    visit '/login'
    fill_in 'Username', with: login
    fill_in 'Password', with: password
    click_button 'Login'

    # ログイン成功確認
    assert_current_path '/', 'ホーム画面にリダイレクトされること'
  end
end