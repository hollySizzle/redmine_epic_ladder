# frozen_string_literal: true

module Kanban
  # 変更追跡システム
  # データ変更履歴・差分検出・ロールバック機能
  class ChangeTracker
    class ChangeTrackingError < StandardError; end
    class RollbackError < StandardError; end

    TRACKABLE_ATTRIBUTES = %w[
      subject status_id assigned_to_id fixed_version_id parent_id
      start_date due_date estimated_hours done_ratio description
    ].freeze

    def self.track_change(issue, user, change_type, options = {})
      new(issue, user).track_change(change_type, options)
    end

    def self.get_change_history(issue, options = {})
      new(issue).get_change_history(options)
    end

    def self.rollback_to_version(issue, version_timestamp, user)
      new(issue, user).rollback_to_version(version_timestamp)
    end

    def self.analyze_change_impact(issue, proposed_changes)
      new(issue).analyze_change_impact(proposed_changes)
    end

    def initialize(issue, user = nil)
      @issue = issue
      @user = user || User.current
      @change_log = []
    end

    # 変更追跡
    def track_change(change_type, options = {})
      begin
        change_record = {
          issue_id: @issue.id,
          user_id: @user.id,
          change_type: change_type,
          timestamp: Time.current,
          before_snapshot: capture_issue_snapshot(@issue),
          change_details: options[:details] || {},
          metadata: {
            user_agent: options[:user_agent],
            ip_address: options[:ip_address],
            source: options[:source] || 'manual'
          }
        }

        # 変更実行
        yield if block_given?

        # 変更後のスナップショット
        change_record[:after_snapshot] = capture_issue_snapshot(@issue.reload)
        change_record[:diff] = calculate_diff(change_record[:before_snapshot], change_record[:after_snapshot])

        # 変更履歴保存
        save_change_record(change_record)

        # キャッシュ無効化
        CacheManager.auto_invalidate_for_issue(@issue)

        # 統計再計算トリガー
        StatisticsEngine.clear_statistics_cache(@issue)

        {
          success: true,
          change_id: change_record[:change_id],
          change_type: change_type,
          diff: change_record[:diff],
          timestamp: change_record[:timestamp]
        }
      rescue => e
        Rails.logger.error "ChangeTracker error: #{e.message}"
        {
          success: false,
          error: e.message,
          error_code: 'CHANGE_TRACKING_ERROR'
        }
      end
    end

    # 変更履歴取得
    def get_change_history(options = {})
      limit = options[:limit] || 50
      offset = options[:offset] || 0
      change_types = options[:change_types]

      # Redmineの標準Journal + 独自変更履歴
      redmine_journals = @issue.journals
                              .includes(:user, :details)
                              .order(created_on: :desc)
                              .limit(limit)
                              .offset(offset)

      custom_changes = get_custom_change_records(limit, offset, change_types)

      # 統合・ソート
      all_changes = merge_change_records(redmine_journals, custom_changes)

      {
        success: true,
        data: {
          issue_id: @issue.id,
          changes: all_changes,
          pagination: {
            limit: limit,
            offset: offset,
            total_count: calculate_total_changes
          },
          summary: generate_change_summary(all_changes)
        }
      }
    rescue => e
      Rails.logger.error "ChangeTracker get_change_history error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'CHANGE_HISTORY_ERROR'
      }
    end

    # 特定バージョンへのロールバック
    def rollback_to_version(version_timestamp, options = {})
      begin
        # ロールバック対象の変更記録取得
        target_change = find_change_record_by_timestamp(version_timestamp)
        raise RollbackError, '指定されたバージョンが見つかりません' unless target_change

        # ロールバック実行前の現在状態保存
        current_snapshot = capture_issue_snapshot(@issue)

        # 影響分析
        impact_analysis = analyze_rollback_impact(target_change[:before_snapshot], current_snapshot)

        if impact_analysis[:high_impact] && !options[:force]
          return {
            success: false,
            error: 'High impact rollback requires force option',
            error_code: 'ROLLBACK_REQUIRES_CONFIRMATION',
            impact_analysis: impact_analysis
          }
        end

        # ロールバック実行
        ActiveRecord::Base.transaction do
          rollback_result = perform_rollback(target_change[:before_snapshot])

          # ロールバック操作も変更として記録
          track_change('rollback', {
            details: {
              target_version: version_timestamp,
              rollback_user: @user.id,
              impact_analysis: impact_analysis
            },
            source: 'rollback_operation'
          }) do
            # ロールバック処理はtrack_change内で実行済み
          end

          {
            success: true,
            rollback_details: {
              target_timestamp: version_timestamp,
              changes_applied: rollback_result[:applied_changes],
              impact_analysis: impact_analysis
            }
          }
        end
      rescue => e
        Rails.logger.error "ChangeTracker rollback error: #{e.message}"
        {
          success: false,
          error: e.message,
          error_code: 'ROLLBACK_ERROR'
        }
      end
    end

    # 変更影響分析
    def analyze_change_impact(proposed_changes)
      current_snapshot = capture_issue_snapshot(@issue)
      impact_analysis = {
        high_impact_changes: [],
        medium_impact_changes: [],
        low_impact_changes: [],
        affected_relationships: [],
        affected_children: [],
        version_propagation_required: false,
        risk_level: 'low'
      }

      proposed_changes.each do |attribute, new_value|
        current_value = current_snapshot[attribute]
        impact_level = assess_change_impact(attribute, current_value, new_value)

        case impact_level
        when 'high'
          impact_analysis[:high_impact_changes] << {
            attribute: attribute,
            from: current_value,
            to: new_value,
            reason: get_impact_reason(attribute, current_value, new_value)
          }
        when 'medium'
          impact_analysis[:medium_impact_changes] << {
            attribute: attribute,
            from: current_value,
            to: new_value
          }
        else
          impact_analysis[:low_impact_changes] << {
            attribute: attribute,
            from: current_value,
            to: new_value
          }
        end
      end

      # 全体的なリスクレベル判定
      if impact_analysis[:high_impact_changes].any?
        impact_analysis[:risk_level] = 'high'
      elsif impact_analysis[:medium_impact_changes].count > 3
        impact_analysis[:risk_level] = 'medium'
      end

      # 関連Issue影響チェック
      impact_analysis[:affected_children] = analyze_children_impact(proposed_changes)
      impact_analysis[:affected_relationships] = analyze_relationship_impact(proposed_changes)

      # Version変更の場合、伝播が必要かチェック
      if proposed_changes.key?('fixed_version_id')
        impact_analysis[:version_propagation_required] = @issue.children.any?
      end

      {
        success: true,
        data: impact_analysis
      }
    rescue => e
      Rails.logger.error "ChangeTracker analyze_change_impact error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'CHANGE_IMPACT_ANALYSIS_ERROR'
      }
    end

    private

    # Issue状態のスナップショット取得
    def capture_issue_snapshot(issue)
      snapshot = {}

      TRACKABLE_ATTRIBUTES.each do |attr|
        snapshot[attr] = issue.send(attr)
      end

      # 関連情報も含める
      snapshot.merge!({
        tracker_id: issue.tracker_id,
        tracker_name: issue.tracker.name,
        status_name: issue.status.name,
        assigned_to_name: issue.assigned_to&.name,
        fixed_version_name: issue.fixed_version&.name,
        parent_subject: issue.parent&.subject,
        children_ids: issue.children.pluck(:id),
        relations: capture_relations_snapshot(issue)
      })

      snapshot
    end

    def capture_relations_snapshot(issue)
      {
        blocks: issue.relations_from.where(relation_type: 'blocks').pluck(:issue_to_id),
        blocked_by: issue.relations_to.where(relation_type: 'blocks').pluck(:issue_from_id),
        follows: issue.relations_from.where(relation_type: 'follows').pluck(:issue_to_id),
        precedes: issue.relations_from.where(relation_type: 'precedes').pluck(:issue_to_id)
      }
    end

    # 差分計算
    def calculate_diff(before_snapshot, after_snapshot)
      diff = {}

      TRACKABLE_ATTRIBUTES.each do |attr|
        before_value = before_snapshot[attr]
        after_value = after_snapshot[attr]

        if before_value != after_value
          diff[attr] = {
            before: before_value,
            after: after_value,
            type: determine_change_type(attr, before_value, after_value)
          }
        end
      end

      diff
    end

    def determine_change_type(attribute, before_value, after_value)
      case attribute
      when 'status_id'
        'status_change'
      when 'assigned_to_id'
        before_value.nil? ? 'assignment' : (after_value.nil? ? 'unassignment' : 'reassignment')
      when 'fixed_version_id'
        'version_change'
      when 'parent_id'
        'hierarchy_change'
      else
        'value_change'
      end
    end

    # 変更記録の保存
    def save_change_record(change_record)
      # 独自テーブルまたはRedmineのJournalシステムを拡張
      change_record[:change_id] = SecureRandom.uuid

      # 簡易実装: Railsキャッシュを利用
      cache_key = "change_record:#{@issue.id}:#{change_record[:change_id]}"
      Rails.cache.write(cache_key, change_record, expires_in: 1.year)

      # 変更一覧キャッシュ更新
      changes_list_key = "change_records:#{@issue.id}"
      existing_changes = Rails.cache.fetch(changes_list_key, expires_in: 1.year) { [] }
      existing_changes.unshift(change_record[:change_id])
      existing_changes = existing_changes.first(1000) # 最新1000件のみ保持
      Rails.cache.write(changes_list_key, existing_changes, expires_in: 1.year)
    end

    def get_custom_change_records(limit, offset, change_types)
      changes_list_key = "change_records:#{@issue.id}"
      change_ids = Rails.cache.fetch(changes_list_key, expires_in: 1.year) { [] }

      selected_ids = change_ids.drop(offset).first(limit)
      changes = []

      selected_ids.each do |change_id|
        cache_key = "change_record:#{@issue.id}:#{change_id}"
        change_record = Rails.cache.fetch(cache_key)

        if change_record && (change_types.nil? || change_types.include?(change_record[:change_type]))
          changes << format_change_record(change_record)
        end
      end

      changes
    end

    def format_change_record(change_record)
      {
        id: change_record[:change_id],
        user_id: change_record[:user_id],
        user_name: User.find_by(id: change_record[:user_id])&.name,
        change_type: change_record[:change_type],
        timestamp: change_record[:timestamp],
        diff: change_record[:diff],
        metadata: change_record[:metadata]
      }
    end

    def merge_change_records(redmine_journals, custom_changes)
      all_changes = []

      # Redmine Journal変換
      redmine_journals.each do |journal|
        all_changes << {
          id: "journal_#{journal.id}",
          user_id: journal.user_id,
          user_name: journal.user.name,
          change_type: 'redmine_update',
          timestamp: journal.created_on,
          diff: format_journal_details(journal.details),
          notes: journal.notes,
          source: 'redmine'
        }
      end

      # 独自変更記録追加
      all_changes.concat(custom_changes)

      # タイムスタンプでソート
      all_changes.sort_by { |change| change[:timestamp] }.reverse
    end

    def format_journal_details(details)
      formatted = {}
      details.each do |detail|
        formatted[detail.property] = {
          before: detail.old_value,
          after: detail.value,
          type: 'journal_change'
        }
      end
      formatted
    end

    def calculate_total_changes
      changes_list_key = "change_records:#{@issue.id}"
      custom_count = Rails.cache.fetch(changes_list_key, expires_in: 1.year) { [] }.count
      journal_count = @issue.journals.count

      custom_count + journal_count
    end

    def generate_change_summary(changes)
      summary = {
        total_changes: changes.count,
        change_types: {},
        most_active_users: {},
        recent_activity: changes.first(5)
      }

      changes.each do |change|
        # 変更タイプ集計
        type = change[:change_type]
        summary[:change_types][type] = (summary[:change_types][type] || 0) + 1

        # ユーザー別集計
        user_name = change[:user_name]
        summary[:most_active_users][user_name] = (summary[:most_active_users][user_name] || 0) + 1
      end

      summary
    end

    def find_change_record_by_timestamp(timestamp)
      changes_list_key = "change_records:#{@issue.id}"
      change_ids = Rails.cache.fetch(changes_list_key, expires_in: 1.year) { [] }

      change_ids.each do |change_id|
        cache_key = "change_record:#{@issue.id}:#{change_id}"
        change_record = Rails.cache.fetch(cache_key)

        return change_record if change_record && change_record[:timestamp].to_i == timestamp.to_i
      end

      nil
    end

    def analyze_rollback_impact(target_snapshot, current_snapshot)
      impact = {
        high_impact: false,
        affected_attributes: [],
        children_affected: false,
        relations_affected: false
      }

      TRACKABLE_ATTRIBUTES.each do |attr|
        if target_snapshot[attr] != current_snapshot[attr]
          impact[:affected_attributes] << attr

          # 高影響判定
          if %w[status_id parent_id tracker_id].include?(attr)
            impact[:high_impact] = true
          end
        end
      end

      # 子要素への影響チェック
      if target_snapshot['children_ids'] != current_snapshot['children_ids']
        impact[:children_affected] = true
        impact[:high_impact] = true
      end

      impact
    end

    def perform_rollback(target_snapshot)
      applied_changes = []

      TRACKABLE_ATTRIBUTES.each do |attr|
        target_value = target_snapshot[attr]
        current_value = @issue.send(attr)

        if target_value != current_value
          @issue.send("#{attr}=", target_value)
          applied_changes << {
            attribute: attr,
            from: current_value,
            to: target_value
          }
        end
      end

      @issue.save!

      { applied_changes: applied_changes }
    end

    def assess_change_impact(attribute, current_value, new_value)
      case attribute
      when 'status_id'
        # ステータス変更は中〜高影響
        current_status = IssueStatus.find_by(id: current_value)
        new_status = IssueStatus.find_by(id: new_value)

        if current_status&.is_closed != new_status&.is_closed
          'high' # クローズ状態の変更
        else
          'medium'
        end
      when 'parent_id'
        'high' # 階層構造の変更
      when 'fixed_version_id'
        'high' # Version変更（子要素への影響大）
      when 'assigned_to_id'
        'medium' # 担当者変更
      else
        'low'
      end
    end

    def get_impact_reason(attribute, current_value, new_value)
      case attribute
      when 'status_id'
        '子要素のワークフローに影響する可能性があります'
      when 'parent_id'
        '階層構造が変更され、関連するIssueに影響します'
      when 'fixed_version_id'
        '子要素への自動Version伝播が発生します'
      else
        '重要な属性の変更です'
      end
    end

    def analyze_children_impact(proposed_changes)
      return [] unless @issue.children.any?

      affected_children = []

      if proposed_changes.key?('fixed_version_id')
        # Version変更は全子要素に影響
        affected_children = @issue.children.map do |child|
          {
            id: child.id,
            subject: child.subject,
            impact_type: 'version_propagation'
          }
        end
      end

      affected_children
    end

    def analyze_relationship_impact(proposed_changes)
      affected_relations = []

      if proposed_changes.key?('status_id')
        # ステータス変更はblocks関係に影響する可能性
        blocked_issues = @issue.relations_from.where(relation_type: 'blocks').includes(:issue_to)

        blocked_issues.each do |relation|
          affected_relations << {
            type: 'blocks',
            target_issue: {
              id: relation.issue_to.id,
              subject: relation.issue_to.subject
            },
            impact_description: 'ブロック状態が変更される可能性があります'
          }
        end
      end

      affected_relations
    end
  end
end