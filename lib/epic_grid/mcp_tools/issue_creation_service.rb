# frozen_string_literal: true

require_relative 'project_validator'

module EpicGrid
  module McpTools
    # チケット作成共通サービス
    # すべてのMCPチケット作成ツールで使用される共通ロジックを提供
    class IssueCreationService
      attr_reader :server_context, :user

      def initialize(server_context:)
        @server_context = server_context
        @user = server_context[:user] || User.current
      end

      # チケット作成メインメソッド
      # @param tracker_type [Symbol] トラッカー種別（:task, :bug, :test, :epic, :feature, :user_story）
      # @param project_id [String, nil] プロジェクトID（省略時はDEFAULT_PROJECT）
      # @param subject [String, nil] 件名（省略時はdescriptionから抽出）
      # @param description [String] 説明
      # @param parent_issue_id [String, nil] 親チケットID
      # @param version_id [String, nil] VersionID
      # @param assigned_to_id [String, nil] 担当者ID
      # @return [Hash] 成功/エラー情報を含むハッシュ
      def create_issue(tracker_type:, project_id: nil, subject: nil, description:, parent_issue_id: nil, version_id: nil, assigned_to_id: nil)
        # 0. MCP API有効チェック
        unless ProjectValidator.mcp_enabled?
          return error_result("MCP APIが無効になっています。管理画面でMCP APIを有効にしてください。")
        end

        # 1. プロジェクトID解決（server_contextからX-Default-Projectヘッダー値を参照）
        resolved_project_id = ProjectValidator.resolve_project_id(project_id, server_context: server_context)
        return error_result("プロジェクトIDが指定されていません。DEFAULT_PROJECTを設定するか、project_idを指定してください") unless resolved_project_id

        # 2. プロジェクト取得
        project = find_project(resolved_project_id)
        return error_result("プロジェクトが見つかりません: #{resolved_project_id}") unless project

        # 3. プロジェクト単位のMCP許可チェック
        unless ProjectValidator.project_allowed?(project)
          return error_result(
            "プロジェクト '#{project.identifier}' でMCP APIが許可されていません",
            { hint: "プロジェクト設定 → Epic Grid タブでMCP APIを有効にしてください" }
          )
        end

        # 4. 権限チェック
        unless user.allowed_to?(:add_issues, project)
          return error_result("チケット作成権限がありません", { project: project.identifier })
        end

        # 5. トラッカー取得
        tracker = find_tracker(tracker_type, project)
        tracker_display_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
        return error_result("#{tracker_display_name}トラッカーが設定されていません") unless tracker

        # 6. 親チケット解決
        parent_issue_result = resolve_parent_issue(parent_issue_id)
        return parent_issue_result if parent_issue_result.is_a?(Hash) && !parent_issue_result[:success]
        parent_issue = parent_issue_result

        # 7. Version解決
        version = resolve_version(project, version_id, parent_issue)

        # 8. 担当者解決
        assigned_to = resolve_assigned_to(assigned_to_id)

        # 9. subject抽出
        final_subject = subject.presence || extract_subject(description)

        # 10. チケット作成
        issue = Issue.new(
          project: project,
          tracker: tracker,
          subject: final_subject,
          description: description,
          parent_issue_id: parent_issue&.id,
          fixed_version_id: version&.id,
          assigned_to: assigned_to,
          author: user,
          status: IssueStatus.first
        )

        unless issue.save
          return error_result("チケット作成に失敗しました", { errors: issue.errors.full_messages })
        end

        # 11. 成功レスポンス生成
        success_result(
          issue: issue,
          parent_issue: parent_issue,
          version: version,
          assigned_to: assigned_to
        )
      end

      private

      # プロジェクト取得（識別子 or ID）
      def find_project(project_id)
        if project_id.to_i.to_s == project_id
          Project.find_by(id: project_id.to_i)
        else
          Project.find_by(identifier: project_id) || Project.find_by(id: project_id.to_i)
        end
      end

      # トラッカー取得
      def find_tracker(tracker_type, project)
        tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
        tracker = Tracker.find_by(name: tracker_name)
        return nil unless tracker
        return nil unless project.trackers.include?(tracker)
        tracker
      end

      # 親チケット解決
      def resolve_parent_issue(parent_issue_id)
        return nil if parent_issue_id.blank?

        issue = Issue.find_by(id: parent_issue_id)
        return error_result("親チケットが見つかりません: #{parent_issue_id}") unless issue

        issue
      end

      # Version解決
      def resolve_version(project, version_id, parent_issue)
        if version_id.present?
          Version.find_by(id: version_id)
        elsif parent_issue&.fixed_version
          parent_issue.fixed_version
        else
          project.versions.where(status: 'open').order(:effective_date).first
        end
      end

      # 担当者解決
      def resolve_assigned_to(assigned_to_id)
        return user if assigned_to_id.blank?
        User.find_by(id: assigned_to_id)
      end

      # descriptionから簡潔なsubjectを抽出
      def extract_subject(description)
        first_sentence = description.split(/[。\n]/).first&.strip || description
        first_sentence.truncate(255)
      end

      # エラー結果生成
      def error_result(message, details = {})
        {
          success: false,
          error: message,
          details: details
        }
      end

      # 成功結果生成
      def success_result(issue:, parent_issue:, version:, assigned_to:)
        {
          success: true,
          issue_id: issue.id.to_s,
          issue_url: issue_url(issue.id),
          subject: issue.subject,
          tracker: issue.tracker.name,
          parent_issue: parent_issue ? {
            id: parent_issue.id.to_s,
            subject: parent_issue.subject
          } : nil,
          version: version ? {
            id: version.id.to_s,
            name: version.name
          } : nil,
          assigned_to: assigned_to ? {
            id: assigned_to.id.to_s,
            name: assigned_to.name
          } : nil
        }
      end

      # RedmineのIssue URLを生成
      def issue_url(issue_id)
        "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
      end
    end
  end
end
