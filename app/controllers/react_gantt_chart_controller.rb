# plugins/redmine_react_gantt_chart/app/controllers/react_gantt_chart_controller.rb

class ReactGanttChartController < ApplicationController
  before_action :find_project, only: [:index, :data, :filters, :bulk_update, :create_subtask, :task_status]
  before_action :authorize, except: [:create_subtask, :task_status]
  before_action :authorize_create_subtask, only: [:create_subtask]
  before_action :authorize_task_status, only: [:task_status]

  # index: Reactアプリのマウント用ビューを表示
  def index
    # app/views/react_gantt_chart/index.html.erb 等でReactアプリを読み込む
  end

  # フィルタ定義を返す（IssueQueryベース）
  def filters
    Rails.logger.info "[GANTT_FILTER] filters action: returning filter definitions"
    
    begin
      query = IssueQuery.new(project: @project)
      available_filters = query.available_filters
      
      Rails.logger.info "[GANTT_FILTER] Available filters count: #{available_filters.keys.size}"
      Rails.logger.info "[GANTT_FILTER] Available filters keys: #{available_filters.keys.join(', ')}"
      
      # 重要なフィルタの詳細ログ
      ['tracker_id', 'status_id'].each do |key|
        if available_filters[key]
          filter_info = available_filters[key]
          Rails.logger.info "[GANTT_FILTER] #{key}: name=#{filter_info[:name]}, type=#{filter_info[:type]}, values_count=#{filter_info[:values]&.size || 0}"
        else
          Rails.logger.warn "[GANTT_FILTER] #{key}: NOT FOUND"
        end
      end
      
      formatted_filters = format_filters(available_filters)
      Rails.logger.info "[GANTT_FILTER] Formatted filters count: #{formatted_filters.keys.size}"
      
      # Redmine標準のフィルタ定義をそのまま使用
      render json: {
        operatorLabels: Query.operators_labels,
        operatorByType: Query.operators_by_filter_type,
        availableFilters: formatted_filters
      }
    rescue => e
      Rails.logger.error "[GANTT_ERROR] Filter definition error: #{e.message}"
      Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.join("\n")}"
      render json: { error: "フィルタ定義の取得に失敗しました: #{e.message}" }, status: :internal_server_error
    end
  end


  # 実際のチケットデータを返す（IssueQuery統合版）
  def data
    start_time = Time.current
    Rails.logger.info("[GANTT_DATA] Gantt data request: #{params.inspect}")

    @query = build_gantt_query(params)
    
    # 大規模データセットの場合、必須フィルタを確認
    total_count = @query.issue_count
    if total_count > 5000 && !gantt_view?(params) && !has_active_filters?(params)
      Rails.logger.warn "[GANTT_DATA] 大規模データセット(#{total_count}件)検出、デフォルト期間フィルタを適用"
      apply_default_date_filter(@query)
    end
    
    limit = calculate_optimal_limit(params)
    @issues = @query.issues(limit: limit)

    Rails.logger.info("[GANTT_DATA] Filtered issues count: #{@issues.size} (limit: #{limit}, total: #{total_count})")

    # ガントビュー時の追加フィルタリング処理（Redmineらしい実装）
    if gantt_view?(params)
      view_start = params[:view_start].present? ? Date.parse(params[:view_start]) : Date.today.beginning_of_month
      # 終了日が空の場合はnilのまま扱う（期日なしタスクを表示するため）
      view_end = params[:view_end].present? ? Date.parse(params[:view_end]) : nil
      
      # 期間に関わるタスクのみを残す（期日なしタスクは開始日で判定）
      before_filter_count = @issues.size
      @issues = @issues.select do |issue|
        # タスクが期間内に表示されるべきかを判定
        task_start = issue.start_date
        task_end = issue.due_date
        
        # 開始日・期日の両方がない場合は除外（ガントチャートに表示できない）
        next false if task_start.nil? && task_end.nil?
        
        # 期日がない場合は開始日で判定
        if task_end.nil?
          # 開始日が期間内（view_endがnilの場合は終了日制限なし）
          if view_end.nil?
            task_start >= view_start
          else
            task_start >= view_start && task_start <= view_end
          end
        else
          # タスクが期間と重なっているか判定
          # 1. タスクが期間開始前に終了している場合は除外
          next false if task_end < view_start
          
          # 2. タスクが期間終了後に開始する場合は除外（view_endがnilの場合は制限なし）
          next false if view_end && task_start && task_start > view_end
          
          # 3. それ以外は期間と重なっているので表示
          true
        end
      end
      after_filter_count = @issues.size
      
      Rails.logger.info("[GANTT_DATA] 期間フィルタリング: #{before_filter_count} → #{after_filter_count} 件")
      Rails.logger.info("[GANTT_DATA] 表示期間: #{view_start} 〜 #{view_end}")
      
      # 期間内のバージョンに関連するタスクも含める
      version_ids = Version.where(project_id: @project.id)
                          .where("effective_date BETWEEN ? AND ?", view_start, view_end)
                          .pluck(:id)
      
      if version_ids.any?
        # バージョンに関連するタスクを追加取得
        version_issues = Issue.where(project_id: @project.id, fixed_version_id: version_ids)
                             .includes(:status, :tracker, :priority, :assigned_to, :custom_values)
        
        # 同じ期間フィルタリングを適用
        version_issues = version_issues.select do |issue|
          task_start = issue.start_date
          task_end = issue.due_date
          
          next false if task_start.nil? && task_end.nil?
          
          if task_end.nil?
            task_start >= view_start && task_start <= view_end
          else
            !(task_end < view_start || (task_start && task_start > view_end))
          end
        end
        
        # 既存のissuesと結合（重複を除去）
        current_issue_ids = @issues.map(&:id)
        new_issues = version_issues.reject { |issue| current_issue_ids.include?(issue.id) }
        @issues = @issues + new_issues
        
        Rails.logger.info("[GANTT_DATA] 期間内バージョン考慮後のissues数: #{@issues.size}")
      end
    end

    # データ構築
    builder = RedmineReactGanttChart::GanttDataBuilder.new(
      project: @project,
      issues: @issues,
      params: params,
      user: User.current
    )
    result = builder.build
    
    # メタデータ追加（警告情報を含む）
    result[:meta] = {
      total_count: total_count,
      returned_count: @issues.size,
      view_range: {
        start: params[:view_start],
        end: params[:view_end]
      },
      has_more: @issues.size >= limit,
      limit_applied: limit
    }
    
    # データ切り捨て警告
    if @issues.size >= limit
      result[:warnings] = {
        data_truncated: true,
        total_count: total_count,
        displayed_count: @issues.size,
        limit: limit,
        message: "表示件数が制限値(#{limit}件)に達しています。より多くのデータを表示するにはフィルタで絞り込んでください。",
        severity: limit >= 10000 ? 'info' : 'warning'
      }
      Rails.logger.warn "[GANTT_DATA] データ切り捨て警告: #{@issues.size}/#{total_count}件表示 (制限: #{limit})"
    end
    
    # 権限情報を追加
    result[:permissions] = {
      can_edit: User.current.allowed_to?(:edit_issues, @project),
      can_add: User.current.allowed_to?(:add_issues, @project),
      can_delete: User.current.allowed_to?(:delete_issues, @project),
      readonly: !User.current.allowed_to?(:edit_issues, @project)
    }
    
    # パフォーマンスログ
    Rails.logger.info "[GANTT_PERF] Gantt data: " \
      "#{@issues.size} issues in #{(Time.current - start_time) * 1000}ms"
    
    result[:performance] = {
      query_time: (Time.current - start_time) * 1000,
      issue_count: @issues.size
    }

    # フィルタオプションを追加（フロントエンドのヘッダーフィルタ用）
    result[:filter_options] = {
      trackers: @project.trackers.pluck(:id, :name).map { |id, name|
        { value: id.to_s, label: name }
      },
      statuses: IssueStatus.sorted.pluck(:id, :name).map { |id, name|
        { value: id.to_s, label: name }
      },
      assignees: @project.assignable_users.reorder(:firstname, :lastname).pluck(:id, :firstname, :lastname).map { |id, first, last|
        name = [first, last].compact.join(' ').presence || "User #{id}"
        { value: id.to_s, label: name }
      },
      categories: @project.issue_categories.pluck(:id, :name).map { |id, name|
        { value: id.to_s, label: name }
      }
    }.tap do |options|
      Rails.logger.info "[GANTT_FILTER] Filter options generated: trackers=#{options[:trackers].size}, statuses=#{options[:statuses].size}, assignees=#{options[:assignees].size}, categories=#{options[:categories].size}"
    end

    render json: result
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[GANTT_ERROR] Record not found in data action: #{e.message}"
    Rails.logger.error "[GANTT_ERROR] Params: #{params.inspect}"
    render json: { error: "指定されたレコードが見つかりません" }, status: :not_found
  rescue ArgumentError => e
    Rails.logger.error "[GANTT_ERROR] Invalid argument in data action: #{e.message}"
    Rails.logger.error "[GANTT_ERROR] Params: #{params.inspect}"
    Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.first(10).join("\n")}"
    render json: { error: "無効なパラメータです: #{e.message}" }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "[GANTT_ERROR] Data action failed: #{e.class.name}: #{e.message}"
    Rails.logger.error "[GANTT_ERROR] Params: #{params.inspect}"
    Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.join("\n")}"
    render json: { error: "データ取得に失敗しました: #{e.message}" }, status: :internal_server_error
  end

  # POST /projects/:project_id/react_gantt_chart/bulk_update
  def bulk_update
    begin
      # パラメータのバリデーション
      unless params[:issues].is_a?(Array)
        return render json: { error: '不正なパラメータ形式です' }, status: :bad_request
      end

      ActiveRecord::Base.transaction do
        updated_issues = []
        errors = []

        params[:issues].each do |issue_params|
          issue = Issue.find_by(id: issue_params[:id])

          next unless issue && issue.project_id == @project.id
          next unless User.current.allowed_to?(:edit_issues, @project)

          # 更新可能な属性のみを抽出
          attributes = {}

          # --- bridge older "description" ⇔ front‑end "details" ---
          if issue_params.key?(:details) && !issue_params.key?(:description)
            issue_params[:description] = issue_params.delete(:details)
          end
          # --------------------------------------------------------

          # 基本フィールド
          [
            :subject, :description, :assigned_to_id, :tracker_id,
            :status_id, :category_id, :fixed_version_id, :priority_id,
            :done_ratio, :estimated_hours, :is_private, :parent_issue_id # parent_issue_id を追加
          ].each do |field|
            # parent_issue_id は parent_id にマッピング
            target_field = (field == :parent_issue_id) ? :parent_id : field
            attributes[target_field] = issue_params[field] if issue_params.key?(field)
          end

          # 日付フィールド
          [:start_date, :due_date].each do |field|
            if issue_params.key?(field) && issue_params[field].present?
              # JavaScriptから送られてくるISO形式の日時を日付に変換
              # タイムゾーン変換を考慮して、Time.zone.parseを使用
              parsed_time = Time.zone.parse(issue_params[field]) rescue nil
              attributes[field] = parsed_time.to_date if parsed_time
            end
          end

          # カスタムフィールド
          if issue_params[:custom_fields].is_a?(Hash)
            custom_field_values = issue_params[:custom_fields].map do |field_id, value|
              [field_id.to_s.sub(/^cf_/, '').to_i, value]
            end
            attributes[:custom_field_values] = custom_field_values.to_h
          end

          # 更新を試行
          if issue.update(attributes)
            # GanttDataBuilder と同じ形式でデータを整形
            builder = RedmineReactGanttChart::GanttDataBuilder.new(
              project: @project,
              issues: Issue.where(id: issue.id),
              params: params,
              user: User.current
            )
            result = builder.build

            # result[:tasks] は [version_summaries + task_list] の順
            # ここから更新対象 Issue のタスクのみを抽出する
            updated_task = result[:tasks].find { |t| t[:id] == issue.id }

            # 万一見つからなかった場合はフォールバックとして最初の要素を返す
            updated_issues << (updated_task || result[:tasks].first)
          else
            errors << { id: issue.id, errors: issue.errors.full_messages }
          end
        end

        if errors.any?
          render json: { error: 'チケットの更新に失敗しました', details: errors }, status: :unprocessable_entity
        else
          updated_issues.uniq! { |t| t[:id] }
          render json: { success: true, updated_issues: updated_issues }
        end
      end
    rescue => e
      Rails.logger.error "[GANTT_ERROR] Bulk update failed: #{e.message}"
      Rails.logger.error "[GANTT_ERROR] Params: #{params.inspect}"
      Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.join("\n")}"
      render json: { error: 'サーバーエラーが発生しました' }, status: :internal_server_error
    end
  end

  # サブタスク作成アクション
  def create_subtask
    # チケット作成権限をチェック
    unless User.current.allowed_to?(:add_issues, @project)
      render json: { error: 'チケット作成権限がありません' }, status: :forbidden
      return
    end
    
    @issue = Issue.new
    @issue.project = @project
    @issue.author = User.current
    
    # パラメータの設定
    @issue.subject = params[:issue][:subject]
    @issue.parent_issue_id = params[:issue][:parent_issue_id]
    @issue.start_date = params[:issue][:start_date]
    @issue.due_date = params[:issue][:due_date]
    
    # デフォルト値の設定
    @issue.tracker = @project.trackers.first
    # IssueStatusは最初のステータスを使用（通常は「新規」）
    @issue.status = IssueStatus.sorted.first
    # IssuePriorityはis_defaultがtrueのものを使用
    @issue.priority = IssuePriority.where(is_default: true).first || IssuePriority.active.first
    
    if @issue.save
      # Ganttチャートに必要なデータを含めて返す
      issue_data = {
        id: @issue.id,
        text: @issue.subject,
        start_date: @issue.start_date&.strftime('%Y-%m-%d'),
        end_date: @issue.due_date&.strftime('%Y-%m-%d'),
        duration: @issue.due_date && @issue.start_date ? (@issue.due_date - @issue.start_date).to_i + 1 : 1,
        progress: 0,
        parent: @issue.parent_issue_id || 0,
        open: true,  # 新規作成時は展開状態
        editable: true,
        type: 'task',  # タスクタイプを明示
        redmine_data: {
          issue_id: @issue.id,
          subject: @issue.subject,
          tracker_name: @issue.tracker.name,
          status_name: @issue.status.name,
          priority_name: @issue.priority.name,
          assigned_to_name: @issue.assigned_to&.name || '',
          done_ratio: 0,
          start_date: @issue.start_date&.strftime('%Y-%m-%d'),
          due_date: @issue.due_date&.strftime('%Y-%m-%d'),
          end_date: @issue.due_date&.strftime('%Y-%m-%d'),  # end_dateも追加
          parent_id: @issue.parent_issue_id,
          custom_fields: {}  # カスタムフィールドの空オブジェクト
        }
      }
      
      render json: { issue: issue_data }
    else
      render json: { errors: @issue.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/react_gantt_chart/task/:task_id/status
  # 軽量ポーリングAPI - タスクの更新状態を確認
  def task_status
    Rails.logger.info "task_status called with params: #{params.inspect}"
    Rails.logger.info "Project: #{@project.inspect}"
    Rails.logger.info "User: #{User.current.inspect}"
    
    issue = Issue.find_by(id: params[:task_id])
    Rails.logger.info "Issue found: #{issue.inspect}"
    
    unless issue && issue.project_id == @project.id
      Rails.logger.error "Issue not found or project mismatch: issue_project_id=#{issue&.project_id}, current_project_id=#{@project.id}"
      render json: { error: 'チケットが見つかりません' }, status: :not_found
      return
    end
    
    # Railsキャッシュを使用（30秒間キャッシュ）
    cache_key = "gantt_task_status_#{issue.id}_#{issue.updated_on.to_i}"
    
    status_data = Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
      {
        id: issue.id,
        updated_on: issue.updated_on.iso8601,
        status: issue.status.name,
        done_ratio: issue.done_ratio,
        # 最小限のデータのみ返却
        updated: true  # クライアントに更新を知らせるフラグ
      }
    end
    
    render json: status_data
  rescue => e
    Rails.logger.error "[GANTT_ERROR] Task status failed: #{e.message}"
    Rails.logger.error "[GANTT_ERROR] Params: #{params.inspect}"
    Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.join("\n")}"
    render json: { error: 'ステータス取得に失敗しました' }, status: :internal_server_error
  end


  private

  def find_project
    @project = Project.find(params[:project_id])
  end
  
  def authorize_create_subtask
    # チケット作成権限とガントチャート表示権限の両方をチェック
    unless User.current.allowed_to?(:add_issues, @project) && 
           User.current.allowed_to?(:view_react_gantt_chart, @project)
      deny_access
    end
  end
  
  def authorize_task_status
    # ガントチャート表示権限をチェック
    unless User.current.allowed_to?(:view_react_gantt_chart, @project)
      deny_access
    end
  end
  
  # クリーンなクエリビルダー（パラメータ汚染を回避）
  def build_gantt_query(params)
    Rails.logger.info "[GANTT_QUERY] build_gantt_query開始"
    
    begin
      query = IssueQuery.new(name: '_', project: @project)
      Rails.logger.info "[GANTT_QUERY] IssueQuery作成完了"
      
      if gantt_view?(params)
        Rails.logger.info "[GANTT_QUERY] 期間フィルター適用中"
        query = apply_date_range_filter(query, params)
        Rails.logger.info "[GANTT_QUERY] 期間フィルター適用完了"
      end
      
      # 元のparamsをコピーして安全に処理
      Rails.logger.info "[GANTT_QUERY] フィルターパラメータ構築中"
      filter_params = build_filter_params(params)
      
      Rails.logger.info "[GANTT_QUERY] クエリビルド中: #{filter_params.keys}"
      query.build_from_params(filter_params, project: @project)
      Rails.logger.info "[GANTT_QUERY] クエリビルド完了"
      
      query
    rescue => e
      Rails.logger.error "[GANTT_ERROR] build_gantt_query failed: #{e.message}"
      Rails.logger.error "[GANTT_ERROR] Params: #{params.inspect}"
      Rails.logger.error "[GANTT_ERROR] Project: #{@project&.identifier}"
      Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.join("\\n")}"
      raise e  # 例外を再発生させる
    end
  end
  
  def gantt_view?(params)
    params[:gantt_view].present?
  end
  
  def apply_date_range_filter(query, params)
    # パラメータの存在チェックと型変換
    view_start = if params[:view_start].present?
      Date.parse(params[:view_start]) rescue Date.today.beginning_of_month
    else
      Date.today.beginning_of_month
    end
    
    view_end = if params[:view_end].present?
      Date.parse(params[:view_end]) rescue nil
    else
      nil
    end
    
    Rails.logger.info "[GANTT_RANGE] Gantt期間絞込み: #{view_start} 〜 #{view_end || '無制限'}"
    
    begin
      # 表示期間に関わるタスクを取得するフィルタ
      # 終了日が指定されている場合のみ、開始日フィルタを適用
      if view_end
        # 1. 開始日が期間終了日以前
        query.add_filter('start_date', '<=', [view_end.to_s])
        Rails.logger.info "[GANTT_RANGE] フィルタ: start_date <= #{view_end}"
      else
        Rails.logger.info "[GANTT_RANGE] 終了日未指定のため、開始日フィルタは適用しません"
      end
      
      # 2. 以下のいずれかを満たす:
      #    - 期日が期間開始日以降
      #    - 期日が未設定で開始日が期間内
      #    - 開始日も期日も未設定（プロジェクトのデフォルトタスク）
      # 
      # 注: IssueQueryの標準フィルタでは複雑な条件を表現できないため、
      # ここでは最低限のフィルタのみ適用し、詳細な条件は次の処理で行う
      
      Rails.logger.info "[GANTT_RANGE] 期間フィルタ適用完了"
      Rails.logger.info "[GANTT_RANGE] 詳細な期間判定は次の処理で実施"
      
    rescue => e
      Rails.logger.error "[GANTT_ERROR] apply_date_range_filter failed: #{e.message}"
      Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.first(5).join("\n")}"
    end
    
    query
  end
  
  def build_filter_params(original_params)
    Rails.logger.info "[GANTT_FILTER] build_filter_params開始: #{original_params.except(:project_id).inspect}"
    
    begin
      # paramsを安全にコピー（汚染を防止）
      filter_params = original_params.except(:gantt_view, :view_start, :view_end, :zoom_level, :project_id)
      filter_params[:f] ||= []
      filter_params[:op] ||= {}
      filter_params[:v] ||= {}
      
      Rails.logger.info "[GANTT_FILTER] フィルター検証前: #{filter_params.inspect}"
      
      # 無効なフィルタ値を除去
      filter_params = validate_filter_values(filter_params)
      
      Rails.logger.info "[GANTT_FILTER] フィルター検証後: #{filter_params.inspect}"
      
      filter_params
    rescue => e
      Rails.logger.error "[GANTT_ERROR] build_filter_params failed: #{e.message}"
      Rails.logger.error "[GANTT_ERROR] Original params: #{original_params.inspect}"
      Rails.logger.error "[GANTT_ERROR] Backtrace: #{e.backtrace.join("\\n")}"
      raise e  # 例外を再発生させる
    end
  end
  
  def validate_filter_values(filter_params)
    # 本番環境でも確実にログ出力するため、明示的にinfoレベルを指定
    Rails.logger.info "[GANTT_FILTER] === validate_filter_values 開始 (Rails.env: #{Rails.env}, Logger.level: #{Rails.logger.level}) ==="
    Rails.logger.info "[GANTT_FILTER] filter_params[:v].class: #{filter_params[:v].class}"
    Rails.logger.info "[GANTT_FILTER] filter_params[:v]: #{filter_params[:v].inspect}"
    
    return filter_params unless filter_params[:v].is_a?(Hash)
    
    # 各フィルタフィールドの値を検証
    filter_params[:v].each do |field_name, values|
      Rails.logger.info "[GANTT_FILTER] === フィールド検証: #{field_name} ==="
      Rails.logger.info "[GANTT_FILTER] values.class: #{values.class}"
      Rails.logger.info "[GANTT_FILTER] values: #{values.inspect}"
      Rails.logger.info "[GANTT_FILTER] values.is_a?(Array): #{values.is_a?(Array)}"
      
      next unless values.is_a?(Array)
      
      case field_name.to_s
      when 'priority_id'
        Rails.logger.info "[GANTT_FILTER] === priority_id 検証開始 ==="
        
        begin
          # IssuePriority の存在確認
          Rails.logger.info "[GANTT_FILTER] IssuePriority.class: #{IssuePriority.class}"
          priority_count = IssuePriority.count
          Rails.logger.info "[GANTT_FILTER] IssuePriority.count: #{priority_count}"
          
          # pluck の実行
          priority_data = IssuePriority.pluck(:id, :name)
          Rails.logger.info "[GANTT_FILTER] IssuePriority.pluck(:id, :name): #{priority_data.inspect}"
          Rails.logger.info "[GANTT_FILTER] priority_data.class: #{priority_data.class}"
          
          # map の実行
          valid_priority_ids = priority_data.map { |id, name| [id.to_s, name] }.to_h
          Rails.logger.info "[GANTT_FILTER] valid_priority_ids: #{valid_priority_ids.inspect}"
          Rails.logger.info "[GANTT_FILTER] valid_priority_ids.class: #{valid_priority_ids.class}"
          
          # 値の検証
          valid_values = values.select do |value|
            Rails.logger.info "[GANTT_FILTER] 検証中: value=#{value.inspect}, value.class=#{value.class}"
            result = valid_priority_ids.key?(value.to_s) || valid_priority_ids.value?(value.to_s)
            Rails.logger.info "[GANTT_FILTER] 検証結果: #{result}"
            result
          end
          
          Rails.logger.info "[GANTT_FILTER] valid_values: #{valid_values.inspect}"
          
          if valid_values.empty?
            Rails.logger.warn "[GANTT_FILTER] Invalid priority values removed: #{values.inspect}"
            filter_params[:f] = filter_params[:f] - [field_name.to_s]
            filter_params[:op].delete(field_name.to_s)
            filter_params[:v].delete(field_name.to_s)
          else
            filter_params[:v][field_name] = valid_values
            if valid_values.size < values.size
              Rails.logger.warn "[GANTT_FILTER] Some invalid priority values removed: #{(values - valid_values).inspect}"
            end
          end
        rescue => e
          Rails.logger.error "[GANTT_FILTER] === priority_id 検証でエラー ==="
          Rails.logger.error "[GANTT_FILTER] エラークラス: #{e.class}"
          Rails.logger.error "[GANTT_FILTER] エラーメッセージ: #{e.message}"
          Rails.logger.error "[GANTT_FILTER] バックトレース:"
          e.backtrace.first(10).each { |line| Rails.logger.error "[GANTT_FILTER]   #{line}" }
          
          # エラーが発生した場合はフィルタを除去
          filter_params[:f] = filter_params[:f] - [field_name.to_s] if filter_params[:f]
          filter_params[:op].delete(field_name.to_s) if filter_params[:op]
          filter_params[:v].delete(field_name.to_s) if filter_params[:v]
        end
        
      when 'status_id'
        Rails.logger.info "[GANTT_FILTER] === status_id 検証開始 ==="
        
        begin
          valid_status_ids = IssueStatus.pluck(:id, :name).map { |id, name| [id.to_s, name] }.to_h
          Rails.logger.info "[GANTT_FILTER] valid_status_ids: #{valid_status_ids.inspect}"
          
          valid_values = values.select do |value|
            valid_status_ids.key?(value.to_s) || valid_status_ids.value?(value.to_s)
          end
          
          if valid_values.empty?
            Rails.logger.warn "[GANTT_FILTER] Invalid status values removed: #{values.inspect}"
            filter_params[:f] = filter_params[:f] - [field_name.to_s]
            filter_params[:op].delete(field_name.to_s)
            filter_params[:v].delete(field_name.to_s)
          else
            filter_params[:v][field_name] = valid_values
          end
        rescue => e
          Rails.logger.error "[GANTT_FILTER] === status_id 検証でエラー ==="
          Rails.logger.error "[GANTT_FILTER] エラー: #{e.class}: #{e.message}"
          filter_params[:f] = filter_params[:f] - [field_name.to_s] if filter_params[:f]
          filter_params[:op].delete(field_name.to_s) if filter_params[:op]
          filter_params[:v].delete(field_name.to_s) if filter_params[:v]
        end
        
      when 'tracker_id'
        Rails.logger.info "[GANTT_FILTER] === tracker_id 検証開始 ==="
        
        begin
          Rails.logger.info "[GANTT_FILTER] @project.class: #{@project.class}"
          Rails.logger.info "[GANTT_FILTER] @project.trackers.class: #{@project.trackers.class}"
          
          # プロジェクトのトラッカー一覧を安全に取得
          project_trackers = @project.trackers.to_a
          valid_tracker_ids = project_trackers.map { |tracker| tracker.id.to_s }
          valid_tracker_names = project_trackers.map { |tracker| tracker.name }
          
          Rails.logger.info "[GANTT_FILTER] valid_tracker_ids: #{valid_tracker_ids.inspect}"
          Rails.logger.info "[GANTT_FILTER] valid_tracker_names: #{valid_tracker_names.inspect}"
          
          valid_values = values.select do |value|
            value_str = value.to_s.strip
            Rails.logger.info "[GANTT_FILTER] tracker_id値検証: '#{value_str}' (class: #{value.class})"
            
            # ID または名前で一致を確認
            result = valid_tracker_ids.include?(value_str) || valid_tracker_names.include?(value_str)
            Rails.logger.info "[GANTT_FILTER] tracker_id検証結果: #{result}"
            result
          end
          
          if valid_values.empty?
            Rails.logger.warn "[GANTT_FILTER] Invalid tracker values removed: #{values.inspect}"
            filter_params[:f] = filter_params[:f] - [field_name.to_s]
            filter_params[:op].delete(field_name.to_s)
            filter_params[:v].delete(field_name.to_s)
          else
            filter_params[:v][field_name] = valid_values
          end
        rescue => e
          Rails.logger.error "[GANTT_FILTER] === tracker_id 検証でエラー ==="
          Rails.logger.error "[GANTT_FILTER] エラー: #{e.class}: #{e.message}"
          Rails.logger.error "[GANTT_FILTER] バックトレース:"
          e.backtrace.first(5).each { |line| Rails.logger.error "[GANTT_FILTER]   #{line}" }
          filter_params[:f] = filter_params[:f] - [field_name.to_s] if filter_params[:f]
          filter_params[:op].delete(field_name.to_s) if filter_params[:op]
          filter_params[:v].delete(field_name.to_s) if filter_params[:v]
        end
      end
    end
    
    Rails.logger.info "[GANTT_FILTER] === validate_filter_values 完了 ==="
    Rails.logger.info "[GANTT_FILTER] 最終的な filter_params[:v]: #{filter_params[:v].inspect}"
    
    filter_params
  end

  def calculate_optimal_limit(params)
    # 基本制限値（デフォルトを1000から5000に引き上げ）
    base_limit = 5000
    
    # フィルタが適用されている場合は制限を緩和
    if has_active_filters?(params)
      base_limit = 10000  # フィルタで絞り込まれているなら多めに許可
      Rails.logger.info "[GANTT_LIMIT] フィルタ適用中のため制限を緩和: #{base_limit}"
    end
    
    # ガントビューかつ期間フィルタがある場合はさらに動的調整
    if gantt_view?(params) && params[:view_start].present? && params[:view_end].present?
      begin
        start_date = Date.parse(params[:view_start])
        end_date = Date.parse(params[:view_end])
        days = (end_date - start_date).to_i
        
        # 1日あたり10件を目安に、最大20000件まで
        dynamic_limit = [days * 10, 20000].min
        base_limit = [base_limit, dynamic_limit].max
        
        Rails.logger.info "[GANTT_LIMIT] 期間（#{days}日）に基づく動的制限: #{base_limit}"
      rescue
        Rails.logger.warn "[GANTT_LIMIT] 日付パースエラー、デフォルト制限を使用"
      end
    end
    
    Rails.logger.info "[GANTT_LIMIT] 最終的な制限値: #{base_limit}"
    base_limit
  end
  
  def has_active_filters?(params)
    # set_filterが1で、かつ実際にフィルタフィールドが存在する場合
    return false unless params[:set_filter] == '1' || params[:set_filter] == 1
    return false unless params[:f].is_a?(Array) && params[:f].any?
    
    # 有効なフィルタが存在するかチェック
    params[:f].any? do |field|
      values = params[:v] && params[:v][field]
      values.is_a?(Array) && values.any?(&:present?)
    end
  end
  
  def apply_default_date_filter(query)
    # デフォルトで過去3ヶ月〜未来3ヶ月の期間フィルタを適用
    default_start = Date.today - 3.months
    default_end = Date.today + 3.months
    
    Rails.logger.info "[GANTT_FILTER] デフォルト期間フィルタ適用: #{default_start} 〜 #{default_end}"
    
    # start_dateとdue_dateのフィルタを追加
    query.add_filter('start_date', '<=', [default_end.to_s])
    query.add_filter('due_date', '>=', [default_start.to_s])
  end
  
  def format_filters(available_filters)
    formatted = {}
    available_filters.each do |field, options|
      formatted[field] = {
        name: options[:name],
        type: options[:type],
        values: options[:values] || []
      }
    end
    formatted
  end
end
