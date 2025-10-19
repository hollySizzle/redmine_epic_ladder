# frozen_string_literal: true

module EpicGrid
  module Hooks
    # Issue詳細画面へのView Hook
    # Task/Test/Bug作成ボタンを追加
    class IssueDetailHooks < Redmine::Hook::ViewListener
      # チケット詳細画面の下部にボタンを表示
      def view_issues_show_details_bottom(context = {})
        issue = context[:issue]
        project = context[:project]

        # epic_gridモジュールが有効化されていない場合は何も表示しない
        return '' unless project&.module_enabled?(:epic_grid)

        # ボタン表示対象トラッカーかチェック
        return '' unless should_show_buttons?(issue)

        # 所属するUserStoryを取得
        user_story = find_user_story(issue)
        return '' unless user_story

        # パーシャルをレンダリング
        context[:controller].send(
          :render_to_string,
          partial: 'hooks/issue_quick_actions',
          locals: {
            issue: issue,
            user_story: user_story,
            project: project
          }
        )
      end

      private

      # ボタン表示対象トラッカーかチェック
      def should_show_buttons?(issue)
        tracker_names = EpicGrid::TrackerHierarchy.tracker_names
        current_tracker = issue.tracker.name

        # Task/Test/Bugトラッカーのみ表示
        [
          tracker_names[:task],
          tracker_names[:test],
          tracker_names[:bug]
        ].include?(current_tracker)
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
