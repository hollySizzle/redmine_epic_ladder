# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# Feature作成E2Eテスト
# ============================================================
#
# テスト対象:
# - 各Epic内の「+ Add Feature」ボタンをクリック
# - プロンプトにFeature名を入力
# - 新しいFeatureが作成され、グリッドに表示される
#
# 参考: spec/system/epic_grid/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Feature Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'feature-creation-test', name: 'Feature Creation Test') }
  let!(:user) { setup_admin_user(login: 'feature_creator') }

  before(:each) do
    # Epicを1つ作成
    epic_tracker = project.trackers.find { |t| t.name == EpicGridTestConfig::TRACKER_NAMES[:epic] }
    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic for Feature')
  end

  describe 'Feature Creation Flow' do
    it 'creates a new Feature via Add Feature button' do
      # Step 1: ログイン
      login_as(user)

      # Step 2: カンバンページに移動
      goto_kanban(project)

      # Step 3: Epicが表示されることを確認
      expect_text_visible('Test Epic for Feature')

      # Step 4: "Add Feature" ボタンを見つける（Epic内、明示的待機）
      @playwright_page.wait_for_selector('.epic-cell button[data-add-button="feature"]', timeout: 10000)
      add_feature_button = @playwright_page.query_selector('.epic-cell button[data-add-button="feature"]')
      expect(add_feature_button).not_to be_nil, 'Add Feature button not found'

      # Step 5: ボタンをクリック（プロンプト対応）
      @playwright_page.once('dialog', ->(dialog) {
        expect(dialog.message).to include('Feature名を入力してください')
        dialog.accept('New Test Feature')
      })

      add_feature_button.click

      # Step 6: 新しいFeatureが表示されることを確認
      @playwright_page.wait_for_selector('.feature-cell >> text="New Test Feature"', timeout: 10000)
      expect_text_visible('New Test Feature')

      puts "\n✅ Feature Creation E2E Test Passed"
    end

    it 'cancels Feature creation when prompt is dismissed' do
      login_as(user)
      goto_kanban(project)

      @playwright_page.wait_for_selector('.epic-cell button[data-add-button="feature"]', timeout: 10000)
      add_feature_button = @playwright_page.query_selector('.epic-cell button[data-add-button="feature"]')
      expect(add_feature_button).not_to be_nil

      # プロンプトをキャンセル
      @playwright_page.once('dialog', ->(dialog) {
        dialog.dismiss
      })

      add_feature_button.click

      # Featureが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Test Feature')

      puts "\n✅ Feature Creation Cancel Test Passed"
    end
  end
end
