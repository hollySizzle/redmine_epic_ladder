# frozen_string_literal: true

# KanbanGridChannel - WebSocket接続管理チャンネル
# 設計書仕様: ActionCable WebSocket、認証・認可、プレゼンス管理
class KanbanGridChannel < ApplicationCable::Channel
  include Kanban::WebSocketChannelService

  # チャンネル購読
  def subscribed
    project_id = params[:project_id]
    user_id = params[:user_id]
    client_id = params[:client_id]

    # 認証・認可チェック
    unless authorized_for_project?(project_id)
      reject
      return
    end

    @project_id = project_id.to_i
    @user_id = user_id.to_i
    @client_id = client_id
    @user = User.find(@user_id)
    @project = Project.find(@project_id)

    # プロジェクトチャンネルに購読
    stream_from project_channel_name(@project_id)

    # 個人チャンネルも購読（エラー通知など）
    stream_from user_channel_name(@project_id, @user_id)

    # ユーザープレゼンス設定
    user_info = {
      id: @user.id,
      name: @user.name,
      avatar_url: avatar_url(@user),
      client_id: @client_id
    }

    Kanban::WebSocketChannelService.user_joined(@project_id, @user_id, user_info)

    # 接続ログ
    Rails.logger.info "[KanbanGrid] User #{@user.name} (ID:#{@user_id}) connected to project #{@project.name} (ID:#{@project_id})"

    # 初期データ送信
    send_initial_data
  end

  # チャンネル購読解除
  def unsubscribed
    if @project_id && @user_id
      Kanban::WebSocketChannelService.user_left(@project_id, @user_id)
      Rails.logger.info "[KanbanGrid] User #{@user_id} disconnected from project #{@project_id}"
    end
  end

  # ハートビート処理
  def heartbeat(data)
    Kanban::WebSocketChannelService.update_user_activity(@project_id, @user_id)

    transmit({
      type: 'heartbeat_ack',
      server_timestamp: Time.current.to_f,
      client_timestamp: data['timestamp']
    })
  end

  # 楽観的更新の受信
  def optimistic_update(data)
    return unless authorized_for_project?(@project_id)

    update_type = data['type']
    update_data = data['data']

    case update_type
    when 'feature_move'
      handle_optimistic_feature_move(update_data)
    when 'issue_update'
      handle_optimistic_issue_update(update_data)
    else
      Rails.logger.warn "[KanbanGrid] Unknown optimistic update type: #{update_type}"
    end
  end

  # ユーザーアクション通知
  def user_action(data)
    return unless authorized_for_project?(@project_id)

    action = data['action']
    details = data['details']

    # 他のユーザーにアクション通知をブロードキャスト
    broadcast_user_action(action, details)
  end

  # リアルタイム統計要求
  def request_statistics(data)
    return unless authorized_for_project?(@project_id)

    stats = Kanban::WebSocketChannelService.get_channel_stats(@project_id)

    transmit({
      type: 'statistics_response',
      data: stats,
      timestamp: Time.current.iso8601
    })
  end

  private

  def authorized_for_project?(project_id)
    return false unless current_user && project_id

    project = Project.find_by(id: project_id)
    return false unless project

    current_user.allowed_to?(:view_issues, project)
  end

  def project_channel_name(project_id)
    "kanban_grid_project_#{project_id}"
  end

  def user_channel_name(project_id, user_id)
    "kanban_grid_project_#{project_id}_user_#{user_id}"
  end

  def send_initial_data
    # 現在のオンラインユーザー情報送信
    online_users = Kanban::WebSocketChannelService.get_online_users(@project_id)

    transmit({
      type: 'initial_data',
      data: {
        online_users: online_users,
        project_info: {
          id: @project.id,
          name: @project.name
        },
        user_info: {
          id: @user.id,
          name: @user.name,
          permissions: get_user_permissions
        }
      },
      timestamp: Time.current.iso8601
    })
  end

  def handle_optimistic_feature_move(update_data)
    feature_id = update_data['feature_id']
    source_cell = update_data['source_cell']
    target_cell = update_data['target_cell']
    local_timestamp = update_data['local_timestamp']

    # データベースの現在状態をチェック
    feature = Issue.find_by(id: feature_id)
    return unless feature

    # 衝突検出
    current_state = {
      parent_id: feature.parent_id,
      fixed_version_id: feature.fixed_version_id,
      status_id: feature.status_id,
      updated_on: feature.updated_on.to_f * 1000 # ミリ秒
    }

    # 楽観的更新が古い場合は衝突として処理
    if current_state[:updated_on] > local_timestamp
      conflict_data = {
        feature_id: feature_id,
        expected_state: update_data,
        actual_state: current_state,
        conflict_type: 'stale_update'
      }

      Kanban::WebSocketChannelService.broadcast_optimistic_conflict(
        @project_id,
        conflict_data,
        @user_id
      )
    end
  end

  def handle_optimistic_issue_update(update_data)
    issue_id = update_data['issue_id']
    expected_changes = update_data['changes']
    local_timestamp = update_data['local_timestamp']

    issue = Issue.find_by(id: issue_id)
    return unless issue

    # 実際の状態と期待する状態を比較
    conflicts = detect_update_conflicts(issue, expected_changes, local_timestamp)

    if conflicts.any?
      Kanban::WebSocketChannelService.broadcast_optimistic_conflict(
        @project_id,
        {
          issue_id: issue_id,
          conflicts: conflicts,
          conflict_type: 'concurrent_update'
        },
        @user_id
      )
    end
  end

  def detect_update_conflicts(issue, expected_changes, local_timestamp)
    conflicts = []

    # 最終更新時刻チェック
    if issue.updated_on.to_f * 1000 > local_timestamp
      conflicts << {
        type: 'timestamp_conflict',
        expected: local_timestamp,
        actual: issue.updated_on.to_f * 1000
      }
    end

    # 属性値チェック
    expected_changes.each do |attr, expected_value|
      actual_value = issue.send(attr) if issue.respond_to?(attr)
      if actual_value != expected_value
        conflicts << {
          type: 'attribute_conflict',
          attribute: attr,
          expected: expected_value,
          actual: actual_value
        }
      end
    end

    conflicts
  end

  def broadcast_user_action(action, details)
    # 自分以外のユーザーにブロードキャスト
    ActionCable.server.broadcast(
      project_channel_name(@project_id),
      {
        type: 'user_action',
        data: {
          action: action,
          details: details,
          user: {
            id: @user.id,
            name: @user.name
          },
          client_id: @client_id
        },
        timestamp: Time.current.iso8601
      }
    )
  end

  def get_user_permissions
    {
      view_issues: @user.allowed_to?(:view_issues, @project),
      edit_issues: @user.allowed_to?(:edit_issues, @project),
      add_issues: @user.allowed_to?(:add_issues, @project),
      delete_issues: @user.allowed_to?(:delete_issues, @project),
      manage_versions: @user.allowed_to?(:manage_versions, @project)
    }
  end

  def avatar_url(user)
    # Redmineのアバター画像取得
    if user.respond_to?(:avatar) && user.avatar.present?
      Rails.application.routes.url_helpers.avatar_url(user.avatar)
    else
      # デフォルトアバター
      "/images/user.png"
    end
  end

  def current_user
    @user
  end
end