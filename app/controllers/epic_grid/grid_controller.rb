# frozen_string_literal: true

module EpicGrid
  # グリッドデータ管理コントローラー
  # Epic×Version マトリクスデータ取得・操作API提供
  class GridController < BaseApiController
    before_action :find_issue, only: [:move_feature, :create_epic]

    # Grid Data取得 (API001)
    # MSW NormalizedAPIResponse形式を直接返す
    def show
      # Fat Model使用: Project#epic_grid_data
      include_closed = params[:include_closed] != 'false'
      grid_data = @project.epic_grid_data(include_closed: include_closed)

      # MSW準拠レスポンス: NormalizedAPIResponse形式（success/dataラッパーなし）
      response_data = {
        entities: grid_data[:entities],
        grid: grid_data[:grid],
        metadata: grid_data[:metadata].merge({
          user_permissions: user_permissions,
          grid_configuration: {
            default_expanded: true,
            show_statistics: true,
            show_closed_issues: include_closed,
            columns: []
          },
          api_version: 'v1',
          timestamp: Time.current.iso8601,
          request_id: request.uuid
        }),
        statistics: @project.epic_grid_build_statistics
      }

      render json: response_data, status: :ok
    rescue => e
      Rails.logger.error "Grid data error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render_error('グリッドデータの取得に失敗しました', :internal_server_error)
    end

    # Feature移動 (API002) - 楽観的更新対応
    def move_feature
      feature = Issue.find(params[:feature_id])
      target_epic_id = params[:target_epic_id]
      target_version_id = params[:target_version_id]
      optimistic_lock_version = params[:lock_version]

      # 楽観的ロックチェック
      if optimistic_lock_version && feature.lock_version != optimistic_lock_version.to_i
        return render_error(
          'リソースが他のユーザーによって更新されています',
          :conflict,
          {
            resource_id: feature.id,
            current_version: feature.lock_version,
            attempted_version: optimistic_lock_version
          }
        )
      end

      # Fat Model使用: Issue#epic_grid_move_to_cell
      feature.epic_grid_move_to_cell(target_epic_id, target_version_id)

      # 影響を受けた子要素を取得
      affected_issues = feature.descendants

      render_success({
        feature: serialize_issue(feature),
        affected_issues: affected_issues.map { |issue| serialize_issue(issue) },
        propagation_results: {
          propagated_count: affected_issues.count,
          new_version_id: target_version_id
        },
        grid_updates: {
          source_cell: "#{feature.parent_id_was}:#{feature.fixed_version_id_was}",
          target_cell: "#{target_epic_id}:#{target_version_id}"
        }
      })
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたFeatureが見つかりません', :not_found)
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record.errors)
    end

    # Epic作成 (API003)
    def create_epic
      # 権限チェック
      unless User.current.allowed_to?(:add_issues, @project)
        return render_error('権限が不足しています', :forbidden, {
          required_permission: 'add_issues',
          resource_type: 'Project',
          resource_id: @project.id
        })
      end

      epic_params = params.require(:epic).permit(:subject, :description, :assigned_to_id, :fixed_version_id)

      # Epicトラッカー取得
      epic_tracker = @project.trackers.find_by(name: EpicGrid::TrackerHierarchy.tracker_names[:epic])
      unless epic_tracker
        return render_error(
          'Epicトラッカーが設定されていません',
          :unprocessable_entity,
          {
            error_code: 'EPIC_TRACKER_NOT_FOUND',
            error_type: 'configuration_error',
            help_url: '/help/kanban_setup'
          }
        )
      end

      # Epic作成
      epic = Issue.create!(
        project: @project,
        tracker: epic_tracker,
        author: User.current,
        status: IssueStatus.first,
        **epic_params
      )

      # MSW準拠のレスポンス構築
      render_normalized_success(
        created_entity: epic.epic_grid_as_normalized_json,
        updated_entities: {
          epics: { epic.id.to_s => epic.epic_grid_as_normalized_json }
        },
        grid_updates: {
          epic_order: @project.epic_grid_index[:epic_order]
        },
        status: :created
      )
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record.errors)
    end

    # Version自動伝播 (API004)
    def propagate_version
      issue = Issue.find(params[:issue_id])
      version_id = params[:version_id].presence

      # Fat Model使用: Issue#epic_grid_propagate_version_to_children
      issue.epic_grid_propagate_version_to_children(version_id)

      # 影響を受けた子要素
      affected_issues = issue.descendants

      render_success({
        root_issue: serialize_issue(issue.reload),
        affected_issues_count: affected_issues.count,
        affected_issue_ids: affected_issues.pluck(:id),
        propagation_summary: {
          propagated_count: affected_issues.count,
          new_version_id: version_id
        }
      })
    rescue ActiveRecord::RecordNotFound
      render_error('指定されたIssueまたはVersionが見つかりません', :not_found)
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record.errors)
    end

    # Version作成 (設計書準拠API)
    def create_version
      version_params = params.require(:version).permit(:name, :description, :effective_date, :status)

      Rails.logger.info "Creating version for project #{@project.id}: #{version_params.inspect}"

      # 権限チェック
      unless User.current.allowed_to?(:manage_versions, @project)
        return render_error('権限が不足しています', :forbidden, {
          required_permission: 'manage_versions',
          resource_type: 'Project',
          resource_id: @project.id
        })
      end

      # バージョンインスタンス作成
      version = @project.versions.build(version_params)

      # 重複名チェック
      if @project.versions.where(name: version_params[:name]).exists?
        Rails.logger.warn "Version name already exists: #{version_params[:name]}"
        return render_error('バージョン名が既に存在します', :unprocessable_entity, {
          field: 'name',
          value: version_params[:name]
        })
      end

      # バージョン保存実行
      if version.save
        Rails.logger.info "Version created successfully: #{version.name} (id: #{version.id})"

        # MSW準拠のレスポンス構築
        version_json = {
          id: version.id.to_s,
          name: version.name,
          description: version.description || '',
          effective_date: version.effective_date&.iso8601,
          due_date: version.effective_date&.iso8601,
          status: version.status,
          created_on: version.created_on.iso8601,
          updated_on: version.updated_on.iso8601
        }

        render_normalized_success(
          created_entity: version_json,
          updated_entities: {
            versions: { version.id.to_s => version_json }
          },
          grid_updates: {
            version_order: @project.epic_grid_index[:version_order]
          },
          status: :created
        )
      else
        Rails.logger.error "Version save failed: #{version.errors.full_messages}"
        render_validation_error(version.errors)
      end
    end

    # カード移動 (設計書準拠move_card API)
    def move_card
      card_id = params.require(:card_id)
      source_cell = params.require(:source_cell).permit(:epic_id, :version_id, :column_id)
      target_cell = params.require(:target_cell).permit(:epic_id, :version_id, :column_id)

      Rails.logger.info "Moving card #{card_id}: #{source_cell.inspect} -> #{target_cell.inspect}"

      card = Issue.find(card_id)

      # 移動サービス実行
      result = EpicGrid::CardMoveService.execute(
        card: card,
        source_cell: source_cell.to_h.symbolize_keys,
        target_cell: target_cell.to_h.symbolize_keys,
        user: User.current,
        project: @project
      )

      if result[:success]
        render_success({
          updated_card: serialize_issue(result[:issue]),
          move_type: result[:move_type],
          affected_cells: result[:affected_cells],
          propagation_results: result[:propagation_results],
          statistics_update: result[:statistics_update],
          timestamp: result[:timestamp]
        })
      else
        render_error(result[:error], :unprocessable_entity, result.except(:success, :error))
      end

    rescue ActiveRecord::RecordNotFound
      render_error('指定されたカードが見つかりません', :not_found)
    rescue => e
      Rails.logger.error "Card move error: #{e.message}"
      render_error('カード移動に失敗しました', :internal_server_error)
    end

    # リアルタイム更新取得 (設計書準拠)
    def real_time_updates
      since_timestamp = params[:since]
      last_update_time = since_timestamp ? Time.parse(since_timestamp) : 1.hour.ago

      # 更新されたIssue取得
      updated_issues = @project.issues
                               .includes(:tracker, :status, :fixed_version, :assigned_to)
                               .where('updated_on > ?', last_update_time)
                               .order(:updated_on)

      # グリッド構造変更チェック
      structure_changes = detect_grid_structure_changes(last_update_time)

      render_success({
        updates: updated_issues.map { |issue| serialize_issue(issue) },
        deleted_issues: [], # TODO: 削除されたIssue検出実装
        grid_structure_changes: structure_changes,
        metadata: {
          update_count: updated_issues.count,
          next_poll_time: Time.current.iso8601,
          cache_version: calculate_cache_version
        }
      })

    rescue ArgumentError
      render_error('無効なタイムスタンプフォーマットです', :bad_request)
    rescue => e
      Rails.logger.error "Real-time updates error: #{e.message}"
      render_error('更新取得に失敗しました', :internal_server_error)
    end

    private

    def find_issue
      @issue = Issue.find(params[:issue_id]) if params[:issue_id]
    end

    def project_metadata
      {
        id: @project.id,
        name: @project.name,
        identifier: @project.identifier,
        description: @project.description,
        trackers: @project.trackers.pluck(:id, :name),
        versions: @project.versions.pluck(:id, :name, :status),
        issue_statuses: IssueStatus.all.pluck(:id, :name)
      }
    end

    def user_permissions
      {
        view_issues: User.current.allowed_to?(:view_issues, @project),
        edit_issues: User.current.allowed_to?(:edit_issues, @project),
        manage_versions: User.current.allowed_to?(:manage_versions, @project),
        view_kanban: User.current.allowed_to?(:view_kanban, @project),
        manage_kanban: User.current.allowed_to?(:manage_kanban, @project)
      }
    end

    def serialize_issue(issue)
      {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker.name,
        status: issue.status.name,
        status_column: determine_kanban_column(issue),
        priority: issue.priority.name,
        assigned_to: issue.assigned_to&.name,
        fixed_version: issue.fixed_version&.name,
        parent_id: issue.parent_id,
        hierarchy_level: EpicGrid::TrackerHierarchy.level(issue.tracker.name),
        lock_version: issue.lock_version,
        created_on: issue.created_on.iso8601,
        updated_on: issue.updated_on.iso8601,
        can_edit: User.current.allowed_to?(:edit_issues, @project),
        workflow_transitions: available_status_transitions(issue)
      }
    end

    def determine_kanban_column(issue)
      status_name = issue.status.name
      case status_name
      when 'New', 'Open'
        'backlog'
      when 'Ready'
        'ready'
      when 'In Progress', 'Assigned'
        'in_progress'
      when 'Review', 'Ready for Test'
        'review'
      when 'Testing', 'QA'
        'testing'
      when 'Resolved', 'Closed'
        'done'
      else
        'backlog'
      end
    end

    def available_status_transitions(issue)
      issue.new_statuses_allowed_to(User.current).map do |status|
        {
          id: status.id,
          name: status.name,
          column: determine_kanban_column_by_status(status)
        }
      end
    end

    def determine_kanban_column_by_status(status)
      determine_kanban_column(OpenStruct.new(status: status))
    end

    def calculate_cache_version
      # プロジェクトの最終更新時刻とIssue数をベースにキャッシュバージョン計算
      latest_issue_update = @project.issues.maximum(:updated_on) || @project.updated_on
      issue_count = @project.issues.count
      Digest::MD5.hexdigest("#{latest_issue_update}-#{issue_count}")
    end

    # Version情報のシリアライゼーション
    def serialize_version(version)
      {
        id: version.id,
        name: version.name,
        description: version.description,
        effective_date: version.effective_date,
        due_date: version.effective_date, # 互換性のため
        status: version.status,
        created_on: version.created_on.iso8601,
        updated_on: version.updated_on.iso8601,
        issues_count: version.fixed_issues.count,
        closed_issues_count: version.fixed_issues.joins(:status).where(issue_statuses: { is_closed: true }).count
      }
    end

    # 新しいVersionがグリッドに与える影響を計算
    def calculate_grid_impact_for_new_version(version)
      {
        statistics: {
          new_column: true,
          total_versions: @project.versions.count,
          version_position: version.id
        },
        requires_reload: false # 新しいVersionは既存のIssueに影響しないため
      }
    end

    # グリッド構造変更検出
    def detect_grid_structure_changes(since_time)
      changes = []

      # 新しいVersionの検出
      new_versions = @project.versions.where('created_on > ?', since_time)
      new_versions.each do |version|
        changes << {
          type: 'version_added',
          version_id: version.id,
          version_name: version.name,
          timestamp: version.created_on.iso8601
        }
      end

      # 削除されたVersionの検出は難しいため、キャッシュベースで検出予定

      # 新しいEpicの検出
      epic_tracker_name = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      new_epics = @project.issues.joins(:tracker)
                          .where(trackers: { name: epic_tracker_name })
                          .where('issues.created_on > ?', since_time)
      new_epics.each do |epic|
        changes << {
          type: 'epic_added',
          epic_id: epic.id,
          epic_subject: epic.subject,
          timestamp: epic.created_on.iso8601
        }
      end

      changes
    end

    public

    # テストデータリセット (テスト環境専用)
    def reset
      # 本番環境では実行不可
      unless Rails.env.test? || Rails.env.development?
        return render_error('この操作は本番環境では実行できません', :forbidden)
      end

      # プロジェクトの全Issueを削除
      deleted_count = @project.issues.delete_all

      # キャッシュクリア
      Rails.cache.clear

      render_success({
        message: 'グリッドデータをリセットしました',
        deleted_issues_count: deleted_count,
        project_id: @project.id,
        timestamp: Time.current.iso8601
      })
    rescue => e
      Rails.logger.error "Reset error: #{e.message}"
      render_error('リセット処理に失敗しました', :internal_server_error)
    end
  end
end