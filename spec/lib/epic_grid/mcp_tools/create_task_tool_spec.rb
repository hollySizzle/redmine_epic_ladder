# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::CreateTaskTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:user_story_tracker) do
    Tracker.create!(
      name: EpicGrid::TrackerHierarchy.tracker_names[:user_story],
      default_status: IssueStatus.first
    )
  end
  let(:parent_user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory') }

  before do
    member # ensure member exists
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates a Task successfully' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'カートのリファクタリング',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['task_id']).to be_present
        expect(response_text['subject']).to be_present

        # Taskが実際に作成されたか確認
        task = Issue.find(response_text['task_id'])
        expect(task.tracker.name).to eq(EpicGrid::TrackerHierarchy.tracker_names[:task])
        expect(task.description).to eq('カートのリファクタリング')
        expect(task.parent).to eq(parent_user_story)
      end

      it 'creates a Task with numeric project_id' do
        result = described_class.call(
          project_id: project.id.to_s,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end

      it 'assigns Task to specified user' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          assigned_to_id: user.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        task = Issue.find(response_text['task_id'])
        expect(task.assigned_to).to eq(user)
      end

      it 'assigns Task to version when version_id provided' do
        version = create(:version, project: project)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          parent_user_story_id: parent_user_story.id.to_s,
          version_id: version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        task = Issue.find(response_text['task_id'])
        expect(task.fixed_version).to eq(version)
      end

      it 'creates Task without parent_user_story_id (auto-inference)' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true
      end
    end

    context 'AUTO_INFER_PARENT environment variable' do
      let!(:matching_user_story) { create(:issue, project: project, tracker: user_story_tracker, subject: 'カート機能改善') }

      it 'auto-infers parent when AUTO_INFER_PARENT=true (default)' do
        result = described_class.call(
          project_id: project.identifier,
          description: 'カートのリファクタリング',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        task = Issue.find(response_text['task_id'])
        expect(task.parent).to eq(matching_user_story)
      end

      it 'does not auto-infer parent when AUTO_INFER_PARENT=false' do
        # 環境変数を一時的に設定
        ClimateControl.modify AUTO_INFER_PARENT: 'false' do
          result = described_class.call(
            project_id: project.identifier,
            description: 'カートのリファクタリング',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])
          expect(response_text['success']).to be true

          task = Issue.find(response_text['task_id'])
          expect(task.parent).to be_nil
        end
      end

      it 'respects AUTO_INFER_THRESHOLD setting' do
        # 確信度が低いケース（閾値未満）
        low_confidence_story = create(:issue, project: project, tracker: user_story_tracker, subject: '別の機能')

        # 閾値を高く設定（0.8 = 80%）
        ClimateControl.modify AUTO_INFER_THRESHOLD: '0.8' do
          result = described_class.call(
            project_id: project.identifier,
            description: 'テストタスク',
            server_context: server_context
          )

          response_text = JSON.parse(result.content.first[:text])
          task = Issue.find(response_text['task_id'])
          # 閾値が高すぎて推論されない
          expect(task.parent).to be_nil
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns error when project not found' do
        result = described_class.call(
          project_id: 'invalid-project',
          description: 'テストタスク',
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
          description: 'テストタスク',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('タスク作成権限がありません')
      end

      it 'returns error when Task tracker not configured' do
        # Taskトラッカーをプロジェクトから削除
        project.trackers.delete(task_tracker)

        result = described_class.call(
          project_id: project.identifier,
          description: 'テストタスク',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('Taskトラッカーが設定されていません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('Task')
      expect(described_class.description).to include('自然言語')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id, :description)
      expect(schema.instance_variable_get(:@required)).to include(:project_id, :description)
    end
  end
end
