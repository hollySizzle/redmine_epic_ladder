# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # Redmineプロジェクト検索MCPツール
    class SearchProjectsTool < MCP::Tool
      extend BaseHelper

      description "Searches visible Redmine projects by name or identifier. Use before creating issues when the project_id is unknown."

      input_schema(
        properties: {
          query: { type: "string", description: "Project name or identifier keyword. Omit to list visible projects." },
          limit: { type: "number", description: "Max results (default: 20, max: 100)" },
          include_archived: { type: "boolean", description: "Include archived/closed projects (default: false)" }
        },
        required: []
      )

      def self.call(query: nil, limit: 20, include_archived: false, server_context:)
        Rails.logger.info "SearchProjectsTool#call started: query=#{query.inspect}, limit=#{limit}"

        unless ProjectValidator.mcp_enabled?
          return error_response("MCP APIが無効になっています。管理画面でMCP APIを有効にしてください。")
        end

        user = server_context[:user] || User.current
        User.current = user

        projects = Project.visible(user)
        projects = projects.where(status: Project::STATUS_ACTIVE) unless include_archived
        projects = projects.like(query) if query.present?
        projects = projects.order(:lft, :name).limit(normalize_limit(limit))

        success_response(
          projects: projects.map { |project| project_payload(project, user) },
          total_count: projects.size,
          hint: "Use the identifier as project_id for other MCP tools."
        )
      rescue StandardError => e
        Rails.logger.error "SearchProjectsTool error: #{e.class.name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
      end

      class << self
        private

        def normalize_limit(limit)
          value = limit.to_i
          value = 20 if value <= 0
          [value, 100].min
        end

        def project_payload(project, user)
          {
            id: project.id.to_s,
            identifier: project.identifier,
            name: project.name,
            status: project.status,
            is_public: project.is_public?,
            parent: project.parent ? {
              id: project.parent.id.to_s,
              identifier: project.parent.identifier,
              name: project.parent.name
            } : nil,
            mcp_enabled: EpicLadder::ProjectSetting.mcp_enabled?(project),
            can_create_subproject: user.allowed_to?(:add_subprojects, project),
            url: project_url(project)
          }
        end

        def project_url(project)
          "#{Setting.protocol}://#{Setting.host_name}/projects/#{project.identifier}"
        end
      end
    end
  end
end
