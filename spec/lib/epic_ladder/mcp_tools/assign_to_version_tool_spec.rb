# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::AssignToVersionTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  # バージョンに期日を設定（日付自動計算テスト用）
  let(:version) { create(:version, project: project, name: 'Version 1.0', effective_date: Date.current + 30.days) }
  let(:earlier_version) { create(:version, project: project, name: 'Version 0.9', effective_date: Date.current + 15.days) }
  let(:user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'UserStory') }

  before do
    member # ensure member exists
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
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

      it 'assigns issue and its children to version with dates' do
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

        # 子チケットもVersionと日付が設定されたか確認
        child_task.reload
        expect(child_task.fixed_version).to eq(version)
        expect(child_task.due_date).to eq(version.effective_date)
      end

      it 'sets start_date and due_date based on version effective_date' do
        # 直前のバージョンを作成（開始日の計算に使用）
        earlier_version # create earlier version

        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['dates']).to be_present
        expect(response_text['dates']['due_date']).to eq(version.effective_date.to_s)
        expect(response_text['dates']['start_date']).to eq(earlier_version.effective_date.to_s)

        # 実際のIssueにも日付が設定されているか確認
        user_story.reload
        expect(user_story.due_date).to eq(version.effective_date)
        expect(user_story.start_date).to eq(earlier_version.effective_date)
      end

      it 'does not propagate to children when propagate_to_children is false' do
        child_task = create(:issue, project: project, tracker: task_tracker, parent_issue_id: user_story.id)
        original_version = child_task.fixed_version

        result = described_class.call(
          issue_id: user_story.id.to_s,
          version_id: version.id.to_s,
          propagate_to_children: false,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['updated_children_count']).to eq(0)

        # 子チケットは更新されていないことを確認
        child_task.reload
        expect(child_task.fixed_version).to eq(original_version)
      end
    end

    context 'with update_parent option' do
      let(:feature) { create(:issue, project: project, tracker: feature_tracker, subject: 'Feature') }
      let(:user_story_with_parent) do
        create(:issue, project: project, tracker: user_story_tracker, subject: 'UserStory', parent_issue_id: feature.id)
      end
      let(:task) do
        create(:issue, project: project, tracker: task_tracker, subject: 'Task', parent_issue_id: user_story_with_parent.id)
      end

      it 'updates parent and siblings when update_parent is true and parent is UserStory' do
        # UserStory配下のTaskを更新するケース
        sibling_task = create(:issue, project: project, tracker: task_tracker, subject: 'Sibling Task', parent_issue_id: user_story_with_parent.id)

        result = described_class.call(
          issue_id: task.id.to_s,
          version_id: version.id.to_s,
          update_parent: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        # 親UserStoryも更新されたか確認
        user_story_with_parent.reload
        expect(user_story_with_parent.fixed_version).to eq(version)

        # 兄弟Taskも更新されたか確認
        sibling_task.reload
        expect(sibling_task.fixed_version).to eq(version)
      end

      it 'skips parent update when parent is Feature (grouping tracker)' do
        # Feature配下のUserStoryを更新するケース
        result = described_class.call(
          issue_id: user_story_with_parent.id.to_s,
          version_id: version.id.to_s,
          update_parent: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['parent_update_skipped']).to be true
        expect(response_text['skip_reason']).to eq('parent_is_grouping_tracker')

        # 親Featureは更新されていないことを確認
        feature.reload
        expect(feature.fixed_version).to be_nil
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
    it 'has correct description including date setting' do
      expect(described_class.description).to include('Version')
      expect(described_class.description).to include('UserStory')
      expect(described_class.description).to include('date')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :version_id)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :version_id)
    end

    it 'has optional parameters for parent and children propagation' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:update_parent, :propagate_to_children)
    end
  end
end
