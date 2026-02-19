# frozen_string_literal: true
require_relative 'base_helper'

module EpicLadder
  module McpTools
    # チケットコピーMCPツール
    # 既存チケットを元に属性をコピーした新規チケットを作成する
    #
    # @example
    #   ユーザー: 「Task #123をコピーして新しいチケットを作って」
    #   AI: CopyIssueToolを呼び出し
    #   結果: 元チケットと同じトラッカー・親・バージョン等を持つ新チケットが作成される
    class CopyIssueTool < MCP::Tool
      extend BaseHelper
      description "Copies an existing issue with optional overrides. Creates a new issue with the same tracker, parent, version, description, and priority as the source issue."

      input_schema(
        properties: {
          source_issue_id: { type: "string", description: "Source issue ID to copy from" },
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses source issue's project if omitted)" },
          subject: { type: "string", description: "Override subject (uses source if omitted)" },
          description: { type: "string", description: "Override description (uses source if omitted)" },
          parent_issue_id: { type: "string", description: "Override parent issue ID (uses source if omitted)" },
          version_id: { type: "string", description: "Override version ID (uses source if omitted)" },
          assigned_to_id: { type: "string", description: "Assignee user ID (defaults to current user)" }
        },
        required: ["source_issue_id"]
      )

      def self.call(source_issue_id:, project_id: nil, subject: nil, description: nil, parent_issue_id: nil, version_id: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CopyIssueTool#call started: source_issue_id=#{source_issue_id}"

        begin
          # MCP有効チェック
          unless ProjectValidator.mcp_enabled?
            return ProjectValidator.mcp_disabled_response
          end

          # ソースチケット取得
          source_issue = Issue.find_by(id: source_issue_id)
          return error_response("コピー元チケットが見つかりません: #{source_issue_id}") unless source_issue

          # プロジェクト決定
          project = if project_id.present?
                      find_project(project_id)
                    else
                      source_issue.project
                    end
          return error_response("プロジェクトが見つかりません: #{project_id}") unless project

          # プロジェクトMCP許可チェック
          unless ProjectValidator.project_allowed?(project)
            return ProjectValidator.project_not_allowed_response(project)
          end

          # 権限チェック
          user = server_context[:user] || User.current

          # ソースチケットの閲覧権限チェック
          unless user.allowed_to?(:view_issues, source_issue.project)
            return error_response("コピー元チケットの閲覧権限がありません", { project: source_issue.project.identifier })
          end

          unless user.allowed_to?(:add_issues, project)
            return error_response("チケット作成権限がありません", { project: project.identifier })
          end

          # 担当者決定
          assignee = if assigned_to_id.present?
                       User.find_by(id: assigned_to_id)
                     else
                       user
                     end

          # 新規チケット作成
          new_issue = Issue.new
          new_issue.project = project
          new_issue.tracker = source_issue.tracker
          new_issue.subject = subject.present? ? subject : source_issue.subject
          new_issue.description = description.present? ? description : source_issue.description
          new_issue.parent_issue_id = parent_issue_id.present? ? parent_issue_id : source_issue.parent_id
          new_issue.fixed_version_id = version_id.present? ? version_id : source_issue.fixed_version_id
          new_issue.priority = source_issue.priority
          new_issue.assigned_to = assignee
          new_issue.author = user
          new_issue.status = IssueStatus.first
          new_issue.done_ratio = 0

          unless new_issue.save
            return error_response("チケット作成に失敗しました", { errors: new_issue.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            issue_id: new_issue.id.to_s,
            issue_url: issue_url(new_issue.id),
            subject: new_issue.subject,
            tracker: new_issue.tracker.name,
            source_issue: {
              id: source_issue.id.to_s,
              subject: source_issue.subject
            },
            parent_issue: new_issue.parent ? { id: new_issue.parent.id.to_s, subject: new_issue.parent.subject } : nil,
            version: new_issue.fixed_version ? { id: new_issue.fixed_version.id.to_s, name: new_issue.fixed_version.name } : nil,
            assigned_to: new_issue.assigned_to ? { id: new_issue.assigned_to.id.to_s, name: new_issue.assigned_to.name } : nil
          )
        rescue StandardError => e
          Rails.logger.error "CopyIssueTool error: #{e.class.name}: #{e.message}"
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
