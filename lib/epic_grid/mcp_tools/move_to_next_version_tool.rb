# frozen_string_literal: true

module EpicGrid
  module McpTools
    # チケットを次のVersionに移動するMCPツール
    # スケジュール変更（リスケ）を簡単に行う
    #
    # @example
    #   ユーザー: 「UserStory #123を次のVersionに移動して（リスケ）」
    #   AI: MoveToNextVersionToolを呼び出し
    #   結果: UserStory #123とその配下が次のVersionに移動される
    class MoveToNextVersionTool < MCP::Tool
      description "チケット（UserStory推奨）を次のVersionに移動します（リスケ）。配下のTask/Bug/Testも自動的に移動されます。"

      input_schema(
        properties: {
          issue_id: { type: "string", description: "チケットID" }
        },
        required: ["issue_id"]
      )

      def self.call(issue_id:, server_context:)
        Rails.logger.info "MoveToNextVersionTool#call started: issue_id=#{issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # 現在のVersion取得
          current_version = issue.fixed_version
          return error_response("チケットにVersionが設定されていません") unless current_version

          # 次のVersionを検索
          next_version = find_next_version(issue.project, current_version)
          return error_response("次のVersionが見つかりません", { current_version: current_version.name }) unless next_version

          # チケットに次のVersionを設定
          old_version = issue.fixed_version
          issue.fixed_version = next_version

          unless issue.save
            return error_response("Version移動に失敗しました", { errors: issue.errors.full_messages })
          end

          # 配下のチケット（子チケット）も同じVersionに設定
          updated_children = []
          if issue.children.any?
            issue.children.each do |child|
              child.fixed_version = next_version
              if child.save
                updated_children << {
                  id: child.id.to_s,
                  subject: child.subject,
                  tracker: child.tracker.name
                }
              end
            end
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            tracker: issue.tracker.name,
            old_version: {
              id: old_version.id.to_s,
              name: old_version.name,
              effective_date: old_version.effective_date&.to_s
            },
            new_version: {
              id: next_version.id.to_s,
              name: next_version.name,
              effective_date: next_version.effective_date&.to_s
            },
            updated_children: updated_children.any? ? updated_children : nil,
            updated_children_count: updated_children.size
          )
        rescue StandardError => e
          Rails.logger.error "MoveToNextVersionTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # 次のVersionを検索
        # - 現在のVersionより後のeffective_date
        # - status = 'open'
        # - effective_dateが最も近いもの
        def find_next_version(project, current_version)
          project.versions
                 .where(status: 'open')
                 .where('effective_date > ?', current_version.effective_date)
                 .order(:effective_date)
                 .first
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
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
end
