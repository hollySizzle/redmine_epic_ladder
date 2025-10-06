# frozen_string_literal: true

module EpicGridE2EHelpers
  # プロジェクトとトラッカーのセットアップ
  def setup_epic_grid_project(identifier: 'test-project', name: nil)
    project = create(:project, identifier: identifier, name: name || identifier)

    # 全トラッカー作成してプロジェクトに追加
    [:epic, :feature, :user_story, :task, :test, :bug].each do |type|
      tracker = create(:"#{type}_tracker")
      project.trackers << tracker
    end

    # epic_gridモジュール有効化
    project.enabled_modules.create!(name: 'epic_grid') unless project.module_enabled?('epic_grid')

    project
  end

  # 管理者ユーザー作成
  def setup_admin_user(login: 'test_user', firstname: 'Test', lastname: 'User')
    create(:user, login: login, firstname: firstname, lastname: lastname, admin: true)
  end

  # 一般ユーザー作成と権限設定
  def setup_user_with_permissions(project, login: 'test_user', permissions: [:view_issues, :add_issues, :edit_issues, :view_epic_grid, :manage_epic_grid])
    user = create(:user, login: login, admin: false)

    role = Role.find_or_create_by!(name: 'Test Role') do |r|
      r.permissions = permissions
      r.assignable = true
    end

    Member.create!(user: user, project: project, roles: [role])

    user
  end

  # ログイン処理
  def login_as(user, password: 'password123')
    @playwright_page.goto('/login', timeout: 30000)
    @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

    @playwright_page.fill('input[name="username"]', user.login)
    @playwright_page.fill('input[name="password"]', password)
    @playwright_page.click('input#login-submit')

    # ログイン成功確認
    @playwright_page.wait_for_url(/\/my\/page/, timeout: 15000)
  end

  # カンバンページへ遷移
  def goto_kanban(project)
    @playwright_page.goto("/projects/#{project.identifier}/epic_grid", timeout: 30000)
    @playwright_page.wait_for_load_state('networkidle', timeout: 10000) rescue nil

    # Reactアプリのマウント待機
    @playwright_page.wait_for_selector('#kanban-root', timeout: 15000)

    # Loading状態の終了を待つ
    @playwright_page.wait_for_function(
      "() => !document.body.textContent.includes('Loading grid data')",
      timeout: 30000
    ) rescue nil
  end

  # カンバングリッドの基本構造確認
  def verify_kanban_structure
    expect(@playwright_page.query_selector('.epic-feature-version-grid')).not_to be_nil
    expect(@playwright_page.query_selector('.epic-cell')).not_to be_nil
    expect(@playwright_page.query_selector('.feature-cell')).not_to be_nil
  end

  # 要素が表示されるまで待機
  def wait_for_text(text, timeout: 10000)
    @playwright_page.wait_for_selector("text='#{text}'", timeout: timeout)
  end

  # 要素が表示されていることを確認
  def expect_text_visible(text)
    element = @playwright_page.query_selector("text='#{text}'")
    expect(element).not_to be_nil, "Expected text '#{text}' to be visible"
  end

  # 要素が表示されていないことを確認
  def expect_text_not_visible(text)
    element = @playwright_page.query_selector("text='#{text}'")
    expect(element).to be_nil, "Expected text '#{text}' to not be visible"
  end

  # ========================================
  # Drag & Drop ヘルパー
  # ========================================

  # UserStoryをD&Dで移動する
  # @param user_story_subject [String] 移動するUserStoryのsubject
  # @param target_cell_selector [String] ドロップ先のセレクタ（例: ".us-cell[data-epic='1'][data-feature='2'][data-version='3']"）
  def drag_user_story_to_cell(user_story_subject, target_cell_selector)
    # ソース要素のセレクタ（UserStoryカード）
    source_selector = ".user-story:has-text('#{user_story_subject}')"

    # 要素の存在確認
    source = @playwright_page.query_selector(source_selector)
    raise "UserStory '#{user_story_subject}' not found with selector: #{source_selector}" unless source

    target = @playwright_page.query_selector(target_cell_selector)
    raise "Target cell '#{target_cell_selector}' not found" unless target

    # Pragmatic Drag and Dropを動作させるには、実際のマウスイベントをシミュレートする必要がある
    # PlaywrightのCDP (Chrome DevTools Protocol) を使用してネイティブD&Dを実行
    source_box = source.bounding_box
    target_box = target.bounding_box

    # ソースの中心点
    source_x = source_box['x'] + source_box['width'] / 2
    source_y = source_box['y'] + source_box['height'] / 2

    # ターゲットの中心点
    target_x = target_box['x'] + target_box['width'] / 2
    target_y = target_box['y'] + target_box['height'] / 2

    # D&Dシーケンス
    @playwright_page.mouse.move(source_x, source_y)
    @playwright_page.mouse.down
    sleep 0.3 # ドラッグ開始の待機
    @playwright_page.mouse.move(target_x, target_y, steps: 10)
    sleep 0.3 # ドロップ前の待機
    @playwright_page.mouse.up

    # D&D後のアニメーション待機
    sleep 0.5
  end

  # Featureカードを並び替える
  def reorder_feature(feature_subject, target_feature_subject)
    source_selector = ".feature-cell:has-text('#{feature_subject}')"
    target_selector = ".feature-cell:has-text('#{target_feature_subject}')"

    source = @playwright_page.query_selector(source_selector)
    target = @playwright_page.query_selector(target_selector)

    raise "Feature '#{feature_subject}' not found" unless source
    raise "Target Feature '#{target_feature_subject}' not found" unless target

    @playwright_page.drag_and_drop(source_selector, target_selector)
    sleep 0.5
  end

  # 保存ボタンをクリック
  def click_save_button
    save_button = @playwright_page.query_selector('button.save-btn, button:has-text("保存")')
    raise "Save button not found" unless save_button

    save_button.click
    # 保存完了のアラート待機
    sleep 1
  end

  # 破棄ボタンをクリック
  def click_discard_button
    discard_button = @playwright_page.query_selector('button.discard-btn, button:has-text("破棄")')
    raise "Discard button not found" unless discard_button

    # confirm dialogを自動でOKにする
    @playwright_page.on('dialog', ->(dialog) { dialog.accept })
    discard_button.click
    sleep 1
  end

  # 保存ボタンが表示されているか確認
  def expect_save_button_visible
    save_button = @playwright_page.query_selector('button.save-btn, button:has-text("保存")')
    expect(save_button).not_to be_nil, "Expected save button to be visible"
  end

  # 保存ボタンが非表示か確認
  def expect_save_button_hidden
    save_button = @playwright_page.query_selector('button.save-btn, button:has-text("保存")')
    expect(save_button).to be_nil, "Expected save button to be hidden"
  end

  # 変更件数の確認
  def expect_changes_count(count)
    save_button = @playwright_page.query_selector('button.save-btn, button:has-text("保存")')
    expect(save_button).not_to be_nil
    expect(save_button.text_content).to include(count.to_s)
  end
end

RSpec.configure do |config|
  config.include EpicGridE2EHelpers, type: :system
end
