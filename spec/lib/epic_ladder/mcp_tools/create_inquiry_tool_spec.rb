# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateInquiryTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { find_or_create_epic_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  let(:inquiry_feature) { create(:issue, project: project, tracker: feature_tracker, subject: '問合せ') }

  before do
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

  describe '.call' do
    let(:server_context) { { user: user } }

    context '問合せFeatureが存在する場合' do
      before { inquiry_feature }

      it '問合せFeature配下にUserStoryを作成する' do
        result = described_class.call(
          project_id: project.identifier,
          subject: '本番ログが消えている件',
          description: '本番環境のログが3/15以降消失している。原因調査を依頼したい。',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])

        expect(response['success']).to be true
        expect(response['inquiry_id']).to be_present
        expect(response['subject']).to eq('本番ログが消えている件')
        expect(response['inquiry_feature']['id']).to eq(inquiry_feature.id.to_s)
        expect(response['inquiry_feature']['subject']).to eq('問合せ')

        issue = Issue.find(response['inquiry_id'])
        expect(issue.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:user_story])
        expect(issue.parent).to eq(inquiry_feature)
        expect(issue.description).to include('本番環境のログ')
      end

      it 'parent_feature_idの指定が不要' do
        result = described_class.call(
          project_id: project.identifier,
          subject: '権限エラーの件',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        expect(response['inquiry_feature']['id']).to eq(inquiry_feature.id.to_s)
      end

      it '担当者を指定できる' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テスト問合せ',
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        issue = Issue.find(response['inquiry_id'])
        expect(issue.assigned_to).to eq(user)
      end

      it 'DEFAULT_PROJECTからプロジェクトを解決する' do
        context_with_default = { user: user, default_project: project.identifier }

        result = described_class.call(
          subject: 'デフォルトプロジェクトで起票',
          server_context: context_with_default
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
      end
    end

    context '問合せFeatureの検出パターン' do
      it '「問合せ」を含むFeatureを検出する' do
        create(:issue, project: project, tracker: feature_tracker, subject: 'PMO問合せ窓口')

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テスト',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        expect(response['inquiry_feature']['subject']).to eq('PMO問合せ窓口')
      end

      it '「問い合わせ」を含むFeatureも検出する' do
        create(:issue, project: project, tracker: feature_tracker, subject: 'お問い合わせ')

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テスト',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        expect(response['inquiry_feature']['subject']).to eq('お問い合わせ')
      end

      it '複数Featureがある場合はID昇順で最初のものを使用する' do
        first = create(:issue, project: project, tracker: feature_tracker, subject: '問合せ（メイン）')
        create(:issue, project: project, tracker: feature_tracker, subject: '問合せ（サブ）')

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テスト',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['inquiry_feature']['id']).to eq(first.id.to_s)
      end
    end

    context '問合せFeatureが存在しない場合' do
      it 'エラーを返しFeature作成を案内する' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テスト問合せ',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('問合せFeatureが見つかりません')
        expect(response['details']['hint']).to include('問合せ')
      end
    end

    context 'エラーケース' do
      before { inquiry_feature }

      it 'プロジェクトが見つからない場合エラーを返す' do
        result = described_class.call(
          project_id: 'nonexistent',
          subject: 'テスト',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('プロジェクトが見つかりません')
      end

      it 'プロジェクトIDが未指定でDEFAULT_PROJECTもない場合エラーを返す' do
        result = described_class.call(
          subject: 'テスト',
          server_context: { user: user }
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('プロジェクトIDが指定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('inquiry')
      expect(described_class.description).to include('問合せ')
    end

    it 'does not require parent_feature_id' do
      schema = described_class.input_schema
      required = schema.instance_variable_get(:@required)
      expect(required).to include(:subject)
      expect(required).not_to include(:parent_feature_id)
    end
  end
end
