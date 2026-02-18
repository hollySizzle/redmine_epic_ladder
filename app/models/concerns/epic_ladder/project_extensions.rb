# frozen_string_literal: true

module EpicLadder
  module ProjectExtensions
    extend ActiveSupport::Concern

    # ========================================
    # グリッドデータ構築（MSW準拠）
    # ========================================

    # Epic Ladderのデータを正規化APIレスポンス形式で取得
    # @param include_closed [Boolean] closedステータスを含めるか
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか（デフォルト: true）
    # @param filters [Hash] Ransackフィルタパラメータ (例: { status_id_in: [1,2], fixed_version_id_eq: 3, fixed_version_effective_date_gteq: '2025-01-01' })
    # @param sort_options [Hash] ソートオプション (例: { epic: { sort_by: :subject, sort_direction: :asc }, version: { sort_by: :date, sort_direction: :desc } })
    # @return [Hash] MSW NormalizedAPIResponse準拠のHash
    def epic_ladder_data(include_closed: true, exclude_closed_versions: true, filters: {}, sort_options: {})
      # Versionフィルタを分離（Versionエンティティに直接適用）
      version_filters = filters.slice(:fixed_version_effective_date_gteq, :fixed_version_effective_date_lteq)
      issue_filters = filters.except(:fixed_version_effective_date_gteq, :fixed_version_effective_date_lteq)

      {
        entities: epic_ladder_entities(
          include_closed: include_closed,
          exclude_closed_versions: exclude_closed_versions,
          filters: issue_filters,
          version_filters: version_filters
        ),
        grid: epic_ladder_index(
          exclude_closed_versions: exclude_closed_versions,
          filters: issue_filters,
          version_filters: version_filters,
          sort_options: sort_options
        ),
        metadata: epic_ladder_metadata
      }
    end

    # ========================================
    # 統計計算
    # ========================================

    # プロジェクト全体の統計情報を構築
    # @return [Hash] 統計情報
    def epic_ladder_build_statistics
      project_issues = issues.includes(:tracker, :status, :assigned_to)

      {
        by_tracker: epic_ladder_statistics_by_tracker(project_issues),
        by_status: epic_ladder_statistics_by_status(project_issues),
        by_assignee: epic_ladder_statistics_by_assignee(project_issues)
      }
    end

    # トラッカー別統計
    # @param issues [ActiveRecord::Relation] 集計対象のIssue群
    # @return [Hash] トラッカー別カウント
    def epic_ladder_statistics_by_tracker(project_issues)
      project_issues.group(:tracker_id).count.transform_keys { |id| Tracker.find(id).name }
    end

    # ステータス別統計
    # @param issues [ActiveRecord::Relation] 集計対象のIssue群
    # @return [Hash] ステータス別カウント
    def epic_ladder_statistics_by_status(project_issues)
      project_issues.group(:status_id).count.transform_keys { |id| IssueStatus.find(id).name }
    end

    # 担当者別統計
    # @param issues [ActiveRecord::Relation] 集計対象のIssue群
    # @return [Hash] 担当者別カウント
    def epic_ladder_statistics_by_assignee(project_issues)
      project_issues.group(:assigned_to_id).count.transform_keys { |id| id ? User.find(id).name : '未割当' }
    end

    # ========================================
    # バージョン取得（ビュー用）
    # ========================================

    # Openバージョンを期日昇順で取得（クイックアクション用）
    # フロントエンドのデフォルトソート（date/asc）と一致
    # NULLは先頭に来る（build_version_sort_clauseと同じ動作）
    # @return [ActiveRecord::Relation] 期日昇順でソートされたOpenバージョン
    def open_versions_by_date
      versions.open.order(Arel.sql('CASE WHEN effective_date IS NULL THEN 0 ELSE 1 END, effective_date ASC'))
    end

    # ========================================
    # グリッドインデックス構築（public - Controller から呼び出される）
    # ========================================

    # グリッドインデックスを構築 (3次元: Epic × Feature × Version)
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか
    # @param filters [Hash] Issueに対するRansackフィルタパラメータ
    # @param version_filters [Hash] Versionに対するフィルタパラメータ
    # @param sort_options [Hash] ソートオプション
    def epic_ladder_index(exclude_closed_versions: true, filters: {}, version_filters: {}, sort_options: {})
      epic_tracker = EpicLadder::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicLadder::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker = EpicLadder::TrackerHierarchy.tracker_names[:user_story]

      # 担当者フィルタを分離（階層的フィルタリングのため）
      assignee_ids = filters[:assigned_to_id_in]&.map(&:to_i)
      filters_without_assignee = filters.except(:assigned_to_id_in)

      # ベーススコープ（Versionフィルタなし）- Epic/Feature用
      base_scope_without_version = apply_ransack_filters(issues, filters_without_assignee)

      # Versionフィルタ適用スコープ（UserStory用）
      base_scope_with_version = base_scope_without_version
      if version_filters.present? && version_filters.any?
        filtered_version_ids = get_filtered_version_ids(exclude_closed_versions: exclude_closed_versions, version_filters: version_filters)
        # フィルタされたVersionに紐づくIssueのみに絞り込む
        base_scope_with_version = base_scope_with_version.where(fixed_version_id: filtered_version_ids)
      end

      # Epic/Featureは全て表示（Versionフィルタ適用しない）
      epics = apply_hierarchical_filter(base_scope_without_version, epic_tracker, assignee_ids)
      features = apply_hierarchical_filter(base_scope_without_version, feature_tracker, assignee_ids)
      # UserStoryはVersionフィルタ適用
      user_stories = apply_hierarchical_filter(base_scope_with_version, user_story_tracker, assignee_ids)

      grid_index = {}
      epic_ids = []
      feature_order_by_epic = {}

      # Versionフィルタとソート句を構築
      version_sort_clause = build_version_sort_clause(sort_options[:version] || {})
      version_scope = versions
      version_scope = version_scope.where.not(status: 'closed') if exclude_closed_versions

      # Version期日フィルタを適用
      if version_filters[:fixed_version_effective_date_gteq].present?
        version_scope = version_scope.where('effective_date >= ?', version_filters[:fixed_version_effective_date_gteq])
      end
      if version_filters[:fixed_version_effective_date_lteq].present?
        version_scope = version_scope.where('effective_date <= ?', version_filters[:fixed_version_effective_date_lteq])
      end

      version_ids = version_scope
                      .order(Arel.sql(version_sort_clause))
                      .pluck(:id)
                      .map(&:to_s)

      # Epicソート設定を取得
      epic_sort_by = (sort_options[:epic] || {})[:sort_by] || :subject
      epic_sort_direction = (sort_options[:epic] || {})[:sort_direction] || :asc

      # Epicの取得とソート
      if epic_sort_by.to_sym == :subject
        # :subject の場合はRuby側で自然順ソート（DB非依存）
        epics_array = sort_by_natural_order(epics.order(:id).to_a, epic_sort_direction)
      else
        # :id や :date の場合はSQL側でソート（従来通り）
        epic_sort_clause = build_epic_sort_clause(sort_options[:epic] || {})
        epics_array = epics.order(Arel.sql(epic_sort_clause)).to_a
      end

      # Epic単位でループ
      epics_array.each do |epic|
        epic_ids << epic.id.to_s

        # Featureも同様に処理（Epicと同じソート設定）
        features_for_epic = features.where(parent_id: epic.id)

        if epic_sort_by.to_sym == :subject
          # :subject の場合はRuby側で自然順ソート
          epic_features = sort_by_natural_order(features_for_epic.to_a, epic_sort_direction)
        else
          # :id や :date の場合はSQL側でソート
          epic_sort_clause = build_epic_sort_clause(sort_options[:epic] || {})
          epic_features = features_for_epic.order(Arel.sql(epic_sort_clause)).to_a
        end

        # Epic配下の全Feature IDsを記録
        feature_order_by_epic[epic.id.to_s] = epic_features.map { |f| f.id.to_s }

        # 各Featureについて、UserStory個別のVersionでグループ化
        epic_features.each do |feature|
          feature_user_stories = user_stories.where(parent_id: feature.id)

          # UserStory個別のVersionでグループ化（Featureのバージョンは無視）
          feature_user_stories.group_by { |us| us.fixed_version_id&.to_s || 'none' }.each do |version_id, stories|
            # 3次元キー: {epicId}:{featureId}:{versionId}
            cell_key = "#{epic.id}:#{feature.id}:#{version_id}"
            grid_index[cell_key] = stories.sort_by(&:created_on).map { |us| us.id.to_s }
          end
        end
      end

      {
        index: grid_index,
        epic_order: epic_ids,
        feature_order_by_epic: feature_order_by_epic,
        version_order: version_ids + ['none']
      }
    end

    # ========================================
    # プライベートメソッド
    # ========================================

    private

    # Ransackフィルタを適用
    # @param scope [ActiveRecord::Relation] フィルタ対象のスコープ
    # @param filters [Hash] Ransackフィルタパラメータ
    # @return [ActiveRecord::Relation] フィルタ適用後のスコープ
    def apply_ransack_filters(scope, filters)
      return scope if filters.blank?

      # parent_id_in を特別扱い（階層検索のため、Ransackに渡さない）
      filters_copy = filters.dup
      parent_ids = filters_copy.delete(:parent_id_in)

      # AssociationRelationをRelationに変換してからRansackを適用
      # issues アソシエーションは AssociationRelation なので、.all で Relation に変換
      relation = scope.is_a?(ActiveRecord::AssociationRelation) ? scope.all : scope

      # 通常のRansackフィルタを適用
      relation = relation.ransack(filters_copy).result if filters_copy.present?

      # parent_id_in がある場合は階層検索を適用
      # 指定されたIssueの祖先 + Issue自身 + その子孫全て
      # Redmineのネストセット（lft/rgt）を利用
      if parent_ids.present? && parent_ids.any?
        # 文字列IDを整数に変換
        parent_ids = parent_ids.map(&:to_i)

        relation = relation.where(
          "issues.id IN (:ids) OR EXISTS (
            SELECT 1 FROM issues parents
            WHERE parents.id IN (:ids)
              AND issues.lft > parents.lft
              AND issues.rgt < parents.rgt
              AND issues.root_id = parents.root_id
          ) OR EXISTS (
            SELECT 1 FROM issues descendants
            WHERE descendants.id IN (:ids)
              AND issues.lft < descendants.lft
              AND issues.rgt > descendants.rgt
              AND issues.root_id = descendants.root_id
          )",
          ids: parent_ids
        )
      end

      relation
    end

    # エンティティハッシュを構築
    # @param include_closed [Boolean] closedステータスを含めるか
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか
    # @param filters [Hash] Issueに対するRansackフィルタパラメータ
    # @param version_filters [Hash] Versionに対するフィルタパラメータ
    def epic_ladder_entities(include_closed: true, exclude_closed_versions: true, filters: {}, version_filters: {})
      epic_tracker = EpicLadder::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicLadder::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker = EpicLadder::TrackerHierarchy.tracker_names[:user_story]
      task_tracker = EpicLadder::TrackerHierarchy.tracker_names[:task]
      test_tracker = EpicLadder::TrackerHierarchy.tracker_names[:test]
      bug_tracker = EpicLadder::TrackerHierarchy.tracker_names[:bug]

      # 担当者フィルタを分離（階層的フィルタリングのため）
      assignee_ids = filters[:assigned_to_id_in]&.map(&:to_i)
      filters_without_assignee = filters.except(:assigned_to_id_in)

      # ベーススコープ（Versionフィルタなし）- Epic/Feature用
      base_scope_without_version = issues.includes(:tracker, :status, :fixed_version)
      base_scope_without_version = base_scope_without_version.joins(:status).where.not(issue_statuses: { is_closed: true }) unless include_closed
      base_scope_without_version = apply_ransack_filters(base_scope_without_version, filters_without_assignee)

      # Versionフィルタ適用スコープ（UserStory以下用）
      scope_with_version = base_scope_without_version
      if version_filters.present? && version_filters.any?
        filtered_version_ids = get_filtered_version_ids(exclude_closed_versions: exclude_closed_versions, version_filters: version_filters)
        # フィルタされたVersionに紐づくIssueのみに絞り込む
        scope_with_version = scope_with_version.where(fixed_version_id: filtered_version_ids)
      end

      {
        # Epic/Featureは全て表示（Versionフィルタ適用しない）
        epics: build_entity_hash_hierarchical(base_scope_without_version, epic_tracker, assignee_ids),
        features: build_entity_hash_hierarchical(base_scope_without_version, feature_tracker, assignee_ids),
        # UserStory以下はVersionフィルタ適用
        user_stories: build_entity_hash_hierarchical(scope_with_version, user_story_tracker, assignee_ids),
        tasks: build_entity_hash_direct(scope_with_version, task_tracker, assignee_ids),
        tests: build_entity_hash_direct(scope_with_version, test_tracker, assignee_ids),
        bugs: build_entity_hash_direct(scope_with_version, bug_tracker, assignee_ids),
        versions: build_versions_hash(exclude_closed_versions: exclude_closed_versions, version_filters: version_filters),
        users: build_users_hash
      }
    end

    # トラッカー別のエンティティハッシュを構築（従来の挙動、後方互換性のため残す）
    def build_entity_hash(scope, tracker_name)
      scope.joins(:tracker)
           .where(trackers: { name: tracker_name })
           .index_by { |issue| issue.id.to_s }
           .transform_values(&:epic_ladder_as_normalized_json)
    end

    # 階層的フィルタリング（Epic/Feature用）
    # 自分または子孫に該当担当者がいるIssueを取得
    # @param scope [ActiveRecord::Relation] ベーススコープ
    # @param tracker_name [String] トラッカー名
    # @param assignee_ids [Array<Integer>] 担当者IDの配列
    # @return [Hash] Issue IDをキーとするハッシュ
    def build_entity_hash_hierarchical(scope, tracker_name, assignee_ids)
      base_scope = apply_hierarchical_filter(scope, tracker_name, assignee_ids)
      base_scope.index_by { |issue| issue.id.to_s }
               .transform_values(&:epic_ladder_as_normalized_json)
    end

    # 直接フィルタリング（UserStory以下用）
    # 自分の担当者のみでフィルタ（従来通り）
    # @param scope [ActiveRecord::Relation] ベーススコープ
    # @param tracker_name [String] トラッカー名
    # @param assignee_ids [Array<Integer>] 担当者IDの配列
    # @return [Hash] Issue IDをキーとするハッシュ
    def build_entity_hash_direct(scope, tracker_name, assignee_ids)
      base_scope = apply_direct_filter(scope, tracker_name, assignee_ids)
      base_scope.index_by { |issue| issue.id.to_s }
               .transform_values(&:epic_ladder_as_normalized_json)
    end

    # 階層的フィルタをActiveRecord::Relationとして返す（epic_ladder_index用）
    # @param scope [ActiveRecord::Relation] ベーススコープ
    # @param tracker_name [String] トラッカー名
    # @param assignee_ids [Array<Integer>] 担当者IDの配列
    # @return [ActiveRecord::Relation] フィルタ適用後のRelation
    def apply_hierarchical_filter(scope, tracker_name, assignee_ids)
      base_scope = scope.joins(:tracker).where(trackers: { name: tracker_name })

      if assignee_ids.present? && assignee_ids.any?
        base_scope = base_scope.where(
          "issues.assigned_to_id IN (:assignee_ids) OR EXISTS (
            SELECT 1 FROM issues descendants
            WHERE descendants.lft > issues.lft
              AND descendants.rgt < issues.rgt
              AND descendants.root_id = issues.root_id
              AND descendants.assigned_to_id IN (:assignee_ids)
          )",
          assignee_ids: assignee_ids
        )
      end

      base_scope
    end

    # 直接フィルタをActiveRecord::Relationとして返す（epic_ladder_index用）
    # @param scope [ActiveRecord::Relation] ベーススコープ
    # @param tracker_name [String] トラッカー名
    # @param assignee_ids [Array<Integer>] 担当者IDの配列
    # @return [ActiveRecord::Relation] フィルタ適用後のRelation
    def apply_direct_filter(scope, tracker_name, assignee_ids)
      base_scope = scope.joins(:tracker).where(trackers: { name: tracker_name })

      if assignee_ids.present? && assignee_ids.any?
        base_scope = base_scope.where(assigned_to_id: assignee_ids)
      end

      base_scope
    end

    # フィルタされたVersionのIDリストを取得
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか
    # @param version_filters [Hash] Versionに対するフィルタパラメータ
    # @return [Array<Integer>] フィルタされたVersionのIDリスト
    def get_filtered_version_ids(exclude_closed_versions: true, version_filters: {})
      version_scope = versions
      version_scope = version_scope.where.not(status: 'closed') if exclude_closed_versions

      # Version期日フィルタを適用
      if version_filters[:fixed_version_effective_date_gteq].present?
        version_scope = version_scope.where('effective_date >= ?', version_filters[:fixed_version_effective_date_gteq])
      end
      if version_filters[:fixed_version_effective_date_lteq].present?
        version_scope = version_scope.where('effective_date <= ?', version_filters[:fixed_version_effective_date_lteq])
      end

      version_scope.pluck(:id)
    end

    # バージョンのエンティティハッシュを構築
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか
    # @param version_filters [Hash] Versionに対するフィルタパラメータ
    def build_versions_hash(exclude_closed_versions: true, version_filters: {})
      version_scope = versions
      version_scope = version_scope.where.not(status: 'closed') if exclude_closed_versions

      # Version期日フィルタを適用
      if version_filters[:fixed_version_effective_date_gteq].present?
        version_scope = version_scope.where('effective_date >= ?', version_filters[:fixed_version_effective_date_gteq])
      end
      if version_filters[:fixed_version_effective_date_lteq].present?
        version_scope = version_scope.where('effective_date <= ?', version_filters[:fixed_version_effective_date_lteq])
      end

      version_scope.index_by { |v| v.id.to_s }.transform_values do |version|
        {
          id: version.id.to_s,
          name: version.name,
          description: version.description,
          status: version.status,
          effective_date: version.effective_date&.iso8601,
          created_on: version.created_on.iso8601,
          updated_on: version.updated_on.iso8601
        }
      end
    end

    # ユーザーのエンティティハッシュを構築
    def build_users_hash
      # プロジェクトメンバーのユーザーを取得
      member_users = members.includes(:user).map(&:user).compact.uniq

      member_users.index_by(&:id).transform_values do |user|
        {
          id: user.id,
          login: user.login,
          firstname: user.firstname,
          lastname: user.lastname,
          mail: user.mail,
          admin: user.admin?
        }
      end
    end

    # メタデータを構築
    def epic_ladder_metadata
      {
        project: {
          id: id,
          name: name,
          identifier: identifier,
          description: description,
          created_on: created_on.iso8601
        },
        # フィルタ用マスターデータ（環境依存）
        available_statuses: build_available_statuses,
        available_trackers: build_available_trackers,
        api_version: 'v2',
        timestamp: Time.current.iso8601,
        request_id: "req_#{SecureRandom.hex(8)}"
      }
    end

    # フィルタ用：利用可能なステータス一覧
    def build_available_statuses
      IssueStatus.all.order(:position).map do |status|
        {
          id: status.id,
          name: status.name,
          is_closed: status.is_closed
        }
      end
    end

    # フィルタ用：利用可能なトラッカー一覧
    def build_available_trackers
      trackers.order(:position).map do |tracker|
        {
          id: tracker.id,
          name: tracker.name,
          description: tracker.description
        }
      end
    end

    # Epic/Featureソート句を構築
    # @param sort_option [Hash] { sort_by: :subject/:id/:date, sort_direction: :asc/:desc }
    # @return [String] SQL ORDER BY句
    def build_epic_sort_clause(sort_option)
      sort_by = sort_option[:sort_by] || :subject
      sort_direction = sort_option[:sort_direction] || :asc
      direction = sort_direction.to_s.upcase

      case sort_by.to_sym
      when :date
        # start_date でソート、nullは先頭
        "CASE WHEN start_date IS NULL THEN 0 ELSE 1 END, start_date #{direction}, id ASC"
      when :id
        "id #{direction}"
      when :subject
        "subject #{direction}, id ASC"
      else
        # デフォルトはsubject昇順
        "subject ASC, id ASC"
      end
    end

    # Versionソート句を構築
    # @param sort_option [Hash] { sort_by: :subject/:id/:date, sort_direction: :asc/:desc }
    # @return [String] SQL ORDER BY句
    def build_version_sort_clause(sort_option)
      sort_by = sort_option[:sort_by] || :date
      sort_direction = sort_option[:sort_direction] || :asc
      direction = sort_direction.to_s.upcase

      case sort_by.to_sym
      when :date
        # effective_date でソート、nullは先頭
        "CASE WHEN effective_date IS NULL THEN 0 ELSE 1 END, effective_date #{direction}, id ASC"
      when :id
        "id #{direction}"
      when :subject  # Versionの場合はname
        "name #{direction}, id ASC"
      else
        # デフォルトは日付昇順
        "CASE WHEN effective_date IS NULL THEN 0 ELSE 1 END, effective_date ASC, id ASC"
      end
    end

    # 自然順ソート（Natural Sort）
    # 文字列中の数値部分を数値として認識してソート
    # 例: "2_認証" → "10_サーバ" → "100_ユーザ" → "1000_出力"
    # @param records [Array<Issue>] ソート対象のIssue配列
    # @param direction [Symbol] :asc または :desc
    # @return [Array<Issue>] ソート済みの配列
    def sort_by_natural_order(records, direction)
      sorted = records.sort_by { |record| natural_sort_key(record.subject) }
      direction.to_sym == :desc ? sorted.reverse : sorted
    end

    # 自然順ソートキー生成
    # 文字列を数値部分と非数値部分に分解し、数値は整数として扱う
    # 例: "10_サーバ構築" → [[0, 10], [1, "_サーバ構築"]]
    #     "100_ユーザ管理" → [[0, 100], [1, "_ユーザ管理"]]
    # @param str [String] ソート対象の文字列
    # @return [Array] ソートキー配列（[型フラグ, 値]の配列）
    #   型フラグ: 0=数値, 1=文字列 (比較時に型が揃うように)
    def natural_sort_key(str)
      str.to_s.scan(/(\d+|\D+)/).map do |part|
        if part[0] =~ /\d/
          [0, part[0].to_i]  # 数値は [0, 整数値]
        else
          [1, part[0]]       # 文字列は [1, 文字列]
        end
      end
    end
  end
end
