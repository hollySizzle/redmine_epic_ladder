# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::ListProjectMembersTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role_developer) do
    Role.find_by(name: 'Developer') ||
      create(:role, name: 'Developer', permissions: [:view_issues, :edit_issues])
  end
  let(:role_manager) do
    Role.find_by(name: 'Manager') ||
      create(:role, name: 'Manager', permissions: [:view_issues, :edit_issues, :manage_versions])
  end
  let(:member) { create(:member, project: project, user: user, roles: [role_developer]) }

  before do
    member # ensure member exists
    # MCP APIを有効化
    EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'lists all members in project' do
        user2 = create(:user)
        create(:member, project: project, user: user2, roles: [role_developer])

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(2)
        expect(response_text['members'].map { |m| m['user_id'] }).to include(user.id.to_s, user2.id.to_s)
      end

      it 'includes member details' do
        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        member_data = response_text['members'].first

        expect(member_data['user_id']).to eq(user.id.to_s)
        expect(member_data['login']).to eq(user.login)
        expect(member_data['name']).to eq(user.name)
        expect(member_data['roles']).to be_an(Array)
        expect(member_data['roles'].first['name']).to eq('Developer')
        expect(member_data['is_active']).to be true
      end

      it 'filters members by role' do
        manager_user = create(:user)
        create(:member, project: project, user: manager_user, roles: [role_manager])

        result = described_class.call(
          project_id: project.identifier,
          role_name: 'Manager',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['members'].first['user_id']).to eq(manager_user.id.to_s)
      end

      it 'limits the number of results' do
        5.times { |i| create(:member, project: project, user: create(:user), roles: [role_developer]) }

        result = described_class.call(
          project_id: project.identifier,
          limit: 3,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(3)
      end

      it 'excludes inactive users' do
        inactive_user = create(:user, status: User::STATUS_LOCKED)
        create(:member, project: project, user: inactive_user, roles: [role_developer])

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        # Only active user should be included
        expect(response_text['members'].map { |m| m['user_id'] }).not_to include(inactive_user.id.to_s)
      end

      it 'includes hint for assignee update' do
        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['hint']).to include('update_issue_assignee')
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
        expect(response_text['error']).to include('プロジェクト閲覧権限がありません')
      end

      it 'returns error when role not found' do
        result = described_class.call(
          project_id: project.identifier,
          role_name: 'NonExistentRole',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('指定されたロールが見つかりません')
      end
    end

    context 'with empty data' do
      it 'returns only active members when all are inactive' do
        # 新規プロジェクトを作成し、ユーザーをメンバーとして追加
        empty_project = create(:project)
        EpicLadder::ProjectSetting.create!(project: empty_project, mcp_enabled: true)
        create(:member, project: empty_project, user: user, roles: [role_developer])

        # このユーザー以外にinactiveユーザーのみがいる場合
        inactive_user = create(:user, status: User::STATUS_LOCKED)
        create(:member, project: empty_project, user: inactive_user, roles: [role_developer])

        result = described_class.call(
          project_id: empty_project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        # activeなユーザー（自分自身）のみが返される
        expect(response_text['members'].map { |m| m['user_id'] }).to include(user.id.to_s)
        expect(response_text['members'].map { |m| m['user_id'] }).not_to include(inactive_user.id.to_s)
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('member')
    end

    it 'has input schema with optional parameters' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      expect(schema.properties).to include(:role_name)
      expect(schema.properties).to include(:limit)
    end
  end
end
