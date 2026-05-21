# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe 'Mcp::ServerController', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:api_key) { user.api_key || user.generate_api_key! }
  let(:project) { FactoryBot.create(:project, identifier: 'test-project') }

  before do
    role = FactoryBot.create(:role, permissions: [:view_issues, :add_issues, :edit_issues])
    FactoryBot.create(:member, project: project, user: user, roles: [role])
  end

  describe 'POST /mcp/rpc' do
    context 'tools/list request' do
      it 'returns available tools' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/list',
            id: 1
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['result']).to be_present
        expect(json['result']['tools']).to be_an(Array)
        expect(json['result']['tools']).not_to be_empty
      end

      it 'exposes the complete MCP tool surface with schemas' do
        expected_tool_names = %w[
          add_issue_comment_tool
          add_related_issue_tool
          assign_to_version_tool
          bulk_update_issue_status_tool
          copy_issue_tool
          create_bug_tool
          create_epic_tool
          create_feature_tool
          create_inquiry_tool
          create_project_tool
          create_task_tool
          create_test_tool
          create_user_story_tool
          create_version_tool
          get_issue_detail_tool
          get_project_structure_tool
          list_epics_tool
          list_project_members_tool
          list_recently_updated_issues_tool
          list_statuses_tool
          list_user_stories_tool
          list_versions_tool
          move_to_next_version_tool
          promote_to_us_tool
          remove_related_issue_tool
          search_projects_tool
          update_custom_fields_tool
          update_issue_assignee_tool
          update_issue_description_tool
          update_issue_parent_tool
          update_issue_progress_tool
          update_issue_status_tool
          update_issue_subject_tool
        ]

        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/list',
            id: 1
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        tools = json.fetch('result').fetch('tools')
        tool_names = tools.map { |tool| tool.fetch('name') }.sort

        expect(tool_names).to eq(expected_tool_names)
        expect(tools.size).to eq(33)
        tools.each do |tool|
          expect(tool.fetch('description')).to be_present
          expect(tool.fetch('inputSchema')).to include('type' => 'object')
        end
      end
    end

    context 'tools/call request' do
      let(:task_tracker) { find_or_create_task_tracker }
      let(:epic_tracker) { find_or_create_epic_tracker }
      let(:feature_tracker) { find_or_create_feature_tracker }
      let(:user_story_tracker) { find_or_create_user_story_tracker }

      let(:parent_epic) { FactoryBot.create(:issue, project: project, tracker: epic_tracker, subject: 'Parent Epic', author: user) }
      let(:parent_feature) { FactoryBot.create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature', parent: parent_epic, author: user) }
      let(:parent_user_story) { FactoryBot.create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory', parent: parent_feature, author: user) }

      before do
        project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
        project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
        project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
        project.trackers << task_tracker unless project.trackers.include?(task_tracker)
        Setting.plugin_redmine_epic_ladder = {
          'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
          'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
          'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
          'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
          'mcp_enabled' => '1'
        }
        EpicLadder::TrackerHierarchy.clear_cache!
        # プロジェクト単位でMCP有効化
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
        # 階層を事前に作成
        parent_user_story
      end

      it 'creates a task via CreateTaskTool' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: project.identifier,
                description: 'Refactor cart module',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 2
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['result']).to be_present

        # Response形式の検証
        expect(json['result']['content']).to be_an(Array)
        expect(json['result']['content'].first['type']).to eq('text')

        # 成功レスポンスの検証
        result_data = JSON.parse(json['result']['content'].first['text'])
        expect(result_data['success']).to be true
        expect(result_data['task_id']).to be_present
        expect(result_data['subject']).to be_present
      end

      it 'returns error when tool execution fails' do
        # 存在しないプロジェクトを指定
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: 'nonexistent-project',
                description: 'Test task',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 3
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')

        # エラーレスポンスの検証
        result_data = JSON.parse(json['result']['content'].first['text'])
        expect(result_data['success']).to be false
        expect(result_data['error']).to include('プロジェクトが見つかりません')
      end

      it 'returns error when user lacks permission' do
        # 権限のないユーザーを作成
        unauthorized_user = FactoryBot.create(:user)
        api_token = Token.create!(user: unauthorized_user, action: 'api', value: SecureRandom.hex(20))

        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: project.identifier,
                description: 'Test task',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 4
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_token.value
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # エラーレスポンスの検証
        result_data = JSON.parse(json['result']['content'].first['text'])
        expect(result_data['success']).to be false
        expect(result_data['error']).to include('権限')
      end
    end

    context 'project management tools' do
      let(:parent_project) { FactoryBot.create(:project, identifier: 'mcp-parent-project', name: 'MCP Parent Project') }
      let(:project_admin_role) { FactoryBot.create(:role, permissions: [:view_project, :view_issues, :add_subprojects]) }

      before do
        FactoryBot.create(:member, project: parent_project, user: user, roles: [project_admin_role])
        EpicLadder::ProjectSetting.create!(project: parent_project, mcp_enabled: true)
        Setting.plugin_redmine_epic_ladder = {
          'mcp_enabled' => '1',
          'mcp_project_creation_enabled' => '1',
          'mcp_project_creation_scope' => 'allowed_parents_only',
          'mcp_project_creation_allowed_parent_ids' => [parent_project.id.to_s],
          'mcp_project_creation_allow_root' => '0'
        }
      end

      it 'searches projects through MCP tools/call' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'search_projects_tool',
              arguments: {
                query: 'MCP Parent'
              }
            },
            id: 30
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        result_data = JSON.parse(JSON.parse(response.body)['result']['content'].first['text'])
        expect(result_data['success']).to be true
        expect(result_data['projects'].map { |p| p['identifier'] }).to include(parent_project.identifier)
      end

      it 'creates a project through MCP tools/call under an allowed parent' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_project_tool',
              arguments: {
                name: 'MCP Child Project',
                identifier: 'mcp-child-project',
                parent_project_id: parent_project.identifier,
                description: 'Created from request spec'
              }
            },
            id: 31
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        result_data = JSON.parse(JSON.parse(response.body)['result']['content'].first['text'])
        expect(result_data['success']).to be true
        expect(result_data['project']['identifier']).to eq('mcp-child-project')

        created_project = Project.find_by!(identifier: 'mcp-child-project')
        expect(created_project.parent).to eq(parent_project)
        expect(EpicLadder::ProjectSetting.mcp_enabled?(created_project)).to be true
      end

      it 'rejects project creation through MCP tools/call outside the configured parent allowlist' do
        blocked_parent = FactoryBot.create(:project, identifier: 'blocked-parent-project', name: 'Blocked Parent')
        FactoryBot.create(:member, project: blocked_parent, user: user, roles: [project_admin_role])

        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_project_tool',
              arguments: {
                name: 'Blocked MCP Child',
                identifier: 'blocked-mcp-child',
                parent_project_id: blocked_parent.identifier
              }
            },
            id: 32
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        result_data = JSON.parse(JSON.parse(response.body)['result']['content'].first['text'])
        expect(result_data['success']).to be false
        expect(result_data['error']).to include('許可されていません')
        expect(Project.find_by(identifier: 'blocked-mcp-child')).to be_nil
      end
    end

    context 'authentication' do
      it 'rejects request without API key' do
        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to include('/.well-known/oauth-protected-resource/mcp/rpc')
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['error']).to be_present
        expect(json['error']['message']).to include('APIキー')
      end

      it 'rejects request with invalid API key' do
        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => 'invalid_key_12345'
          }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['error']).to be_present
        expect(json['error']['message']).to include('無効')
      end

      it 'accepts valid API key in header' do
        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['result']).to be_present
      end

      it 'accepts valid OAuth bearer token' do
        access_token = double(
          'Doorkeeper::AccessToken',
          accessible?: true,
          resource_owner_id: user.id,
          scopes: double('Doorkeeper::OAuth::Scopes', all: ['view_issues'])
        )

        allow(Doorkeeper).to receive(:authenticate).and_return(access_token)

        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer valid-oauth-token'
          }

        expect(response).to have_http_status(:ok)
        expect(Doorkeeper).to have_received(:authenticate)

        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['result']).to be_present
      end

      it 'rejects invalid OAuth bearer token with OAuth challenge' do
        allow(Doorkeeper).to receive(:authenticate).and_return(nil)

        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer invalid-oauth-token'
          }

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to include('/.well-known/oauth-protected-resource/mcp/rpc')

        json = JSON.parse(response.body)
        expect(json['error']['message']).to include('OAuth')
      end
    end

    context 'CORS headers' do
      it 'includes CORS headers in response' do
        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
        expect(response.headers['Access-Control-Allow-Methods']).to include('POST')
      end

      it 'includes X-Default-Project in allowed headers' do
        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response.headers['Access-Control-Allow-Headers']).to include('X-Default-Project')
      end
    end

    context 'X-Default-Project header' do
      let(:task_tracker) { find_or_create_task_tracker }

      let(:epic_tracker) { find_or_create_epic_tracker }
      let(:feature_tracker) { find_or_create_feature_tracker }
      let(:user_story_tracker) { find_or_create_user_story_tracker }

      let(:default_project) { FactoryBot.create(:project, identifier: 'default-proj') }

      # Hierarchy for main project
      let(:parent_epic) { FactoryBot.create(:issue, project: project, tracker: epic_tracker, subject: 'Parent Epic', author: user) }
      let(:parent_feature) { FactoryBot.create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature', parent: parent_epic, author: user) }
      let(:parent_user_story) { FactoryBot.create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory', parent: parent_feature, author: user) }

      # Hierarchy for default_project
      let(:default_epic) { FactoryBot.create(:issue, project: default_project, tracker: epic_tracker, subject: 'Default Epic', author: user) }
      let(:default_feature) { FactoryBot.create(:issue, project: default_project, tracker: feature_tracker, subject: 'Default Feature', parent: default_epic, author: user) }
      let(:default_user_story) { FactoryBot.create(:issue, project: default_project, tracker: user_story_tracker, subject: 'Default UserStory', parent: default_feature, author: user) }

      before do
        [epic_tracker, feature_tracker, user_story_tracker, task_tracker].each do |t|
          project.trackers << t unless project.trackers.include?(t)
          default_project.trackers << t unless default_project.trackers.include?(t)
        end
        Setting.plugin_redmine_epic_ladder = {
          'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
          'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
          'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
          'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
          'mcp_enabled' => '1'
        }
        EpicLadder::TrackerHierarchy.clear_cache!

        # プロジェクト単位でMCP有効化
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
        EpicLadder::ProjectSetting.create!(project: default_project, mcp_enabled: true)

        # ユーザーにdefault_projectへのアクセス権限を付与
        role = Role.find_by(name: 'Manager') || FactoryBot.create(:role, permissions: [:view_issues, :add_issues, :edit_issues])
        FactoryBot.create(:member, project: default_project, user: user, roles: [role])

        # 階層を事前に作成
        parent_user_story
        default_user_story
      end

      it 'uses X-Default-Project header when project_id is not specified' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                description: 'Task created with default project header',
                parent_user_story_id: default_user_story.id.to_s
              }
            },
            id: 10
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key,
            'X-Default-Project' => default_project.identifier
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        result_data = JSON.parse(json['result']['content'].first['text'])

        expect(result_data['success']).to be true
        expect(result_data['task_id']).to be_present

        # 作成されたタスクがdefault_projectに属していることを確認
        created_task = Issue.find(result_data['task_id'])
        expect(created_task.project).to eq(default_project)
      end

      it 'prioritizes explicit project_id over X-Default-Project header' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: project.identifier,
                description: 'Task with explicit project_id',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 11
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key,
            'X-Default-Project' => default_project.identifier
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        result_data = JSON.parse(json['result']['content'].first['text'])

        expect(result_data['success']).to be true

        # 明示的に指定されたproject（default_projectではなく）に作成されることを確認
        created_task = Issue.find(result_data['task_id'])
        expect(created_task.project).to eq(project)
      end

      it 'returns error when X-Default-Project specifies non-existent project' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                description: 'Task with invalid default project',
                parent_user_story_id: default_user_story.id.to_s
              }
            },
            id: 12
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key,
            'X-Default-Project' => 'nonexistent-default-project'
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        result_data = JSON.parse(json['result']['content'].first['text'])

        expect(result_data['success']).to be false
        expect(result_data['error']).to include('プロジェクトが見つかりません')
      end
    end

    context 'JSON-RPC error handling' do
      it 'returns error for unknown method' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'unknown/method',
            id: 99
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['error']).to be_present
        expect(json['error']['code']).to eq(-32601) # Method not found
      end

      it 'returns error for invalid JSON-RPC request' do
        post '/mcp/rpc',
          params: { invalid: 'request' }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        # 無効なJSON-RPCリクエストは204または200+errorを返す
        expect([200, 204]).to include(response.status)

        if response.status == 200 && response.body.present?
          json = JSON.parse(response.body)
          expect(json['jsonrpc']).to eq('2.0')
          expect(json['error']).to be_present
        end
      end

      it 'handles malformed JSON gracefully' do
        post '/mcp/rpc',
          params: 'not a json',
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        # Controllerがmalformed JSONをどう扱うかは実装依存
        # 400 Bad RequestまたはJSON-RPCエラーを返すべき
        expect([400, 200]).to include(response.status)

        if response.body.present?
          json = JSON.parse(response.body)
          expect(json['jsonrpc']).to eq('2.0')
          expect(json['error']).to be_present
        end
      end

      it 'returns error when tool name does not exist' do
        Setting.plugin_redmine_epic_ladder = { 'mcp_enabled' => '1' }

        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'nonexistent_tool',
              arguments: {}
            },
            id: 98
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['jsonrpc']).to eq('2.0')
        expect(json['error']).to be_present
      end
    end
  end

  describe 'OPTIONS /mcp/rpc' do
    it 'handles CORS preflight request' do
      options '/mcp/rpc'

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  describe 'OAuth discovery for Claude Web custom connector' do
    it 'returns protected resource metadata for /mcp/rpc' do
      get '/.well-known/oauth-protected-resource/mcp/rpc'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json['resource']).to eq('http://www.example.com/mcp/rpc')
      expect(json['authorization_servers']).to eq([
        'http://www.example.com/.well-known/oauth-authorization-server'
      ])
    end

    it 'returns authorization server metadata backed by Redmine OAuth aliases' do
      get '/.well-known/oauth-authorization-server'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['issuer']).to eq('http://www.example.com')
      expect(json['authorization_endpoint']).to eq('http://www.example.com/authorize')
      expect(json['token_endpoint']).to eq('http://www.example.com/token')
      expect(json['response_types_supported']).to include('code')
      expect(json['grant_types_supported']).to include('authorization_code')
      expect(json['code_challenge_methods_supported']).to include('S256')
      expect(json['scopes_supported']).to include(
        'view_project',
        'view_issues',
        'add_issues',
        'edit_issues',
        'add_issue_notes',
        'manage_versions',
        'manage_issue_relations',
        'add_subprojects'
      )
    end

    it 'redirects root authorize alias to Redmine Doorkeeper authorize endpoint with default MCP scopes' do
      get '/authorize',
        params: {
          client_id: 'client-123',
          redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
          response_type: 'code'
        }

      expect(response).to have_http_status(:moved_permanently)
      location = URI.parse(response.location)
      query = Rack::Utils.parse_query(location.query)

      expect(location.path).to eq('/oauth/authorize')
      expect(query['client_id']).to eq('client-123')
      expect(query['redirect_uri']).to eq('https://claude.ai/api/mcp/auth_callback')
      expect(query['response_type']).to eq('code')
      expect(query['scope']).to eq(
        'view_project view_issues add_issues edit_issues add_issue_notes manage_versions manage_issue_relations add_subprojects'
      )
    end

    it 'does not overwrite explicit authorize scopes' do
      get '/authorize',
        params: {
          client_id: 'client-123',
          redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
          response_type: 'code',
          scope: 'view_project'
        }

      location = URI.parse(response.location)
      query = Rack::Utils.parse_query(location.query)

      expect(location.path).to eq('/oauth/authorize')
      expect(query['scope']).to eq('view_project')
    end
  end

  describe 'Plugin settings for MCP' do
    let(:task_tracker) { find_or_create_task_tracker }
    let(:epic_tracker) { find_or_create_epic_tracker }
    let(:feature_tracker) { find_or_create_feature_tracker }
    let(:user_story_tracker) { find_or_create_user_story_tracker }

    let(:parent_epic) { FactoryBot.create(:issue, project: project, tracker: epic_tracker, subject: 'Parent Epic', author: user) }
    let(:parent_feature) { FactoryBot.create(:issue, project: project, tracker: feature_tracker, subject: 'Parent Feature', parent: parent_epic, author: user) }
    let(:parent_user_story) { FactoryBot.create(:issue, project: project, tracker: user_story_tracker, subject: 'Parent UserStory', parent: parent_feature, author: user) }

    before do
      [epic_tracker, feature_tracker, user_story_tracker, task_tracker].each do |t|
        project.trackers << t unless project.trackers.include?(t)
      end
      # 階層を事前に作成
      parent_user_story
    end

    context 'when MCP is disabled globally' do
      before do
        Setting.plugin_redmine_epic_ladder = {
          'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
          'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
          'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
          'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
          'mcp_enabled' => '0'
        }
        EpicLadder::TrackerHierarchy.clear_cache!
        # プロジェクト単位では有効化
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
      end

      it 'rejects all MCP requests' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: project.identifier,
                description: 'Test task',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 20
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        result_data = JSON.parse(json['result']['content'].first['text'])

        expect(result_data['success']).to be false
        expect(result_data['error']).to include('MCP API')
      end
    end

    context 'when MCP is not enabled for project' do
      before do
        Setting.plugin_redmine_epic_ladder = {
          'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
          'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
          'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
          'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
          'mcp_enabled' => '1'
        }
        EpicLadder::TrackerHierarchy.clear_cache!
        # プロジェクト単位でMCPを明示的に無効化
        ps = EpicLadder::ProjectSetting.find_or_initialize_by(project: project)
        ps.mcp_enabled = false
        ps.save!
      end

      it 'rejects access to project without MCP enabled' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: project.identifier,
                description: 'Test task',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 21
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        result_data = JSON.parse(json['result']['content'].first['text'])

        expect(result_data['success']).to be false
        expect(result_data['error']).to include('許可されていません')
      end
    end

    context 'when MCP is enabled for project' do
      before do
        Setting.plugin_redmine_epic_ladder = {
          'epic_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:epic],
          'feature_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:feature],
          'user_story_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:user_story],
          'task_tracker' => EpicLadder::TrackerHierarchy.tracker_names[:task],
          'mcp_enabled' => '1'
        }
        EpicLadder::TrackerHierarchy.clear_cache!
        # プロジェクト単位でMCP有効化
        EpicLadder::ProjectSetting.create!(project: project, mcp_enabled: true)
      end

      it 'allows access to project with MCP enabled' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                project_id: project.identifier,
                description: 'Test task on MCP-enabled project',
                parent_user_story_id: parent_user_story.id.to_s
              }
            },
            id: 22
          }.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-Redmine-API-Key' => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        result_data = JSON.parse(json['result']['content'].first['text'])

        expect(result_data['success']).to be true
      end
    end
  end
end
