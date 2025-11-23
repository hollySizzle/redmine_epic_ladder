# frozen_string_literal: true

module EpicGrid
  module McpTools
    # Test作成MCPツール
    # Test（やるべきテストや検証）チケットを作成する
    #
    # @example
    #   ユーザー: 「申込完了までのE2Eテストを作るTestチケットを作って」
    #   AI: CreateTestToolを呼び出し
    #   結果: Test #1004が作成される
    class CreateTestTool < MCP::Tool
      description "Test（やるべきテストや検証）チケットを作成します。例: '申込完了までのE2Eテスト'"

      input_schema(
        properties: {
          project_id: { type: "string", description: "プロジェクトID（識別子または数値ID）" },
          description: { type: "string", description: "Testの説明（自然言語OK）" },
          parent_user_story_id: { type: "string", description: "親UserStory ID（省略時は推論）" },
          version_id: { type: "string", description: "Version ID（省略時は親から継承）" },
          assigned_to_id: { type: "string", description: "担当者ID（省略時は現在のユーザー）" }
        },
        required: ["project_id", "description"]
      )

      def self.call(project_id:, description:, parent_user_story_id: nil, version_id: nil, assigned_to_id: nil, server_context:)
        Rails.logger.info "CreateTestTool#call started: project_id=#{project_id}, description=#{description}"

        begin
          # プロジェクト取得
          project = find_project(project_id)
          unless project
            return error_response("プロジェクトが見つかりません: #{project_id}")
          end

          # 権限チェック
          user = server_context[:user] || User.current
          unless user.allowed_to?(:add_issues, project)
            return error_response("Test作成権限がありません", { project: project.identifier })
          end

          # Testトラッカー取得
          test_tracker = find_tracker(:test, project)
          return error_response("Testトラッカーが設定されていません") unless test_tracker

          # 親UserStory解決
          parent_user_story = resolve_parent_user_story(project, parent_user_story_id, description)

          # Version解決
          version = resolve_version(project, version_id, parent_user_story)

          # 担当者解決
          assigned_to = resolve_assigned_to(project, assigned_to_id, user)

          # subject抽出
          subject = extract_subject(description)

          # Test作成
          test = Issue.new(
            project: project,
            tracker: test_tracker,
            subject: subject,
            description: description,
            parent_issue_id: parent_user_story&.id,
            fixed_version_id: version&.id,
            assigned_to: assigned_to,
            author: user,
            status: IssueStatus.first
          )

          unless test.save
            return error_response("Test作成に失敗しました", { errors: test.errors.full_messages })
          end

          # 成功レスポンス
          success_response(
            test_id: test.id.to_s,
            test_url: issue_url(test.id),
            subject: test.subject,
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
          Rails.logger.error "CreateTestTool error: #{e.class.name}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          error_response("予期しないエラーが発生しました: #{e.message}", { error_class: e.class.name })
        end
      end

      class << self
        private

        # プロジェクト取得（識別子 or ID）
        def find_project(project_id)
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
            # 環境変数チェック: AUTO_INFER_PARENT（デフォルトtrue）
            auto_infer_enabled = ENV.fetch('AUTO_INFER_PARENT', 'true') == 'true'

            if auto_infer_enabled
              # 推論: descriptionから類似UserStoryを検索
              result = find_best_parent_user_story_with_confidence(project, description)

              if result
                Rails.logger.info "Auto-inferred parent UserStory: ##{result[:story].id} (confidence: #{result[:confidence]})"
                result[:story]
              else
                Rails.logger.info "No suitable parent UserStory found (below threshold)"
                nil
              end
            else
              Rails.logger.info "AUTO_INFER_PARENT is disabled"
              nil
            end
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
            current_user
          end
        end

        # descriptionから類似UserStoryを検索（確信度スコア付き）
        def find_best_parent_user_story_with_confidence(project, description)
          user_story_tracker = find_tracker(:user_story, project)
          return nil unless user_story_tracker

          # キーワード抽出（簡易版: スペース・句読点で分割）
          keywords = description.split(/[、。\s]/).reject(&:blank?).map(&:strip)
          return nil if keywords.empty?

          # プロジェクト内のUserStoryを検索（openのみ）
          user_stories = project.issues.where(tracker: user_story_tracker)
                                 .where("#{IssueStatus.table_name}.is_closed = ?", false)
                                 .joins(:status)

          return nil if user_stories.empty?

          # スコアリング: subjectとdescriptionに含まれるキーワード数でランク付け
          scored_stories = user_stories.map do |story|
            subject_matches = keywords.count { |kw| story.subject.include?(kw) }
            description_matches = keywords.count { |kw| story.description.to_s.include?(kw) }

            # スコア計算: subject一致を重視（weight: 2.0）
            raw_score = (subject_matches * 2.0) + description_matches

            # 正規化: 最大スコアはキーワード数 * 3（subject全一致 + description全一致）
            max_possible_score = keywords.size * 3.0
            confidence = max_possible_score > 0 ? (raw_score / max_possible_score) : 0.0

            {
              story: story,
              raw_score: raw_score,
              confidence: confidence.round(2)
            }
          end

          # 確信度で降順ソート
          scored_stories.sort_by! { |s| -s[:confidence] }

          # 環境変数で閾値を取得（デフォルト0.3 = 30%）
          threshold = ENV.fetch('AUTO_INFER_THRESHOLD', '0.3').to_f

          # 閾値以上の最高スコアを選択
          best_match = scored_stories.find { |s| s[:confidence] >= threshold }

          if best_match
            Rails.logger.info "Parent inference candidates: #{scored_stories.first(3).map { |s| "##{s[:story].id} (#{s[:confidence]})" }.join(', ')}"
          end

          best_match
        end

        # descriptionから簡潔なsubjectを抽出
        def extract_subject(description)
          first_sentence = description.split(/[。\n]/).first&.strip || description
          first_sentence.truncate(255)
        end

        # トラッカー取得ヘルパー
        def find_tracker(tracker_type, project)
          tracker_name = EpicGrid::TrackerHierarchy.tracker_names[tracker_type]
          tracker = Tracker.find_by(name: tracker_name)
          return nil unless tracker
          return nil unless project.trackers.include?(tracker)
          tracker
        end

        # RedmineのIssue URLを生成
        def issue_url(issue_id)
          "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue_id}"
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
