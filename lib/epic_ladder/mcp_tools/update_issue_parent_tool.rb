# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケット親子関係更新MCPツール
    # チケットの親チケットを変更する
    #
    # @example
    #   ユーザー: 「Task #9999を UserStory #8888 の配下に移動して」
    #   AI: UpdateIssueParentToolを呼び出し
    #   結果: Task #9999の親がUserStory #8888になる
    class UpdateIssueParentTool < MCP::Tool
      extend BaseHelper
      description "Changes the parent-child relationship of an issue. Set parent_issue_id to null to remove parent."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID to move" },
          parent_issue_id: { type: "string", description: "New parent issue ID (null or empty to remove parent)" }
        },
        required: %w[issue_id parent_issue_id]
      )

      def self.call(issue_id:, parent_issue_id:, server_context:)
        Rails.logger.info "UpdateIssueParentTool#call started: issue_id=#{issue_id}, parent_issue_id=#{parent_issue_id}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # 古い親を記録
          old_parent = issue.parent

          # 親チケットの処理
          if parent_issue_id.blank? || parent_issue_id == 'null'
            # 親を解除
            issue.parent_issue_id = nil
            new_parent = nil
          else
            # 新しい親チケットを取得
            new_parent = Issue.find_by(id: parent_issue_id)
            return error_response("親チケットが見つかりません: #{parent_issue_id}") unless new_parent

            # 自分自身を親にできない
            if new_parent.id == issue.id
              return error_response("自分自身を親チケットに指定することはできません")
            end

            # 循環参照チェック（自分の子孫を親にできない）
            if is_descendant?(new_parent, issue)
              return error_response("循環参照になるため、この親子関係は設定できません",
                                    { hint: "指定した親チケットは現在のチケットの子孫です" })
            end

            issue.parent_issue_id = new_parent.id
          end

          unless issue.save
            return error_response("親子関係の更新に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            old_parent: old_parent ? {
              id: old_parent.id.to_s,
              subject: old_parent.subject,
              tracker: old_parent.tracker.name
            } : nil,
            new_parent: new_parent ? {
              id: new_parent.id.to_s,
              subject: new_parent.subject,
              tracker: new_parent.tracker.name
            } : nil
          )
        rescue StandardError => e
          Rails.logger.error "UpdateIssueParentTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # 循環参照チェック: target が issue の子孫かどうか
        # @param target [Issue] チェック対象
        # @param issue [Issue] 基準となるチケット
        # @return [Boolean] target が issue の子孫なら true
        def is_descendant?(target, issue)
          return false if issue.children.empty?

          issue.children.each do |child|
            return true if child.id == target.id
            return true if is_descendant?(target, child)
          end

          false
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end
      end
    end
  end
end
