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

      # Step 4: "Add Epic" ボタンを見つける
      add_epic_button = @playwright_page.wait_for_selector('.add-epic-btn', state: 'visible', timeout: 15000)
      expect(add_epic_button).not_to be_nil, 'Add Epic button not found'

      puts "\n✅ Step 4: Add Epic button found"

      # Step 5: Dialogハンドラを先に設定（クリック前に設定する必要がある）
      @playwright_page.on('dialog') do |dialog|
        puts "✅ Dialog detected: #{dialog.message}"
        expect(dialog.message).to include('Epic名を入力してください')
        dialog.accept('New Test Epic')
      end

      puts "✅ Step 5: Dialog handler registered"

      # Step 6: ボタンをクリック
      add_epic_button.click

      puts "✅ Step 6: Button clicked, waiting for Epic to appear"

      # Step 7: 新しいEpicが表示されることを確認（タイムアウトを長めに）
      @playwright_page.wait_for_selector('.epic-cell:has-text("New Test Epic")', timeout: 15000)
      expect_text_visible('New Test Epic')

      puts "\n✅ Epic Creation E2E Test Passed"
    end

    it 'cancels Epic creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      add_epic_button = @playwright_page.wait_for_selector('.add-epic-btn', state: 'visible', timeout: 15000)
      expect(add_epic_button).not_to be_nil

      # Dialogハンドラを先に設定してキャンセル
      @playwright_page.on('dialog') do |dialog|
        puts "✅ Dialog detected, dismissing..."
        dialog.dismiss
      end

      # ボタンをクリック
      add_epic_button.click
      sleep 1

      # Epicが作成されていないことを確認（エラーがないこと）
      epic_cells = @playwright_page.query_selector_all('.epic-cell')
      expect(epic_cells.length).to eq(0)

      puts "\n✅ Epic Creation Cancel Test Passed"
    end
  end
end
