# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::MoveToNextVersionTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:user_story],
      default_status: IssueStatus.first
    )
  end
  let(:task_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:current_version) { create(:version, project: project, name: 'Version 1.0', effective_date: Date.today) }
  let(:next_version) { create(:version, project: project, name: 'Version 2.0', effective_date: Date.today + 30, status: 'open') }
  let(:user_story) { create(:issue, project: project, tracker: user_story_tracker, fixed_version: current_version) }

  before do
    member # ensure member exists
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    current_version
    next_version
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'moves issue to next version successfully' do
        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(user_story.id.to_s)
        expect(response_text['old_version']['id']).to eq(current_version.id.to_s)
        expect(response_text['new_version']['id']).to eq(next_version.id.to_s)

        # Versionが実際に変更されたか確認
        user_story.reload
        expect(user_story.fixed_version).to eq(next_version)
      end

      it 'moves issue and its children to next version' do
        child_task = create(:issue, project: project, tracker: task_tracker, parent_issue_id: user_story.id, fixed_version: current_version)

        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['updated_children_count']).to eq(1)
        expect(response_text['updated_children'].first['id']).to eq(child_task.id.to_s)

        # 子チケットもVersionが変更されたか確認
        child_task.reload
        expect(child_task.fixed_version).to eq(next_version)
      end
    end

    context 'REQUIRE_CONFIRMATION_FOR environment variable' do
      it 'requires confirmation when REQUIRE_CONFIRMATION_FOR includes move_version' do
        ClimateControl.modify REQUIRE_CONFIRMATION_FOR: 'move_version' do
          result = described_class.call(
            issue_id: user_story.id.to_s,
            confirmed: false,
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          # 確認が必要
          expect(response_text['success']).to be false
          expect(response_text['confirmation_required']).to be true
          expect(response_text['confirmation_message']).to be_present
          expect(response_text['operation']).to eq('move_version')

          # Versionは変更されていない
          user_story.reload
          expect(user_story.fixed_version).to eq(current_version)
        end
      end

      it 'executes when confirmed=true' do
        ClimateControl.modify REQUIRE_CONFIRMATION_FOR: 'move_version' do
          result = described_class.call(
            issue_id: user_story.id.to_s,
            confirmed: true,
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          # 実行される
          expect(response_text['success']).to be true
          expect(response_text['old_version']['id']).to eq(current_version.id.to_s)
          expect(response_text['new_version']['id']).to eq(next_version.id.to_s)

          # Versionが変更されている
          user_story.reload
          expect(user_story.fixed_version).to eq(next_version)
        end
      end

      it 'does not require confirmation when REQUIRE_CONFIRMATION_FOR is empty' do
        ClimateControl.modify REQUIRE_CONFIRMATION_FOR: '' do
          result = described_class.call(
            issue_id: user_story.id.to_s,
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])

          # 確認なしで実行される
          expect(response_text['success']).to be true
          user_story.reload
          expect(user_story.fixed_version).to eq(next_version)
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット編集権限がありません')
      end

      it 'returns error when issue has no version' do
        issue_without_version = create(:issue, project: project, tracker: user_story_tracker)

        result = described_class.call(
          issue_id: issue_without_version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットにVersionが設定されていません')
      end

      it 'returns error when next version not found' do
        # 次のVersionがない状態
        next_version.destroy

        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('次のVersionが見つかりません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('次のVersion')
      expect(described_class.description).to include('移動')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id)
    end
  end
end
