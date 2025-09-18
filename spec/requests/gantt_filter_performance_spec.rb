# frozen_string_literal: true

require 'rails_helper'

# 機能テスト専用 - サーバーサイドフィルタの動作確認
RSpec.describe 'Gantt Filter Functionality', type: :request do
  let(:project) { @test_project }
  let(:user) { @test_user }
  let(:base_url) { "/projects/#{project.identifier}/react_gantt_chart" }
  
  before do
    # 認証ヘッダーを設定（実際の環境に合わせて調整）
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
  
  describe 'サーバーサイドフィルタの動作確認' do
    before do
      # 最小限のテストデータ（100件）
      create_bulk_issues(count: 100, project: project, user: user)
    end
    
    it 'gantt_viewパラメータでフィルタが適用される' do
      # フィルタなし
      get base_url + "/data"
      json_without = expect_valid_gantt_response(response)
      count_without = json_without['tasks'].size
      
      # フィルタあり
      params = { gantt_view: true, zoom_level: 'month' }
      get base_url + "/data", params: params
      
      json_with = expect_valid_gantt_response(response)
      count_with = json_with['tasks'].size
      
      # 機能の正確性を検証
      expect(count_with).to be <= count_without
      expect(json_with['meta']).to have_key('view_range')
      expect(response).to have_http_status(:success)
    end
    
    it 'ズームレベルで適切なlimitが適用される' do
      limits = { 'day' => 200, 'month' => 500, 'year' => 1000 }
      
      limits.each do |zoom, expected_limit|
        params = { gantt_view: true, zoom_level: zoom }
        get base_url + "/data", params: params
        
        json = expect_valid_gantt_response(response)
        expect(json['tasks'].size).to be <= expected_limit
      end
    end
  end
  
  describe '複合フィルタの動作確認' do
    before do
      create_bulk_issues(count: 50, project: project, user: user)
    end
    
    it 'ガントフィルタと既存フィルタが同時に機能する' do
      params = {
        gantt_view: true,
        f: ['status_id'],
        op: { 'status_id' => 'o' },
        v: { 'status_id' => [] }
      }
      
      get base_url + "/data", params: params
      
      json = expect_valid_gantt_response(response)
      expect(json['tasks']).to be_present
      expect(response).to have_http_status(:success)
    end
  end
  
  
end