# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Epic作成E2Eテスト（抽象化レイヤー使用）
# ============================================================

RSpec.describe 'Epic Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'epic-creation-test', name: 'Epic Creation Test') }
  let!(:user) { setup_admin_user(login: 'epic_creator') }

  before(:each) do
    # 既存データなし（Epicボタンのみ表示）
  end

  describe 'Epic Creation Flow' do
    it 'creates a new Epic via Add Epic button' do
      login_as(user)
      goto_kanban(project)

      # グリッドヘッダーが表示されることを確認
      expect_text_visible('Epic')
      expect_text_visible('Feature')

      # ✅ 抽象化ヘルパー使用（将来のカスタムダイアログ対応済み）
      create_epic_via_ui('New Test Epic')

      # 作成されたEpicが表示されることを確認
      expect_text_visible('New Test Epic')

      puts "\n✅ Epic Creation E2E Test Passed"
    end

    it 'cancels Epic creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      # ✅ 抽象化ヘルパー使用（キャンセル操作）
      cancel_item_creation_via_ui('epic')

      # Epicが作成されていないことを確認
      epic_cells = @playwright_page.query_selector_all('.epic-cell')
      expect(epic_cells.length).to eq(0)

      puts "\n✅ Epic Creation Cancel Test Passed"
    end
  end
end
