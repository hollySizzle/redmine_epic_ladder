# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# ============================================================
# 📦 Batch Save E2E Test - D&D操作のバッチ保存機能
# ============================================================
#
# このテストは以下の機能を検証します:
#
# 1. UserStoryのD&D移動がローカル変更として記録される
# 2. 保存ボタンが表示され、変更件数が表示される
# 3. 保存ボタンクリックで変更がバックエンドに永続化される
# 4. 破棄ボタンで変更が元に戻る
# 5. ページリロード後も保存された変更が残っている
#
# ============================================================

RSpec.describe 'Batch Save E2E', type: :system, js: true do
  let!(:project) { setup_epic_ladder_project(identifier: 'batch-save-test', name: 'Batch Save Test Project') }
  let!(:user) { setup_admin_user(login: 'batch_save_user') }

  before(:each) do
    # プロジェクトに紐づいているトラッカーを取得
    epic_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:epic] }
    feature_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:feature] }
    user_story_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:user_story] }

    # テストデータ作成
    @version1 = create(:version, project: project, name: 'v1.0.0')
    @version2 = create(:version, project: project, name: 'v2.0.0')

    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1')
    @epic2 = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 2')

    @feature1 = create(:issue, project: project, tracker: feature_tracker, parent: @epic1, subject: 'Feature 1')
    @feature2 = create(:issue, project: project, tracker: feature_tracker, parent: @epic2, subject: 'Feature 2')

    @user_story1 = create(:issue, project: project, tracker: user_story_tracker, parent: @feature1, fixed_version: @version1, subject: 'Story 1')
    @user_story2 = create(:issue, project: project, tracker: user_story_tracker, parent: @feature1, fixed_version: @version1, subject: 'Story 2')
  end

  describe 'UserStory Drag & Drop' do
    # NOTE: このテストはPragmatic Drag and DropとPlaywrightの互換性問題により
    # 現在pendingとしています。
    #
    # 問題点:
    # 1. Pragmatic D&DはブラウザネイティブのD&D APIを使用
    # 2. Playwrightのマウスシミュレーションでは、dropTargetが認識されない
    # 3. Global drop detectedログは出るが、後続のmoveUserStoryCellが呼ばれない
    #
    # 解決策の候補:
    # 1. Playwrightのdrag_and_dropメソッドを使用（データ転送が必要）
    # 2. JavaScript経由でD&Dイベントを直接発火
    # 3. E2Eではなくユニットテストでカバー
    #
    # 関連チケット: #4563
    xit 'should move UserStory with D&D and persist immediately (E2E with real API)' do
      # Note: E2Eテストでは実際のバックエンドAPIを使用するため、MSWモックは無効
      # D&D操作は即座にbatch_update APIを呼び出して保存される

      # Step 1: ログインとページ遷移
      login_as(user)
      goto_kanban(project)

      # Step 2: 初期状態確認
      expect_text_visible('Story 1')
      expect_text_visible('Story 2')
      expect_text_visible('Feature 1')
      expect_text_visible('Feature 2')

      puts "\n✅ Step 1-2: Initial state verified"

      # Step 3: 初期DB状態確認
      @user_story1.reload
      expect(@user_story1.parent_id).to eq(@feature1.id) # Feature1にいる
      expect(@user_story1.fixed_version_id).to eq(@version1.id) # Version1

      puts "✅ Step 3: Initial DB state - Story1 in Feature1/Version1"

      # Step 4: UserStory1をD&Dで移動（Feature1/Version1 → Feature2/Version2）
      target_cell = ".us-cell[data-epic='#{@epic2.id}'][data-feature='#{@feature2.id}'][data-version='#{@version2.id}']"
      drag_user_story_to_cell('Story 1', target_cell)

      puts "✅ Step 4: UserStory dragged to Feature2/Version2 cell"

      # Step 5: D&D後、UIの更新を待つ（バックエンドAPIコール完了待機）
      sleep 2

      # Step 6: DBが即座に更新されていることを確認（E2EではMSW無効なので即座に保存される）
      @user_story1.reload
      expect(@user_story1.parent_id).to eq(@feature2.id) # Feature2に移動済み
      expect(@user_story1.fixed_version_id).to eq(@version2.id) # Version2に移動済み

      puts "✅ Step 5-6: DB updated immediately - Story1 now in Feature2/Version2"

      # Step 7: ページをリロードして永続化を確認
      @playwright_page.reload
      goto_kanban(project)

      # Story 1がFeature 2のセルに表示されている
      target_cell_element = @playwright_page.query_selector(target_cell)
      expect(target_cell_element).not_to be_nil

      # そのセル内にStory 1が存在する
      story_in_target = target_cell_element.query_selector(".user-story:has-text('Story 1')")
      expect(story_in_target).not_to be_nil, "Story 1 should be in Feature2/Version2 cell after reload"

      puts "✅ Step 7: Changes persisted after page reload"
    end

    # 関連チケット: #4563
    xit 'should move UserStory to cell with no version (unassigned)' do
      login_as(user)
      goto_kanban(project)

      # Initial state: Story 1 is in Feature1/Version1
      @user_story1.reload
      expect(@user_story1.parent_id).to eq(@feature1.id)
      expect(@user_story1.fixed_version_id).to eq(@version1.id)

      puts "\n✅ Initial: Story1 in Feature1/Version1"

      # Move to Feature2/(未設定)
      target_cell = ".us-cell[data-epic='#{@epic2.id}'][data-feature='#{@feature2.id}'][data-version='none']"
      drag_user_story_to_cell('Story 1', target_cell)
      sleep 2

      # Verify DB update
      @user_story1.reload
      expect(@user_story1.parent_id).to eq(@feature2.id)
      expect(@user_story1.fixed_version_id).to be_nil # Version unassigned

      puts "✅ Story1 moved to Feature2/(未設定)"
    end

    # 関連チケット: #4563
    xit 'should move multiple UserStories sequentially' do
      login_as(user)
      goto_kanban(project)

      target_cell = ".us-cell[data-epic='#{@epic2.id}'][data-feature='#{@feature2.id}'][data-version='#{@version2.id}']"

      # Move Story 1
      drag_user_story_to_cell('Story 1', target_cell)
      sleep 2

      # Move Story 2
      drag_user_story_to_cell('Story 2', target_cell)
      sleep 2

      puts "\n✅ Two UserStories dragged sequentially"

      # Verify both moved
      @user_story1.reload
      @user_story2.reload

      expect(@user_story1.parent_id).to eq(@feature2.id)
      expect(@user_story1.fixed_version_id).to eq(@version2.id)
      expect(@user_story2.parent_id).to eq(@feature2.id)
      expect(@user_story2.fixed_version_id).to eq(@version2.id)

      puts "✅ Both UserStories moved successfully"
    end
  end
end
