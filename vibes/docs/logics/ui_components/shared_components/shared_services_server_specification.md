# 共通サービス サーバーサイド実装仕様

## 概要
Kanbanコンポーネント間で共有されるサーバーサイドサービス。認証・認可、キャッシング、通知、ロギング、バリデーション、エラーハンドリング。

## 認証・認可サービス

### Kanban権限管理
```ruby
# app/services/kanban/permission_service.rb
module Kanban
  class PermissionService
    def initialize(user, project)
      @user = user
      @project = project
    end

    def can_view_kanban?
      @user.allowed_to?(:view_kanban, @project)
    end

    def can_edit_issues?
      @user.allowed_to?(:edit_issues, @project)
    end

    def can_manage_versions?
      @user.allowed_to?(:manage_versions, @project)
    end

    def can_bulk_update?
      @user.allowed_to?(:bulk_update_issues, @project)
    end

    def can_generate_tests?
      @user.allowed_to?(:generate_kanban_tests, @project)
    end

    def can_drag_issue?(issue)
      return false unless can_edit_issues?
      return false if issue.closed?

      # 階層制約チェック
      case issue.tracker.name
      when 'Epic'
        can_move_epic?(issue)
      when 'Feature'
        can_move_feature?(issue)
      when 'UserStory'
        can_move_user_story?(issue)
      else
        can_move_child_item?(issue)
      end
    end

    def available_transitions(issue)
      return [] unless can_edit_issues?

      workflow = WorkflowPermission.where(
        tracker_id: issue.tracker_id,
        old_status_id: issue.status_id,
        role_id: @user.roles_for_project(@project).pluck(:id)
      )

      workflow.includes(:new_status).map(&:new_status)
    end

    private

    def can_move_epic?(epic)
      # Epic移動は特別な権限が必要
      @user.allowed_to?(:manage_epic_structure, @project)
    end

    def can_move_feature?(feature)
      # Feature移動は標準編集権限で可能
      true
    end

    def can_move_user_story?(user_story)
      # UserStory移動は親Featureの状態に依存
      parent_feature = user_story.parent
      return true unless parent_feature

      !parent_feature.closed?
    end

    def can_move_child_item?(item)
      # Task/Test/Bug移動は親UserStoryの状態に依存
      parent_user_story = item.parent
      return true unless parent_user_story

      !parent_user_story.closed?
    end
  end
end
```

### セッション管理サービス
```ruby
# app/services/kanban/session_service.rb
module Kanban
  class SessionService
    def self.create_kanban_session(user, project)
      session_data = {
        user_id: user.id,
        project_id: project.id,
        started_at: Time.zone.now,
        preferences: load_user_preferences(user, project)
      }

      Rails.cache.write("kanban_session:#{user.id}:#{project.id}", session_data, expires_in: 4.hours)
      session_data
    end

    def self.get_session(user, project)
      Rails.cache.read("kanban_session:#{user.id}:#{project.id}")
    end

    def self.update_preferences(user, project, preferences)
      session = get_session(user, project) || {}
      session[:preferences] = session[:preferences].merge(preferences)

      Rails.cache.write("kanban_session:#{user.id}:#{project.id}", session, expires_in: 4.hours)

      # 永続化
      save_user_preferences(user, project, session[:preferences])
    end

    private

    def self.load_user_preferences(user, project)
      pref = KanbanUserPreference.find_by(user: user, project: project)
      return default_preferences unless pref

      {
        default_expanded: pref.default_expanded,
        auto_refresh: pref.auto_refresh,
        column_widths: pref.column_widths,
        filter_settings: pref.filter_settings
      }
    end

    def self.default_preferences
      {
        default_expanded: false,
        auto_refresh: true,
        column_widths: { todo: 200, in_progress: 200, ready_for_test: 200, released: 200 },
        filter_settings: {}
      }
    end
  end
end
```

## キャッシング サービス

### Kanban データキャッシュ
```ruby
# app/services/kanban/cache_service.rb
module Kanban
  class CacheService
    CACHE_EXPIRY = 15.minutes

    def self.get_kanban_data(project, user, filters = {})
      cache_key = generate_cache_key(project, user, filters)

      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
        KanbanDataBuilder.new(project, user, filters).build
      end
    end

    def self.invalidate_kanban_data(project, epic_ids = nil)
      if epic_ids.present?
        # 特定Epicのキャッシュのみ無効化
        epic_ids.each do |epic_id|
          Rails.cache.delete_matched("kanban:data:#{project.id}:*:epic:#{epic_id}:*")
        end
      else
        # プロジェクト全体のキャッシュを無効化
        Rails.cache.delete_matched("kanban:data:#{project.id}:*")
      end
    end

    def self.get_issue_data(issue_id)
      cache_key = "kanban:issue:#{issue_id}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
        issue = Issue.includes(:tracker, :status, :assigned_to, :fixed_version, :children).find(issue_id)
        serialize_issue_with_hierarchy(issue)
      end
    end

    def self.invalidate_issue_data(issue_ids)
      Array(issue_ids).each do |issue_id|
        Rails.cache.delete("kanban:issue:#{issue_id}")

        # 関連する親・子Issueのキャッシュも無効化
        issue = Issue.find_by(id: issue_id)
        next unless issue

        invalidate_related_issues(issue)
      end
    end

    def self.warm_up_cache(project, user)
      # よく使用されるデータを事前にキャッシュ
      KanbanWarmUpJob.perform_later(project.id, user.id)
    end

    private

    def self.generate_cache_key(project, user, filters)
      filter_hash = Digest::MD5.hexdigest(filters.to_json)
      "kanban:data:#{project.id}:#{user.id}:#{filter_hash}"
    end

    def self.invalidate_related_issues(issue)
      related_ids = []

      # 親Issue
      related_ids << issue.parent_id if issue.parent_id

      # 子Issues
      related_ids.concat(issue.children.pluck(:id))

      # 関連Issues（ブロック関係等）
      related_ids.concat(
        issue.relations_from.pluck(:issue_to_id) +
        issue.relations_to.pluck(:issue_from_id)
      )

      related_ids.compact.uniq.each do |related_id|
        Rails.cache.delete("kanban:issue:#{related_id}")
      end
    end
  end
end
```

## 通知サービス

### リアルタイム通知
```ruby
# app/services/kanban/notification_service.rb
module Kanban
  class NotificationService
    def self.notify_issue_update(issue, user, action_type)
      notification_data = {
        type: 'issue_update',
        issue_id: issue.id,
        epic_id: issue.root.id,
        action: action_type,
        user: { id: user.id, name: user.name },
        timestamp: Time.zone.now.iso8601,
        changes: build_change_summary(issue)
      }

      # WebSocket通知
      broadcast_to_project(issue.project, notification_data)

      # メール通知（設定による）
      send_email_notification(issue, user, action_type) if should_send_email?(issue, action_type)

      # アクティビティログ
      log_activity(issue, user, action_type)
    end

    def self.notify_bulk_update(issues, user, action_type, results)
      notification_data = {
        type: 'bulk_update',
        action: action_type,
        user: { id: user.id, name: user.name },
        results: {
          successful: results[:successful],
          failed: results[:failed],
          total: issues.size
        },
        affected_epics: issues.map(&:root).uniq.map(&:id),
        timestamp: Time.zone.now.iso8601
      }

      # プロジェクトの全ユーザーに通知
      broadcast_to_project(issues.first.project, notification_data)
    end

    def self.notify_version_assignment(version, issues, user)
      notification_data = {
        type: 'version_assignment',
        version: { id: version.id, name: version.name },
        issue_count: issues.size,
        user: { id: user.id, name: user.name },
        affected_epics: issues.map(&:root).uniq.map(&:id),
        timestamp: Time.zone.now.iso8601
      }

      broadcast_to_project(version.project, notification_data)
    end

    private

    def self.broadcast_to_project(project, data)
      ActionCable.server.broadcast("kanban_project_#{project.id}", data)
    end

    def self.build_change_summary(issue)
      changes = {}

      if issue.previous_changes.key?('status_id')
        old_status = IssueStatus.find(issue.previous_changes['status_id'][0])
        changes[:status] = { from: old_status.name, to: issue.status.name }
      end

      if issue.previous_changes.key?('fixed_version_id')
        old_version_id = issue.previous_changes['fixed_version_id'][0]
        old_version = old_version_id ? Version.find(old_version_id) : nil
        changes[:version] = {
          from: old_version&.name,
          to: issue.fixed_version&.name
        }
      end

      changes
    end

    def self.should_send_email?(issue, action_type)
      # メール通知条件
      return true if action_type == 'status_changed' && issue.closed?
      return true if action_type == 'version_assigned'
      false
    end

    def self.send_email_notification(issue, user, action_type)
      # 非同期メール送信
      KanbanMailer.issue_update_notification(issue, user, action_type).deliver_later
    end

    def self.log_activity(issue, user, action_type)
      ActivityLogger.log(
        user: user,
        project: issue.project,
        action: action_type,
        target: issue,
        details: { tracker: issue.tracker.name, epic_id: issue.root.id }
      )
    end
  end
end
```

## バリデーション サービス

### Kanban ルールバリデータ
```ruby
# app/services/kanban/validation_service.rb
module Kanban
  class ValidationService
    def initialize(project)
      @project = project
    end

    def validate_issue_move(issue, target_column, target_version = nil)
      errors = []

      errors.concat(validate_status_transition(issue, target_column))
      errors.concat(validate_hierarchy_constraints(issue, target_column))
      errors.concat(validate_version_assignment(issue, target_version)) if target_version
      errors.concat(validate_workflow_rules(issue, target_column))

      ValidationResult.new(errors.empty?, errors)
    end

    def validate_bulk_operation(issues, operation_type, operation_params)
      errors = []
      valid_issues = []

      issues.each do |issue|
        issue_errors = validate_single_issue_operation(issue, operation_type, operation_params)

        if issue_errors.empty?
          valid_issues << issue
        else
          errors << { issue: issue, errors: issue_errors }
        end
      end

      BulkValidationResult.new(valid_issues, errors)
    end

    private

    def validate_status_transition(issue, target_column)
      errors = []

      column_config = KanbanColumnConfig.for_project(@project)
      target_column_data = column_config.find { |col| col[:id] == target_column }

      unless target_column_data
        errors << "無効な移動先列: #{target_column}"
        return errors
      end

      allowed_statuses = target_column_data[:statuses_for_tracker][issue.tracker.name]

      unless allowed_statuses&.any?
        errors << "#{issue.tracker.name} は #{target_column_data[:name]} 列に移動できません"
      end

      errors
    end

    def validate_hierarchy_constraints(issue, target_column)
      errors = []

      case issue.tracker.name
      when 'Feature'
        errors.concat(validate_feature_move_constraints(issue, target_column))
      when 'UserStory'
        errors.concat(validate_user_story_move_constraints(issue, target_column))
      when 'Task', 'Test', 'Bug'
        errors.concat(validate_child_item_move_constraints(issue, target_column))
      end

      errors
    end

    def validate_feature_move_constraints(feature, target_column)
      errors = []

      # 完了状態への移動時は全UserStoryが完了していること
      if target_column == 'released'
        incomplete_user_stories = feature.children
                                        .select { |child| child.tracker.name == 'UserStory' }
                                        .reject(&:closed?)

        if incomplete_user_stories.any?
          errors << "未完了のUserStoryがあるため、Featureを完了状態に移動できません"
        end
      end

      errors
    end

    def validate_user_story_move_constraints(user_story, target_column)
      errors = []

      # 親Featureが完了している場合は移動不可
      if user_story.parent&.closed?
        errors << "完了したFeatureのUserStoryは移動できません"
      end

      # 完了状態への移動時は全子アイテムが完了していること
      if target_column == 'released'
        incomplete_children = user_story.children.reject(&:closed?)

        if incomplete_children.any?
          errors << "未完了のTask/Test/Bugがあるため、UserStoryを完了状態に移動できません"
        end
      end

      errors
    end

    def validate_version_assignment(issue, version)
      errors = []

      # バージョンのステータスチェック
      unless version.open?
        errors << "クローズされたバージョンには割り当てできません"
      end

      # 階層整合性チェック
      if issue.parent && issue.parent.fixed_version && issue.parent.fixed_version != version
        errors << "親Issueと異なるバージョンは割り当てできません"
      end

      errors
    end

    def validate_workflow_rules(issue, target_column)
      errors = []

      # カスタムワークフロールールの適用
      workflow_rules = WorkflowRule.for_project_and_tracker(@project, issue.tracker)

      workflow_rules.each do |rule|
        unless rule.allows_transition?(issue, target_column)
          errors << rule.error_message
        end
      end

      errors
    end
  end

  class ValidationResult
    attr_reader :valid, :errors

    def initialize(valid, errors)
      @valid = valid
      @errors = errors
    end

    def valid?
      @valid
    end

    def error_message
      @errors.join(', ')
    end
  end

  class BulkValidationResult
    attr_reader :valid_issues, :invalid_issues

    def initialize(valid_issues, invalid_issues)
      @valid_issues = valid_issues
      @invalid_issues = invalid_issues
    end

    def any_valid?
      @valid_issues.any?
    end

    def all_valid?
      @invalid_issues.empty?
    end

    def error_summary
      @invalid_issues.map do |item|
        "#{item[:issue].subject}: #{item[:errors].join(', ')}"
      end.join('; ')
    end
  end
end
```

## エラーハンドリング サービス

### Kanban例外ハンドラー
```ruby
# app/services/kanban/error_handling_service.rb
module Kanban
  class ErrorHandlingService
    def self.handle_api_error(error, context = {})
      case error
      when ActiveRecord::RecordNotFound
        handle_not_found_error(error, context)
      when ActiveRecord::RecordInvalid
        handle_validation_error(error, context)
      when Kanban::PermissionDenied
        handle_permission_error(error, context)
      when Kanban::WorkflowViolation
        handle_workflow_error(error, context)
      else
        handle_generic_error(error, context)
      end
    end

    def self.log_error(error, context = {})
      Rails.logger.error("[Kanban Error] #{error.class}: #{error.message}")
      Rails.logger.error("Context: #{context.inspect}")
      Rails.logger.error(error.backtrace.join("\n")) if Rails.env.development?

      # エラー追跡システム（Sentry等）への送信
      if defined?(Sentry)
        Sentry.capture_exception(error, extra: context)
      end
    end

    private

    def self.handle_not_found_error(error, context)
      {
        status: :not_found,
        error: 'リソースが見つかりません',
        details: extract_model_name(error.message),
        request_id: context[:request_id]
      }
    end

    def self.handle_validation_error(error, context)
      {
        status: :unprocessable_entity,
        error: 'バリデーションエラー',
        validation_errors: format_validation_errors(error.record),
        request_id: context[:request_id]
      }
    end

    def self.handle_permission_error(error, context)
      {
        status: :forbidden,
        error: 'この操作を実行する権限がありません',
        required_permission: error.required_permission,
        request_id: context[:request_id]
      }
    end

    def self.handle_workflow_error(error, context)
      {
        status: :unprocessable_entity,
        error: 'ワークフロールール違反',
        workflow_message: error.message,
        suggested_actions: error.suggested_actions,
        request_id: context[:request_id]
      }
    end

    def self.handle_generic_error(error, context)
      {
        status: :internal_server_error,
        error: 'サーバーエラーが発生しました',
        message: Rails.env.development? ? error.message : '管理者にお問い合わせください',
        request_id: context[:request_id]
      }
    end

    def self.format_validation_errors(record)
      record.errors.full_messages.map do |message|
        {
          field: record.errors.keys.first,
          message: message
        }
      end
    end
  end

  # カスタム例外クラス
  class PermissionDenied < StandardError
    attr_reader :required_permission

    def initialize(message, required_permission = nil)
      super(message)
      @required_permission = required_permission
    end
  end

  class WorkflowViolation < StandardError
    attr_reader :suggested_actions

    def initialize(message, suggested_actions = [])
      super(message)
      @suggested_actions = suggested_actions
    end
  end
end
```

## ユーティリティサービス

### データシリアライザ
```ruby
# app/services/kanban/serializer_service.rb
module Kanban
  class SerializerService
    def self.serialize_issue(issue, options = {})
      base_data = {
        id: issue.id,
        subject: issue.subject,
        description: options[:include_description] ? issue.description : nil,
        tracker: issue.tracker.name,
        status: {
          id: issue.status.id,
          name: issue.status.name,
          color: issue.status.color,
          is_closed: issue.status.is_closed?
        },
        assigned_to: issue.assigned_to ? {
          id: issue.assigned_to.id,
          name: issue.assigned_to.name
        } : nil,
        fixed_version: issue.fixed_version ? {
          id: issue.fixed_version.id,
          name: issue.fixed_version.name
        } : nil,
        priority: {
          id: issue.priority.id,
          name: issue.priority.name
        },
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601
      }

      if options[:include_hierarchy]
        base_data[:hierarchy] = {
          parent_id: issue.parent_id,
          root_id: issue.root.id,
          level: calculate_hierarchy_level(issue),
          has_children: issue.children.any?
        }
      end

      if options[:include_relations]
        base_data[:relations] = serialize_issue_relations(issue)
      end

      base_data.compact
    end

    def self.serialize_project_metadata(project)
      {
        id: project.id,
        name: project.name,
        identifier: project.identifier,
        trackers: project.trackers.pluck(:id, :name),
        versions: project.versions.open.pluck(:id, :name),
        issue_statuses: project.rolled_up_statuses.pluck(:id, :name, :is_closed),
        members: project.members.joins(:user).pluck('users.id', 'users.name')
      }
    end

    private

    def self.calculate_hierarchy_level(issue)
      level = 0
      current = issue

      while current.parent
        level += 1
        current = current.parent
        break if level > 5 # 無限ループ防止
      end

      level
    end

    def self.serialize_issue_relations(issue)
      issue.relations_from.includes(:issue_to, :relation_type).map do |relation|
        {
          type: relation.relation_type,
          target_issue_id: relation.issue_to.id,
          target_issue_subject: relation.issue_to.subject,
          delay: relation.delay
        }
      end
    end
  end
end
```

---

*Kanban共通サーバーサイドサービス。認証・認可、キャッシング、通知、バリデーション、エラーハンドリング*