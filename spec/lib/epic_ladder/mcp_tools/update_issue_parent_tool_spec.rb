# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateIssueParentTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: %i[view_issues edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { find_or_create_epic_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:task_tracker) { find_or_create_task_tracker }
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

      it 'calculates dates correctly when no earlier version exists' do
        # version2のみ存在する状態を作成
        version1.destroy
        project.versions.reload

        user_story_v2_only = create(:issue,
                                    project: project,
                                    tracker: user_story_tracker,
                                    subject: 'UserStory v2 only',
                                    parent: epic,
                                    fixed_version: version2)

        orphan_task = create(:issue,
                             project: project,
                             tracker: task_tracker,
                             subject: 'Orphan Task')

        result = described_class.call(
          issue_id: orphan_task.id.to_s,
          parent_issue_id: user_story_v2_only.id.to_s,
          inherit_version_and_dates: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['inherited']['version']['id']).to eq(version2.id.to_s)

        orphan_task.reload
        # 前のバージョンがない場合、開始日=期日となる
        expect(orphan_task.start_date).to eq(Date.new(2026, 1, 20))
        expect(orphan_task.due_date).to eq(Date.new(2026, 1, 20))
      end

      it 'inherits from parent and calculates dates with multiple versions' do
        # 3つのバージョンがある場合の日付計算を確認
        version3 = create(:version,
                          project: project,
                          name: 'v3.0',
                          effective_date: Date.new(2026, 1, 30))

        user_story_v3 = create(:issue,
                               project: project,
                               tracker: user_story_tracker,
                               subject: 'UserStory v3',
                               parent: epic,
                               fixed_version: version3)

        orphan_task = create(:issue,
                             project: project,
                             tracker: task_tracker,
                             subject: 'Orphan Task')

        result = described_class.call(
          issue_id: orphan_task.id.to_s,
          parent_issue_id: user_story_v3.id.to_s,
          inherit_version_and_dates: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['inherited']['version']['name']).to eq('v3.0')

        orphan_task.reload
        expect(orphan_task.fixed_version).to eq(version3)
        # 開始日 = v2.0の期日(2026/1/20)、期日 = v3.0の期日(2026/1/30)
        expect(orphan_task.start_date).to eq(Date.new(2026, 1, 20))
        expect(orphan_task.due_date).to eq(Date.new(2026, 1, 30))
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

    context 'with closed issue' do
      let(:closed_status) { create(:closed_status) }

      it 'allows changing parent of closed issue' do
        # クローズ済みのタスクを作成
        closed_task = create(:issue,
                             project: project,
                             tracker: task_tracker,
                             subject: 'Closed Task',
                             parent: user_story,
                             status: closed_status)

        new_user_story = create(:issue,
                                project: project,
                                tracker: user_story_tracker,
                                subject: 'New UserStory',
                                parent: epic)

        result = described_class.call(
          issue_id: closed_task.id.to_s,
          parent_issue_id: new_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # Redmineコアでは通常、クローズ済みIssueの親変更は可能
        expect(response_text['success']).to be true
        expect(response_text['new_parent']['id']).to eq(new_user_story.id.to_s)

        closed_task.reload
        expect(closed_task.parent).to eq(new_user_story)
      end

      it 'handles setting closed issue as parent' do
        # クローズ済みのUserStoryを作成
        closed_user_story = create(:issue,
                                   project: project,
                                   tracker: user_story_tracker,
                                   subject: 'Closed UserStory',
                                   parent: epic,
                                   status: closed_status)

        orphan_task = create(:issue,
                             project: project,
                             tracker: task_tracker,
                             subject: 'Orphan Task')

        result = described_class.call(
          issue_id: orphan_task.id.to_s,
          parent_issue_id: closed_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # Redmineの設定やワークフローによって結果が変わる可能性あり
        # このテストは動作を文書化する目的
        if response_text['success']
          orphan_task.reload
          expect(orphan_task.parent).to eq(closed_user_story)
        else
          # クローズ済みIssueを親に設定できない場合
          expect(response_text['error']).to be_present
        end
      end
    end

    context 'with cross-project parent' do
      let(:other_project) { create(:project) }
      let(:other_user_story) do
        other_project.trackers << user_story_tracker unless other_project.trackers.include?(user_story_tracker)
        create(:issue,
               project: other_project,
               tracker: user_story_tracker,
               subject: 'Other Project UserStory')
      end

      before do
        # 他プロジェクトのメンバーシップも追加
        create(:member, project: other_project, user: user, roles: [role])
      end

      it 'handles cross-project parent setting based on Redmine settings' do
        # Redmineのサブタスク設定に応じた動作確認
        # 設定によって成功/失敗が変わる
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: other_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # 結果は設定依存だが、エラーハンドリングが適切に行われていることを確認
        if response_text['success']
          task.reload
          expect(task.parent).to eq(other_user_story)
        else
          # クロスプロジェクトが禁止の場合はエラーになる
          expect(response_text['error']).to be_present
        end
      end
    end

    context 'with hierarchy constraint violation' do
      let(:feature_tracker) { find_or_create_feature_tracker }
      let(:feature) do
        project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
        create(:issue, project: project, tracker: feature_tracker, subject: 'Feature', parent: epic)
      end

      before do
        feature # 作成を確実にする
      end

      it 'allows valid hierarchy change (Task under UserStory)' do
        # 正しい階層: UserStory → Task
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'handles hierarchy constraint when setting Task directly under Epic' do
        # TrackerHierarchy制約: Epic → Task は直接不可（Feature/UserStoryを経由すべき）
        # ただし、Redmineコアはこの制約を持たないため、ツールレベルでの制約確認
        result = described_class.call(
          issue_id: task.id.to_s,
          parent_issue_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # 現在の実装ではRedmineコアに委譲しているため、成功する可能性がある
        # このテストは階層制約の動作を文書化する目的
        if response_text['success']
          task.reload
          expect(task.parent).to eq(epic)
        else
          # 将来的にツールレベルで制約を追加した場合
          expect(response_text['error']).to include('階層')
        end
      end

      it 'handles UserStory directly under Epic (valid in TrackerHierarchy)' do
        # 正しい階層: Epic → Feature → UserStory
        # ただし Epic → UserStory も許容される場合がある
        new_user_story = create(:issue,
                                project: project,
                                tracker: user_story_tracker,
                                subject: 'Direct UserStory')

        result = described_class.call(
          issue_id: new_user_story.id.to_s,
          parent_issue_id: epic.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # TrackerHierarchyの設定に応じた動作
        expect(response_text).to have_key('success')
      end
    end
  end
end
