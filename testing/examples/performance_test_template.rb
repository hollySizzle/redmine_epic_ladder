# frozen_string_literal: true

# パフォーマンステストの雛形
# 新機能のパフォーマンス検証時にこのテンプレートを参考にしてください

require 'rails_helper'

RSpec.describe 'New Feature Performance', type: :request, :performance do
  let(:project) { @test_project }
  let(:user) { @test_user }
  let(:base_url) { "/projects/#{project.identifier}/react_gantt_chart" }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe '新機能のパフォーマンス検証' do
    before do
      # 大量テストデータの作成
      create_bulk_issues(count: 2000, project: project, user: user)
    end
    
    it '新機能が適切なパフォーマンスで動作する' do
      # ベースライン測定（既存機能）
      baseline_perf = measure_performance("Baseline") do
        get base_url + "/data", params: gantt_params(project_id: project.id)
      end
      
      json_baseline = expect_valid_gantt_response(response)
      baseline_count = json_baseline['tasks'].size
      
      # 新機能のパフォーマンス測定
      new_feature_perf = measure_performance("New Feature") do
        get base_url + "/new_endpoint", params: gantt_params(
          project_id: project.id,
          new_feature_param: 'enabled'
        )
      end
      
      json_new = expect_valid_gantt_response(response)
      new_count = json_new['tasks'].size
      
      # パフォーマンス検証
      expect(new_feature_perf[:wall_time]).to be < (baseline_perf[:wall_time] * 1.5) # 50%以内の性能劣化
      expect(new_feature_perf[:memory_delta]).to be < 50_000 # 50MB以下のメモリ増加
      
      # 結果ログ出力
      puts "\n=== 新機能パフォーマンス比較 ==="
      puts "ベースライン: #{baseline_count}件 / #{baseline_perf[:wall_time].round(2)}ms"
      puts "新機能: #{new_count}件 / #{new_feature_perf[:wall_time].round(2)}ms"
      puts "性能比: #{(new_feature_perf[:wall_time] / baseline_perf[:wall_time] * 100).round(1)}%"
    end
    
    it 'ズームレベル別の新機能パフォーマンス' do
      performance_results = {}
      
      expect_zoom_level_limits do |zoom_level, expected_limit|
        params = gantt_params(
          project_id: project.id,
          zoom_level: zoom_level,
          new_feature_enabled: true
        )
        
        perf = measure_performance("New Feature - #{zoom_level}") do
          get base_url + "/new_endpoint", params: params
        end
        
        json = expect_valid_gantt_response(response)
        
        performance_results[zoom_level] = {
          count: json['tasks'].size,
          time: perf[:wall_time].round(2),
          memory: perf[:memory_delta]
        }
        
        # 各ズームレベルでの期待値チェック
        expect(json['tasks'].size).to be <= expected_limit
        expect(perf[:wall_time]).to be < 3000 # 3秒以内
      end
      
      # パフォーマンスレポート
      puts "\n=== 新機能ズームレベル別パフォーマンス ==="
      performance_results.each do |zoom, result|
        puts "#{zoom.ljust(8)}: #{result[:count].to_s.rjust(4)}件 / " \
             "#{result[:time]}ms / #{(result[:memory] / 1024.0).round(1)}MB"
      end
    end
    
    it 'メモリ使用量が適切に制御される' do
      # 超大量データでのメモリテスト
      create_bulk_issues(count: 5000, project: project, user: user)
      
      params = gantt_params(
        project_id: project.id,
        new_feature_enabled: true
      )
      
      expect_performance("Memory Control Test") do
        get base_url + "/new_endpoint", params: params
      end.to_use_less_memory_than(100_000) # 100MB以下
      
      json = expect_valid_gantt_response(response)
      expect(json['tasks']).to be_present
    end
    
    it '複数回実行での安定性確認' do
      params = gantt_params(project_id: project.id, new_feature_enabled: true)
      times = []
      
      5.times do |i|
        perf = measure_performance("Stability Test #{i + 1}") do
          get base_url + "/new_endpoint", params: params
        end
        
        times << perf[:wall_time]
        expect_valid_gantt_response(response)
      end
      
      # 性能の安定性チェック
      avg_time = times.sum / times.size
      max_deviation = times.map { |t| (t - avg_time).abs }.max
      
      expect(max_deviation).to be < (avg_time * 0.3) # 平均の30%以内の変動
      
      puts "\n=== 安定性テスト結果 ==="
      puts "平均応答時間: #{avg_time.round(2)}ms"
      puts "最大変動: #{max_deviation.round(2)}ms (#{(max_deviation / avg_time * 100).round(1)}%)"
    end
  end
end