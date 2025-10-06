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

    # グリッドインデックスを構築 (3次元: Epic × Feature × Version)
    def epic_grid_index
      epic_tracker = EpicGrid::TrackerHierarchy.tracker_names[:epic]
      feature_tracker = EpicGrid::TrackerHierarchy.tracker_names[:feature]
      user_story_tracker = EpicGrid::TrackerHierarchy.tracker_names[:user_story]

      epics = issues.joins(:tracker).where(trackers: { name: epic_tracker })
      features = issues.joins(:tracker).where(trackers: { name: feature_tracker })
      user_stories = issues.joins(:tracker).where(trackers: { name: user_story_tracker })

      grid_index = {}
      epic_ids = []
      feature_order_by_epic = {}
      version_ids = versions.pluck(:id).map(&:to_s)

      epics.order(:created_on).each do |epic|
        epic_ids << epic.id.to_s

        # Epic配下のFeature
        epic_features = features.where(parent_id: epic.id).order(:created_on)

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
        versions: build_versions_hash,
        users: build_users_hash
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
        api_version: 'v2',
        timestamp: Time.current.iso8601,
        request_id: "req_#{SecureRandom.hex(8)}"
      }
    end
  end
end
