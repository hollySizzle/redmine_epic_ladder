# frozen_string_literal: true

# コントローラーテストの雛形
# 新機能追加時にこのテンプレートを参考にしてください

require 'rails_helper'

RSpec.describe ReactGanttChartController, type: :controller do
  let(:project) { @test_project }
  let(:user) { @test_user }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #new_action' do
    context '正常系' do
      it '新機能が正常に動作する' do
        # ガント用パラメータを生成
        params = gantt_params(
          project_id: project.id,
          custom_param: 'test_value'
        )
        
        get :new_action, params: params
        
        # レスポンス検証
        json = expect_valid_gantt_response(response)
        expect(json).to have_key('expected_data')
        
        # デバッグ出力（必要に応じて）
        debug_gantt_response(response, "New Action Response")
      end
      
      it 'パフォーマンスが適切' do
        # 大量データでのテスト
        create_bulk_issues(count: 500, project: project, user: user)
        
        params = gantt_params(project_id: project.id)
        
        # パフォーマンス測定
        performance = measure_api_performance(:new_action, params)
        
        # 期待値チェック
        expect(performance[:wall_time]).to be < 2000 # 2秒以内
        expect(response).to have_http_status(:success)
      end
    end
    
    context '異常系' do
      it '不正なパラメータでもエラーにならない' do
        get :new_action, params: {
          project_id: project.id,
          invalid_param: 'invalid_value'
        }
        
        expect(response).to have_http_status(:success)
      end
      
      it '権限がない場合は403エラー' do
        # ユーザーの権限を削除
        Member.where(user_id: user.id, project_id: project.id).destroy_all
        
        get :new_action, params: { project_id: project.id }
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end