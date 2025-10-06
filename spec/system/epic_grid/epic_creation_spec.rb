# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Epic作成E2Eテスト
# ============================================================

RSpec.describe 'Epic Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'epic-creation-test', name: 'Epic Creation Test') }
  let!(:user) { setup_admin_user(login: 'epic_creator') }

  before(:each) do
    # 既存データなし（Epicボタンのみ表示）
  end

  # Dialog handler (公式推奨のmethod形式)
  def handle_epic_creation_dialog(dialog)
    puts "✅ Dialog detected: #{dialog.message}"
    expect(dialog.message).to include('Epic名を入力してください')
    dialog.accept('New Test Epic')
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

      # Step 5: Dialogハンドラを先に設定（method形式 - 公式推奨）
      @playwright_page.on('dialog', method(:handle_epic_creation_dialog))

      puts "✅ Step 5: Dialog handler registered"

      # Step 6: ボタンをクリック
      puts "✅ Step 6: About to click button..."
      add_epic_button.click

      puts "✅ Step 7: Button clicked, waiting for Epic to appear"

      # Step 8: 新しいEpicが表示されることを確認（タイムアウトを長めに）
      @playwright_page.wait_for_selector('.epic-cell:has-text("New Test Epic")', timeout: 15000)
      expect_text_visible('New Test Epic')

      puts "\n✅ Epic Creation E2E Test Passed"
    end
  end
end
