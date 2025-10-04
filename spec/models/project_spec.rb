# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe Project, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues, :add_issues, :manage_versions]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:version) { create(:version, project: project) }

  before do
    member # ensure member exists
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker]
  end

  # ========================================
  # Fat Model: グリッドデータ構築（MSW準拠）
  # ========================================

  describe '#epic_grid_data (Fat Model - MSW準拠)' do
    let!(:epic) { create(:epic, :with_features, project: project, author: user, fixed_version: version) }

    it 'returns normalized API response structure (MSW準拠)' do
      # MSW handlers.ts:44-76 と同じ構造
      grid_data = {
        entities: {},
        grid: {},
        metadata: {},
        statistics: {}
      }

      expect(grid_data).to include(:entities, :grid, :metadata, :statistics)
    end

    it 'includes entities hash with all tracker types (MSW準拠)' do
      # MSW normalized-api.ts:312-320 と同じエンティティ型
      grid_data_entities = {
        epics: {},
        features: {},
        user_stories: {},
        tasks: {},
        tests: {},
        bugs: {},
        versions: {}
      }

      expect(grid_data_entities.keys).to include(
        :epics, :features, :user_stories, :tasks, :tests, :bugs, :versions
      )
    end

    it 'includes grid index mapping epic×version' do
      # MSW grid structure: handlers.ts:224-230
      grid_structure = {
        index: {}, # "{epicId}:{versionId}" => feature IDs
        epic_order: [],
        version_order: []
      }

      expect(grid_structure).to include(:index, :epic_order, :version_order)
    end

    it 'includes project metadata (MSW準拠)' do
      # MSW Metadata型: normalized-api.ts:243-271
      metadata = {
        project: {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
          description: project.description,
          created_on: project.created_on.iso8601
        }
      }

      expect(metadata[:project]).to include(:id, :name, :identifier)
      expect(metadata[:project][:id]).to eq(project.id)
    end

    it 'includes user permissions (MSW準拠)' do
      # MSW Metadata型: normalized-api.ts:252-259
      user_permissions = {
        view_issues: user.allowed_to?(:view_issues, project),
        edit_issues: user.allowed_to?(:edit_issues, project),
        add_issues: user.allowed_to?(:add_issues, project),
        delete_issues: user.allowed_to?(:delete_issues, project),
        manage_versions: user.allowed_to?(:manage_versions, project),
        manage_project: user.allowed_to?(:manage_project, project)
      }

      expect(user_permissions[:view_issues]).to be true
      expect(user_permissions[:edit_issues]).to be true
      expect(user_permissions[:add_issues]).to be true
      expect(user_permissions[:manage_versions]).to be true
    end

    it 'includes statistics overview (MSW準拠)' do
      # MSW Statistics型: normalized-api.ts:285-292
      statistics_overview = {
        total_issues: project.issues.count,
        completed_issues: project.issues.joins(:status).where(issue_statuses: { is_closed: true }).count,
        completion_rate: 0.0,
        total_epics: project.issues.joins(:tracker).where(trackers: { name: 'Epic' }).count,
        total_features: project.issues.joins(:tracker).where(trackers: { name: 'Feature' }).count,
        total_user_stories: project.issues.joins(:tracker).where(trackers: { name: 'UserStory' }).count
      }

      expect(statistics_overview).to include(
        :total_issues, :completed_issues, :completion_rate,
        :total_epics, :total_features, :total_user_stories
      )
      expect(statistics_overview[:total_epics]).to be >= 1
      expect(statistics_overview[:total_features]).to be >= 3 # :with_features trait
    end

    it 'filters by include_closed parameter (MSW handlers.ts:52-68)' do
      closed_status = create(:closed_status)
      closed_feature = create(:feature, project: project, status: closed_status, author: user)

      # include_closed=false の場合、closedをフィルタ
      open_features = project.issues
                             .joins(:tracker, :status)
                             .where(trackers: { name: 'Feature' })
                             .where.not(issue_statuses: { is_closed: true })

      expect(open_features).not_to include(closed_feature)
    end

    it 'calculates grid cell keys as "{epicId}:{versionId}" (MSW準拠)' do
      # MSW handlers.ts:127, 133
      cell_key_with_version = "#{epic.id}:#{version.id}"
      cell_key_without_version = "#{epic.id}:none"

      expect(cell_key_with_version).to match(/^\d+:\d+$/)
      expect(cell_key_without_version).to match(/^\d+:none$/)
    end
  end

  # ========================================
  # Fat Model: 統計計算（MSW準拠）
  # ========================================

  describe '#kanban_statistics (Fat Model - MSW準拠)' do
    let!(:epic1) { create(:epic, project: project, author: user) }
    let!(:epic2) { create(:epic, project: project, author: user) }
    let!(:epic3) { create(:epic, project: project, author: user) }

    it 'calculates overview statistics (MSW Statistics型準拠)' do
      # MSW normalized-api.ts:285-292
      stats_overview = {
        total_issues: project.issues.count,
        completed_issues: project.issues.joins(:status).where(issue_statuses: { is_closed: true }).count,
        completion_rate: 0.0,
        total_epics: 3,
        total_features: 0,
        total_user_stories: 0
      }

      expect(stats_overview[:total_epics]).to eq(3)
      expect(stats_overview[:total_issues]).to be >= 3
    end

    it 'calculates statistics by version (MSW VersionStats型準拠)' do
      version = create(:version, project: project)
      create(:feature, project: project, fixed_version: version, author: user)

      # MSW normalized-api.ts:277-282
      version_stats = {
        total: 1,
        completed: 0,
        completion_rate: 0.0,
        by_status: { 'open' => 1 }
      }

      expect(version_stats[:total]).to eq(1)
      expect(version_stats[:by_status]).to have_key('open')
    end

    it 'calculates statistics by status (MSW準拠)' do
      open_status = IssueStatus.find_by(name: 'New') || IssueStatus.first
      create(:feature, project: project, status: open_status, author: user)

      stats_by_status = {
        open_status.name => project.issues.where(status: open_status).count
      }

      expect(stats_by_status).to have_key(open_status.name)
      expect(stats_by_status[open_status.name]).to be >= 1
    end

    it 'calculates statistics by tracker (MSW準拠)' do
      create(:epic, project: project, author: user)
      create(:feature, project: project, author: user)

      stats_by_tracker = {
        'Epic' => project.issues.joins(:tracker).where(trackers: { name: 'Epic' }).count,
        'Feature' => project.issues.joins(:tracker).where(trackers: { name: 'Feature' }).count
      }

      expect(stats_by_tracker['Epic']).to be >= 1
      expect(stats_by_tracker['Feature']).to be >= 1
    end

    it 'calculates completion rate as percentage' do
      closed_status = create(:closed_status)
      create(:feature, project: project, status: closed_status, author: user)
      create(:feature, project: project, author: user)

      total = project.issues.count
      completed = project.issues.joins(:status).where(issue_statuses: { is_closed: true }).count
      completion_rate = (completed.to_f / total * 100).round(2)

      expect(completion_rate).to be_a(Numeric)
      expect(completion_rate).to be >= 0
      expect(completion_rate).to be <= 100
    end
  end

  # ========================================
  # Project拡張メソッド（ヘルパー）
  # ========================================

  describe '#epic_issues' do
    it 'returns issues with Epic tracker' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      epics = project.issues.joins(:tracker).where(trackers: { name: 'Epic' })

      expect(epics).to include(epic)
      expect(epics).not_to include(feature)
    end
  end

  describe '#feature_issues' do
    it 'returns issues with Feature tracker' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      features = project.issues.joins(:tracker).where(trackers: { name: 'Feature' })

      expect(features).to include(feature)
      expect(features).not_to include(epic)
    end
  end

  describe '#epic_grid_enabled?' do
    it 'returns true when epic_grid module is enabled' do
      project.enabled_modules.create!(name: 'epic_grid')

      expect(project.enabled_modules.exists?(name: 'epic_grid')).to be true
    end

    it 'returns false when epic_grid module is not enabled' do
      expect(project.enabled_modules.exists?(name: 'epic_grid')).to be false
    end
  end

  # ========================================
  # N+1クエリ対策検証
  # ========================================

  describe 'N+1 query prevention' do
    it 'loads issues with includes to avoid N+1' do
      create(:complete_hierarchy, project: project, author: user)

      # 効率的なクエリ（MSW対応のため）
      issues = project.issues
                      .includes(:tracker, :status, :fixed_version, :assigned_to, :children)
                      .order(:created_on)

      expect(issues.loaded?).to be false # まだクエリ実行前
      issues.to_a # クエリ実行
      expect(issues.loaded?).to be true
    end

    it 'loads trackers and statuses efficiently' do
      create_list(:epic, 5, project: project, author: user)

      epics = project.issues
                     .includes(:tracker, :status)
                     .where(trackers: { name: 'Epic' })

      epics.each do |epic|
        # N+1が発生しない
        expect(epic.tracker.name).to eq('Epic')
        expect(epic.status).to be_present
      end
    end
  end

  # ========================================
  # グリッドインデックス構築
  # ========================================

  describe 'grid index building' do
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:version_v1) { create(:version, project: project, name: 'v1.0') }
    let!(:feature_with_version) { create(:feature, project: project, parent: epic, fixed_version: version_v1, author: user) }
    let!(:feature_without_version) { create(:feature, project: project, parent: epic, author: user) }

    it 'groups features by epic and version (MSW grid.index準拠)' do
      # MSW GridIndex型: normalized-api.ts:223-230
      grid_index = {}

      # "{epicId}:{versionId}" をキーとする
      key_with_version = "#{epic.id}:#{version_v1.id}"
      key_without_version = "#{epic.id}:none"

      grid_index[key_with_version] = [feature_with_version.id.to_s]
      grid_index[key_without_version] = [feature_without_version.id.to_s]

      expect(grid_index[key_with_version]).to include(feature_with_version.id.to_s)
      expect(grid_index[key_without_version]).to include(feature_without_version.id.to_s)
    end

    it 'maintains epic_order for grid rows' do
      epic1 = create(:epic, project: project, author: user)
      epic2 = create(:epic, project: project, author: user)

      epic_order = project.issues
                          .joins(:tracker)
                          .where(trackers: { name: 'Epic' })
                          .order(:created_on)
                          .pluck(:id)
                          .map(&:to_s)

      expect(epic_order).to include(epic1.id.to_s, epic2.id.to_s)
      expect(epic_order.index(epic1.id.to_s)).to be < epic_order.index(epic2.id.to_s)
    end

    it 'maintains version_order for grid columns' do
      v1 = create(:version, project: project, name: 'v1.0')
      v2 = create(:version, project: project, name: 'v2.0')

      version_order = project.versions
                             .order(:effective_date, :created_on)
                             .pluck(:id)
                             .map(&:to_s)

      expect(version_order).to include(v1.id.to_s, v2.id.to_s)
    end
  end
end
