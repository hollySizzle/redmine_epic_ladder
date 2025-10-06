# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Version作成E2Eテスト
# ============================================================
#
# テスト対象:
# - グリッド右側の「+ New Version」ボタンをクリック
# - プロンプトにVersion名を入力
# - 新しいVersionが作成され、グリッドヘッダーに表示される
#
# 参考: spec/system/epic_grid/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Version Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'version-creation-test', name: 'Version Creation Test') }
  let!(:user) { setup_admin_user(login: 'version_creator') }

  before(:each) do
    # 既存データなし（Versionボタンのみ表示）
  end

  describe 'Version Creation Flow' do
    it 'creates a new Version via Add Version button' do
      # Step 1: ログイン
      login_as(user)

      # Step 2: カンバンページに移動
      goto_kanban(project)

      # Step 3: グリッドヘッダーが表示されることを確認
      expect_text_visible('Epic')
      expect_text_visible('Feature')

      # Step 4: "New Version" ボタンを見つける（明示的待機）
      add_version_button = @playwright_page.wait_for_selector('button[data-add-button="version"]', state: 'visible', timeout: 10000)
      expect(add_version_button).not_to be_nil, 'Add Version button not found'

      # Step 5: Dialogリスナーを設定（クリック前に設定）
      @playwright_page.on('dialog', ->(dialog) {
        expect(dialog.message).to include('Version名を入力してください')
        dialog.accept('v2.0.0')
      })

      # Step 6: ボタンをクリック
      add_version_button.click

      # Step 7: 新しいVersionがヘッダーに表示されることを確認
      @playwright_page.wait_for_selector('.version-header >> text="v2.0.0"', timeout: 10000)
      expect_text_visible('v2.0.0')

      puts "\n✅ Version Creation E2E Test Passed"
    end

    it 'cancels Version creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      add_version_button = @playwright_page.wait_for_selector('button[data-add-button="version"]', state: 'visible', timeout: 10000)
      expect(add_version_button).not_to be_nil

      # Dialogリスナーを設定（キャンセル）
      @playwright_page.on('dialog', ->(dialog) {
        dialog.dismiss
      })

      add_version_button.click

      # Versionが作成されていないことを確認（エラーがないこと）
      sleep 1
      version_headers = @playwright_page.query_selector_all('.version-header')
      # 初期状態で(未設定)が1つあるはず
      expect(version_headers.length).to eq(1)

      puts "\n✅ Version Creation Cancel Test Passed"
    end
  end
end
