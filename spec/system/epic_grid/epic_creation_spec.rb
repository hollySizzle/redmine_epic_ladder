# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Epic作成E2Eテスト
# ============================================================
#
# テスト対象:
# - グリッド下部の「+ New Epic」ボタンをクリック
# - プロンプトにEpic名を入力
# - 新しいEpicが作成され、グリッドに表示される
#
# 参考: spec/system/epic_grid/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Epic Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'epic-creation-test', name: 'Epic Creation Test') }
  let!(:user) { setup_admin_user(login: 'epic_creator') }

  before(:each) do
    # 既存データなし（Epicボタンのみ表示）
  end

  describe 'Epic Creation Flow' do
    it 'creates a new Epic via Add Epic button' do
      # Step 1: ログイン
      login_as(user)

      # Step 2: カンバンページに移動
      goto_kanban(project)

      # Step 3: グリッド構造確認（初期状態）
      verify_kanban_structure

      # Step 4: "Add Epic" ボタンを見つける（明示的待機）
      @playwright_page.wait_for_selector('button[data-add-button="epic"]', timeout: 10000)
      add_epic_button = @playwright_page.query_selector('button[data-add-button="epic"]')
      expect(add_epic_button).not_to be_nil, 'Add Epic button not found'

      # Step 5: ボタンをクリック（プロンプト対応）
      @playwright_page.once('dialog', ->(dialog) {
        expect(dialog.message).to include('Epic名を入力してください')
        dialog.accept('New Test Epic')
      })

      add_epic_button.click

      # Step 6: 新しいEpicが表示されることを確認
      @playwright_page.wait_for_selector('.epic-cell >> text="New Test Epic"', timeout: 10000)
      expect_text_visible('New Test Epic')

      puts "\n✅ Epic Creation E2E Test Passed"
    end

    it 'cancels Epic creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      @playwright_page.wait_for_selector('button[data-add-button="epic"]', timeout: 10000)
      add_epic_button = @playwright_page.query_selector('button[data-add-button="epic"]')
      expect(add_epic_button).not_to be_nil

      # プロンプトをキャンセル
      @playwright_page.once('dialog', ->(dialog) {
        dialog.dismiss
      })

      add_epic_button.click

      # Epicが作成されていないことを確認（エラーがないこと）
      sleep 1
      epic_cells = @playwright_page.query_selector_all('.epic-cell')
      expect(epic_cells.length).to eq(0)

      puts "\n✅ Epic Creation Cancel Test Passed"
    end
  end
end
