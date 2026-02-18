# frozen_string_literal: true

module EpicLadder
  module Hooks
    # Issue詳細画面へのView Hook
    # 各トラッカーに応じたクイックアクションボタンを追加
    class IssueDetailHooks < Redmine::Hook::ViewListener
      # 説明セクションの下部に階層ガイド（子チケット折り畳み）を表示
      def view_issues_show_description_bottom(context = {})
        return '' unless hierarchy_guide_enabled?(context[:project])

        context[:controller].send(
          :render_to_string,
          partial: 'hooks/issue_hierarchy_guide',
          locals: {
            issue: context[:issue],
            project: context[:project]
          }
        )
      end

      # issues/form（new/edit共通）でバージョンフィールドに警告を表示
      def view_issues_form_details_bottom(context = {})
        project = context[:issue]&.project
        return '' unless hierarchy_guide_enabled?(project)

        context[:controller].send(
          :render_to_string,
          partial: 'hooks/issue_form_version_warning',
          locals: {
            issue: context[:issue],
            project: project
          }
        )
      end

      # issues/new画面の上部に階層ガイド通知を表示
      def view_issues_new_top(context = {})
        project = context[:issue]&.project
        return '' unless hierarchy_guide_enabled?(project)

        context[:controller].send(
          :render_to_string,
          partial: 'hooks/issue_new_hierarchy_notice',
          locals: {
            issue: context[:issue],
            project: project
          }
        )
      end

      # チケット詳細画面の下部にボタンを表示
      def view_issues_show_details_bottom(context = {})
        issue = context[:issue]
        project = context[:project]

        # epic_ladderモジュールが有効化されていない場合は何も表示しない
        return '' unless project&.module_enabled?(:epic_ladder)

        html_parts = []

        # クイックアクション（子Issue作成）
        tracker_type = get_tracker_type(issue)
        if tracker_type.present?
          partial_name, locals = build_partial_context(issue, project, tracker_type)
          if partial_name.present?
            html_parts << context[:controller].send(
              :render_to_string,
              partial: partial_name,
              locals: locals
            )
          end
        end

        # Note: Version変更はクイックアクション内に統合されたため、
        # 別途レンダリングは不要

        html_parts.join("\n").html_safe
      end

      private

      # トラッカータイプを判定
      # @return [Symbol, nil] :task_level, :user_story, :feature, :epic, nil
      def get_tracker_type(issue)
        tracker_names = EpicLadder::TrackerHierarchy.tracker_names
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
        tracker_names = EpicLadder::TrackerHierarchy.tracker_names
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

      # 階層ガイドが有効かチェック
      def hierarchy_guide_enabled?(project)
        return false unless project&.module_enabled?(:epic_ladder)

        Setting.plugin_redmine_epic_ladder['hierarchy_guide_enabled'] == '1'
      end
    end
  end
end
