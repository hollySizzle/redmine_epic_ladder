# frozen_string_literal: true

require_relative 'base_helper'

module EpicGrid
  module McpTools
    # バージョン一覧取得MCPツール
    # プロジェクト内のバージョンを一覧取得する
    #
    # @example
    #   ユーザー: 「sakura-ecプロジェクトのバージョン一覧を見せて」
    #   AI: ListVersionsToolを呼び出し
    #   結果: バージョン一覧が返却される（デフォルトはopen、期日近い順）
    class ListVersionsTool < MCP::Tool
      extend BaseHelper

      description "プロジェクト内のバージョン一覧を取得します。デフォルトはopen状態のみ、期日が近い順でソートされます。"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID、省略時はDEFAULT_PROJECT）" },
          status: { type: "string", description: "ステータスでフィルタ（open/locked/closed/all、デフォルト: open）" },
          sort: { type: "string", description: "ソート順（effective_date_asc/effective_date_desc/name_asc/name_desc、デフォルト: effective_date_asc）" },
          limit: { type: "number", description: "取得件数上限（デフォルト: 50）" }
        },
        required: []
      )

      def self.call(project_id: nil, status: "open", sort: "effective_date_asc", limit: 50, server_context:)
        Rails.logger.info "ListVersionsTool#call started: project_id=#{project_id || 'DEFAULT'}, status=#{status}, sort=#{sort}"

        begin
          # プロジェクト取得と権限チェック（server_contextからX-Default-Projectヘッダー値を参照）
          result = resolve_and_validate_project(project_id, server_context: server_context)
          return error_response(result[:error], result[:details] || {}) if result[:error]

          project = result[:project]

          # 権限チェック（バージョン閲覧はプロジェクト閲覧権限で十分）
          user = server_context[:user] || User.current
          unless user.allowed_to?(:view_issues, project)
            return error_response("プロジェクト閲覧権限がありません", { project: project.identifier })
          end

          # バージョン一覧取得
          versions = project.versions

          # ステータスフィルタ（デフォルト: open）
          versions = apply_status_filter(versions, status)

          # ソート（デフォルト: 期日昇順、NULLは最後）
          versions = apply_sort(versions, sort)

          # 件数制限
          versions = versions.limit(limit) if limit

          # バージョン情報構築
          version_list = versions.map do |version|
            {
              id: version.id.to_s,
              name: version.name,
              description: version.description,
              status: version.status,
              effective_date: version.effective_date&.iso8601,
              sharing: version.sharing,
              issues_count: version.fixed_issues.count,
              open_issues_count: version.fixed_issues.open.count,
              closed_issues_count: version.fixed_issues.where(status: IssueStatus.where(is_closed: true)).count,
              url: version_url(version)
            }
          end

          # 成功レスポンス
          success_response(
            project: {
              id: project.id.to_s,
              identifier: project.identifier,
              name: project.name
            },
            versions: version_list,
            total_count: version_list.size
          )
        rescue StandardError => e
          Rails.logger.error "ListVersionsTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # ステータスフィルタ適用
        # @param versions [ActiveRecord::Relation] バージョンのクエリ
        # @param status [String] open/locked/closed/all
        def apply_status_filter(versions, status)
          case status&.downcase
          when 'open'
            versions.where(status: 'open')
          when 'locked'
            versions.where(status: 'locked')
          when 'closed'
            versions.where(status: 'closed')
          when 'all'
            versions
          else
            # デフォルトはopen
            versions.where(status: 'open')
          end
        end

        # ソート適用
        # @param versions [ActiveRecord::Relation] バージョンのクエリ
        # @param sort [String] ソート指定
        def apply_sort(versions, sort)
          case sort&.downcase
          when 'effective_date_asc'
            # NULLは最後に配置
            versions.order(Arel.sql('effective_date IS NULL, effective_date ASC'))
          when 'effective_date_desc'
            # NULLは最後に配置
            versions.order(Arel.sql('effective_date IS NULL, effective_date DESC'))
          when 'name_asc'
            versions.order(name: :asc)
          when 'name_desc'
            versions.order(name: :desc)
          else
            # デフォルトは期日昇順
            versions.order(Arel.sql('effective_date IS NULL, effective_date ASC'))
          end
        end

        # RedmineのVersion URLを生成
        def version_url(version)
          "#{Setting.protocol}://#{Setting.host_name}/versions/#{version.id}"
        end
      end
    end
  end
end
