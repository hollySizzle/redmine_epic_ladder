# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::GetProjectStructureTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:epic],
      default_status: IssueStatus.first
    )
  end
  let(:feature_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:feature],
      default_status: IssueStatus.first
    )
  end
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
  let(:bug_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:bug],
      default_status: IssueStatus.first
    )
  end
  let(:test_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:test],
      default_status: IssueStatus.first
    )
  end
  let(:version) { create(:version, project: project, name: 'Version 1.0') }
  let(:open_status) { IssueStatus.find_or_create_by!(name: 'Open') { |s| s.is_closed = false } }
  let(:closed_status) { IssueStatus.find_or_create_by!(name: 'Closed') { |s| s.is_closed = true } }

  before do
    member # ensure member exists
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    project.trackers << bug_tracker unless project.trackers.include?(bug_tracker)
    project.trackers << test_tracker unless project.trackers.include?(test_tracker)
    open_status
    closed_status
    # MCP APIを有効化
    EpicGrid::ProjectSetting.create!(project: project, mcp_enabled: true)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'returns project structure successfully' do
        epic = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1', status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, subject: 'Feature 1', parent_issue_id: epic.id, status: open_status)
        user_story = create(:issue, project: project, tracker: user_story_tracker, subject: 'Story 1', parent_issue_id: feature.id, status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['structure'].size).to eq(1)

        epic_data = response_text['structure'].first
        expect(epic_data['subject']).to eq('Epic 1')
        expect(epic_data['type']).to eq('Epic')
        expect(epic_data['features'].size).to eq(1)

        feature_data = epic_data['features'].first
        expect(feature_data['subject']).to eq('Feature 1')
        expect(feature_data['type']).to eq('Feature')
        expect(feature_data['user_stories'].size).to eq(1)

        story_data = feature_data['user_stories'].first
        expect(story_data['subject']).to eq('Story 1')
        expect(story_data['type']).to eq('UserStory')
      end

      it 'includes summary statistics' do
        epic = create(:issue, project: project, tracker: epic_tracker)
        feature1 = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)
        feature2 = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)
        create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature1.id)
        create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature1.id)
        create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature2.id)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        summary = response_text['summary']

        expect(summary['total_epics']).to eq(1)
        expect(summary['total_features']).to eq(2)
        expect(summary['total_user_stories']).to eq(3)
      end

      it 'filters by version' do
        epic = create(:issue, project: project, tracker: epic_tracker)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)
        story_with_version = create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id, fixed_version: version)
        create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id) # story without version

        result = described_class.call(
          project_id: project.identifier,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        feature_data = response_text['structure'].first['features'].first

        expect(feature_data['user_stories'].size).to eq(1)
        expect(feature_data['user_stories'].first['id']).to eq(story_with_version.id.to_s)
      end

      it 'filters by status (open)' do
        epic = create(:issue, project: project, tracker: epic_tracker, status: open_status)
        create(:issue, project: project, tracker: epic_tracker, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          status: 'open',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].size).to eq(1)
        expect(response_text['structure'].first['id']).to eq(epic.id.to_s)
      end

      it 'filters by status (closed)' do
        create(:issue, project: project, tracker: epic_tracker, status: open_status)
        closed_epic = create(:issue, project: project, tracker: epic_tracker, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          status: 'closed',
          include_closed: true, # status: 'closed'を使う場合はinclude_closedも必要
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].size).to eq(1)
        expect(response_text['structure'].first['id']).to eq(closed_epic.id.to_s)
      end

      it 'includes user story details' do
        epic = create(:issue, project: project, tracker: epic_tracker)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)
        story = create(:issue,
          project: project,
          tracker: user_story_tracker,
          parent_issue_id: feature.id,
          subject: 'Test Story',
          assigned_to: user,
          fixed_version: version,
          status: open_status
        )

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        expect(story_data['subject']).to eq('Test Story')
        expect(story_data['assigned_to']['id']).to eq(user.id.to_s)
        expect(story_data['version']['name']).to eq('Version 1.0')
        expect(story_data['status']['name']).to eq('Open')
      end

      it 'handles multiple epics with complex hierarchy' do
        epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1')
        epic2 = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 2')

        feature1 = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic1.id)
        feature2 = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic2.id)

        create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature1.id)
        create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature2.id)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].size).to eq(2)
        expect(response_text['summary']['total_epics']).to eq(2)
        expect(response_text['summary']['total_features']).to eq(2)
        expect(response_text['summary']['total_user_stories']).to eq(2)
      end

      it 'includes children (Task/Bug/Test) under UserStory' do
        epic = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1', status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, subject: 'Feature 1', parent_issue_id: epic.id, status: open_status)
        user_story = create(:issue, project: project, tracker: user_story_tracker, subject: 'User Story 1', parent_issue_id: feature.id, status: open_status)

        # Task/Bug/Testを作成
        task1 = create(:issue, project: project, tracker: task_tracker, subject: 'Task 1', parent_issue_id: user_story.id, assigned_to: user, done_ratio: 30, status: open_status)
        task2 = create(:issue, project: project, tracker: task_tracker, subject: 'Task 2', parent_issue_id: user_story.id, done_ratio: 0, status: open_status)
        bug1 = create(:issue, project: project, tracker: bug_tracker, subject: 'Bug 1', parent_issue_id: user_story.id, status: open_status, done_ratio: 50)
        test1 = create(:issue, project: project, tracker: test_tracker, subject: 'Test 1', parent_issue_id: user_story.id, done_ratio: 100, status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          max_depth: 4, # childrenを取得するためにmax_depth: 4を指定
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        # children構造の検証
        expect(story_data['children']).to be_present
        expect(story_data['children']['tasks']).to be_an(Array)
        expect(story_data['children']['bugs']).to be_an(Array)
        expect(story_data['children']['tests']).to be_an(Array)

        # Task検証
        expect(story_data['children']['tasks'].size).to eq(2)
        task_data = story_data['children']['tasks'].find { |t| t['id'] == task1.id.to_s }
        expect(task_data['subject']).to eq('Task 1')
        expect(task_data['assigned_to']['id']).to eq(user.id.to_s)
        expect(task_data['done_ratio']).to eq(30)
        expect(task_data['status']['name']).to be_present

        # Bug検証
        expect(story_data['children']['bugs'].size).to eq(1)
        bug_data = story_data['children']['bugs'].first
        expect(bug_data['subject']).to eq('Bug 1')
        expect(bug_data['done_ratio']).to eq(50)
        expect(bug_data['status']['is_closed']).to be false

        # Test検証
        expect(story_data['children']['tests'].size).to eq(1)
        test_data = story_data['children']['tests'].first
        expect(test_data['subject']).to eq('Test 1')
        expect(test_data['done_ratio']).to eq(100)

        # Summary検証
        summary = response_text['summary']
        expect(summary['total_tasks']).to eq(2)
        expect(summary['total_bugs']).to eq(1)
        expect(summary['total_tests']).to eq(1)
      end

      it 'returns empty children arrays when no child tickets exist' do
        epic = create(:issue, project: project, tracker: epic_tracker)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id)
        user_story = create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        expect(story_data['children']['tasks']).to eq([])
        expect(story_data['children']['bugs']).to eq([])
        expect(story_data['children']['tests']).to eq([])

        summary = response_text['summary']
        expect(summary['total_tasks']).to eq(0)
        expect(summary['total_bugs']).to eq(0)
        expect(summary['total_tests']).to eq(0)
      end
    end

    context 'with max_depth parameter' do
      it 'returns only Epics when max_depth is 1' do
        epic = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1', status: open_status)
        create(:issue, project: project, tracker: feature_tracker, subject: 'Feature 1', parent_issue_id: epic.id, status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          max_depth: 1,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].size).to eq(1)
        expect(response_text['structure'].first['subject']).to eq('Epic 1')
        expect(response_text['structure'].first['features']).to eq([])
      end

      it 'returns Epics and Features when max_depth is 2' do
        epic = create(:issue, project: project, tracker: epic_tracker, subject: 'Epic 1', status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, subject: 'Feature 1', parent_issue_id: epic.id, status: open_status)
        create(:issue, project: project, tracker: user_story_tracker, subject: 'Story 1', parent_issue_id: feature.id, status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          max_depth: 2,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].first['features'].size).to eq(1)
        expect(response_text['structure'].first['features'].first['subject']).to eq('Feature 1')
        expect(response_text['structure'].first['features'].first['user_stories']).to eq([])
      end

      it 'returns up to UserStories when max_depth is 3 (default)' do
        epic = create(:issue, project: project, tracker: epic_tracker, status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id, status: open_status)
        user_story = create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id, status: open_status)
        create(:issue, project: project, tracker: task_tracker, parent_issue_id: user_story.id, status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          # max_depth: 3 is default
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        expect(story_data).to be_present
        # max_depth=3ではchildren(Task/Bug/Test)は空
        expect(story_data['children']['tasks']).to eq([])
      end

      it 'includes all levels including children when max_depth is 4' do
        epic = create(:issue, project: project, tracker: epic_tracker, status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id, status: open_status)
        user_story = create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id, status: open_status)
        task = create(:issue, project: project, tracker: task_tracker, subject: 'Task 1', parent_issue_id: user_story.id, status: open_status)

        result = described_class.call(
          project_id: project.identifier,
          max_depth: 4,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        expect(story_data['children']['tasks'].size).to eq(1)
        expect(story_data['children']['tasks'].first['subject']).to eq('Task 1')
      end
    end

    context 'with include_closed parameter' do
      it 'excludes closed issues by default (include_closed: false)' do
        open_epic = create(:issue, project: project, tracker: epic_tracker, subject: 'Open Epic', status: open_status)
        create(:issue, project: project, tracker: epic_tracker, subject: 'Closed Epic', status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].size).to eq(1)
        expect(response_text['structure'].first['subject']).to eq('Open Epic')
      end

      it 'includes closed issues when include_closed: true' do
        create(:issue, project: project, tracker: epic_tracker, subject: 'Open Epic', status: open_status)
        create(:issue, project: project, tracker: epic_tracker, subject: 'Closed Epic', status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          include_closed: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['structure'].size).to eq(2)
        subjects = response_text['structure'].map { |e| e['subject'] }
        expect(subjects).to include('Open Epic', 'Closed Epic')
      end

      it 'filters closed children (Task/Bug/Test) by default' do
        epic = create(:issue, project: project, tracker: epic_tracker, status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id, status: open_status)
        user_story = create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id, status: open_status)
        create(:issue, project: project, tracker: task_tracker, subject: 'Open Task', parent_issue_id: user_story.id, status: open_status)
        create(:issue, project: project, tracker: task_tracker, subject: 'Closed Task', parent_issue_id: user_story.id, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          max_depth: 4,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        expect(story_data['children']['tasks'].size).to eq(1)
        expect(story_data['children']['tasks'].first['subject']).to eq('Open Task')
      end

      it 'includes closed children when include_closed: true' do
        epic = create(:issue, project: project, tracker: epic_tracker, status: open_status)
        feature = create(:issue, project: project, tracker: feature_tracker, parent_issue_id: epic.id, status: open_status)
        user_story = create(:issue, project: project, tracker: user_story_tracker, parent_issue_id: feature.id, status: open_status)
        create(:issue, project: project, tracker: task_tracker, subject: 'Open Task', parent_issue_id: user_story.id, status: open_status)
        create(:issue, project: project, tracker: task_tracker, subject: 'Closed Task', parent_issue_id: user_story.id, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          max_depth: 4,
          include_closed: true,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        story_data = response_text['structure'].first['features'].first['user_stories'].first

        expect(story_data['children']['tasks'].size).to eq(2)
        subjects = story_data['children']['tasks'].map { |t| t['subject'] }
        expect(subjects).to include('Open Task', 'Closed Task')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
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
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット閲覧権限がありません')
      end

      it 'returns error when Epic tracker not configured' do
        # Epicトラッカーを削除
        Tracker.where(name: EpicGrid::TrackerHierarchy.tracker_names[:epic]).destroy_all

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Epic階層のトラッカーが設定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('プロジェクト')
      expect(described_class.description).to include('構造')
      expect(described_class.description).to include('Epic階層')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      expect(schema.properties).to include(:max_depth)
      expect(schema.properties).to include(:include_closed)
      # project_idは任意（DEFAULT_PROJECTフォールバックあり）
      expect(schema.instance_variable_get(:@required)).to eq([])
    end
  end
end
