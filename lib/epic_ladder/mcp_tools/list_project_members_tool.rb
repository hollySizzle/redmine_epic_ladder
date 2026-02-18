# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # プロジェクトメンバー一覧取得MCPツール
    # プロジェクトに所属するメンバーを一覧取得する
    # チケットの担当者を設定する際に、担当可能なユーザーを探すのに使用
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトのメンバー一覧を見せて」
    #   AI: ListProjectMembersToolを呼び出し
    #   結果: メンバー一覧が返却される
    #
    # @example
    #   ユーザー: 「このタスクを担当できる人は誰？」
    #   AI: ListProjectMembersToolを呼び出し
    #   結果: 担当者候補となるメンバー一覧が返却される
    class ListProjectMembersTool < MCP::Tool
      extend BaseHelper

      description "Lists project members. Use this to find assignee candidates."

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          role_name: { type: "string", description: "Filter by role name (optional)" },
          limit: { type: "number", description: "Max results (default: 100)" }
        },
        required: []
      )

      def self.call(project_id: nil, role_name: nil, limit: 100, server_context:)
        Rails.logger.info "ListProjectMembersTool#call started: project_id=#{project_id || 'DEFAULT'}"

        begin
          # プロジェクト取得と権限チェック
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック（メンバー一覧閲覧には少なくともプロジェクト閲覧権限が必要）
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("プロジェクト閲覧権限がありません", { project: project.identifier })
          end

          # メンバー取得
          members = project.members.includes(:user, :roles)

          # ロールフィルタ
          if role_name.present?
            role = Role.find_by(name: role_name)
            if role
              members = members.joins(:roles).where(member_roles: { role_id: role.id })
            else
              return error_response("指定されたロールが見つかりません: #{role_name}")
            end
          end

          # 件数制限
          members = members.limit(limit) if limit

          # メンバー情報構築
          member_list = members.map do |member|
            next unless member.user # Userが存在しないメンバーをスキップ

            {
              user_id: member.user.id.to_s,
              login: member.user.login,
              name: member.user.name,
              mail: member.user.mail,
              roles: member.roles.map do |role|
                {
                  id: role.id.to_s,
                  name: role.name
                }
              end,
              is_active: member.user.active?
            }
          end.compact

          # アクティブユーザーのみに絞る（担当者候補として適切なユーザー）
          active_members = member_list.select { |m| m[:is_active] }

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            members: active_members,
            total_count: active_members.size,
            hint: "担当者変更にはupdate_issue_assigneeツールを使用してください"
          )
        rescue StandardError => e
          Rails.logger.error "ListProjectMembersTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end
    end
  end
end
