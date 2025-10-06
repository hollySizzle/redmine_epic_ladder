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

  # ========================================
  # 作成ダイアログの抽象化レイヤー
  # ========================================
  #
  # 将来カスタムダイアログに変更する際は、このメソッド群だけを
  # 書き換えればE2Eテスト全体が対応できる設計
  #

  # アイテム作成（汎用）
  # @param item_type [String] アイテムタイプ ('epic', 'version', 'feature', 'user-story', 'task', 'test', 'bug')
  # @param item_name [String] 作成するアイテムの名前
  # @param parent_info [Hash] 親要素情報（featureの場合はepic_id, user-storyの場合はfeature_idなど）
  def create_item_via_ui(item_type, item_name, parent_info: {})
    # Step 1: ボタンを見つけてクリック
    button_selector = if parent_info[:epic_id]
      # Feature作成: Epic内のボタン
      ".epic-cell[data-epic='#{parent_info[:epic_id]}'] .add-feature-btn"
    elsif parent_info[:feature_id]
      # UserStory/Task/Test/Bug作成: Feature内のボタン
      ".feature-card[data-feature='#{parent_info[:feature_id]}'] .add-#{item_type}-btn"
    else
      # Epic/Version作成: グローバルボタン
      ".add-#{item_type}-btn"
    end

    button = @playwright_page.wait_for_selector(button_selector, state: 'visible', timeout: 15000)

    # Step 2: ダイアログ処理（抽象化ポイント）
    handle_creation_dialog(item_type, item_name, button)

    # Step 3: 作成完了待機
    wait_for_item_created(item_type, item_name)
  end

  # Epic作成（簡易版）
  def create_epic_via_ui(epic_name)
    create_item_via_ui('epic', epic_name)
  end

  # Version作成（簡易版）
  def create_version_via_ui(version_name)
    create_item_via_ui('version', version_name)
  end

  # Feature作成（簡易版）
  def create_feature_via_ui(epic_id, feature_name)
    create_item_via_ui('feature', feature_name, parent_info: { epic_id: epic_id })
  end

  # UserStory作成（簡易版）
  def create_user_story_via_ui(feature_id, story_name)
    create_item_via_ui('user-story', story_name, parent_info: { feature_id: feature_id })
  end

  # キャンセル操作（汎用）
  def cancel_item_creation_via_ui(item_type, parent_info: {})
    button_selector = if parent_info[:epic_id]
      ".epic-cell[data-epic='#{parent_info[:epic_id]}'] .add-feature-btn"
    elsif parent_info[:feature_id]
      ".feature-card[data-feature='#{parent_info[:feature_id]}'] .add-#{item_type}-btn"
    else
      ".add-#{item_type}-btn"
    end

    button = @playwright_page.wait_for_selector(button_selector, state: 'visible', timeout: 15000)

    handle_creation_dialog_cancel(item_type, button)
  end

  private

  # ========================================
  # 実装詳細レイヤー（将来の変更ポイント）
  # ========================================

  # ダイアログ処理（現在: prompt() / 将来: カスタムダイアログ）
  def handle_creation_dialog(item_type, item_name, button)
    # 現在の実装: ブラウザネイティブのprompt()を使用
    @playwright_page.on('dialog', lambda { |dialog|
      puts "[E2E] Dialog detected for #{item_type}: #{dialog.message}"
      dialog.accept(item_name)
    })

    button.click

    # 将来の実装例（カスタムダイアログに変更する場合）:
    # button.click
    # @playwright_page.wait_for_selector(".custom-dialog[data-type='#{item_type}']")
    # @playwright_page.fill('.custom-dialog input[name="subject"]', item_name)
    # @playwright_page.click('.custom-dialog button[type="submit"]')
  end

  # キャンセル処理（現在: prompt() dismiss / 将来: カスタムダイアログ）
  def handle_creation_dialog_cancel(item_type, button)
    # 現在の実装: ブラウザネイティブのprompt()をdismiss
    @playwright_page.on('dialog', lambda { |dialog|
      puts "[E2E] Dialog detected for #{item_type}, dismissing..."
      dialog.dismiss
    })

    button.click
    sleep 0.5 # キャンセル処理の完了待ち

    # 将来の実装例（カスタムダイアログに変更する場合）:
    # button.click
    # @playwright_page.wait_for_selector(".custom-dialog[data-type='#{item_type}']")
    # @playwright_page.click('.custom-dialog button[data-action="cancel"]')
  end

  # アイテム作成完了待機
  def wait_for_item_created(item_type, item_name)
    case item_type
    when 'epic'
      @playwright_page.wait_for_selector(".epic-cell:has-text('#{item_name}')", timeout: 15000)
    when 'version'
      @playwright_page.wait_for_selector(".version-header:has-text('#{item_name}')", timeout: 15000)
    when 'feature'
      @playwright_page.wait_for_selector(".feature-cell:has-text('#{item_name}')", timeout: 15000)
    when 'user-story'
      @playwright_page.wait_for_selector(".user-story:has-text('#{item_name}')", timeout: 15000)
    when 'task', 'test', 'bug'
      @playwright_page.wait_for_selector(".#{item_type}:has-text('#{item_name}')", timeout: 15000)
    end
  end
end

RSpec.configure do |config|
  config.include EpicGridE2EHelpers, type: :system
end
