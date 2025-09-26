# frozen_string_literal: true

module Kanban
  # キャッシュ管理システム
  # 統計・クエリ結果の多層キャッシングと自動無効化
  class CacheManager
    class CacheError < StandardError; end
    class CacheKeyGenerationError < StandardError; end

    # キャッシュ設定
    CACHE_SETTINGS = {
      statistics: {
        ttl: 5.minutes,
        namespace: 'kanban:stats',
        auto_invalidate: true
      },
      hierarchy: {
        ttl: 15.minutes,
        namespace: 'kanban:hierarchy',
        auto_invalidate: true
      },
      version_data: {
        ttl: 10.minutes,
        namespace: 'kanban:versions',
        auto_invalidate: true
      },
      user_permissions: {
        ttl: 30.minutes,
        namespace: 'kanban:permissions',
        auto_invalidate: false
      }
    }.freeze

    def self.fetch(cache_type, key_components, options = {}, &block)
      new(cache_type).fetch(key_components, options, &block)
    end

    def self.invalidate(cache_type, key_components = nil)
      new(cache_type).invalidate(key_components)
    end

    def self.warm_up_cache(project, options = {})
      new(:all).warm_up_cache(project, options)
    end

    def self.get_cache_stats(project)
      new(:all).get_cache_stats(project)
    end

    def initialize(cache_type)
      @cache_type = cache_type
      @cache_config = CACHE_SETTINGS[@cache_type] || CACHE_SETTINGS[:hierarchy]
      @metrics = {
        hits: 0,
        misses: 0,
        invalidations: 0,
        generation_time: 0.0
      }
    end

    # キャッシュからデータ取得または生成
    def fetch(key_components, options = {}, &block)
      return block.call unless block_given?

      cache_key = generate_cache_key(key_components)
      ttl = options[:ttl] || @cache_config[:ttl]

      start_time = Time.current

      result = Rails.cache.fetch(cache_key, expires_in: ttl) do
        @metrics[:misses] += 1
        generation_start = Time.current

        data = block.call

        @metrics[:generation_time] += (Time.current - generation_start)

        # キャッシュデータにメタ情報を追加
        {
          data: data,
          cached_at: Time.current,
          cache_key: cache_key,
          cache_type: @cache_type,
          generation_time: (Time.current - generation_start).round(3)
        }
      end

      @metrics[:hits] += 1 if result[:cached_at] != Time.current

      # 自動無効化設定の登録
      register_auto_invalidation(cache_key, key_components) if @cache_config[:auto_invalidate]

      {
        success: true,
        data: result[:data],
        cache_hit: result[:cached_at] != Time.current,
        cache_key: cache_key,
        generation_time: result[:generation_time],
        cached_at: result[:cached_at]
      }
    rescue => e
      Rails.logger.error "CacheManager fetch error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'CACHE_FETCH_ERROR',
        data: block&.call # フォールバック
      }
    end

    # キャッシュ無効化
    def invalidate(key_components = nil)
      invalidated_count = 0

      if key_components
        # 特定のキー無効化
        cache_key = generate_cache_key(key_components)
        Rails.cache.delete(cache_key)
        invalidated_count = 1
      else
        # パターンマッチング無効化
        pattern = "#{@cache_config[:namespace]}:*"
        invalidated_count = Rails.cache.delete_matched(pattern)
      end

      @metrics[:invalidations] += invalidated_count

      {
        success: true,
        invalidated_count: invalidated_count,
        pattern: key_components ? generate_cache_key(key_components) : pattern
      }
    rescue => e
      Rails.logger.error "CacheManager invalidate error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'CACHE_INVALIDATE_ERROR'
      }
    end

    # キャッシュウォームアップ
    def warm_up_cache(project, options = {})
      warmed_count = 0
      start_time = Time.current

      warm_up_tasks = [
        -> { warm_up_statistics_cache(project) },
        -> { warm_up_hierarchy_cache(project) },
        -> { warm_up_version_cache(project) }
      ]

      if options[:parallel]
        # 並列実行
        threads = warm_up_tasks.map do |task|
          Thread.new { task.call }
        end
        threads.each(&:join)
        warmed_count = warm_up_tasks.size
      else
        # 逐次実行
        warm_up_tasks.each do |task|
          task.call
          warmed_count += 1
        end
      end

      {
        success: true,
        warmed_count: warmed_count,
        warm_up_time: (Time.current - start_time).round(3),
        project_id: project.id
      }
    rescue => e
      Rails.logger.error "CacheManager warm_up error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'CACHE_WARM_UP_ERROR'
      }
    end

    # キャッシュ統計情報取得
    def get_cache_stats(project)
      cache_stats = {}

      CACHE_SETTINGS.each do |cache_type, config|
        namespace = config[:namespace]
        pattern = "#{namespace}:project:#{project.id}:*"

        keys = Rails.cache.instance_variable_get(:@data)&.keys&.select { |k| k.match?(/#{pattern}/) } || []

        cache_stats[cache_type] = {
          namespace: namespace,
          key_count: keys.count,
          total_size: calculate_cache_size(keys),
          hit_rate: calculate_hit_rate(cache_type),
          oldest_entry: find_oldest_entry(keys),
          newest_entry: find_newest_entry(keys)
        }
      end

      {
        success: true,
        data: {
          project_id: project.id,
          cache_stats: cache_stats,
          overall_metrics: @metrics,
          cache_health: calculate_cache_health(cache_stats)
        }
      }
    rescue => e
      Rails.logger.error "CacheManager get_cache_stats error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: 'CACHE_STATS_ERROR'
      }
    end

    private

    def generate_cache_key(key_components)
      case key_components
      when Hash
        # プロジェクト + 追加コンポーネント
        project_id = key_components[:project_id] || key_components[:project]&.id
        components = [
          @cache_config[:namespace],
          "project:#{project_id}",
          key_components.except(:project_id, :project).map { |k, v| "#{k}:#{v}" }.join(':')
        ].reject(&:blank?)

        components.join(':')
      when Array
        # 配列形式
        [@cache_config[:namespace], key_components].flatten.join(':')
      when String
        # 文字列形式
        "#{@cache_config[:namespace]}:#{key_components}"
      else
        raise CacheKeyGenerationError, "Invalid key_components format: #{key_components.class}"
      end
    end

    def register_auto_invalidation(cache_key, key_components)
      # Redis の keyspace notification または専用テーブルでの管理
      # 実装例: キーと関連するissue_idの関連を記録
      if key_components.is_a?(Hash) && key_components[:issue_id]
        auto_invalidation_key = "invalidation:issue:#{key_components[:issue_id]}"
        existing_keys = Rails.cache.fetch(auto_invalidation_key, expires_in: 1.hour) { [] }
        existing_keys << cache_key unless existing_keys.include?(cache_key)
        Rails.cache.write(auto_invalidation_key, existing_keys, expires_in: 1.hour)
      end
    end

    def warm_up_statistics_cache(project)
      # Epic統計
      epics = project.issues.joins(:tracker).where(trackers: { name: 'Epic' }).limit(10)
      epics.each do |epic|
        StatisticsEngine.calculate_epic_statistics(epic)
      end

      # Feature統計
      features = project.issues.joins(:tracker).where(trackers: { name: 'Feature' }).limit(20)
      features.each do |feature|
        StatisticsEngine.calculate_feature_statistics(feature)
      end

      # Version統計
      project.versions.limit(5).each do |version|
        StatisticsEngine.calculate_version_statistics(version)
      end
    end

    def warm_up_hierarchy_cache(project)
      # プロジェクト階層データ
      hierarchy_key = { project_id: project.id, type: 'full_hierarchy' }
      fetch(hierarchy_key) do
        project.issues
               .joins(:tracker)
               .where(trackers: { name: TrackerHierarchy.configured_tracker_names })
               .includes(:tracker, :status, :assigned_to, :fixed_version, :parent, :children)
               .to_a
      end
    end

    def warm_up_version_cache(project)
      # Version情報
      version_key = { project_id: project.id, type: 'active_versions' }
      fetch(version_key) do
        project.versions
               .where(status: 'open')
               .includes(:issues)
               .to_a
      end
    end

    def calculate_cache_size(keys)
      total_size = 0
      keys.each do |key|
        value = Rails.cache.fetch(key)
        total_size += value.to_s.bytesize if value
      end
      total_size
    end

    def calculate_hit_rate(cache_type)
      total_requests = @metrics[:hits] + @metrics[:misses]
      return 0.0 if total_requests.zero?

      (@metrics[:hits].to_f / total_requests * 100).round(2)
    end

    def find_oldest_entry(keys)
      oldest_time = nil
      keys.each do |key|
        value = Rails.cache.fetch(key)
        if value.is_a?(Hash) && value[:cached_at]
          cached_at = value[:cached_at]
          oldest_time = cached_at if oldest_time.nil? || cached_at < oldest_time
        end
      end
      oldest_time
    end

    def find_newest_entry(keys)
      newest_time = nil
      keys.each do |key|
        value = Rails.cache.fetch(key)
        if value.is_a?(Hash) && value[:cached_at]
          cached_at = value[:cached_at]
          newest_time = cached_at if newest_time.nil? || cached_at > newest_time
        end
      end
      newest_time
    end

    def calculate_cache_health(cache_stats)
      total_keys = cache_stats.values.sum { |stats| stats[:key_count] }
      avg_hit_rate = cache_stats.values.map { |stats| stats[:hit_rate] || 0 }.sum.to_f / cache_stats.size

      health_score = case avg_hit_rate
                    when 90..100 then 'excellent'
                    when 70..89 then 'good'
                    when 50..69 then 'fair'
                    else 'poor'
                    end

      {
        score: health_score,
        hit_rate: avg_hit_rate.round(2),
        total_keys: total_keys,
        recommendations: generate_cache_recommendations(avg_hit_rate, total_keys)
      }
    end

    def generate_cache_recommendations(hit_rate, total_keys)
      recommendations = []

      recommendations << 'キャッシュヒット率を向上させるため、TTLの調整を検討してください' if hit_rate < 70
      recommendations << 'キーが多すぎます。不要なキャッシュの削除を検討してください' if total_keys > 1000
      recommendations << 'ウォームアップ戦略を見直してください' if hit_rate < 50

      recommendations
    end

    # 自動無効化トリガー（Issueの更新時に呼び出される）
    def self.auto_invalidate_for_issue(issue)
      invalidation_key = "invalidation:issue:#{issue.id}"
      cache_keys = Rails.cache.fetch(invalidation_key) { [] }

      invalidated_count = 0
      cache_keys.each do |cache_key|
        Rails.cache.delete(cache_key)
        invalidated_count += 1
      end

      # 関連キーもクリア
      Rails.cache.delete(invalidation_key)

      # 親子関係のキャッシュもクリア
      if issue.parent_id
        auto_invalidate_for_issue(Issue.find(issue.parent_id))
      end

      issue.children.each do |child|
        auto_invalidate_for_issue(child)
      end

      Rails.logger.info "Auto-invalidated #{invalidated_count} cache keys for Issue##{issue.id}"
    rescue => e
      Rails.logger.error "Auto-invalidation error for Issue##{issue.id}: #{e.message}"
    end
  end
end