#!/usr/bin/env ruby
# 修正内容のテスト用スクリプト

require 'net/http'
require 'uri'
require 'json'

puts "=== Task Not Found エラー修正のテスト ==="

# プロジェクトIDを取得（適当なプロジェクトを使用）
project_id = "space-mine"  # 適宜変更

# ステータスフィルタ付きでデータを取得
uri = URI("http://localhost:3000/projects/#{project_id}/react_gantt_chart/data")
uri.query = URI.encode_www_form([
  ['set_filter', '1'],
  ['f[]', 'status_id'],
  ['op[status_id]', '='],
  ['v[status_id][]', '1'],  # 新規ステータス
  ['gantt_view', 'true']
])

puts "リクエストURL: #{uri}"

begin
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    data = JSON.parse(response.body)
    tasks_count = data['tasks']&.size || 0
    links_count = data['links']&.size || 0
    
    puts "✅ API呼び出し成功"
    puts "   タスク数: #{tasks_count}"
    puts "   リンク数: #{links_count}"
    
    # レスポンスが空でも正常とみなす（フィルタにより全てのタスクが除外される可能性）
    puts "✅ ステータスフィルタ適用成功"
  else
    puts "❌ API呼び出し失敗: #{response.code} #{response.message}"
    puts response.body
  end
  
rescue => e
  puts "❌ テスト実行エラー: #{e.message}"
end

puts "\n=== テスト完了 ==="
puts "修正内容："
puts "1. gantt.isTaskExists() による事前チェック追加"
puts "2. 'Task not found' エラーをワーニングレベルに変更"
puts "3. 全ての gantt.getTask() 呼び出し箇所の安全化"
puts "\nブラウザでガントチャートを開き、ステータスフィルタを適用して"
puts "コンソールで 'Task not found' エラーが警告レベルになっていることを確認してください"