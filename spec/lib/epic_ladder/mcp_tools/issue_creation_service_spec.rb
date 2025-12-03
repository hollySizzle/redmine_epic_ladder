# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::IssueCreationService do
  let(:user) { create(:user, admin: true) }
  let(:project) { create(:project) }
  let(:server_context) { { user: user } }

  # 既存のファクトリーを使用
  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }
  let(:bug_tracker) { create(:bug_tracker) }
  let(:test_tracker) { create(:test_tracker) }

  before do
    # プラグイン設定（テスト用トラッカー名を設定）
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:epic],
      'feature_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:feature],
      'user_story_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:user_story],
      'task_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:task],
      'bug_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:bug],
      'test_tracker' => EpicLadderTestConfig::TRACKER_NAMES[:test],
      'mcp_enabled' => '1'
    }
    EpicLadder::TrackerHierarchy.clear_cache!

    # プロジェクトにトラッカーを追加
    project.trackers = [epic_tracker, feature_tracker, user_story_tracker, task_tracker, bug_tracker, test_tracker]
    project.save!

    # MCP許可設定
    setting = EpicLadder::ProjectSetting.for_project(project)
    setting.mcp_enabled = true
    setting.save!

    User.current = user
  end

  describe '#create_issue with hierarchy validation' do
    subject(:service) { described_class.new(server_context: server_context) }

    context 'valid hierarchy' do
      let(:epic) { create(:epic, project: project, author: user) }
      let(:feature) { create(:feature, project: project, author: user, parent: epic) }
      let(:user_story) { create(:user_story, project: project, author: user, parent: feature) }

      it 'allows creating Feature under Epic' do
        result = service.create_issue(
          tracker_type: :feature,
          project_id: project.identifier,
          subject: 'Test Feature',
          description: 'Test description',
          parent_issue_id: epic.id.to_s
        )

        expect(result[:success]).to be true
        expect(result[:tracker]).to eq EpicLadderTestConfig::TRACKER_NAMES[:feature]
      end

      it 'allows creating UserStory under Feature' do
        result = service.create_issue(
          tracker_type: :user_story,
          project_id: project.identifier,
          subject: 'Test UserStory',
          description: 'Test description',
          parent_issue_id: feature.id.to_s
        )

        expect(result[:success]).to be true
        expect(result[:tracker]).to eq EpicLadderTestConfig::TRACKER_NAMES[:user_story]
      end

      it 'allows creating Task under UserStory' do
        result = service.create_issue(
          tracker_type: :task,
          project_id: project.identifier,
          subject: 'Test Task',
          description: 'Test description',
          parent_issue_id: user_story.id.to_s
        )

        expect(result[:success]).to be true
        expect(result[:tracker]).to eq EpicLadderTestConfig::TRACKER_NAMES[:task]
      end

      it 'allows creating Bug under UserStory' do
        result = service.create_issue(
          tracker_type: :bug,
          project_id: project.identifier,
          subject: 'Test Bug',
          description: 'Test description',
          parent_issue_id: user_story.id.to_s
        )

        expect(result[:success]).to be true
        expect(result[:tracker]).to eq EpicLadderTestConfig::TRACKER_NAMES[:bug]
      end

      it 'allows creating Test under UserStory' do
        result = service.create_issue(
          tracker_type: :test,
          project_id: project.identifier,
          subject: 'Test Test',
          description: 'Test description',
          parent_issue_id: user_story.id.to_s
        )

        expect(result[:success]).to be true
        expect(result[:tracker]).to eq EpicLadderTestConfig::TRACKER_NAMES[:test]
      end
    end

    context 'invalid hierarchy (main use case: prevent LLM mistakes)' do
      let(:epic) { create(:epic, project: project, author: user) }
      let(:feature) { create(:feature, project: project, author: user, parent: epic) }
      let(:user_story) { create(:user_story, project: project, author: user, parent: feature) }
      let(:task) { create(:task, project: project, author: user, parent: user_story) }

      it 'rejects creating UserStory under Task (LLM common mistake)' do
        result = service.create_issue(
          tracker_type: :user_story,
          project_id: project.identifier,
          subject: 'Invalid UserStory',
          description: 'This should fail',
          parent_issue_id: task.id.to_s
        )

        expect(result[:success]).to be false
        expect(result[:error]).to include('階層違反')
        expect(result[:error]).to include(EpicLadderTestConfig::TRACKER_NAMES[:user_story])
        expect(result[:error]).to include(EpicLadderTestConfig::TRACKER_NAMES[:feature])
        expect(result[:details][:actual_parent_type]).to eq EpicLadderTestConfig::TRACKER_NAMES[:task]
        expect(result[:details][:expected_parent_types]).to include(EpicLadderTestConfig::TRACKER_NAMES[:feature])
      end

      it 'rejects creating UserStory under Bug' do
        bug = create(:bug, project: project, author: user, parent: user_story)

        result = service.create_issue(
          tracker_type: :user_story,
          project_id: project.identifier,
          subject: 'Invalid UserStory',
          description: 'This should fail',
          parent_issue_id: bug.id.to_s
        )

        expect(result[:success]).to be false
        expect(result[:error]).to include('階層違反')
        expect(result[:details][:actual_parent_type]).to eq EpicLadderTestConfig::TRACKER_NAMES[:bug]
      end

      it 'rejects creating Feature under UserStory' do
        result = service.create_issue(
          tracker_type: :feature,
          project_id: project.identifier,
          subject: 'Invalid Feature',
          description: 'This should fail',
          parent_issue_id: user_story.id.to_s
        )

        expect(result[:success]).to be false
        expect(result[:error]).to include('階層違反')
        expect(result[:error]).to include(EpicLadderTestConfig::TRACKER_NAMES[:feature])
        expect(result[:error]).to include(EpicLadderTestConfig::TRACKER_NAMES[:epic])
        expect(result[:details][:actual_parent_type]).to eq EpicLadderTestConfig::TRACKER_NAMES[:user_story]
      end

      it 'rejects creating Task under Epic (skipping levels)' do
        result = service.create_issue(
          tracker_type: :task,
          project_id: project.identifier,
          subject: 'Invalid Task',
          description: 'This should fail',
          parent_issue_id: epic.id.to_s
        )

        expect(result[:success]).to be false
        expect(result[:error]).to include('階層違反')
        expect(result[:details][:actual_parent_type]).to eq EpicLadderTestConfig::TRACKER_NAMES[:epic]
        expect(result[:details][:expected_parent_types]).to include(EpicLadderTestConfig::TRACKER_NAMES[:user_story])
      end

      it 'rejects creating Task under Feature (skipping levels)' do
        result = service.create_issue(
          tracker_type: :task,
          project_id: project.identifier,
          subject: 'Invalid Task',
          description: 'This should fail',
          parent_issue_id: feature.id.to_s
        )

        expect(result[:success]).to be false
        expect(result[:error]).to include('階層違反')
        expect(result[:details][:actual_parent_type]).to eq EpicLadderTestConfig::TRACKER_NAMES[:feature]
      end
    end

    context 'error message provides helpful hints for LLM' do
      let(:epic) { create(:epic, project: project, author: user) }
      let(:task) { create(:task, project: project, author: user) }

      it 'includes hint with actual parent info' do
        result = service.create_issue(
          tracker_type: :user_story,
          project_id: project.identifier,
          subject: 'Test',
          description: 'Test',
          parent_issue_id: task.id.to_s
        )

        expect(result[:details][:hint]).to include("チケット##{task.id}")
        expect(result[:details][:hint]).to include(EpicLadderTestConfig::TRACKER_NAMES[:task])
        expect(result[:details][:hint]).to include('正しい親チケットID')
      end

      it 'includes expected parent types in details' do
        result = service.create_issue(
          tracker_type: :task,
          project_id: project.identifier,
          subject: 'Test',
          description: 'Test',
          parent_issue_id: epic.id.to_s
        )

        expect(result[:details][:expected_parent_types]).to eq [EpicLadderTestConfig::TRACKER_NAMES[:user_story]]
        expect(result[:details][:actual_parent_type]).to eq EpicLadderTestConfig::TRACKER_NAMES[:epic]
        expect(result[:details][:parent_issue_id]).to eq epic.id.to_s
      end
    end
  end
end
