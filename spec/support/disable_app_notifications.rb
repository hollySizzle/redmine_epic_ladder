# frozen_string_literal: true

# ============================================================
# redmine_app_notifications プラグインの無効化
# ============================================================
#
# テスト環境では redmine_app_notifications プラグインの
# Issue作成時の通知機能を無効化します。
#
# 理由:
# - epic_ladder プラグインのテストには不要
# - app_notification 属性の依存関係を回避
# - テストの実行速度向上
#
# ============================================================

RSpec.configure do |config|
  config.before(:suite) do
    # redmine_app_notifications プラグインのIssueパッチが存在する場合、無効化
    if defined?(AppNotificationsIssuesPatch)
      Issue.class_eval do
        # after_create コールバックを削除
        begin
          skip_callback :create, :after, :create_app_notifications_after_create_issue
        rescue ArgumentError => e
          # コールバックが存在しない場合は無視
          Rails.logger.debug "app_notifications callback not found: #{e.message}"
        end
      end

      puts "[INFO] ✅ redmine_app_notifications プラグインのIssue通知を無効化しました"
    end

    # redmine_app_notifications プラグインのJournalパッチが存在する場合、無効化
    if defined?(AppNotificationsJournalsPatch)
      Journal.class_eval do
        # after_create コールバックを削除
        begin
          skip_callback :create, :after, :create_app_notifications_after_create_journal
        rescue ArgumentError => e
          # コールバックが存在しない場合は無視
          Rails.logger.debug "app_notifications journal callback not found: #{e.message}"
        end
      end

      puts "[INFO] ✅ redmine_app_notifications プラグインのJournal通知を無効化しました"
    end

    # ViewHookを無効化（Fayeスクリプトの挿入を防ぐ）
    if defined?(AppNotificationsViewHook)
      AppNotificationsViewHook.class_eval do
        def view_layouts_base_html_head(context)
          '' # Fayeスクリプトタグを挿入しない
        end
      end

      puts "[INFO] ✅ redmine_app_notifications プラグインのViewHookを無効化しました"
    end
  end
end
