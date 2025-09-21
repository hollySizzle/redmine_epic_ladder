# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KanbanController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    User.current = user
    allow(User.current).to receive(:allowed_to?).with(:view_issues, project).and_return(true)
  end

  describe 'GET #index' do
    context '正常なアクセスの場合' do
      before do
        get :index, params: { project_id: project.id }
      end

      it 'ステータス200を返す' do
        expect(response).to have_http_status(:success)
      end

      it '@project_dataが設定される' do
        expect(assigns(:project_data)).to include(
          id: project.id,
          name: project.name,
          identifier: project.identifier
        )
      end

      it '@current_user_dataが設定される' do
        expect(assigns(:current_user_data)).to include(
          id: user.id,
          name: user.name,
          login: user.login
        )
      end

      it '@react_configが設定される' do
        react_config = assigns(:react_config)
        expect(react_config).to include(
          :projectId,
          :currentUser,
          :permissions,
          :settings
        )
      end
    end

    context 'JSON形式でリクエストした場合' do
      before do
        get :index, params: { project_id: project.id }, format: :json
      end

      it 'JSON形式で応答する' do
        expect(response.content_type).to include('application/json')
      end

      it 'React設定をJSONで返す' do
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'projectId',
          'currentUser',
          'permissions',
          'settings'
        )
      end
    end

    context 'preload=trueパラメータがある場合' do
      before do
        # テスト用のイシューを作成
        create(:issue, project: project, subject: 'Test Issue')
        get :index, params: { project_id: project.id, preload: 'true' }
      end

      it '初期データが構築される' do
        expect(assigns(:initial_kanban_data)).not_to be_nil
        expect(assigns(:initial_kanban_data)).to include(:project, :columns, :issues, :statistics, :metadata)
      end
    end

    context '権限がない場合' do
      before do
        allow(User.current).to receive(:allowed_to?).with(:view_issues, project).and_return(false)
      end

      it 'アクセスが拒否される' do
        expect {
          get :index, params: { project_id: project.id }
        }.to raise_error(ActionController::UrlGenerationError).or(
          have_received(:deny_access)
        )
      end
    end

    context '存在しないプロジェクトの場合' do
      it '404エラーが発生する' do
        expect {
          get :index, params: { project_id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'private methods' do
    let(:controller) { described_class.new }

    before do
      controller.instance_variable_set(:@project, project)
      controller.instance_variable_set(:@project_data, {
        id: project.id,
        name: project.name,
        identifier: project.identifier
      })
    end

    describe '#determine_hierarchy_level' do
      it '各トラッカーの正しい階層レベルを返す' do
        expect(controller.send(:determine_hierarchy_level, 'Epic')).to eq(1)
        expect(controller.send(:determine_hierarchy_level, 'Feature')).to eq(2)
        expect(controller.send(:determine_hierarchy_level, 'UserStory')).to eq(3)
        expect(controller.send(:determine_hierarchy_level, 'Task')).to eq(4)
        expect(controller.send(:determine_hierarchy_level, 'Test')).to eq(4)
        expect(controller.send(:determine_hierarchy_level, 'Bug')).to eq(4)
      end
    end

    describe '#determine_column_for_status' do
      it '正しいカラムを返す' do
        expect(controller.send(:determine_column_for_status, 'New')).to eq('backlog')
        expect(controller.send(:determine_column_for_status, 'Ready')).to eq('ready')
        expect(controller.send(:determine_column_for_status, 'In Progress')).to eq('in_progress')
        expect(controller.send(:determine_column_for_status, 'Review')).to eq('review')
        expect(controller.send(:determine_column_for_status, 'Testing')).to eq('testing')
        expect(controller.send(:determine_column_for_status, 'Resolved')).to eq('done')
      end

      it '未知のステータスの場合はbacklogを返す' do
        expect(controller.send(:determine_column_for_status, 'Unknown Status')).to eq('backlog')
      end
    end

    describe '#gather_user_permissions' do
      it '適切な権限情報を返す' do
        permissions = controller.send(:gather_user_permissions)

        expect(permissions).to include(
          :view_issues,
          :edit_issues,
          :add_issues,
          :delete_issues,
          :manage_versions,
          :view_time_entries
        )

        expect(permissions[:view_issues]).to be_in([true, false])
      end
    end

    describe '#gather_kanban_settings' do
      it '適切な設定情報を返す' do
        settings = controller.send(:gather_kanban_settings)

        expect(settings).to include(:features, :ui)
        expect(settings[:features]).to include(
          :tracker_hierarchy,
          :version_management,
          :auto_generation,
          :state_transition,
          :validation_guard,
          :api_integration
        )
      end
    end
  end

  # Factory定義（実際のプロジェクトではfactory_botを使用）
  def create(factory_name, attributes = {})
    case factory_name
    when :user
      User.create!(
        login: 'test_user',
        firstname: 'Test',
        lastname: 'User',
        mail: 'test@example.com',
        status: User::STATUS_ACTIVE,
        **attributes
      )
    when :project
      Project.create!(
        name: 'Test Project',
        identifier: 'test-project',
        **attributes
      )
    when :issue
      project = attributes.delete(:project)
      Issue.create!(
        project: project,
        tracker: Tracker.first || create_tracker,
        status: IssueStatus.first || create_status,
        subject: 'Test Issue',
        author: user,
        priority: IssuePriority.first || create_priority,
        **attributes
      )
    end
  end

  private

  def create_tracker
    Tracker.create!(name: 'Bug', position: 1)
  end

  def create_status
    IssueStatus.create!(name: 'New', position: 1)
  end

  def create_priority
    IssuePriority.create!(name: 'Normal', position: 1, is_default: true)
  end
end