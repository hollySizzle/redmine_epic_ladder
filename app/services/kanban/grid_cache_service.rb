# frozen_string_literal: true

module Kanban
  # GridCacheService - Redis最適化キャッシュサービス
  # 設計書仕様: グリッドデータ段階的キャッシュ、スケーラブル設計
  class GridCacheService
    CACHE_NAMESPACE = 'kanban_grid'.freeze
    CACHE_VERSION = '2.0'.freeze

    # キャッシュ階層設定（設計書準拠）
    CACHE_LEVELS = {
      project_metadata: { ttl: 1.hour, prefix: 'proj_meta' },
      grid_structure: { ttl: 30.minutes, prefix: 'grid_struct' },
      grid_data: { ttl: 5.minutes, prefix: 'grid_data' },
      cell_statistics: { ttl: 2.minutes, prefix: 'cell_stats' },
      user_permissions: { ttl: 10.minutes, prefix: 'user_perms' },
      real_time_updates: { ttl: 30.seconds, prefix: 'rt_updates' }
    }.freeze

    class << self
      # グリッドデータキャッシュ取得
      def get_grid_data(project_id, user_id, filters = {})
        cache_key = build_cache_key(:grid_data, project_id, user_id, filters)

        cached_data = Rails.cache.read(cache_key)

        if cached_data&.dig(:version) == CACHE_VERSION
          Rails.logger.debug "Grid cache hit: #{cache_key}"
          return cached_data[:data]
        end

        Rails.logger.debug "Grid cache miss: #{cache_key}"
        nil
      end

      # グリッドデータキャッシュ保存
      def set_grid_data(project_id, user_id, filters, data)
        cache_key = build_cache_key(:grid_data, project_id, user_id, filters)
        cache_data = {
          version: CACHE_VERSION,
          data: data,
          timestamp: Time.current.to_f,
          project_updated_at: get_project_update_timestamp(project_id)
        }

        ttl = CACHE_LEVELS[:grid_data][:ttl]
        Rails.cache.write(cache_key, cache_data, expires_in: ttl)

        # 関連キャッシュのタグ付け（無効化用）
        tag_cache_entry(cache_key, project_id, user_id)

        Rails.logger.debug "Grid cache set: #{cache_key} (TTL: #{ttl})"
        data
      end

      # プロジェクトメタデータキャッシュ
      def get_project_metadata(project_id)
        cache_key = build_cache_key(:project_metadata, project_id)

        Rails.cache.fetch(cache_key, expires_in: CACHE_LEVELS[:project_metadata][:ttl]) do
          Rails.logger.debug "Project metadata cache miss: #{cache_key}"
          build_project_metadata(project_id)
        end
      end

      # セル統計キャッシュ
      def get_cell_statistics(project_id, epic_id, version_id)
        cache_key = build_cache_key(:cell_statistics, project_id, epic_id, version_id)

        Rails.cache.fetch(cache_key, expires_in: CACHE_LEVELS[:cell_statistics][:ttl]) do
          Rails.logger.debug "Cell statistics cache miss: #{cache_key}"
          calculate_cell_statistics(project_id, epic_id, version_id)
        end
      end

      # ユーザー権限キャッシュ
      def get_user_permissions(project_id, user_id)
        cache_key = build_cache_key(:user_permissions, project_id, user_id)

        Rails.cache.fetch(cache_key, expires_in: CACHE_LEVELS[:user_permissions][:ttl]) do
          Rails.logger.debug "User permissions cache miss: #{cache_key}"
          calculate_user_permissions(project_id, user_id)
        end
      end

      # リアルタイム更新キャッシュ
      def get_real_time_updates(project_id, since_timestamp)
        cache_key = build_cache_key(:real_time_updates, project_id, since_timestamp.to_i)

        cached_updates = Rails.cache.read(cache_key)
        return cached_updates if cached_updates

        Rails.logger.debug "Real-time updates cache miss: #{cache_key}"
        nil
      end

      def set_real_time_updates(project_id, since_timestamp, updates)
        cache_key = build_cache_key(:real_time_updates, project_id, since_timestamp.to_i)
        ttl = CACHE_LEVELS[:real_time_updates][:ttl]

        Rails.cache.write(cache_key, updates, expires_in: ttl)
        Rails.logger.debug "Real-time updates cached: #{cache_key}"
      end

      # キャッシュ無効化（階層的）
      def invalidate_project_cache(project_id)
        patterns = [
          "#{cache_namespace}:*:proj_#{project_id}:*",
          "#{cache_namespace}:grid_data:proj_#{project_id}:*",
          "#{cache_namespace}:cell_stats:proj_#{project_id}:*",
          "#{cache_namespace}:rt_updates:proj_#{project_id}:*"
        ]

        invalidated_count = 0
        patterns.each do |pattern|
          keys = find_cache_keys(pattern)
          keys.each do |key|
            Rails.cache.delete(key)
            invalidated_count += 1
          end
        end

        Rails.logger.info "Invalidated #{invalidated_count} cache entries for project #{project_id}"
        invalidated_count
      end

      def invalidate_user_cache(project_id, user_id)
        pattern = "#{cache_namespace}:*:proj_#{project_id}:user_#{user_id}:*"
        keys = find_cache_keys(pattern)

        keys.each { |key| Rails.cache.delete(key) }
        Rails.logger.info "Invalidated #{keys.count} cache entries for user #{user_id} in project #{project_id}"
      end

      # バッチキャッシュウォームアップ
      def warm_up_cache(project_id, user_ids = [])
        Rails.logger.info "Warming up cache for project #{project_id}"

        # プロジェクトメタデータ事前読み込み
        get_project_metadata(project_id)

        # 各ユーザーの権限情報事前読み込み
        user_ids.each do |user_id|
          get_user_permissions(project_id, user_id)
        end

        # 基本グリッドデータ事前読み込み（フィルタなし）
        if user_ids.any?
          primary_user = User.find(user_ids.first)
          builder = Kanban::GridDataBuilder.new(Project.find(project_id), primary_user)
          grid_data = builder.build

          set_grid_data(project_id, primary_user.id, {}, grid_data)
        end

        Rails.logger.info "Cache warm-up completed for project #{project_id}"
      end

      # キャッシュ統計情報
      def cache_statistics(project_id)
        patterns = [
          "#{cache_namespace}:*:proj_#{project_id}:*"
        ]

        total_keys = 0
        cache_sizes = {}

        patterns.each do |pattern|
          keys = find_cache_keys(pattern)
          total_keys += keys.count

          keys.each do |key|
            cached_data = Rails.cache.read(key)
            if cached_data
              size = cached_data.to_json.bytesize
              cache_level = extract_cache_level(key)
              cache_sizes[cache_level] ||= { count: 0, total_size: 0 }
              cache_sizes[cache_level][:count] += 1
              cache_sizes[cache_level][:total_size] += size
            end
          end
        end

        {
          project_id: project_id,
          total_keys: total_keys,
          cache_levels: cache_sizes,
          timestamp: Time.current.iso8601
        }
      end

      private

      def build_cache_key(cache_level, *components)
        prefix = CACHE_LEVELS[cache_level][:prefix]
        namespace = cache_namespace
        formatted_components = components.map { |c| format_component(c) }.join(':')

        "#{namespace}:#{prefix}:#{formatted_components}"
      end

      def format_component(component)
        case component
        when Hash
          # フィルタなどのハッシュ値を安定したキーに変換
          sorted_pairs = component.sort.map { |k, v| "#{k}=#{v}" }
          Digest::MD5.hexdigest(sorted_pairs.join('&'))
        when ActiveRecord::Base
          "#{component.class.name.underscore}_#{component.id}"
        when Integer, String
          "#{component}"
        else
          component.to_s
        end
      end

      def cache_namespace
        "#{CACHE_NAMESPACE}_v#{CACHE_VERSION}"
      end

      # Redis固有の実装（Railsキャッシュストアに依存）
      def find_cache_keys(pattern)
        if Rails.cache.respond_to?(:redis)
          # Redis使用時
          Rails.cache.redis.keys(pattern)
        else
          # 他のキャッシュストア使用時（メモリストアなど）
          # パターンマッチングの代替実装
          []
        end
      end

      def tag_cache_entry(cache_key, project_id, user_id)
        # キャッシュタグ機能（Redisの場合）
        if Rails.cache.respond_to?(:redis)
          tags = ["project_#{project_id}", "user_#{user_id}"]
          # Redisタグ実装は簡略化
        end
      end

      def extract_cache_level(cache_key)
        CACHE_LEVELS.keys.find do |level|
          prefix = CACHE_LEVELS[level][:prefix]
          cache_key.include?(":#{prefix}:")
        end || :unknown
      end

      # プロジェクトメタデータ構築
      def build_project_metadata(project_id)
        project = Project.find(project_id)

        {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
          description: project.description,
          status: project.status,
          created_on: project.created_on.iso8601,
          updated_on: project.updated_on.iso8601,
          trackers: project.trackers.pluck(:id, :name),
          versions: project.versions.active.pluck(:id, :name, :status),
          issue_statuses: IssueStatus.all.pluck(:id, :name)
        }
      end

      # セル統計計算
      def calculate_cell_statistics(project_id, epic_id, version_id)
        project = Project.find(project_id)

        feature_tracker_name = Kanban::TrackerHierarchy.tracker_names[:feature]
        query = project.issues.joins(:tracker).where(trackers: { name: feature_tracker_name })

        if epic_id && epic_id != 'no-epic'
          query = query.where(parent_id: epic_id)
        elsif epic_id == 'no-epic'
          query = query.where(parent_id: nil)
        end

        if version_id && version_id != 'no-version'
          query = query.where(fixed_version_id: version_id)
        elsif version_id == 'no-version'
          query = query.where(fixed_version_id: nil)
        end

        total_features = query.count
        completed_features = query.joins(:status)
                                  .where(issue_statuses: { name: ['Resolved', 'Closed'] })
                                  .count

        {
          total_features: total_features,
          completed_features: completed_features,
          completion_rate: total_features > 0 ?
            ((completed_features.to_f / total_features) * 100).round(2) : 0,
          last_calculated: Time.current.iso8601
        }
      end

      # ユーザー権限計算
      def calculate_user_permissions(project_id, user_id)
        project = Project.find(project_id)
        user = User.find(user_id)

        {
          view_issues: user.allowed_to?(:view_issues, project),
          edit_issues: user.allowed_to?(:edit_issues, project),
          add_issues: user.allowed_to?(:add_issues, project),
          delete_issues: user.allowed_to?(:delete_issues, project),
          manage_versions: user.allowed_to?(:manage_versions, project),
          view_time_entries: user.allowed_to?(:view_time_entries, project)
        }
      end

      def get_project_update_timestamp(project_id)
        project = Project.find(project_id)
        latest_issue_update = project.issues.maximum(:updated_on)
        [project.updated_on, latest_issue_update].compact.max.to_f
      end
    end

    # インスタンスメソッド（特定プロジェクト・ユーザー向け）
    def initialize(project, user)
      @project = project
      @user = user
    end

    def get_cached_grid_data(filters = {})
      self.class.get_grid_data(@project.id, @user.id, filters)
    end

    def cache_grid_data(filters, data)
      self.class.set_grid_data(@project.id, @user.id, filters, data)
    end

    def get_cached_user_permissions
      self.class.get_user_permissions(@project.id, @user.id)
    end

    def invalidate_cache
      self.class.invalidate_user_cache(@project.id, @user.id)
    end

    private

    attr_reader :project, :user
  end
end