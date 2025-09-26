# frozen_string_literal: true

module Kanban
  # WebSocketChannelService - WebSocket/SSE チャンネル管理サービス
  # 設計書仕様: リアルタイム通信、ユーザープレゼンス、データ伝播
  class WebSocketChannelService
    include ActionCable::Channel::Broadcasting

    CHANNEL_PREFIX = 'kanban_grid'.freeze
    USER_PRESENCE_TTL = 30.seconds

    class << self
      # プロジェクトチャンネルにブロードキャスト
      def broadcast_to_project(project_id, event_type, data)
        channel_name = project_channel_name(project_id)

        message = {
          type: event_type,
          data: data,
          timestamp: Time.current.iso8601,
          server_timestamp: Time.current.to_f
        }

        ActionCable.server.broadcast(channel_name, message)

        Rails.logger.debug "WebSocket broadcast to #{channel_name}: #{event_type}"

        # Redis統計更新
        update_broadcast_stats(project_id, event_type)
      end

      # グリッド更新の伝播
      def broadcast_grid_update(project_id, updated_data, user_id)
        broadcast_to_project(project_id, 'grid_update', {
          updated_issues: updated_data[:issues] || [],
          deleted_issues: updated_data[:deleted_ids] || [],
          grid_changes: updated_data[:grid_changes] || [],
          user_id: user_id,
          change_summary: build_change_summary(updated_data)
        })
      end

      # Feature移動の伝播
      def broadcast_feature_move(project_id, move_result, user_id, client_id = nil)
        broadcast_to_project(project_id, 'feature_moved', {
          issue_id: move_result[:issue].id,
          source_cell: move_result[:source_cell],
          target_cell: move_result[:target_cell],
          updated_issue: serialize_issue(move_result[:issue]),
          affected_cells: move_result[:affected_cells] || [],
          user_id: user_id,
          client_id: client_id
        })
      end

      # Epic作成の伝播
      def broadcast_epic_created(project_id, epic, user_id)
        broadcast_to_project(project_id, 'epic_created', {
          epic: serialize_issue(epic),
          user_id: user_id
        })
      end

      # Version作成の伝播
      def broadcast_version_created(project_id, version, user_id)
        broadcast_to_project(project_id, 'version_created', {
          version: serialize_version(version),
          user_id: user_id
        })
      end

      # Issue更新の伝播
      def broadcast_issue_updated(project_id, issue, changes, user_id)
        # Feature関連のIssueのみ伝播
        return unless relevant_for_grid?(issue)

        broadcast_to_project(project_id, 'issue_updated', {
          issue_id: issue.id,
          updated_issue: serialize_issue(issue),
          changes: serialize_changes(changes),
          user_id: user_id
        })
      end

      # 楽観的更新の衝突通知
      def broadcast_optimistic_conflict(project_id, conflict_data, target_user_id)
        user_channel = user_channel_name(project_id, target_user_id)

        ActionCable.server.broadcast(user_channel, {
          type: 'conflict_detected',
          data: conflict_data,
          timestamp: Time.current.iso8601
        })
      end

      # ユーザープレゼンス管理
      def user_joined(project_id, user_id, user_info)
        set_user_presence(project_id, user_id, user_info)
        online_users = get_online_users(project_id)

        broadcast_to_project(project_id, 'user_presence', {
          action: 'joined',
          user: user_info,
          online_users_count: online_users.count
        })
      end

      def user_left(project_id, user_id)
        user_info = remove_user_presence(project_id, user_id)
        online_users = get_online_users(project_id)

        if user_info
          broadcast_to_project(project_id, 'user_presence', {
            action: 'left',
            user: user_info,
            online_users_count: online_users.count
          })
        end
      end

      def update_user_activity(project_id, user_id)
        presence_key = user_presence_key(project_id, user_id)
        Rails.cache.write(presence_key, Time.current.to_f, expires_in: USER_PRESENCE_TTL)
      end

      # エラー通知
      def broadcast_error(project_id, error_data, user_id = nil)
        if user_id
          user_channel = user_channel_name(project_id, user_id)
          ActionCable.server.broadcast(user_channel, {
            type: 'server_error',
            data: error_data,
            timestamp: Time.current.iso8601
          })
        else
          broadcast_to_project(project_id, 'server_error', error_data)
        end
      end

      # チャンネル統計
      def get_channel_stats(project_id)
        stats_key = channel_stats_key(project_id)
        cached_stats = Rails.cache.read(stats_key) || {}

        online_users = get_online_users(project_id)

        {
          project_id: project_id,
          online_users_count: online_users.count,
          online_users: online_users,
          broadcast_stats: cached_stats,
          last_activity: cached_stats[:last_activity],
          channel_name: project_channel_name(project_id)
        }
      end

      private

      def project_channel_name(project_id)
        "#{CHANNEL_PREFIX}_project_#{project_id}"
      end

      def user_channel_name(project_id, user_id)
        "#{CHANNEL_PREFIX}_project_#{project_id}_user_#{user_id}"
      end

      def user_presence_key(project_id, user_id)
        "#{CHANNEL_PREFIX}:presence:proj_#{project_id}:user_#{user_id}"
      end

      def channel_stats_key(project_id)
        "#{CHANNEL_PREFIX}:stats:proj_#{project_id}"
      end

      def set_user_presence(project_id, user_id, user_info)
        presence_key = user_presence_key(project_id, user_id)
        Rails.cache.write(presence_key, user_info.merge(
          last_seen: Time.current.to_f,
          user_id: user_id
        ), expires_in: USER_PRESENCE_TTL)
      end

      def remove_user_presence(project_id, user_id)
        presence_key = user_presence_key(project_id, user_id)
        user_info = Rails.cache.read(presence_key)
        Rails.cache.delete(presence_key)
        user_info
      end

      def get_online_users(project_id)
        pattern = "#{CHANNEL_PREFIX}:presence:proj_#{project_id}:user_*"
        online_users = []

        # Redis使用時のパターンマッチング
        if Rails.cache.respond_to?(:redis)
          keys = Rails.cache.redis.keys(pattern)
          keys.each do |key|
            user_info = Rails.cache.read(key)
            if user_info && (Time.current.to_f - user_info[:last_seen]) < USER_PRESENCE_TTL.seconds
              online_users << user_info
            end
          end
        end

        online_users
      end

      def update_broadcast_stats(project_id, event_type)
        stats_key = channel_stats_key(project_id)
        stats = Rails.cache.read(stats_key) || {}

        stats[:total_broadcasts] ||= 0
        stats[:broadcasts_by_type] ||= {}
        stats[:total_broadcasts] += 1
        stats[:broadcasts_by_type][event_type] ||= 0
        stats[:broadcasts_by_type][event_type] += 1
        stats[:last_activity] = Time.current.iso8601

        Rails.cache.write(stats_key, stats, expires_in: 1.hour)
      end

      def build_change_summary(updated_data)
        {
          issues_updated: updated_data[:issues]&.count || 0,
          issues_deleted: updated_data[:deleted_ids]&.count || 0,
          grid_structure_changed: updated_data[:grid_changes]&.any? || false
        }
      end

      def serialize_issue(issue)
        {
          id: issue.id,
          subject: issue.subject,
          description: issue.description,
          status: {
            id: issue.status.id,
            name: issue.status.name
          },
          tracker: {
            id: issue.tracker.id,
            name: issue.tracker.name
          },
          assigned_to: issue.assigned_to ? {
            id: issue.assigned_to.id,
            name: issue.assigned_to.name
          } : nil,
          fixed_version: issue.fixed_version ? {
            id: issue.fixed_version.id,
            name: issue.fixed_version.name
          } : nil,
          parent: issue.parent ? {
            id: issue.parent.id,
            subject: issue.parent.subject
          } : nil,
          updated_on: issue.updated_on.iso8601,
          lock_version: issue.lock_version
        }
      end

      def serialize_version(version)
        {
          id: version.id,
          name: version.name,
          description: version.description,
          effective_date: version.effective_date&.iso8601,
          status: version.status,
          issue_count: version.issues.count
        }
      end

      def serialize_changes(changes)
        serialized = {}

        changes.each do |attribute, (old_value, new_value)|
          case attribute
          when 'status_id'
            serialized['status'] = {
              old: old_value ? IssueStatus.find(old_value).name : nil,
              new: new_value ? IssueStatus.find(new_value).name : nil
            }
          when 'fixed_version_id'
            serialized['version'] = {
              old: old_value ? Version.find(old_value).name : nil,
              new: new_value ? Version.find(new_value).name : nil
            }
          when 'parent_id'
            serialized['epic'] = {
              old: old_value ? Issue.find(old_value).subject : nil,
              new: new_value ? Issue.find(new_value).subject : nil
            }
          else
            serialized[attribute] = { old: old_value, new: new_value }
          end
        end

        serialized
      end

      def relevant_for_grid?(issue)
        # Feature または Epic トラッカーのIssueのみ
        %w[Feature Epic].include?(issue.tracker.name)
      end
    end
  end
end