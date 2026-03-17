# frozen_string_literal: true

require_relative '../../../rails_helper'

# ============================================================
# 問合せ起票 統合テスト（クリティカルパス）
# ============================================================
#
# PMOワークフローのクリティカルパスを保護するテスト。
# ProjectSetting → Feature検出 → IssueCreationService → DB書き込み
# の一連のフローをエンドツーエンドで検証する。
#
# 対象シナリオ:
# 1. 命名規則による自動検出で問合せ起票
# 2. ProjectSettingで明示指定されたFeatureに問合せ起票
# 3. 設定変更後のFeature切り替え
# 4. Feature削除時のフォールバック動作
# ============================================================
RSpec.describe 'CreateInquiryTool Integration (Critical Path)', type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { find_or_create_epic_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  let(:server_context) { { user: user } }

  before do
    ActiveRecord::Base.connection.schema_cache.clear!
    EpicLadder::ProjectSetting.reset_column_information
    member
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)

    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
      'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
      'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      'mcp_enabled' => '1'
    }
    EpicLadder::TrackerHierarchy.clear_cache!

    setting = EpicLadder::ProjectSetting.for_project(project)
    setting.mcp_enabled = true
    setting.save!
  end

  describe 'シナリオ1: 命名規則による自動検出で問合せ起票' do
    it '「問合せ」FeatureにUserStoryが作成され、DBに永続化される' do
      inquiry_feature = create(:issue, project: project, tracker: feature_tracker, subject: '問合せ')

      result = EpicLadder::McpTools::CreateInquiryTool.call(
        project_id: project.identifier,
        subject: '本番DBのレプリケーション遅延について',
        description: "## 事象\n本番DBのレプリケーション遅延が30秒を超えている。\n\n## 影響\nリードレプリカ参照のAPIレスポンスが古いデータを返す。",
        server_context: server_context
      )

      response = JSON.parse(result.content.first[:text])
      expect(response['success']).to be true

      # DB永続化の検証
      created_issue = Issue.find(response['inquiry_id'])
      expect(created_issue).to be_present
      expect(created_issue.subject).to eq('本番DBのレプリケーション遅延について')
      expect(created_issue.parent).to eq(inquiry_feature)
      expect(created_issue.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:user_story])
      expect(created_issue.author).to eq(user)
      expect(created_issue.project).to eq(project)
      expect(created_issue.description).to include('レプリケーション遅延')

      # レスポンスの整合性
      expect(response['inquiry_feature']['id']).to eq(inquiry_feature.id.to_s)
      expect(response['inquiry_url']).to include("/issues/#{created_issue.id}")
    end
  end

  describe 'シナリオ2: ProjectSettingで明示指定されたFeatureに問合せ起票' do
    it '命名規則に一致しないFeatureでも設定IDで起票できる' do
      # 命名規則に一致しないFeature
      custom_feature = create(:issue, project: project, tracker: feature_tracker, subject: 'PMO受付窓口 2026Q1')

      setting = EpicLadder::ProjectSetting.for_project(project)
      setting.inquiry_feature_id = custom_feature.id
      setting.save!

      result = EpicLadder::McpTools::CreateInquiryTool.call(
        project_id: project.identifier,
        subject: 'CI/CDパイプライン改善の相談',
        server_context: server_context
      )

      response = JSON.parse(result.content.first[:text])
      expect(response['success']).to be true

      created_issue = Issue.find(response['inquiry_id'])
      expect(created_issue.parent).to eq(custom_feature)
      expect(response['inquiry_feature']['subject']).to eq('PMO受付窓口 2026Q1')
    end
  end

  describe 'シナリオ3: 設定変更後のFeature切り替え' do
    it '問合せFeatureを切り替えると新しいFeature配下に起票される' do
      feature_a = create(:issue, project: project, tracker: feature_tracker, subject: '問合せ（旧）')
      feature_b = create(:issue, project: project, tracker: feature_tracker, subject: 'PMO窓口（新）')

      # 最初はfeature_a（命名規則で自動検出）
      result1 = EpicLadder::McpTools::CreateInquiryTool.call(
        project_id: project.identifier,
        subject: '問合せ1件目',
        server_context: server_context
      )
      response1 = JSON.parse(result1.content.first[:text])
      expect(Issue.find(response1['inquiry_id']).parent).to eq(feature_a)

      # feature_bに切り替え
      setting = EpicLadder::ProjectSetting.for_project(project)
      setting.inquiry_feature_id = feature_b.id
      setting.save!

      result2 = EpicLadder::McpTools::CreateInquiryTool.call(
        project_id: project.identifier,
        subject: '問合せ2件目',
        server_context: server_context
      )
      response2 = JSON.parse(result2.content.first[:text])
      expect(Issue.find(response2['inquiry_id']).parent).to eq(feature_b)
    end
  end

  describe 'シナリオ4: Feature削除時のフォールバック' do
    it '設定されたFeatureが削除されても命名規則で自動検出にフォールバックする' do
      deleted_feature = create(:issue, project: project, tracker: feature_tracker, subject: '旧窓口')
      fallback_feature = create(:issue, project: project, tracker: feature_tracker, subject: '問合せ')

      setting = EpicLadder::ProjectSetting.for_project(project)
      setting.inquiry_feature_id = deleted_feature.id
      setting.save!

      # Feature削除をシミュレート（DB直接削除でRedmineコールバック回避）
      Issue.where(id: deleted_feature.id).delete_all

      result = EpicLadder::McpTools::CreateInquiryTool.call(
        project_id: project.identifier,
        subject: '削除後の問合せ',
        server_context: server_context
      )

      response = JSON.parse(result.content.first[:text])
      expect(response['success']).to be true
      expect(Issue.find(response['inquiry_id']).parent).to eq(fallback_feature)
      expect(response['inquiry_feature']['id']).to eq(fallback_feature.id.to_s)
    end
  end

  describe 'シナリオ5: 問合せFeatureが全く存在しない場合' do
    it '明確なエラーメッセージで案内する' do
      # Featureは存在するが「問合せ」を含まない
      create(:issue, project: project, tracker: feature_tracker, subject: 'ログイン機能')

      result = EpicLadder::McpTools::CreateInquiryTool.call(
        project_id: project.identifier,
        subject: 'テスト',
        server_context: server_context
      )

      response = JSON.parse(result.content.first[:text])
      expect(response['success']).to be false
      expect(response['error']).to include('問合せFeatureが見つかりません')
      expect(response['details']['hint']).to include('inquiry_feature_id')
      expect(response['details']['project']).to eq(project.identifier)
    end
  end

  describe 'シナリオ6: 連続起票（同一Feature配下に複数US）' do
    it '同一Feature配下に複数のUserStoryを起票できる' do
      inquiry_feature = create(:issue, project: project, tracker: feature_tracker, subject: '問合せ')

      subjects = ['権限エラーの件', 'ログ消失の件', 'パフォーマンス劣化の件']
      created_ids = subjects.map do |subj|
        result = EpicLadder::McpTools::CreateInquiryTool.call(
          project_id: project.identifier,
          subject: subj,
          server_context: server_context
        )
        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        response['inquiry_id']
      end

      # 全て異なるIDで作成され、同一Feature配下
      expect(created_ids.uniq.size).to eq(3)
      created_ids.each do |id|
        issue = Issue.find(id)
        expect(issue.parent).to eq(inquiry_feature)
      end

      # Featureの子チケット数を確認
      expect(inquiry_feature.reload.children.count).to eq(3)
    end
  end
end
