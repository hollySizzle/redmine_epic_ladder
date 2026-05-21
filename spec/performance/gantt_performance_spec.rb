# frozen_string_literal: true

require 'rails_helper'

# パフォーマンステスト専用ファイル - 単一責任の原則
RSpec.describe 'Gantt Performance', type: :request, :performance do
  include_context "gantt test data"
  include_context "gantt parameters"
  
  let(:project) { @test_project }
  let(:user) { @test_user }
  let(:base_url) { "/projects/#{project.identifier}/react_gantt_chart" }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'サーバーサイドフィルタの効果測定' do
    before { setup_test_data(:large) }
    
    it 'データ削減率80%以上を達成する' do
      # フィルタなし（従来）
      get base_url + "/data"
      baseline_count = JSON.parse(response.body)['tasks'].size
      
      # フィルタあり（新機能）
      get base_url + "/data", params: basic_gantt_params
      
      filtered_count = JSON.parse(response.body)['tasks'].size
      reduction = ((baseline_count - filtered_count).to_f / baseline_count * 100).round(1)
      
      expect(reduction).to be >= 80.0
      expect(filtered_count).to be <= 500  # month zoom limit
      
      puts "データ削減: #{reduction}% (#{baseline_count} → #{filtered_count})"
    end
    
    it '応答時間50%短縮を達成する' do
      start = Time.current
      get base_url + "/data"
      baseline_time = (Time.current - start) * 1000
      
      start = Time.current
      get base_url + "/data", params: basic_gantt_params
      filtered_time = (Time.current - start) * 1000
      
      improvement = ((1 - filtered_time / baseline_time) * 100).round(1)
      expect(improvement).to be >= 50.0
      
      puts "応答時間改善: #{improvement}% (#{baseline_time.round}ms → #{filtered_time.round}ms)"
    end
  end

  describe 'ズームレベル別パフォーマンス' do
    before { setup_test_data(:medium) }
    
    it '各ズームレベルで適切なlimitが適用される' do
      zoom_limits.each do |zoom, expected_limit|
        get base_url + "/data", params: { gantt_view: true, zoom_level: zoom }
        
        json = JSON.parse(response.body)
        actual_count = json['tasks'].size
        
        expect(actual_count).to be <= expected_limit
        expect(response).to have_http_status(:success)
        
        puts "#{zoom}: #{actual_count}/#{expected_limit} tasks"
      end
    end
    
    it 'すべてのズームで2秒以内に応答する' do
      %w[day week month quarter year].each do |zoom|
        start = Time.current
        get base_url + "/data", params: { gantt_view: true, zoom_level: zoom }
        response_time = (Time.current - start) * 1000
        
        expect(response_time).to be < 2000
        expect(response).to have_http_status(:success)
      end
    end
  end
end