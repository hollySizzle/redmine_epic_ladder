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
    end

    context 'tools/call request' do
      let(:task_tracker) do
        Tracker.find_by(name: 'Task') || begin
          default_status = IssueStatus.first || IssueStatus.create!(name: 'New')
          Tracker.create!(name: 'Task', default_status: default_status)
        end
      end

      before do
        project.trackers << task_tracker
        Setting.plugin_redmine_epic_grid = { 'task_tracker' => 'Task' }
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
                description: 'Refactor cart module'
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
                description: 'Test task'
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
                description: 'Test task'
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

    context 'authentication' do
      it 'rejects request without API key' do
        post '/mcp/rpc',
          params: { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
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
      let(:task_tracker) do
        Tracker.find_by(name: 'Task') || begin
          default_status = IssueStatus.first || IssueStatus.create!(name: 'New')
          Tracker.create!(name: 'Task', default_status: default_status)
        end
      end

      let(:default_project) { FactoryBot.create(:project, identifier: 'default-proj') }

      before do
        project.trackers << task_tracker
        default_project.trackers << task_tracker
        Setting.plugin_redmine_epic_grid = { 'task_tracker' => 'Task' }

        # ユーザーにdefault_projectへのアクセス権限を付与
        role = Role.find_by(name: 'Manager') || FactoryBot.create(:role, permissions: [:view_issues, :add_issues, :edit_issues])
        FactoryBot.create(:member, project: default_project, user: user, roles: [role])
      end

      it 'uses X-Default-Project header when project_id is not specified' do
        post '/mcp/rpc',
          params: {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
              name: 'create_task_tool',
              arguments: {
                description: 'Task created with default project header'
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
                description: 'Task with explicit project_id'
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
                description: 'Task with invalid default project'
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
end
