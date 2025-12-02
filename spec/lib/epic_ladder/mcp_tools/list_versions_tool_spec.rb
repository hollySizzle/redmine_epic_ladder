# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::ListVersionsTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
    # MCP APIを有効化
    EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'lists all open versions in project (default)' do
        open_version = create(:version, project: project, name: 'v1.0', status: 'open')
        closed_version = create(:version, project: project, name: 'v0.9', status: 'closed')

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['versions'].map { |v| v['id'] }).to include(open_version.id.to_s)
        expect(response_text['versions'].map { |v| v['id'] }).not_to include(closed_version.id.to_s)
      end

      it 'lists versions without any issues (important use case)' do
        # チケットが紐づいていないバージョンも取得できること
        empty_version = create(:version, project: project, name: 'v2.0-planned', status: 'open')

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['versions'].map { |v| v['id'] }).to include(empty_version.id.to_s)
        version_data = response_text['versions'].find { |v| v['id'] == empty_version.id.to_s }
        expect(version_data['issues_count']).to eq(0)
      end

      it 'sorts by effective_date ascending by default (nulls last)' do
        v3 = create(:version, project: project, name: 'v3', status: 'open', effective_date: nil)
        v1 = create(:version, project: project, name: 'v1', status: 'open', effective_date: Date.today + 7)
        v2 = create(:version, project: project, name: 'v2', status: 'open', effective_date: Date.today + 30)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        version_ids = response_text['versions'].map { |v| v['id'] }

        # 期日が近い順、NULLは最後
        expect(version_ids).to eq([v1.id.to_s, v2.id.to_s, v3.id.to_s])
      end

      it 'filters versions by status=all' do
        open_version = create(:version, project: project, name: 'v1.0', status: 'open')
        locked_version = create(:version, project: project, name: 'v0.9', status: 'locked')
        closed_version = create(:version, project: project, name: 'v0.8', status: 'closed')

        result = described_class.call(
          project_id: project.identifier,
          status: 'all',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(3)
        version_ids = response_text['versions'].map { |v| v['id'] }
        expect(version_ids).to include(open_version.id.to_s, locked_version.id.to_s, closed_version.id.to_s)
      end

      it 'filters versions by status=locked' do
        create(:version, project: project, name: 'v1.0', status: 'open')
        locked_version = create(:version, project: project, name: 'v0.9', status: 'locked')

        result = described_class.call(
          project_id: project.identifier,
          status: 'locked',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['versions'].first['id']).to eq(locked_version.id.to_s)
      end

      it 'filters versions by status=closed' do
        create(:version, project: project, name: 'v1.0', status: 'open')
        closed_version = create(:version, project: project, name: 'v0.8', status: 'closed')

        result = described_class.call(
          project_id: project.identifier,
          status: 'closed',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(1)
        expect(response_text['versions'].first['id']).to eq(closed_version.id.to_s)
      end

      it 'sorts by effective_date descending' do
        v1 = create(:version, project: project, name: 'v1', status: 'open', effective_date: Date.today + 7)
        v2 = create(:version, project: project, name: 'v2', status: 'open', effective_date: Date.today + 30)
        v3 = create(:version, project: project, name: 'v3', status: 'open', effective_date: nil)

        result = described_class.call(
          project_id: project.identifier,
          sort: 'effective_date_desc',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        version_ids = response_text['versions'].map { |v| v['id'] }

        # 期日が遠い順、NULLは最後
        expect(version_ids).to eq([v2.id.to_s, v1.id.to_s, v3.id.to_s])
      end

      it 'sorts by name ascending' do
        v_beta = create(:version, project: project, name: 'Beta', status: 'open')
        v_alpha = create(:version, project: project, name: 'Alpha', status: 'open')
        v_gamma = create(:version, project: project, name: 'Gamma', status: 'open')

        result = described_class.call(
          project_id: project.identifier,
          sort: 'name_asc',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        version_names = response_text['versions'].map { |v| v['name'] }

        expect(version_names).to eq(%w[Alpha Beta Gamma])
      end

      it 'limits the number of results' do
        5.times { |i| create(:version, project: project, name: "v#{i}", status: 'open') }

        result = described_class.call(
          project_id: project.identifier,
          limit: 3,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['total_count']).to eq(3)
      end

      it 'includes complete version details with issue counts' do
        version = create(:version,
          project: project,
          name: 'v1.0.0',
          description: 'First stable release',
          status: 'open',
          effective_date: Date.today + 14,
          sharing: 'none'
        )

        # チケットを紐づける
        tracker = Tracker.first || create(:tracker)
        project.trackers << tracker unless project.trackers.include?(tracker)
        open_status = IssueStatus.find_or_create_by!(name: 'Open') { |s| s.is_closed = false }
        closed_status = IssueStatus.find_or_create_by!(name: 'Closed') { |s| s.is_closed = true }

        create(:issue, project: project, tracker: tracker, fixed_version: version, status: open_status)
        create(:issue, project: project, tracker: tracker, fixed_version: version, status: open_status)
        create(:issue, project: project, tracker: tracker, fixed_version: version, status: closed_status)

        result = described_class.call(
          project_id: project.identifier,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        version_data = response_text['versions'].first

        expect(version_data['id']).to eq(version.id.to_s)
        expect(version_data['name']).to eq('v1.0.0')
        expect(version_data['description']).to eq('First stable release')
        expect(version_data['status']).to eq('open')
        expect(version_data['effective_date']).to eq((Date.today + 14).iso8601)
        expect(version_data['sharing']).to eq('none')
        expect(version_data['issues_count']).to eq(3)
        expect(version_data['open_issues_count']).to eq(2)
        expect(version_data['closed_issues_count']).to eq(1)
        expect(version_data['url']).to include("/versions/#{version.id}")
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
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('バージョン')
      expect(described_class.description).to include('一覧')
    end

    it 'has optional input schema (no required fields)' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:project_id)
      expect(schema.properties).to include(:status)
      expect(schema.properties).to include(:sort)
      expect(schema.properties).to include(:limit)
      # project_idは省略可能（DEFAULT_PROJECT使用）
      expect(schema.instance_variable_get(:@required)).to eq([])
    end
  end
end
