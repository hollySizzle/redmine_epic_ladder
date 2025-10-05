# frozen_string_literal: true

module EpicGrid
  module ProjectExtensions
    extend ActiveSupport::Concern

    # ========================================
    # グリッドデータ構築（MSW準拠）
    # ========================================

    # Epic Gridのデータを正規化APIレスポンス形式で取得
    # @param include_closed [Boolean] closedステータスを含めるか
    # @return [Hash] MSW NormalizedAPIResponse準拠のHash
    def epic_grid_data(include_closed: true)
      {
        entities: epic_grid_entities(include_closed: include_closed),
        grid: epic_grid_index,
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

    # グリッドインデックスを構築
    def epic_grid_index
      epic_tracker = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicGrid::TrackerHierarchy.tracker_names[:feature]

      epics = issues.joins(:tracker).where(trackers: { name: epic_tracker })
      features = issues.joins(:tracker).where(trackers: { name: feature_tracker })

      grid_index = {}
      epic_ids = []
      version_ids = versions.pluck(:id).map(&:to_s)

      epics.order(:created_on).each do |epic|
        epic_ids << epic.id.to_s

        # Epic配下のFeatureをバージョン別に分類
        epic_features = features.where(parent_id: epic.id)

        # バージョンありのFeature
        epic_features.where.not(fixed_version_id: nil).group_by(&:fixed_version_id).each do |version_id, version_features|
          key = "#{epic.id}:#{version_id}"
          grid_index[key] = version_features.map { |f| f.id.to_s }
        end

        # バージョンなしのFeature
        no_version_features = epic_features.where(fixed_version_id: nil)
        if no_version_features.any?
          key = "#{epic.id}:none"
          grid_index[key] = no_version_features.map { |f| f.id.to_s }
        end
      end

      {
        index: grid_index,
        epic_order: epic_ids,
        version_order: version_ids + ['none']
      }
    end

    # ========================================
    # プライベートメソッド
    # ========================================

    private

    # エンティティハッシュを構築
    def epic_grid_entities(include_closed: true)
      epic_tracker = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicGrid::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker = EpicGrid::TrackerHierarchy.tracker_names[:user_story]
      task_tracker = EpicGrid::TrackerHierarchy.tracker_names[:task]
      test_tracker = EpicGrid::TrackerHierarchy.tracker_names[:test]
      bug_tracker = EpicGrid::TrackerHierarchy.tracker_names[:bug]

      scope = issues.includes(:tracker, :status, :fixed_version)
      scope = scope.joins(:status).where.not(issue_statuses: { is_closed: true }) unless include_closed

      {
        epics: build_entity_hash(scope, epic_tracker),
        features: build_entity_hash(scope, feature_tracker),
        user_stories: build_entity_hash(scope, user_story_tracker),
        tasks: build_entity_hash(scope, task_tracker),
        tests: build_entity_hash(scope, test_tracker),
        bugs: build_entity_hash(scope, bug_tracker),
        versions: build_versions_hash
      }
    end

    # トラッカー別のエンティティハッシュを構築
    def build_entity_hash(scope, tracker_name)
      scope.joins(:tracker)
           .where(trackers: { name: tracker_name })
           .index_by { |issue| issue.id.to_s }
           .transform_values(&:epic_grid_as_normalized_json)
    end

    # バージョンのエンティティハッシュを構築
    def build_versions_hash
      versions.index_by { |v| v.id.to_s }.transform_values do |version|
        {
          id: version.id.to_s,
          name: version.name,
          description: version.description,
          status: version.status,
          due_date: version.due_date&.iso8601,
          created_on: version.created_on.iso8601,
          updated_on: version.updated_on.iso8601
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
        api_version: 'v2',
        timestamp: Time.current.iso8601,
        request_id: "req_#{SecureRandom.hex(8)}"
      }
    end
  end
end
