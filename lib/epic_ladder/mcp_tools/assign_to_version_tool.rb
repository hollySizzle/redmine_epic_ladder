# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケットをVersionに割り当てるMCPツール
    # UserStoryをVersionに割り当て、配下のTask/Bug/Testも自動的に同じVersionに設定する
    # バージョンの期日に基づいて開始日・終了日も自動設定する
    #
    # @example
    #   ユーザー: 「UserStory #123をVersion 1.2に割り当てて」
    #   AI: AssignToVersionToolを呼び出し
    #   結果: UserStory #123とその配下のTask/Bug/Testが全てVersion 1.2に設定され、
    #         開始日・終了日も自動設定される
    class AssignToVersionTool < MCP::Tool
      extend BaseHelper
      description "チケット（UserStory推奨）をVersionに割り当てます。UserStoryの場合、配下のTask/Bug/Testも自動的に同じVersionに設定されます。バージョンの期日に基づいて開始日・終了日も自動設定されます。"

      input_schema(
        properties: {
          issue_id: { type: "string", description: "チケットID" },
          version_id: { type: "string", description: "Version ID" },
          update_parent: { type: "boolean", description: "親チケットも同時に更新するか（デフォルト: false）" },
          propagate_to_children: { type: "boolean", description: "子チケットにもバージョンと日付を伝播するか（デフォルト: true）" }
        },
        required: ["issue_id", "version_id"]
      )

      def self.call(issue_id:, version_id:, update_parent: false, propagate_to_children: true, server_context:)
        Rails.logger.info "AssignToVersionTool#call started: issue_id=#{issue_id}, version_id=#{version_id}, " \
                          "update_parent=#{update_parent}, propagate_to_children=#{propagate_to_children}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # Version取得
          version = Version.find_by(id: version_id)
          return error_response("Versionが見つかりません: #{version_id}") unless version

          # 権限チェック
          user = server_context[:user] || User.current
          User.current = user # VersionDateManagerがUser.currentを使用するため設定
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # バージョンが割り当て可能かチェック
          unless issue.assignable_versions.include?(version)
            assignable_versions = issue.assignable_versions.map do |v|
              {
                id: v.id.to_s,
                name: v.name,
                status: v.status,
                effective_date: v.effective_date&.to_s,
                project_id: v.project_id.to_s
              }
            end

            return error_response(
              "Version割り当てに失敗しました",
              {
                errors: ["Target version is not included in the list"],
                requested_version_id: version_id,
                requested_version_name: version.name,
                requested_version_status: version.status,
                assignable_versions: assignable_versions,
                assignable_version_count: assignable_versions.size
              }
            )
          end

          # VersionDateManagerを使用してバージョン・日付を一括更新
          result = EpicLadder::VersionDateManager.change_version_with_dates(
            issue,
            version_id,
            update_parent: update_parent,
            propagate_to_children: propagate_to_children
          )

          # 更新された子チケット情報を構築
          updated_children = result[:children].map do |child|
            {
              id: child.id.to_s,
              subject: child.subject,
              tracker: child.tracker.name,
              start_date: child.start_date&.to_s,
              due_date: child.due_date&.to_s
            }
          end

          # 成功レスポンス
          issue.reload
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            tracker: issue.tracker.name,
            version: {
              id: version.id.to_s,
              name: version.name,
              effective_date: version.effective_date&.to_s
            },
            dates: result[:dates] ? {
              start_date: result[:dates][:start_date]&.to_s,
              due_date: result[:dates][:due_date]&.to_s
            } : nil,
            updated_parent: result[:parent] ? {
              id: result[:parent].id.to_s,
              subject: result[:parent].subject,
              start_date: result[:parent].start_date&.to_s,
              due_date: result[:parent].due_date&.to_s
            } : nil,
            updated_siblings_count: result[:siblings].size,
            updated_children: updated_children.any? ? updated_children : nil,
            updated_children_count: updated_children.size,
            parent_update_skipped: result[:parent_update_skipped],
            skip_reason: result[:skip_reason]&.to_s
          )
        rescue StandardError => e
          Rails.logger.error "AssignToVersionTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end
      end
    end
  end
end
