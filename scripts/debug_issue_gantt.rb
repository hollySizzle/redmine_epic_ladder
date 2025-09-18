#!/usr/bin/env ruby
# デバッグスクリプト: チケットのガントチャート表示情報を確認
# 使用方法: rails runner scripts/debug_issue_gantt.rb [issue_id]

issue_id = ARGV[0]&.to_i || 104

begin
  issue = Issue.find(issue_id)
  
  puts "=" * 80
  puts "チケット情報 (Issue ##{issue.id})"
  puts "=" * 80
  puts "題名: #{issue.subject}"
  puts "開始日: #{issue.start_date || '未設定'}"
  puts "期日: #{issue.due_date || '未設定'}"
  puts "ステータス: #{issue.status.name}"
  puts "担当者: #{issue.assigned_to&.name || '未割当'}"
  puts "プロジェクト: #{issue.project.name}"
  
  # ガントチャートデータビルダーでの変換結果
  puts "\n" + "=" * 80
  puts "ガントチャートデータ変換結果"
  puts "=" * 80
  
  builder = RedmineReactGanttChart::GanttDataBuilder.new(
    project: issue.project,
    issues: [issue],
    params: {},
    user: User.current
  )
  
  result = builder.build
  task = result[:tasks].find { |t| t[:id] == issue.id }
  
  if task
    puts "タスクID: #{task[:id]}"
    puts "開始日 (start): #{task[:start] || 'nil'}"
    puts "終了日 (end): #{task[:end] || 'nil'}"
    puts "期間 (duration): #{task[:duration]}"
    puts "タイプ: #{task[:type]}"
    puts "CSSクラス: #{task[:css]}"
    
    # 詳細なデータをJSON形式で表示
    puts "\n" + "-" * 40
    puts "完全なタスクデータ (JSON形式):"
    puts "-" * 40
    require 'json'
    puts JSON.pretty_generate(task)
  else
    puts "エラー: タスクデータが見つかりません"
  end
  
  # 関連するリンク情報
  if result[:links].any?
    puts "\n" + "=" * 80
    puts "依存関係リンク"
    puts "=" * 80
    result[:links].each do |link|
      puts "リンクID: #{link[:id]}, ソース: #{link[:source]}, ターゲット: #{link[:target]}, タイプ: #{link[:type]}"
    end
  end
  
rescue ActiveRecord::RecordNotFound
  puts "エラー: チケット ##{issue_id} が見つかりません"
rescue => e
  puts "エラーが発生しました: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end