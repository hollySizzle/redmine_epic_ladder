# frozen_string_literal: true

require_relative 'base_helper'

module EpicLadder
  module McpTools
    # カスタムフィールド更新MCPツール
    # チケットのカスタムフィールドを更新する
    #
    # @example
    #   ユーザー: 「Task #9999のカスタムフィールド『見積時間』を8に更新して」
    #   AI: UpdateCustomFieldsToolを呼び出し
    #   結果: Task #9999のカスタムフィールドが更新される
    class UpdateCustomFieldsTool < MCP::Tool
      extend BaseHelper
      description "Updates custom fields of an issue. Fields can be specified by ID (number) or name (string)."

      input_schema(
        properties: {
          issue_id: { type: "string", description: "Issue ID" },
          custom_fields: {
            type: "object",
            description: "Custom field values. Key is field ID or name, value is the new value. Example: {\"Estimated Hours\": \"8\", \"Priority Level\": \"High\"}"
          }
        },
        required: %w[issue_id custom_fields]
      )

      def self.call(issue_id:, custom_fields:, server_context:)
        Rails.logger.info "UpdateCustomFieldsTool#call started: issue_id=#{issue_id}, custom_fields=#{custom_fields}"

        begin
          # チケット取得
          issue = Issue.find_by(id: issue_id)
          return error_response("チケットが見つかりません: #{issue_id}") unless issue

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:edit_issues, issue.project)
            return error_response("チケット編集権限がありません", { project: issue.project.identifier })
          end

          # カスタムフィールドの解決と更新
          available_custom_fields = issue.available_custom_fields
          updates = []
          errors = []

          custom_fields.each do |key, value|
            cf = find_custom_field(key, available_custom_fields)
            if cf
              old_value = issue.custom_field_value(cf.id)
              issue.custom_field_values = { cf.id => value }
              updates << {
                field_id: cf.id.to_s,
                field_name: cf.name,
                old_value: old_value,
                new_value: value
              }
            else
              errors << "カスタムフィールドが見つかりません: #{key}"
            end
          end

          return error_response("カスタムフィールドが見つかりません", { errors: errors }) if updates.empty? && errors.any?

          unless issue.save
            return error_response("カスタムフィールドの更新に失敗しました", { errors: issue.errors.full_messages })
          end

          # 成功レスポンス
          response_data = {
            issue_id: issue.id.to_s,
            issue_url: issue_url(issue.id),
            subject: issue.subject,
            updated_fields: updates
          }
          response_data[:warnings] = errors if errors.any?

          success_response(response_data)
        rescue StandardError => e
          Rails.logger.error "UpdateCustomFieldsTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # カスタムフィールドを検索（IDまたは名前で）
        # @param key [String, Integer] フィールドIDまたはフィールド名
        # @param available_fields [Array<CustomField>] 利用可能なカスタムフィールド
        # @return [CustomField, nil]
        def find_custom_field(key, available_fields)
          # 数値IDとして検索
          if key.to_s =~ /^\d+$/
            cf = available_fields.find { |f| f.id == key.to_i }
            return cf if cf
          end

          # 名前で完全一致
          cf = available_fields.find { |f| f.name == key.to_s }
          return cf if cf

          # 名前で大文字小文字無視
          cf = available_fields.find { |f| f.name.downcase == key.to_s.downcase }
          return cf if cf

          # 名前で部分一致
          available_fields.find { |f| f.name.downcase.include?(key.to_s.downcase) }
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
        end
      end
    end
  end
end
