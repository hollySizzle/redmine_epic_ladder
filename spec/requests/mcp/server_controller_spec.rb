# frozen_string_literal: true

require 'spec_helper'

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
      let(:task_tracker) { FactoryBot.create(:tracker, name: 'Task') }

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
              name: 'create_task',
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
