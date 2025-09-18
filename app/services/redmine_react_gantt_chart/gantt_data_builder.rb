# app/services/redmine_react_gantt_chart/gantt_data_builder.rb

module RedmineReactGanttChart
  class GanttDataBuilder
    attr_reader :project, :issues, :params, :user

    def initialize(project:, issues:, params:, user: nil)
      @project = project
      @issues  = issues
      @params  = params
      @user    = user || User.current
    end

    def build
      # 配列とActiveRecord::Relationの両方に対応
      returned_ids = if issues.respond_to?(:pluck)
        issues.pluck(:id)
      else
        issues.map(&:id)
      end

      # バージョン情報 => サマリタスク
      versions = extract_versions(issues)
      versions_array = versions.to_a
      self.class.sort_versions!(versions_array)
      version_summaries = build_version_summaries(versions_array)

      # 各Issue => タスク化
      sorted_issues = issues.to_a
      self.class.sort_issues!(sorted_issues)
      task_list = sorted_issues.map { |issue| build_issue_task(issue, returned_ids) }

      # 親子構造をバージョンサマリにアタッチ
      attach_issues_to_versions(task_list, version_summaries)

      # リンク
      links = build_links(returned_ids)

      # CSSクラス別にチケットをグループ化する
      # !変更箇所
      additional_issues = build_additional_issues(task_list)

      {
        tasks: version_summaries + task_list,
        links: links,
        # !変更箇所
        additional_issues: additional_issues
      }
    end

    # !変更箇所
    # CSSクラス別にチケットをグループ化するプライベートメソッドです
    private def build_additional_issues(task_list)
      result = {}

      task_list.each do |task|
        css_class = task[:css].presence || "default"
        result[css_class] ||= {}
        result[css_class][task[:id].to_s] = {}
      end

      result
    end

    # チケットをソートするクラスメソッドです
    def self.sort_issues!(issues)
      issues.sort_by! { |issue| sort_issue_logic(issue) }
    end

    # チケットのソートロジックです
    def self.sort_issue_logic(issue)
      julian_date = Date.new
      ancesters_start_date = []
      current_issue = issue
      begin
        ancesters_start_date.unshift([current_issue.start_date || julian_date, current_issue.id])
        current_issue = current_issue.parent
      end while (current_issue)
      ancesters_start_date
    end

    # バージョンをソートするクラスメソッド
    def self.sort_versions!(versions)
      # ActiveRecord::Relationではなく配列に対してのみsort!が使えます
      # buildメソッド内でto_aを使って配列化したものを引数として渡す
      versions.sort!
    end

    private

    # ------------------------------
    # バージョン関連
    # ------------------------------
    def extract_versions(issues_relation)
      # issues_relationがActiveRecord::Relationであることを確認
      Rails.logger.debug "extract_versions called with: #{issues_relation.class.name}"
      
      # 配列とActiveRecord::Relationの両方に対応
      version_ids = if issues_relation.respond_to?(:pluck)
        issues_relation.pluck(:fixed_version_id).compact.uniq
      else
        # 配列の場合
        issues_relation.map(&:fixed_version_id).compact.uniq
      end
      
      Rails.logger.debug "Version IDs: #{version_ids.inspect}"
      
      versions = Version.where(id: version_ids).order(:effective_date)
      Rails.logger.debug "Found versions: #{versions.count}"
      
      versions
    end

    def build_version_summaries(versions)
      versions.map do |v|
        {
          id: "version-#{v.id}",
          text: "バージョン: #{v.name}",
          parent: 0,
          start: v.effective_date,
          end:   v.effective_date,
          type:  "summary",
          open:  true,
          duration: 1,
          progress: 0,
          assigned_to_name: "",
          status_name: "",
          # デフォルトCSSは空
          css: ""
        }
      end
    end

    # ------------------------------
    # Issue => タスク
    # ------------------------------
    def build_issue_task(issue, returned_ids)
      start_val = valid_date?(issue.start_date) ? issue.start_date : nil
      end_val   = valid_date?(issue.due_date)   ? issue.due_date   : nil

      # 期日がnullの場合、開始日と同じ日付を設定（DHTMLX Ganttの要件）
      if start_val && end_val.nil?
        end_val = start_val
        Rails.logger.info "Issue #{issue.id}: 期日がnullのため、開始日と同じ日付を設定: #{end_val}"
      end

      # デバッグログ：元の日付を記録
      Rails.logger.info "Issue #{issue.id} (#{issue.subject}): start_date=#{issue.start_date}, due_date=#{issue.due_date}, gantt_end=#{end_val}"

      has_children = issues.any? { |c| c.parent_id == issue.id }
      task_type = has_children ? "summary" : "task"

      assigned_str = issue.assigned_to ? issue.assigned_to.name : ""
      status_str   = issue.status ? issue.status.name : ""

      css_class = decide_css(issue, end_val)

      task_data = {
        id: issue.id,
        text: issue.subject,
        parent: (issue.parent_id && returned_ids.include?(issue.parent_id)) ? issue.parent_id : 0,
        type: task_type,
        open: has_children,
        start: start_val,
        end:   end_val,
        duration: calc_duration(start_val, end_val),
        progress: issue.done_ratio || 0,
        assigned_to_name: assigned_str,
        status_name: status_str,
        # description: issue.description,
        details: issue.description,
        css: css_class,
        tracker_id: issue.tracker_id,
        tracker_name: issue.tracker ? issue.tracker.name : "",
        priority_id: issue.priority_id,
        priority_name: issue.priority ? issue.priority.name : "",
        category_id: issue.category_id,
        category_name: issue.category ? issue.category.name : "",
        fixed_version_id: issue.fixed_version_id,
        fixed_version_name: issue.fixed_version ? issue.fixed_version.name : "",
        author_id: issue.author_id,
        author_name: issue.author.name,
        assigned_to_id: issue.assigned_to_id,
        assigned_name: assigned_str,
        # !変更箇所
        estimated_hours: issue.estimated_hours,
        done_ratio: issue.done_ratio,
        created_on: issue.created_on,
        updated_on: issue.updated_on,
        closed_on: issue.closed_on,
        is_private: issue.is_private,
        # 新規チケット作成権限の追加
        can_create_issue: can_create_issue_for_project?,
        # Issue #737修正テスト: auto_schedulingを一時的に無効化して強制復元のみでテスト
        # auto_scheduling: false
        # 元の期日情報を保持（期日なしタスクの識別用）
        due_date: issue.due_date,
        has_due_date: !issue.due_date.nil?
      }

      # redmine_dataプロパティを追加（フロントエンドのカラムテンプレートで使用）
      task_data[:redmine_data] = {
        tracker_id: issue.tracker_id,
        tracker_name: issue.tracker ? issue.tracker.name : "",
        status_id: issue.status_id,
        status_name: status_str,
        assigned_to_id: issue.assigned_to_id,
        assigned_to_name: assigned_str,
        priority_id: issue.priority_id,
        priority_name: issue.priority ? issue.priority.name : "",
        category_id: issue.category_id,
        category_name: issue.category ? issue.category.name : ""
      }

      # カスタムフィールドを動的に追加します
      custom_fields = {}
      issue.custom_field_values.each do |custom_value|
        next unless custom_value.custom_field

        # カスタムフィールドの基本情報を取得します
        field = custom_value.custom_field
        field_id = "cf_#{field.id}"
        field_format = field.field_format
        raw_value = custom_value.value

        # ログにカスタムフィールドの情報を詳細に出力します
        Rails.logger.debug "CustomField Processing: #{field.name} (#{field_format}) - Raw Value: #{raw_value.inspect}"

        # 値の表示名を設定します
        value_name = case field_format
        when 'user'
          if raw_value.present?
            # ユーザーIDから名前を取得します
            user_id = raw_value.to_i
            if user_id > 0
              user = User.find_by(id: user_id)
              user ? user.name : "User ID: #{raw_value}"
            else
              ""
            end
          else
            ""
          end
        when 'list'
          if raw_value.present?
            # リスト値をそのまま使用します
            raw_value.to_s
          else
            ""
          end
        when 'bool'
          raw_value.present? && raw_value != "0" ? "はい" : "いいえ"
        when 'date'
          raw_value.present? ? raw_value.to_s : ""
        else
          # その他の形式はそのまま文字列として扱います
          raw_value.to_s
        end

        # カスタムフィールドの詳細情報を格納します
        custom_fields[field_id] = {
          id: field.id,
          name: field.name,
          field_format: field_format,
          raw_value: raw_value,
          value: value_name,
          description: field.description,
          is_required: field.is_required,
          is_filter: field.is_filter,
          searchable: field.searchable,
          multiple: field.multiple
        }
      end

      # カスタムフィールド情報をredmine_dataに追加します
      task_data[:redmine_data][:custom_fields] = custom_fields
      
      # 下位互換性のためにルートレベルにも保持
      task_data[:custom_fields] = custom_fields

      # デバッグログ：最終的なタスクデータ
      Rails.logger.info "Task data for Issue #{issue.id}: start=#{task_data[:start]}, end=#{task_data[:end]}, duration=#{task_data[:duration]}"

      task_data
    end

    # ステータス・期日からCSSクラスを判定
    def decide_css(issue, end_val)
      # 1) ステータスがクローズか？
      if issue.status&.is_closed
        return "closed-task"
      end

      # 2) 期日が過ぎているか？(end_val < 今日)
      if end_val && (end_val < Date.today)
        return "overdue-task"
      end

      # どちらでもなければ空
      ""
    end

    def calc_duration(s_val, e_val)
      return 1 unless s_val && e_val
      diff = (e_val - s_val).to_i
      diff < 1 ? 1 : diff
    end

    # ------------------------------
    # バージョンサマリのアタッチ
    # ------------------------------
    def attach_issues_to_versions(tasks, version_summaries)
      tasks_by_id = tasks.index_by { |t| t[:id] }

      # version-summaries は id: "version-#{id}" で管理
      Issue.where(id: tasks_by_id.keys).each do |issue|
        t = tasks_by_id[issue.id]
        next unless t

        if issue.fixed_version_id.present?
          sum_id = "version-#{issue.fixed_version_id}"

          if t[:parent].to_i == 0
            t[:parent] = sum_id
          else
            top = find_top_ancestor(t, tasks_by_id)
            if top && top[:parent].to_i == 0
              top[:parent] = sum_id
            end
          end
        end
      end
    end

    def find_top_ancestor(task, tasks_by_id)
      current = task
      while current && current[:parent].is_a?(Integer) && current[:parent] != 0
        current = tasks_by_id[current[:parent]]
      end
      current
    end

    # ------------------------------
    # リンク
    # ------------------------------
    def build_links(returned_ids)
      rels = IssueRelation.where(issue_from_id: returned_ids, issue_to_id: returned_ids)
      rels.map do |rel|
        {
          id: rel.id,
          source: rel.issue_from_id,
          target: rel.issue_to_id,
          type: "e2e"
        }
      end
    end

    def valid_date?(val)
      val.is_a?(Date) || val.is_a?(Time)
    end

    # 新規チケット作成権限のチェック
    def can_create_issue_for_project?
      return false unless user && project
      
      # add_issues権限の確認
      user.allowed_to?(:add_issues, project)
    end
  end
end
