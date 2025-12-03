# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateIssueParentTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: %i[view_issues edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:epic],
      default_status: IssueStatus.first
    )
  end
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
  let(:epic) { create(:issue, project: project, tracker: epic_tracker, subject: 'Epic') }
  let(:user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'UserStory', parent: epic) }
  let(:task) { create(:issue, project: project, tracker: task_tracker, subject: 'Task', parent: user_story) }

  before do
    member
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'changes parent issue successfully' do
        new_user_story = create(:issue, project: project, tracker: user_story_tracker, subject: 'New UserStory', parent: epic)

        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: new_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['old_parent']['id']).to eq(user_story.id.to_s)
        expect(response_text['new_parent']['id']).to eq(new_user_story.id.to_s)

        task.reload
        expect(task.parent).to eq(new_user_story)
      end

      it 'removes parent when parent_issue_id is null' do
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: 'null',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['old_parent']['id']).to eq(user_story.id.to_s)
        expect(response_text['new_parent']).to be_nil

        task.reload
        expect(task.parent).to be_nil
      end

      it 'removes parent when parent_issue_id is empty' do
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: '',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_parent']).to be_nil

        task.reload
        expect(task.parent).to be_nil
      end

      it 'sets parent for orphan issue' do
        orphan_task = create(:issue, project: project, tracker: task_tracker, subject: 'Orphan Task')

        result = described_class.call(
          issue_id: orphan_task.id.to_s,
          parent_issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['old_parent']).to be_nil
        expect(response_text['new_parent']['id']).to eq(user_story.id.to_s)

        orphan_task.reload
        expect(orphan_task.parent).to eq(user_story)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          parent_issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when parent issue not found' do
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親チケットが見つかりません')
      end

      it 'returns error when trying to set self as parent' do
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: task.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('自分自身を親チケットに指定することはできません')
      end

      it 'returns error when circular reference detected' do
        # task の子を作成
        child_task = create(:issue, project: project, tracker: task_tracker, subject: 'Child Task', parent: task)

        # task の親を child_task にしようとする（循環参照）
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: child_task.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('循環参照')
      end
    end

    context 'without permission' do
      let(:role_without_permission) { create(:role, permissions: [:view_issues]) }
      let(:member_without_permission) do
        create(:member, project: project, user: user, roles: [role_without_permission])
      end

      before do
        member.destroy
        member_without_permission
      end

      it 'returns permission error' do
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('権限がありません')
      end
    end
  end
end
