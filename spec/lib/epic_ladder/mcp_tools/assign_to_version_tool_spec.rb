# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::AssignToVersionTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      default_status: IssueStatus.first
    )
  end
  let(:task_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:version) { create(:version, project: project, name: 'Version 1.0') }
  let(:user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'UserStory') }

  before do
    member # ensure member exists
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'assigns issue to version successfully' do
        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(user_story.id.to_s)
        expect(response_text['version']['id']).to eq(version.id.to_s)
        expect(response_text['version']['name']).to eq('Version 1.0')

        # Versionが実際に設定されたか確認
        user_story.reload
        expect(user_story.fixed_version).to eq(version)
      end

      it 'assigns issue and its children to version' do
        child_task = create(:issue, project: project, tracker: task_tracker, parent_issue_id: user_story.id)

        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['updated_children_count']).to eq(1)
        expect(response_text['updated_children'].first['id']).to eq(child_task.id.to_s)

        # 子チケットもVersionが設定されたか確認
        child_task.reload
        expect(child_task.fixed_version).to eq(version)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when version not found' do
        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Versionが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット編集権限がありません')
      end

      it 'returns error with assignable versions when version is not assignable' do
        # closedのバージョンを作成（割り当て不可）
        closed_version = create(:version, project: project, name: 'Closed Version', status: 'closed')

        # openのバージョンも作成（割り当て可能）
        open_version1 = create(:version, project: project, name: 'Open Version 1', status: 'open')
        open_version2 = create(:version, project: project, name: 'Open Version 2', status: 'open')

        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: closed_version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # エラーレスポンスの検証
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Version割り当てに失敗しました')

        # エラー詳細の検証
        details = response_text['details']
        expect(details).to be_present
        expect(details['errors']).to include('Target version is not included in the list')

        # リクエストされたバージョン情報
        expect(details['requested_version_id']).to eq(closed_version.id.to_s)
        expect(details['requested_version_name']).to eq('Closed Version')
        expect(details['requested_version_status']).to eq('closed')

        # 割り当て可能なバージョンリストの検証
        assignable_versions = details['assignable_versions']
        expect(assignable_versions).to be_present
        expect(assignable_versions).to be_an(Array)
        expect(details['assignable_version_count']).to eq(2) # open_version1とopen_version2のみ

        # closedバージョンが含まれていないことを確認
        assignable_ids = assignable_versions.map { |v| v['id'] }
        expect(assignable_ids).not_to include(closed_version.id.to_s)

        # openバージョンが含まれていることを確認
        expect(assignable_ids).to include(open_version1.id.to_s, open_version2.id.to_s)

        # バージョン情報の構造を確認
        first_version = assignable_versions.first
        expect(first_version).to include('id', 'name', 'status', 'effective_date', 'project_id')
        expect(first_version['status']).to eq('open')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Version')
      expect(described_class.description).to include('割り当て')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :version_id)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :version_id)
    end
  end
end
