# frozen_string_literal: true

module EpicGrid
  module McpTools
    # タスク作成MCPツール
    # 自然言語からTaskチケットを作成する
    #
    # @example
    #   ユーザー: 「カートのリファクタリングタスクを作って」
    #   AI: CreateTaskToolを呼び出し
    #   結果: Task #9999が作成される
    class CreateTaskTool < MCP::Tool
      description "自然言語からTaskチケットを作成します。例: 'カートのリファクタリング'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          description: { type: "string", description: "タスクの説明（自然言語OK）" },
          parent_user_story_id: { type: "string", description: "親UserStory ID（省略時は推論）" },
          version_id: { type: "string", description: "Version ID（省略時は親から継承）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["project_id", "description"]
      )

      def call(project_id:, description:, parent_user_story_id: nil, version_id: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateTaskTool#call started: project_id=#{project_id}, description=#{description}"

        begin
          # プロジェクト取得（識別子 or 数値IDどちらでも対応）
          project = find_project(project_id)
        Rails.logger.info "Project found: #{project&.identifier}"
        unless project
          return error_response("プロジェクトが見つかりません: #{project_id}")
        end

        # 権限チェック
        user = server_context[:user] || User.current
        unless user.allowed_to?(:add_issues, project)
          return error_response("タスク作成権限がありません", { project: project.identifier })
        end

        # Taskトラッカー取得
        task_tracker = find_tracker(:task)
        return error_response("Taskトラッカーが設定されていません") unless task_tracker

        # 親UserStory解決
        parent_user_story = resolve_parent_user_story(project, parent_user_story_id, description)

        # Version解決
        version = resolve_version(project, version_id, parent_user_story)

        # 担当者解決
        assigned_to = resolve_assigned_to(project, assigned_to_id, user)

        # subject抽出（自然言語から簡潔なタイトルを生成）
        subject = extract_subject(description)

        # Task作成
        task = Issue.new(
          project: project,
          tracker: task_tracker,
          subject: subject,
          description: description,
          parent_issue_id: parent_user_story&.id,
          fixed_version_id: version&.id,
          assigned_to: assigned_to,
          author: user,
          status: IssueStatus.first
        )

        unless task.save
          return error_response("タスク作成に失敗しました", { errors: task.errors.full_messages })
        end

        # 成功レスポンス（MCP::Tool::Response形式）
        success_response(
          task_id: task.id.to_s,
          task_url: issue_url(task.id),
          subject: task.subject,
          parent_user_story: parent_user_story ? {
            id: parent_user_story.id.to_s,
            subject: parent_user_story.subject
          } : nil,
          version: version ? {
            id: version.id.to_s,
            name: version.name
          } : nil,
          assigned_to: assigned_to ? {
            id: assigned_to.id.to_s,
            name: assigned_to.name
          } : nil
        )
        rescue StandardError => e
          Rails.logger.error "CreateTaskTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      private

      # プロジェクト取得（識別子 or ID）
      def find_project(project_id)
        # 数値ならID検索、文字列なら識別子検索
        if project_id.to_i.to_s == project_id
          Project.find_by(id: project_id.to_i)
        else
          Project.find_by(identifier: project_id) || Project.find_by(id: project_id.to_i)
        end
      end

      # 親UserStoryを解決
      def resolve_parent_user_story(project, parent_user_story_id, description)
        if parent_user_story_id.present?
          Issue.find_by(id: parent_user_story_id)
        else
          # 推論: descriptionから類似UserStoryを検索
          find_best_parent_user_story(project, description)
        end
      end

      # Versionを解決
      def resolve_version(project, version_id, parent_user_story)
        if version_id.present?
          Version.find_by(id: version_id)
        elsif parent_user_story&.fixed_version
          # 親UserStoryのVersionを継承
          parent_user_story.fixed_version
        else
          # 最新の未完了Versionを選択
          project.versions.where(status: 'open').order(:effective_date).first
        end
      end

      # 担当者を解決
      def resolve_assigned_to(project, assigned_to_id, current_user)
        if assigned_to_id.present?
          User.find_by(id: assigned_to_id)
        else
          # デフォルトは現在のユーザー
          current_user
        end
      end

      # descriptionから類似UserStoryを検索
      def find_best_parent_user_story(project, description)
        user_story_tracker = find_tracker(:user_story)
        return nil unless user_story_tracker

        # キーワード抽出（簡易版: スペース・句読点で分割）
        keywords = description.split(/[、。\s]/).reject(&:blank?).map(&:strip)
        return nil if keywords.empty?

        # プロジェクト内のUserStoryを検索
        user_stories = project.issues.where(tracker: user_story_tracker)

        # スコアリング: subjectに含まれるキーワード数でランク付け
        scored_stories = user_stories.map do |story|
          score = keywords.count { |kw| story.subject.include?(kw) }
          { story: story, score: score }
        end

        # スコアが1以上のものから最高スコアを選択
        best_match = scored_stories.select { |s| s[:score] > 0 }.max_by { |s| s[:score] }
        best_match&.dig(:story)
      end

      # descriptionから簡潔なsubjectを抽出
      def extract_subject(description)
        # 最初の一文を取得（。または改行で区切る）
        first_sentence = description.split(/[。\n]/).first&.strip || description

        # 255文字に切り詰め（Redmineのsubject上限）
        first_sentence.truncate(255)
      end

      # トラッカー取得ヘルパー
      def find_tracker(tracker_type)
        tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
        Tracker.find_by(name: tracker_name)
      end

      # RedmineのIssue URLを生成
      def issue_url(issue_id)
        "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
      end

      # エラーレスポンス生成（MCP::Tool::Response形式）
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

      # 成功レスポンス生成（MCP::Tool::Response形式）
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
