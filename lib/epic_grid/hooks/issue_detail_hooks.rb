# frozen_string_literal: true

module EpicGrid
  module Hooks
    # Issue詳細画面へのView Hook
    # 各トラッカーに応じたクイックアクションボタンを追加
    class IssueDetailHooks < Redmine::Hook::ViewListener
      # チケット詳細画面の下部にボタンを表示
      def view_issues_show_details_bottom(context = {})
        issue = context[:issue]
        project = context[:project]

        # epic_gridモジュールが有効化されていない場合は何も表示しない
        return '' unless project&.module_enabled?(:epic_grid)

        # ボタン表示対象トラッカーかチェック
        tracker_type = get_tracker_type(issue)
        return '' if tracker_type.nil?

        # トラッカータイプに応じてパーシャルを選択
        partial_name, locals = build_partial_context(issue, project, tracker_type)
        return '' if partial_name.blank?

        # パーシャルをレンダリング
        context[:controller].send(
          :render_to_string,
          partial: partial_name,
          locals: locals
        )
      end

      private

      # トラッカータイプを判定
      # @return [Symbol, nil] :task_level, :user_story, :feature, :epic, nil
      def get_tracker_type(issue)
        tracker_names = EpicGrid::TrackerHierarchy.tracker_names
        current_tracker = issue.tracker.name

        case current_tracker
        when tracker_names[:task], tracker_names[:test], tracker_names[:bug]
          :task_level
        when tracker_names[:user_story]
          :user_story
        when tracker_names[:feature]
          :feature
        when tracker_names[:epic]
          :epic
        end
      end

      # トラッカータイプに応じてパーシャル名とlocalsを構築
      def build_partial_context(issue, project, tracker_type)
        case tracker_type
        when :task_level
          # Task/Test/Bug: 親UserStoryを見つけて、その下にTask/Test/Bugを作成
          user_story = find_user_story(issue)
          return ['', {}] unless user_story

          ['hooks/issue_quick_actions', {
            issue: issue,
            user_story: user_story,
            project: project
          }]
        when :user_story
          # UserStory: 自身の下にTask/Test/Bugを作成
          ['hooks/issue_quick_actions_user_story', {
            issue: issue,
            project: project
          }]
        when :feature
          # Feature: 自身の下にUserStoryを作成
          ['hooks/issue_quick_actions_feature', {
            issue: issue,
            project: project
          }]
        when :epic
          # Epic: 自身の下にFeatureを作成
          ['hooks/issue_quick_actions_epic', {
            issue: issue,
            project: project
          }]
        else
          ['', {}]
        end
      end

      # 所属するUserStoryを取得
      def find_user_story(issue)
        tracker_names = EpicGrid::TrackerHierarchy.tracker_names
        user_story_name = tracker_names[:user_story]

        # 自身がUserStoryの場合はそのまま返す
        return issue if issue.tracker.name == user_story_name

        # 親を辿ってUserStoryを見つける（最大10階層まで）
        current = issue
        10.times do
          break unless current.parent

          return current.parent if current.parent.tracker.name == user_story_name

          current = current.parent
        end

        nil
      end
    end
  end
end
