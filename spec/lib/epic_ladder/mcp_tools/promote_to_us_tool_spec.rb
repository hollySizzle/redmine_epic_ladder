# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::PromoteToUsTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  let(:epic_tracker) { find_or_create_epic_tracker }
  let(:feature_tracker) { find_or_create_feature_tracker }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:bug_tracker) { find_or_create_bug_tracker }
  let(:test_tracker) { find_or_create_test_tracker }

  let(:version) { create(:version, project: project) }

  let(:epic) { create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic') }
  let(:feature) { create(:issue, project: project, tracker: feature_tracker, subject: 'Test Feature', parent: epic) }
  let(:parent_us) { create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent US', parent: feature, fixed_version: version) }
  let(:task) do
    create(:issue, project: project, tracker: task_tracker, subject: 'Target Task', parent: parent_us,
                   fixed_version: version, priority: IssuePriority.default || IssuePriority.first,
                   start_date: Date.new(2025, 10, 1), due_date: Date.new(2025, 10, 5))
  end

  before do
    member
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    project.trackers << bug_tracker unless project.trackers.include?(bug_tracker)
    project.trackers << test_tracker unless project.trackers.include?(test_tracker)
    Setting.plugin_redmine_epic_ladder = {
      'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
      'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
      'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
      'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
      'bug_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:bug],
      'test_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:test],
      'mcp_enabled' => '1'
    }
    EpicLadder::TrackerHierarchy.clear_cache!
    setting = EpicLadder::ProjectSetting.for_project(project)
    setting.mcp_enabled = true
    setting.save!
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context '正常系: 昇格成功' do
      it '新USが作成され、成功レスポンスを返す' do
        result = described_class.call(
          issue_id: task.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be true
        expect(response['new_user_story']).to be_present
        expect(response['new_user_story']['id']).to be_present
        expect(response['new_user_story']['subject']).to eq('Target Task')
        expect(response['original_issue']['id']).to eq(task.id.to_s)
        expect(response['original_parent_us']['id']).to eq(parent_us.id.to_s)
        expect(response['relation_id']).to be_present
      end

      it '元issueの親が新USになる' do
        result = described_class.call(
          issue_id: task.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_us_id = response['new_user_story']['id'].to_i

        task.reload
        expect(task.parent_id).to eq(new_us_id)
        # トラッカーは変わらない
        expect(task.tracker).to eq(task_tracker)
      end

      it '新USがFeature配下に作成される' do
        result = described_class.call(
          issue_id: task.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_us = Issue.find(response['new_user_story']['id'])
        expect(new_us.parent_id).to eq(feature.id)
        expect(new_us.tracker).to eq(user_story_tracker)
      end

      it '元の親USと新USがrelates関連で紐づく' do
        described_class.call(
          issue_id: task.id.to_s,
          server_context: server_context
        )

        task.reload
        new_us = task.parent
        relation = IssueRelation.find_by(issue_from: parent_us, issue_to: new_us)
        expect(relation).to be_present
        expect(relation.relation_type).to eq('relates')
      end
    end

    context 'target_feature_id指定' do
      let(:another_feature) { create(:issue, project: project, tracker: feature_tracker, subject: 'Another Feature', parent: epic) }

      it '指定Featureの下にUS作成される' do
        result = described_class.call(
          issue_id: task.id.to_s,
          target_feature_id: another_feature.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        new_us = Issue.find(response['new_user_story']['id'])
        expect(new_us.parent_id).to eq(another_feature.id)
      end
    end

    context 'us_subject指定' do
      it '指定件名でUS作成される' do
        result = described_class.call(
          issue_id: task.id.to_s,
          us_subject: 'カスタムUS件名',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['new_user_story']['subject']).to eq('カスタムUS件名')
      end
    end

    context '権限なし' do
      it 'エラーを返す' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        task # ensure exists

        result = described_class.call(
          issue_id: task.id.to_s,
          server_context: unauthorized_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('権限')
      end
    end

    context '昇格不可（USトラッカー）' do
      let(:us_issue) { create(:issue, project: project, tracker: user_story_tracker, subject: 'US Issue', parent: feature) }

      it 'エラーを返す' do
        result = described_class.call(
          issue_id: us_issue.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to be_present
      end
    end

    context 'チケット不存在' do
      it 'エラーを返す' do
        result = described_class.call(
          issue_id: '999999',
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('見つかりません')
      end
    end

    context 'MCP無効' do
      it 'エラーを返す' do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '0' }

        result = described_class.call(
          issue_id: task.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('MCP API')
      end
    end

    context 'プロジェクトMCP不許可' do
      it 'エラーを返す' do
        setting = EpicLadder::ProjectSetting.for_project(project)
        setting.mcp_enabled = false
        setting.save!

        result = described_class.call(
          issue_id: task.id.to_s,
          server_context: server_context
        )

        response = JSON.parse(result.content.first[:text])
        expect(response['success']).to be false
        expect(response['error']).to include('MCP API')
      end
    end
  end

  describe 'tool metadata' do
    it 'has description containing Promotes' do
      expect(described_class.description).to include('Promotes')
    end

    it 'has issue_id as required in input schema' do
      schema = described_class.input_schema
      required_fields = schema.instance_variable_get(:@required)
      expect(required_fields).to include(:issue_id)
    end
  end
end
