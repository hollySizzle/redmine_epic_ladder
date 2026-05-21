# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReactGanttChartController, type: :controller do
  # 動的にテストデータを作成（fixturesに依存しない）
  let(:project) { @test_project }
  let(:user) { @test_user }
  let(:test_issues) { create_test_issue_set(project, user) }

  before do
    # セッションをセットアップ
    session[:user_id] = user.id
    
    # テストデータのセットアップ（既にrails_helperで基本設定済み）
    test_issues # lazy load test issues
  end

  describe 'GET #data' do
    context 'サーバーサイドフィルタの動作確認' do
      describe '期日範囲フィルタ' do
        it 'gantt_viewパラメータがある場合、期日範囲フィルタが適用される' do
          params = gantt_params(
            project_id: project.id,
            view_start: Date.today.to_s,
            view_end: (Date.today + 60.days).to_s
          )
          
          get :data, params: params
          json = expect_valid_gantt_response(response)
          debug_gantt_response(response, "Server-side filtered response")
          
          task_ids = json['tasks'].map { |t| t['id'] }
          
          # 範囲内のタスクは含まれる
          expect(task_ids).to include(test_issues[:in_range].id)
          
          # 範囲外のタスクは含まれない（未来と過去）
          expect(task_ids).not_to include(test_issues[:future].id)
        end
        
        it 'gantt_viewパラメータがない場合、全タスクが返される' do
          get :data, params: { project_id: project.id }
          
          json = expect_valid_gantt_response(response)
          task_ids = json['tasks'].map { |t| t['id'] }
          
          # 全タスクが含まれる
          test_issues[:all].each do |issue|
            expect(task_ids).to include(issue.id)
          end
        end
        
        it 'カスタム日付範囲でフィルタリングが機能する' do
          # 特定の日付範囲を指定
          start_date = Date.today + 1.month
          end_date = Date.today + 2.months
          
          # その範囲内にIssueを作成
          range_issue = Issue.create!(
            project: project,
            tracker: project.trackers.first,
            author: user,
            subject: 'Custom Range Issue',
            start_date: start_date + 5.days,
            due_date: start_date + 10.days,
            status: IssueStatus.first,
            priority: IssuePriority.first
          )
          
          params = gantt_params(
            project_id: project.id,
            view_start: start_date.to_s,
            view_end: end_date.to_s
          )
          
          get :data, params: params
          json = expect_valid_gantt_response(response)
          
          task_ids = json['tasks'].map { |t| t['id'] }
          expect(task_ids).to include(range_issue.id)
          expect(task_ids).not_to include(test_issues[:in_range].id) # 今日の範囲外
        end
      end

      describe 'メタデータの返却' do
        it 'メタデータが正しく返される' do
          params = gantt_params(
            project_id: project.id,
            view_start: Date.today.to_s,
            view_end: (Date.today + 60.days).to_s
          )
          
          get :data, params: params
          json = expect_valid_gantt_response(response)
          
          # 返却件数が正しい
          expect(json['meta']['returned_count']).to eq(json['tasks'].size)
          
          # 表示範囲が正しい
          expect(json['meta']['view_range']['start']).to eq(Date.today.to_s)
          expect(json['meta']['view_range']['end']).to eq((Date.today + 60.days).to_s)
          
          # 型の検証
          expect(json['meta']['total_count']).to be_a(Integer)
          expect(json['meta']['has_more']).to be_in([true, false])
        end
        
        it 'パフォーマンス情報が含まれる' do
          params = gantt_params(project_id: project.id)
          
          get :data, params: params
          performance = expect_performance_data(response)
          
          expect(performance['query_time']).to be > 0
          expect(performance['issue_count']).to be >= 0
        end
      end

      describe '動的limit計算' do
        it 'ズームレベルに応じて適切なlimitが設定される' do
          expect_zoom_level_limits do |zoom_level, expected_limit|
            # 大量のテストデータを作成
            issues = create_bulk_issues(
              count: expected_limit + 50,
              project: project,
              user: user,
              date_range: 365
            )
            
            params = gantt_params(
              project_id: project.id,
              zoom_level: zoom_level,
              view_start: Date.today.to_s,
              view_end: (Date.today + 365.days).to_s
            )
            
            performance = measure_api_performance(:data, params)
            json = expect_valid_gantt_response(response)
            
            # limitを超えないことを確認
            expect(json['tasks'].size).to be <= expected_limit
            
            # パフォーマンスが適切であることを確認
            expect(performance[:wall_time]).to be < 2000 # 2秒以内
            
            # has_moreフラグが正しく設定される
            if json['tasks'].size >= expected_limit
              expect(json['meta']['has_more']).to be true
            end
            
            # メモリ使用量も妥当であることを確認
            expect(performance[:memory_delta]).to be < 50_000 # 50MB以内
            
            puts "#{zoom_level}: #{json['tasks'].size}/#{expected_limit} tasks, " \
                 "#{performance[:wall_time].round(2)}ms"
            
            # テストデータのクリーンアップ
            issues.destroy_all
          end
        end
        
        it 'calculate_optimal_limit メソッドが正しく動作する', :unit do
          controller = described_class.new
          
          expect_zoom_level_limits do |zoom_level, expected_limit|
            actual_limit = controller.send(:calculate_optimal_limit, { zoom_level: zoom_level })
            expect(actual_limit).to eq(expected_limit)
          end
        end
      end

      describe '既存フィルタとの併用' do
        before do
          @high_priority = IssuePriority.find_by(name: '高め') || IssuePriority.create!(name: '高め')
          @low_priority = IssuePriority.find_by(name: '低め') || IssuePriority.create!(name: '低め')
          
          @high_priority_task = Issue.create!(
            project: project,
            tracker: project.trackers.first,
            author: user,
            subject: '高優先度タスク',
            priority: @high_priority,
            start_date: Date.today,
            due_date: Date.today + 10.days
          )
          
          @low_priority_task = Issue.create!(
            project: project,
            tracker: project.trackers.first,
            author: user,
            subject: '低優先度タスク',
            priority: @low_priority,
            start_date: Date.today,
            due_date: Date.today + 10.days
          )
        end
        
        it '期日範囲フィルタと優先度フィルタが同時に機能する' do
          get :data, params: {
            project_id: project.id,
            gantt_view: true,
            view_start: Date.today.to_s,
            view_end: (Date.today + 30.days).to_s,
            f: ['priority_id'],
            op: { 'priority_id' => '=' },
            v: { 'priority_id' => [@high_priority.id.to_s] }
          }
          
          json_response = JSON.parse(response.body)
          task_ids = json_response['tasks'].map { |t| t['id'] }
          
          # 高優先度タスクのみ含まれる
          expect(task_ids).to include(@high_priority_task.id)
          expect(task_ids).not_to include(@low_priority_task.id)
        end
      end
    end

    context 'パフォーマンステスト' do
      it '大量データでも適切な時間内に応答する' do
        # 1000件のタスクを作成
        1000.times do |i|
          Issue.create!(
            project: project,
            tracker: project.trackers.first,
            author: user,
            subject: "パフォーマンステスト #{i}",
            start_date: Date.today + (i % 365).days,
            due_date: Date.today + ((i % 365) + 7).days
          )
        end
        
        start_time = Time.current
        
        get :data, params: {
          project_id: project.id,
          gantt_view: true,
          view_start: Date.today.to_s,
          view_end: (Date.today + 30.days).to_s,
          zoom_level: 'month'
        }
        
        response_time = Time.current - start_time
        
        expect(response).to have_http_status(:success)
        
        # 3秒以内に応答
        expect(response_time).to be < 3.seconds
        
        json_response = JSON.parse(response.body)
        
        # 適切な件数が返される（500件以下）
        expect(json_response['tasks'].size).to be <= 500
        
        # パフォーマンス情報が含まれる
        expect(json_response).to have_key('performance')
        expect(json_response['performance']['query_time']).to be_present
      end
    end

    context 'エラーハンドリング' do
      it '不正なパラメータでもエラーにならない' do
        get :data, params: {
          project_id: project.id,
          gantt_view: true,
          view_start: 'invalid-date',
          view_end: 'invalid-date'
        }
        
        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tasks')
      end
      
      it '権限がない場合は403エラー' do
        # ユーザーの権限を削除
        Member.where(user_id: user.id, project_id: project.id).destroy_all
        
        get :data, params: {
          project_id: project.id
        }
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #filters' do
    context 'フィルタ定義の簡素化' do
      it 'Redmine標準のオペレータラベルを返す' do
        get :filters, params: { project_id: project.id }
        
        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        
        expect(json_response).to have_key('operatorLabels')
        expect(json_response).to have_key('operatorByType')
        expect(json_response).to have_key('availableFilters')
        
        # Redmine標準のオペレータが含まれる
        expect(json_response['operatorLabels']).to include('=', '!', '~', '!~')
        
        # 過剰な29種類の定義ではない
        expect(json_response['operatorLabels'].keys.size).to be < 29
      end
    end
  end
end