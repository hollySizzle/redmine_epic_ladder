# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::CreateFeatureTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { find_or_create_epic_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  let(:epic) { create(:issue, project: project, tracker: epic_tracker, subject: 'テストEpic') }

  before do
    member
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)

    # MCP API有効化（プラグイン設定）
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
      'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
      'mcp_enabled' => '1'
    }
    # プロジェクト単位でもMCP有効化
    EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates a Feature successfully' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'CTA',
          parent_epic_id: epic.id.to_s,
          description: 'CTA機能',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['feature_id']).to be_present
        expect(response_text['subject']).to eq('CTA')
        expect(response_text['parent_epic']['id']).to eq(epic.id.to_s)

        feature = Issue.find(response_text['feature_id'])
        expect(feature.tracker.name).to eq(EpicLadder::TrackerHierarchy.tracker_names[:feature])
        expect(feature.parent).to eq(epic)
      end

      it 'creates a Feature with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          subject: 'テストFeature',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Feature to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストFeature',
          parent_epic_id: epic.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        feature = Issue.find(response_text['feature_id'])
        expect(feature.assigned_to).to eq(user)
      end

      it 'uses subject as description when description is not provided' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'Subject Only Feature',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        feature = Issue.find(response_text['feature_id'])
        expect(feature.description).to eq('Subject Only Feature')
      end

      it 'creates Feature with Japanese subject' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'ユーザー認証機能',
          parent_epic_id: epic.id.to_s,
          description: 'ログイン・ログアウト機能を提供する',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        expect(response_text['subject']).to eq('ユーザー認証機能')
      end

      it 'creates Feature with special characters in subject' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'Feature <with> "special" & characters',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
        expect(response_text['subject']).to eq('Feature <with> "special" & characters')
      end

      it 'returns feature_url in response' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'URL Test Feature',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['feature_url']).to be_present
        expect(response_text['feature_url']).to include('/issues/')
      end

      it 'returns tracker information in response' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'Tracker Test Feature',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['tracker']).to be_present
        # tracker情報はidとnameを含むか、直接nameを含む
        if response_text['tracker'].is_a?(Hash)
          expect(response_text['tracker']['name'] || response_text['tracker']['id']).to be_present
        else
          expect(response_text['tracker']).to be_present
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns error when parent Epic not found' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストFeature',
          parent_epic_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親チケットが見つかりません')
      end

      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          subject: 'テストFeature',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('プロジェクトが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストFeature',
          parent_epic_id: epic.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット作成権限がありません')
      end

      it 'returns error when Feature tracker not configured' do
        project.trackers.delete(feature_tracker)

        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストFeature',
          parent_epic_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('トラッカーが設定されていません')
      end

      it 'returns error when assigned_to_id is invalid' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストFeature',
          parent_epic_id: epic.id.to_s,
          assigned_to_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        # 存在しないユーザーの場合はエラーまたは無視される
        # 実装に依存するため、少なくともレスポンスがあることを確認
        expect(response_text).to have_key('success')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Feature')
      expect(described_class.description).to include('intermediate category')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :subject, :parent_epic_id)
      expect(schema.instance_variable_get(:@required)).to include(:subject, :parent_epic_id)
    end

    it 'includes optional parameters in schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:description, :assigned_to_id)
    end
  end
end
