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

      # Step 3: グリッドヘッダーが表示されることを確認
      expect_text_visible('Epic')
      expect_text_visible('Feature')

      # Step 4: "Add Epic" ボタンを見つける（明示的待機）
      add_epic_button = @playwright_page.wait_for_selector('button[data-add-button="epic"]', state: 'visible', timeout: 10000)
      expect(add_epic_button).not_to be_nil, 'Add Epic button not found'

      # Step 5: Dialogリスナーを設定（クリック前に設定）
      @playwright_page.on('dialog', ->(dialog) {
        expect(dialog.message).to include('Epic名を入力してください')
        dialog.accept('New Test Epic')
      })

      # Step 6: ボタンをクリック
      add_epic_button.click

      # Step 7: 新しいEpicが表示されることを確認
      @playwright_page.wait_for_selector('.epic-cell >> text="New Test Epic"', timeout: 10000)
      expect_text_visible('New Test Epic')

      puts "\n✅ Epic Creation E2E Test Passed"
    end

    it 'cancels Epic creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      add_epic_button = @playwright_page.wait_for_selector('button[data-add-button="epic"]', state: 'visible', timeout: 10000)
      expect(add_epic_button).not_to be_nil

      # Dialogリスナーを設定（キャンセル）
      @playwright_page.on('dialog', ->(dialog) {
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
