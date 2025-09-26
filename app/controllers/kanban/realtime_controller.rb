# frozen_string_literal: true

module Kanban
  # リアルタイム通信コントローラー
  # WebSocket・ポーリング対応のリアルタイム同期機能提供
  class RealtimeController < BaseApiController
    skip_before_action :verify_authenticity_token, only: [:heartbeat, :poll_updates]

    # リアルタイム通信購読開始
    def subscribe
      channel_name = "kanban_project_#{@project.id}"
      session_id = generate_session_id

      # Redis セッション情報保存
      store_session_data(session_id, channel_name)

      # WebSocket接続情報とポーリング代替情報を返す
      render_success({
        session_id: session_id,
        channel_name: channel_name,
        websocket_url: websocket_connection_url,
        polling_fallback: {
          poll_url: poll_updates_url,
          interval: 5000, # 5秒間隔
          timeout: 30000  # 30秒タイムアウト
        },
        connection_config: {
          heartbeat_interval: 30000,
          reconnect_delay: 1000,
          max_reconnect_attempts: 5
        }
      })
    end

    # ポーリング更新取得
    def poll_updates
      since_timestamp = params[:since]
      session_id = params[:session_id]

      if since_timestamp.blank?
        render_error('since パラメータが必要です', :bad_request)
        return
      end

      begin
        since_time = Time.parse(since_timestamp)
      rescue ArgumentError
        render_error('無効なタイムスタンプ形式です', :bad_request)
        return
      end

      # セッション有効性確認
      unless valid_session?(session_id)
        render_error('無効なセッションです', :unauthorized)
        return
      end

      # 更新データ取得
      updates = collect_updates_since(since_time)
      current_time = Time.current

      render_success({
        updates: updates,
        current_timestamp: current_time.iso8601,
        next_poll_after: (current_time + 5.seconds).iso8601,
        has_more_updates: has_pending_updates?(current_time),
        session_status: 'active'
      })
    rescue => e
      Rails.logger.error "Polling error: #{e.message}"
      render_error('更新データの取得に失敗しました', :internal_server_error)
    end

    # ハートビート
    def heartbeat
      session_id = params[:session_id]

      unless valid_session?(session_id)
        render_error('無効なセッションです', :unauthorized)
        return
      end

      # セッション生存確認更新
      update_session_heartbeat(session_id)

      render_success({
        status: 'alive',
        timestamp: Time.current.iso8601,
        session_valid_until: (Time.current + 30.minutes).iso8601
      })
    end

    # 購読解除
    def unsubscribe
      session_id = params[:session_id]

      if session_id.present?
        cleanup_session(session_id)
      end

      render_success({
        status: 'unsubscribed',
        timestamp: Time.current.iso8601
      })
    end

    # 更新通知送信（内部API）
    def notify_change
      change_type = params[:change_type]
      resource_type = params[:resource_type]
      resource_id = params[:resource_id]
      change_data = params[:change_data] || {}

      unless ['issue_updated', 'issue_created', 'issue_deleted', 'version_updated'].include?(change_type)
        render_error('無効な変更タイプです', :bad_request)
        return
      end

      # 変更通知をRedisに保存
      notification_data = {
        change_type: change_type,
        resource_type: resource_type,
        resource_id: resource_id,
        change_data: change_data,
        project_id: @project.id,
        user_id: User.current.id,
        timestamp: Time.current.iso8601
      }

      store_change_notification(notification_data)

      # WebSocket チャンネルに配信
      broadcast_to_channel("kanban_project_#{@project.id}", notification_data)

      render_success({
        notification_id: SecureRandom.uuid,
        broadcast_status: 'sent',
        affected_sessions: count_active_sessions(@project.id)
      })
    end

    # アクティブセッション状況取得
    def active_sessions
      sessions = get_active_sessions(@project.id)

      render_success({
        total_sessions: sessions.count,
        sessions: sessions.map do |session|
          {
            session_id: session[:session_id],
            user_id: session[:user_id],
            user_name: session[:user_name],
            connected_at: session[:connected_at],
            last_heartbeat: session[:last_heartbeat],
            status: session[:status]
          }
        end,
        project_activity: {
          recent_changes: get_recent_changes(@project.id, 10),
          active_users: get_active_users(@project.id)
        }
      })
    end

    # 通信統計取得
    def connection_stats
      stats = calculate_connection_statistics(@project.id)

      render_success({
        current_connections: stats[:current_connections],
        total_messages_today: stats[:total_messages_today],
        average_response_time: stats[:average_response_time],
        error_rate: stats[:error_rate],
        peak_concurrent_users: stats[:peak_concurrent_users],
        websocket_vs_polling: {
          websocket_usage: stats[:websocket_usage],
          polling_usage: stats[:polling_usage]
        },
        performance_metrics: {
          message_processing_time: stats[:message_processing_time],
          broadcast_latency: stats[:broadcast_latency],
          session_duration_average: stats[:session_duration_average]
        }
      })
    end

    private

    def generate_session_id
      "#{User.current.id}_#{@project.id}_#{SecureRandom.hex(8)}"
    end

    def store_session_data(session_id, channel_name)
      Redis.current.setex(
        "kanban_session:#{session_id}",
        30.minutes.to_i,
        {
          user_id: User.current.id,
          project_id: @project.id,
          channel_name: channel_name,
          connected_at: Time.current.iso8601,
          last_heartbeat: Time.current.iso8601
        }.to_json
      )
    end

    def valid_session?(session_id)
      return false if session_id.blank?
      Redis.current.exists?("kanban_session:#{session_id}")
    end

    def update_session_heartbeat(session_id)
      session_key = "kanban_session:#{session_id}"
      session_data = JSON.parse(Redis.current.get(session_key) || '{}')
      session_data['last_heartbeat'] = Time.current.iso8601

      Redis.current.setex(session_key, 30.minutes.to_i, session_data.to_json)
    end

    def cleanup_session(session_id)
      Redis.current.del("kanban_session:#{session_id}")
    end

    def collect_updates_since(since_time)
      # Redisから変更通知を取得
      notification_key = "kanban_changes:project_#{@project.id}"
      changes = Redis.current.zrangebyscore(
        notification_key,
        since_time.to_f,
        Time.current.to_f,
        with_scores: true
      )

      changes.map do |change_json, timestamp|
        JSON.parse(change_json).merge('timestamp' => Time.at(timestamp).iso8601)
      end
    end

    def has_pending_updates?(current_time)
      notification_key = "kanban_changes:project_#{@project.id}"
      Redis.current.zcount(notification_key, current_time.to_f, '+inf') > 0
    end

    def store_change_notification(notification_data)
      notification_key = "kanban_changes:project_#{@project.id}"
      timestamp = Time.current.to_f

      # Sorted Setに保存（タイムスタンプをスコアとして使用）
      Redis.current.zadd(notification_key, timestamp, notification_data.to_json)

      # 古い通知を削除（24時間以上古いもの）
      old_timestamp = 24.hours.ago.to_f
      Redis.current.zremrangebyscore(notification_key, '-inf', old_timestamp)
    end

    def broadcast_to_channel(channel_name, data)
      # WebSocketチャンネルへのブロードキャスト
      # ActionCableを使用している場合の例
      begin
        ActionCable.server.broadcast(channel_name, data)
      rescue => e
        Rails.logger.error "Broadcast error: #{e.message}"
      end
    end

    def count_active_sessions(project_id)
      pattern = "kanban_session:*_#{project_id}_*"
      Redis.current.keys(pattern).count
    end

    def get_active_sessions(project_id)
      pattern = "kanban_session:*_#{project_id}_*"
      session_keys = Redis.current.keys(pattern)

      session_keys.map do |key|
        session_data = JSON.parse(Redis.current.get(key) || '{}')
        user = User.find_by(id: session_data['user_id'])

        {
          session_id: key.split(':').last,
          user_id: session_data['user_id'],
          user_name: user&.name || 'Unknown',
          connected_at: session_data['connected_at'],
          last_heartbeat: session_data['last_heartbeat'],
          status: calculate_session_status(session_data['last_heartbeat'])
        }
      end
    end

    def calculate_session_status(last_heartbeat)
      return 'inactive' if last_heartbeat.blank?

      heartbeat_time = Time.parse(last_heartbeat)
      minutes_ago = (Time.current - heartbeat_time) / 60

      case minutes_ago
      when 0..2
        'active'
      when 2..5
        'idle'
      else
        'inactive'
      end
    end

    def get_recent_changes(project_id, limit = 10)
      notification_key = "kanban_changes:project_#{project_id}"
      changes = Redis.current.zrevrange(notification_key, 0, limit - 1, with_scores: true)

      changes.map do |change_json, timestamp|
        JSON.parse(change_json).merge('timestamp' => Time.at(timestamp).iso8601)
      end
    end

    def get_active_users(project_id)
      sessions = get_active_sessions(project_id)
      active_sessions = sessions.select { |s| s[:status] == 'active' }

      active_sessions.map do |session|
        {
          user_id: session[:user_id],
          user_name: session[:user_name],
          last_activity: session[:last_heartbeat]
        }
      end.uniq { |user| user[:user_id] }
    end

    def calculate_connection_statistics(project_id)
      # 統計情報の計算（実装例）
      current_sessions = get_active_sessions(project_id)
      active_count = current_sessions.count { |s| s[:status] == 'active' }

      {
        current_connections: active_count,
        total_messages_today: get_daily_message_count(project_id),
        average_response_time: calculate_average_response_time,
        error_rate: calculate_error_rate,
        peak_concurrent_users: get_peak_concurrent_users(project_id),
        websocket_usage: 70.0, # 仮の値
        polling_usage: 30.0,    # 仮の値
        message_processing_time: 50.0, # ミリ秒
        broadcast_latency: 100.0,      # ミリ秒
        session_duration_average: 25.5  # 分
      }
    end

    def get_daily_message_count(project_id)
      # 実装例：Redisから日次メッセージ数を取得
      daily_key = "kanban_daily_messages:#{Date.current}:#{project_id}"
      Redis.current.get(daily_key)&.to_i || 0
    end

    def calculate_average_response_time
      # 実装例：過去のレスポンス時間の平均を計算
      50.0 # ミリ秒（仮の値）
    end

    def calculate_error_rate
      # 実装例：エラー率の計算
      0.5 # パーセント（仮の値）
    end

    def get_peak_concurrent_users(project_id)
      # 実装例：今日のピーク同時接続数を取得
      peak_key = "kanban_peak_users:#{Date.current}:#{project_id}"
      Redis.current.get(peak_key)&.to_i || 0
    end

    def websocket_connection_url
      # WebSocket接続URLの生成
      protocol = Rails.application.config.force_ssl ? 'wss' : 'ws'
      host = request.host
      port = request.port != 80 && request.port != 443 ? ":#{request.port}" : ''

      "#{protocol}://#{host}#{port}/cable"
    end

    def poll_updates_url
      kanban_project_realtime_poll_updates_url(@project)
    end
  end
end