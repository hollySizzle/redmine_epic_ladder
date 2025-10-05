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
    expect(@playwright_page.query_selector('.epic-version-grid')).not_to be_nil
    expect(@playwright_page.query_selector('.feature-card-grid')).not_to be_nil
    expect(@playwright_page.query_selector('.user-story-grid')).not_to be_nil
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
end

RSpec.configure do |config|
  config.include EpicGridE2EHelpers, type: :system
end
