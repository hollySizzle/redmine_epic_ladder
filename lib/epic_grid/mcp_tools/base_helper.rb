# frozen_string_literal: true

module EpicGrid
  module McpTools
    # MCP Tools共通ヘルパーモジュール
    # すべてのMCPツールで使用される共通ヘルパーメソッドを提供
    module BaseHelper
      # プロジェクト取得（識別子 or ID）
      def find_project(project_id)
        if project_id.to_i.to_s == project_id
          Project.find_by(id: project_id.to_i)
        else
          Project.find_by(identifier: project_id) || Project.find_by(id: project_id.to_i)
        end
      end

      # トラッカー取得ヘルパー（projectなし版）
      def find_tracker(tracker_type)
        tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
        Tracker.find_by(name: tracker_name)
      end

      # トラッカー取得ヘルパー（project検証あり版）
      def find_tracker_for_project(tracker_type, project)
        tracker = find_tracker(tracker_type)
        return nil unless tracker
        return nil unless project.trackers.include?(tracker)
        tracker
      end

      # エラーレスポンス生成
      def error_response(message, details = {})
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: false,
            error: message,
            details: details
          })
        }])
      end

      # 成功レスポンス生成
      def success_response(data = {})
        MCP::Tool::Response.new([{
          type: "text",
          text: JSON.generate({
            success: true
          }.merge(data))
        }])
      end
    end
  end
end
