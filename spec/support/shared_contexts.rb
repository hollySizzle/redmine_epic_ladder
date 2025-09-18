# frozen_string_literal: true

# 共通テストデータの定義（重複作成を避ける）
RSpec.shared_context "gantt test data" do
  let(:small_dataset) { 50 }   # 機能テスト用
  let(:medium_dataset) { 200 } # 統合テスト用
  let(:large_dataset) { 1000 } # パフォーマンステスト用
  
  # 実際にデータを作成するかはテストで選択
  def setup_test_data(size = :small)
    count = case size
            when :small then small_dataset
            when :medium then medium_dataset  
            when :large then large_dataset
            else size.to_i
            end
    
    @test_issues ||= create_bulk_issues(
      count: count,
      project: project,
      user: user,
      date_range: 180
    )
  end
end

# 基本的なガントパラメータのデフォルト
RSpec.shared_context "gantt parameters" do
  let(:basic_gantt_params) do
    {
      gantt_view: true,
      zoom_level: 'month',
      view_start: Date.today.to_s,
      view_end: (Date.today + 3.months).to_s
    }
  end
  
  let(:zoom_limits) do
    {
      'day' => 200,
      'week' => 300,  
      'month' => 500,
      'quarter' => 700,
      'year' => 1000
    }
  end
end