# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # Redmineプロジェクト作成MCPツール
    class CreateProjectTool < MCP::Tool
      extend BaseHelper

      description "Creates a Redmine project only when MCP project creation is explicitly enabled and the requested parent is allowed."

      input_schema(
        properties: {
          name: { type: "string", description: "Project name" },
          identifier: { type: "string", description: "Project identifier. Lowercase letters, numbers, dashes and underscores. Generated from name if omitted." },
          description: { type: "string", description: "Project description (optional)" },
          parent_project_id: { type: "string", description: "Parent project ID or identifier. Required unless root project creation is enabled." },
          is_public: { type: "boolean", description: "Whether the project is public (default: false)" },
          inherit_members: { type: "boolean", description: "Inherit members from parent project (default: true when parent is set)" },
          enabled_module_names: {
            type: "array",
            items: { type: "string" },
            description: "Enabled Redmine module names. Defaults to Redmine's default project modules."
          },
          tracker_ids: {
            type: "array",
            items: { type: "string" },
            description: "Tracker IDs to enable. Defaults to Redmine's default tracker behavior."
          },
          mcp_enabled: { type: "boolean", description: "Enable Epic Ladder MCP access on the created project (default: true)" }
        },
        required: ["name"]
      )

      def self.call(name:, identifier: nil, description: nil, parent_project_id: nil, is_public: false,
                    inherit_members: nil, enabled_module_names: nil, tracker_ids: nil, mcp_enabled: true,
                    server_context:)
        Rails.logger.info "CreateProjectTool#call started: name=#{name}, parent_project_id=#{parent_project_id || 'ROOT'}"

        unless ProjectValidator.mcp_enabled?
          return error_response("MCP APIが無効になっています。管理画面でMCP APIを有効にしてください。")
        end

        unless ProjectValidator.project_creation_enabled?
          return ProjectValidator.project_creation_disabled_response
        end

        user = server_context[:user] || User.current
        User.current = user
        parent_project = find_parent_project(parent_project_id)

        if parent_project_id.present? && parent_project.nil?
          return error_response("親プロジェクトが見つかりません: #{parent_project_id}")
        end

        unless ProjectValidator.project_creation_allowed_parent?(parent_project, user)
          return error_response(
            "指定された場所へのプロジェクト作成は許可されていません",
            {
              parent_project_id: parent_project&.identifier,
              scope: ProjectValidator.project_creation_scope,
              hint: "管理画面のMCPプロジェクト作成設定とRedmine権限を確認してください"
            }
          )
        end

        project = Project.new
        project.safe_attributes = build_project_attributes(
          name: name,
          identifier: identifier.presence || generate_identifier(name),
          description: description,
          parent_project: parent_project,
          is_public: is_public,
          inherit_members: inherit_members,
          enabled_module_names: enabled_module_names,
          tracker_ids: tracker_ids
        )

        unless project.save
          return error_response("プロジェクト作成に失敗しました", { errors: project.errors.full_messages })
        end

        project.add_default_member(user) unless user.admin?
        save_project_mcp_setting(project, mcp_enabled)

        success_response(
          project: project_payload(project),
          mcp_enabled: EpicLadder::ProjectSetting.mcp_enabled?(project),
          hint: "Use project.identifier as project_id for subsequent MCP tools."
        )
      rescue StandardError => e
        Rails.logger.error "CreateProjectTool error: #{e.class.name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
      end

      class << self
        private

        def find_parent_project(project_id)
          return nil if project_id.blank?

          if project_id.to_i.to_s == project_id.to_s
            Project.find_by(id: project_id.to_i)
          else
            Project.find_by(identifier: project_id) || Project.find_by(id: project_id.to_i)
          end
        end

        def build_project_attributes(name:, identifier:, description:, parent_project:, is_public:, inherit_members:,
                                     enabled_module_names:, tracker_ids:)
          attrs = {
            'name' => name,
            'identifier' => identifier,
            'description' => description,
            'is_public' => is_public ? '1' : '0'
          }
          attrs['parent_id'] = parent_project.id.to_s if parent_project
          attrs['inherit_members'] = inherit_members.nil? ? (parent_project ? '1' : '0') : (inherit_members ? '1' : '0')
          attrs['enabled_module_names'] = enabled_module_names if enabled_module_names.present?
          attrs['tracker_ids'] = tracker_ids if tracker_ids.present?
          attrs
        end

        def generate_identifier(name)
          base = name.to_s.downcase.gsub(/[^a-z0-9_-]+/, '-').gsub(/\A-+|-+\z/, '')
          base = "project-#{Time.current.to_i}" if base.blank?
          identifier = base
          suffix = 2
          while Project.exists?(identifier: identifier)
            identifier = "#{base}-#{suffix}"
            suffix += 1
          end
          identifier
        end

        def save_project_mcp_setting(project, mcp_enabled)
          setting = EpicLadder::ProjectSetting.for_project(project)
          setting.mcp_enabled = mcp_enabled == true || mcp_enabled.to_s == '1'
          setting.save!
        end

        def project_payload(project)
          {
            id: project.id.to_s,
            identifier: project.identifier,
            name: project.name,
            description: project.description,
            url: "#{Setting.protocol}://#{Setting.host_name}/projects/#{project.identifier}",
            parent: project.parent ? {
              id: project.parent.id.to_s,
              identifier: project.parent.identifier,
              name: project.parent.name
            } : nil
          }
        end
      end
    end
  end
end
