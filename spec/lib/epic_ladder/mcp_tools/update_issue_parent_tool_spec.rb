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

    context 'with inherit_version_and_dates option' do
      let(:version1) do
        create(:version, project: project, name: 'v1.0', effective_date: Date.new(2026, 1, 10))
      end
      let(:version2) do
        create(:version, project: project, name: 'v2.0', effective_date: Date.new(2026, 1, 20))
      end
      let(:user_story_with_version) do
        create(:issue,
               project: project,
               tracker: user_story_tracker,
               subject: 'UserStory with Version',
               parent: epic,
               fixed_version: version2,
               start_date: Date.new(2026, 1, 11),
               due_date: Date.new(2026, 1, 20))
      end
      let(:task_with_version) do
        create(:issue,
               project: project,
               tracker: task_tracker,
               subject: 'Task with Version',
               parent: user_story,
               fixed_version: version1,
               start_date: Date.new(2026, 1, 1),
               due_date: Date.new(2026, 1, 10))
      end

      before do
        version1
        version2
      end

      it 'inherits version and dates from new parent when inherit_version_and_dates is true' do
        result = described_class.call(
          issue_id: task_with_version.id.to_s,
          parent_issue_id: user_story_with_version.id.to_s,
          inherit_version_and_dates: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['inherited']).not_to be_nil
        expect(response_text['inherited']['version']['id']).to eq(version2.id.to_s)
        expect(response_text['inherited']['version']['name']).to eq('v2.0')

        task_with_version.reload
        expect(task_with_version.parent).to eq(user_story_with_version)
        expect(task_with_version.fixed_version).to eq(version2)
        # VersionDateManagerによる日付計算（version1の期日が開始日、version2の期日が終了日）
        expect(task_with_version.start_date).to eq(Date.new(2026, 1, 10))
        expect(task_with_version.due_date).to eq(Date.new(2026, 1, 20))
      end

      it 'does not inherit version when inherit_version_and_dates is false (default)' do
        result = described_class.call(
          issue_id: task_with_version.id.to_s,
          parent_issue_id: user_story_with_version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['inherited']).to be_nil

        task_with_version.reload
        expect(task_with_version.parent).to eq(user_story_with_version)
        # バージョンと日付は変更されない
        expect(task_with_version.fixed_version).to eq(version1)
        expect(task_with_version.start_date).to eq(Date.new(2026, 1, 1))
        expect(task_with_version.due_date).to eq(Date.new(2026, 1, 10))
      end

      it 'skips inheritance when new parent has no version' do
        user_story_no_version = create(:issue,
                                       project: project,
                                       tracker: user_story_tracker,
                                       subject: 'UserStory without Version',
                                       parent: epic)

        result = described_class.call(
          issue_id: task_with_version.id.to_s,
          parent_issue_id: user_story_no_version.id.to_s,
          inherit_version_and_dates: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['inherited']['skipped']).to be true
        expect(response_text['inherited']['reason']).to include('バージョンが設定されていません')

        task_with_version.reload
        expect(task_with_version.parent).to eq(user_story_no_version)
        # バージョンは変更されない
        expect(task_with_version.fixed_version).to eq(version1)
      end

      it 'does not inherit when removing parent' do
        result = described_class.call(
          issue_id: task_with_version.id.to_s,
          parent_issue_id: 'null',
          inherit_version_and_dates: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['inherited']).to be_nil

        task_with_version.reload
        expect(task_with_version.parent).to be_nil
        # バージョンは変更されない
        expect(task_with_version.fixed_version).to eq(version1)
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
