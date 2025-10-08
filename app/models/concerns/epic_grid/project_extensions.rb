# frozen_string_literal: true

module EpicGrid
  module ProjectExtensions
    extend ActiveSupport::Concern

    # ========================================
    # グリッドデータ構築（MSW準拠）
    # ========================================

    # Epic Gridのデータを正規化APIレスポンス形式で取得
    # @param include_closed [Boolean] closedステータスを含めるか
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか（デフォルト: true）
    # @param filters [Hash] Ransackフィルタパラメータ (例: { status_id_in: [1,2], fixed_version_id_eq: 3 })
    # @return [Hash] MSW NormalizedAPIResponse準拠のHash
    def epic_grid_data(include_closed: true, exclude_closed_versions: true, filters: {})
      {
        entities: epic_grid_entities(include_closed: include_closed, exclude_closed_versions: exclude_closed_versions, filters: filters),
        grid: epic_grid_index(exclude_closed_versions: exclude_closed_versions, filters: filters),
        metadata: epic_grid_metadata
      }
    end

    # ========================================
    # 統計計算
    # ========================================

    # プロジェクト全体の統計情報を構築
    # @return [Hash] 統計情報
    def epic_grid_build_statistics
      project_issues = issues.includes(:tracker, :status, :assigned_to)

      {
        by_tracker: epic_grid_statistics_by_tracker(project_issues),
        by_status: epic_grid_statistics_by_status(project_issues),
        by_assignee: epic_grid_statistics_by_assignee(project_issues)
      }
    end

    # トラッカー別統計
    # @param issues [ActiveRecord::Relation] 集計対象のIssue群
    # @return [Hash] トラッカー別カウント
    def epic_grid_statistics_by_tracker(project_issues)
      project_issues.group(:tracker_id).count.transform_keys { |id| Tracker.find(id).name }
    end

    # ステータス別統計
    # @param issues [ActiveRecord::Relation] 集計対象のIssue群
    # @return [Hash] ステータス別カウント
    def epic_grid_statistics_by_status(project_issues)
      project_issues.group(:status_id).count.transform_keys { |id| IssueStatus.find(id).name }
    end

    # 担当者別統計
    # @param issues [ActiveRecord::Relation] 集計対象のIssue群
    # @return [Hash] 担当者別カウント
    def epic_grid_statistics_by_assignee(project_issues)
      project_issues.group(:assigned_to_id).count.transform_keys { |id| id ? User.find(id).name : '未割当' }
    end

    # ========================================
    # グリッドインデックス構築（public - Controller から呼び出される）
    # ========================================

    # グリッドインデックスを構築 (3次元: Epic × Feature × Version)
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか
    # @param filters [Hash] Ransackフィルタパラメータ
    def epic_grid_index(exclude_closed_versions: true, filters: {})
      epic_tracker = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicGrid::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker = EpicGrid::TrackerHierarchy.tracker_names[:user_story]

      # 担当者フィルタを分離（階層的フィルタリングのため）
      assignee_ids = filters[:assigned_to_id_in]&.map(&:to_i)
      filters_without_assignee = filters.except(:assigned_to_id_in)

      base_scope = apply_ransack_filters(issues, filters_without_assignee)

      # Epic/Feature/UserStoryは階層的フィルタを適用
      epics = apply_hierarchical_filter(base_scope, epic_tracker, assignee_ids)
      features = apply_hierarchical_filter(base_scope, feature_tracker, assignee_ids)
      user_stories = apply_hierarchical_filter(base_scope, user_story_tracker, assignee_ids)

      grid_index = {}
      epic_ids = []
      feature_order_by_epic = {}
      # Version: 期日なし→先頭ID順、期日あり→期日昇順
      version_scope = versions
      version_scope = version_scope.where.not(status: 'closed') if exclude_closed_versions
      version_ids = version_scope
                      .order(Arel.sql("CASE WHEN effective_date IS NULL THEN 0 ELSE 1 END, effective_date ASC, id ASC"))
                      .pluck(:id)
                      .map(&:to_s)

      # Epic: 開始日なし→先頭ID順、開始日あり→開始日昇順
      epics.order(Arel.sql("CASE WHEN start_date IS NULL THEN 0 ELSE 1 END, start_date ASC, id ASC")).each do |epic|
        epic_ids << epic.id.to_s

        # Feature: 開始日なし→先頭ID順、開始日あり→開始日昇順
        epic_features = features.where(parent_id: epic.id)
                                .order(Arel.sql("CASE WHEN start_date IS NULL THEN 0 ELSE 1 END, start_date ASC, id ASC"))

        # Epic配下の全Feature IDsを記録
        feature_order_by_epic[epic.id.to_s] = epic_features.pluck(:id).map(&:to_s)

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
    # @param filters [Hash] Ransackフィルタパラメータ
    def epic_grid_entities(include_closed: true, exclude_closed_versions: true, filters: {})
      epic_tracker = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicGrid::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker = EpicGrid::TrackerHierarchy.tracker_names[:user_story]
      task_tracker = EpicGrid::TrackerHierarchy.tracker_names[:task]
      test_tracker = EpicGrid::TrackerHierarchy.tracker_names[:test]
      bug_tracker = EpicGrid::TrackerHierarchy.tracker_names[:bug]

      # 担当者フィルタを分離（階層的フィルタリングのため）
      assignee_ids = filters[:assigned_to_id_in]&.map(&:to_i)
      filters_without_assignee = filters.except(:assigned_to_id_in)

      scope = issues.includes(:tracker, :status, :fixed_version)
      scope = scope.joins(:status).where.not(issue_statuses: { is_closed: true }) unless include_closed
      scope = apply_ransack_filters(scope, filters_without_assignee)

      {
        # Epic/Feature/UserStoryは階層的フィルタ（子孫に該当担当者がいる祖先も含める）
        epics: build_entity_hash_hierarchical(scope, epic_tracker, assignee_ids),
        features: build_entity_hash_hierarchical(scope, feature_tracker, assignee_ids),
        user_stories: build_entity_hash_hierarchical(scope, user_story_tracker, assignee_ids),
        # Task/Test/Bugは直接フィルタ
        tasks: build_entity_hash_direct(scope, task_tracker, assignee_ids),
        tests: build_entity_hash_direct(scope, test_tracker, assignee_ids),
        bugs: build_entity_hash_direct(scope, bug_tracker, assignee_ids),
        versions: build_versions_hash(exclude_closed_versions: exclude_closed_versions),
        users: build_users_hash
      }
    end

    # トラッカー別のエンティティハッシュを構築（従来の挙動、後方互換性のため残す）
    def build_entity_hash(scope, tracker_name)
      scope.joins(:tracker)
           .where(trackers: { name: tracker_name })
           .index_by { |issue| issue.id.to_s }
           .transform_values(&:epic_grid_as_normalized_json)
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
               .transform_values(&:epic_grid_as_normalized_json)
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
               .transform_values(&:epic_grid_as_normalized_json)
    end

    # 階層的フィルタをActiveRecord::Relationとして返す（epic_grid_index用）
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

    # 直接フィルタをActiveRecord::Relationとして返す（epic_grid_index用）
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

    # バージョンのエンティティハッシュを構築
    # @param exclude_closed_versions [Boolean] クローズ済みバージョンを除外するか
    def build_versions_hash(exclude_closed_versions: true)
      version_scope = versions
      version_scope = version_scope.where.not(status: 'closed') if exclude_closed_versions

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
    def epic_grid_metadata
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
  end
end
