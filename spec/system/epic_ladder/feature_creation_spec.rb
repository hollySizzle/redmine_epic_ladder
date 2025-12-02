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
# 参考: spec/system/epic_ladder/simple_e2e_spec.rb
# ============================================================

RSpec.describe 'Feature Creation E2E', type: :system, js: true do
  let!(:project) { setup_epic_ladder_project(identifier: 'feature-creation-test', name: 'Feature Creation Test') }
  let!(:user) { setup_admin_user(login: 'feature_creator') }

  before(:each) do
    # Epicを1つ作成
    epic_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:epic] }
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

      # Step 4: Featureを作成
      create_feature_via_ui(@epic1.id, 'New Test Feature')

      # Step 5: 新しいFeatureが表示されることを確認
      # wait_for_item_createdで既にウェイトしているので、ここでは単純にチェック
      expect_text_visible('New Test Feature')

      puts "\n✅ Feature作成後のグリッド表示を確認"

      puts "\n✅ Feature Creation E2E Test Passed"
    end

    it 'cancels Feature creation when modal is dismissed' do
      login_as(user)
      goto_kanban(project)

      # キャンセル操作を実行
      cancel_item_creation_via_ui('feature', parent_info: { epic_id: @epic1.id })

      # Featureが作成されていないことを確認
      sleep 1
      expect_text_not_visible('New Test Feature')

      puts "\n✅ Feature Creation Cancel Test Passed"
    end
  end
end
