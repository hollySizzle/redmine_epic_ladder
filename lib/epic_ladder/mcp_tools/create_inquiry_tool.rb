# frozen_string_literal: true

require_relative 'issue_creation_service'
require_relative 'project_validator'

module EpicLadder
  module McpTools
    # 問合せ起票MCPツール
    # プロジェクト内の「問合せ」Featureを自動検出し、配下にUserStoryを作成する
    # PMO相談時にFeature IDを知らなくても起票できるようにするためのツール
    #
    # @example
    #   ユーザー: 「本番環境のログが消えている件をPMOに相談したい」
    #   AI: CreateInquiryToolを呼び出し
    #   結果: 問合せFeature配下にUserStory #1234が作成される
    class CreateInquiryTool < MCP::Tool
      description "Creates an inquiry (問合せ) UserStory under the project's inquiry Feature. " \
                  "Use when you need to raise a question or consultation to PMO without knowing the Feature ID. " \
                  "The inquiry Feature is resolved from project settings, or auto-detected by subject containing '問合せ'."

      input_schema(
        properties: {
          project_id: { type: "string", description: "Project ID (identifier or numeric, uses DEFAULT_PROJECT if omitted)" },
          subject: { type: "string", description: "Inquiry subject/title (what you want to ask or consult about)" },
          description: { type: "string", description: "Detailed description of the inquiry" },
          assigned_to_id: { type: "string", description: "Assignee user ID (defaults to current user)" }
        },
        required: ["subject"]
      )

      def self.call(project_id: nil, subject:, description: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateInquiryTool#call started: project_id=#{project_id}, subject=#{subject}"

        begin
          # 1. プロジェクト解決・検証
          resolved_project_id = ProjectValidator.resolve_project_id(project_id, server_context: server_context)
          unless resolved_project_id
            return error_response("プロジェクトIDが指定されていません。DEFAULT_PROJECTを設定するか、project_idを指定してください")
          end

          project = find_project(resolved_project_id)
          unless project
            return error_response("プロジェクトが見つかりません: #{resolved_project_id}")
          end

          # 2. 問合せFeature解決（ProjectSetting → 命名規則フォールバック）
          inquiry_feature = EpicLadder::ProjectSetting.inquiry_feature(project)
          unless inquiry_feature
            return error_response(
              "問合せFeatureが見つかりません",
              {
                hint: "プロジェクト設定でinquiry_feature_idを設定するか、subjectに「問合せ」を含むFeatureを作成してください。",
                project: project.identifier
              }
            )
          end

          # 3. IssueCreationServiceに委譲してUserStory作成
          service = IssueCreationService.new(server_context: server_context)
          result = service.create_issue(
            tracker_type: :user_story,
            project_id: project.identifier,
            subject: subject,
            description: description || subject,
            parent_issue_id: inquiry_feature.id.to_s,
            assigned_to_id: assigned_to_id
          )

          return error_response(result[:error], result[:details]) unless result[:success]

          success_response(
            inquiry_id: result[:issue_id],
            inquiry_url: result[:issue_url],
            subject: result[:subject],
            tracker: result[:tracker],
            inquiry_feature: {
              id: inquiry_feature.id.to_s,
              subject: inquiry_feature.subject
            },
            version: result[:version],
            assigned_to: result[:assigned_to]
          )
        rescue StandardError => e
          Rails.logger.error "CreateInquiryTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # プロジェクト取得（識別子 or ID）
        def find_project(project_id)
          if project_id.to_i.to_s == project_id.to_s
            Project.find_by(id: project_id.to_i)
          else
            Project.find_by(identifier: project_id) || Project.find_by(id: project_id.to_i)
          end
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
