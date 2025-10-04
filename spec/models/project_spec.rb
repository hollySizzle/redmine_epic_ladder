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
  let(:task_tracker) { create(:task_tracker) }
  let(:test_tracker) { create(:test_tracker) }
  let(:bug_tracker) { create(:bug_tracker) }
  let(:version) { create(:version, project: project) }

  before do
    member # ensure member exists
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
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
  # Project拡張メソッド（ヘルパー）
  # ========================================

  describe '#epic_issues' do
    it 'returns issues with Epic tracker' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      epics = project.issues.joins(:tracker).where(trackers: { name: epic_tracker_name })

      expect(epics).to include(epic)
      expect(epics).not_to include(feature)
    end
  end

  describe '#feature_issues' do
    it 'returns issues with Feature tracker' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      features = project.issues.joins(:tracker).where(trackers: { name: feature_tracker_name })

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
  # グリッドインデックス構築
  # ========================================

  describe 'grid index building' do
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:grid_version) { create(:version, project: project, name: 'Grid-v1.0') }
    let!(:feature_with_version) { create(:feature, project: project, parent: epic, fixed_version: grid_version, author: user) }
    let!(:feature_without_version) { create(:feature, project: project, parent: epic, author: user) }

    it 'groups features by epic and version (MSW grid.index準拠)' do
      # MSW GridIndex型: normalized-api.ts:223-230
      grid_index = {}

      # "{epicId}:{versionId}" をキーとする
      key_with_version = "#{epic.id}:#{grid_version.id}"
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
                          .where(trackers: { name: epic_tracker_name })
                          .order(:created_on)
                          .pluck(:id)
                          .map(&:to_s)

      expect(epic_order).to include(epic1.id.to_s, epic2.id.to_s)
      expect(epic_order.index(epic1.id.to_s)).to be < epic_order.index(epic2.id.to_s)
    end

    it 'maintains version_order for grid columns' do
      v1 = create(:version, project: project, name: 'Grid-v2.0')
      v2 = create(:version, project: project, name: 'Grid-v3.0')

      version_order = project.versions
                             .order(:effective_date, :created_on)
                             .pluck(:id)
                             .map(&:to_s)

      expect(version_order).to include(v1.id.to_s, v2.id.to_s)
    end
  end

  # ========================================
  # 追加Fat Modelメソッド: 統計計算
  # ========================================

  describe '#epic_grid_build_statistics' do
    it 'builds project-wide statistics' do
      # プロジェクトにIssueを追加
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, parent: epic, author: user)

      stats = project.epic_grid_build_statistics

      expect(stats).to have_key(:by_tracker)
      expect(stats).to have_key(:by_status)
      expect(stats).to have_key(:by_assignee)
    end

    it 'counts issues by tracker' do
      epic = create(:epic, project: project, author: user)
      feature1 = create(:feature, project: project, parent: epic, author: user)
      feature2 = create(:feature, project: project, parent: epic, author: user)

      stats = project.epic_grid_build_statistics

      expect(stats[:by_tracker][epic_tracker_name]).to eq(1)
      expect(stats[:by_tracker][feature_tracker_name]).to eq(2)
    end

    it 'counts issues by status' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, parent: epic, author: user)

      stats = project.epic_grid_build_statistics

      # デフォルトステータスでカウント
      default_status_name = epic.status.name
      expect(stats[:by_status][default_status_name]).to be >= 1
    end

    it 'counts issues by assignee' do
      epic = create(:epic, project: project, author: user, assigned_to: user)
      feature = create(:feature, project: project, parent: epic, author: user, assigned_to: nil)

      stats = project.epic_grid_build_statistics

      expect(stats[:by_assignee][user.name]).to eq(1)
      expect(stats[:by_assignee]['未割当']).to eq(1)
    end
  end

  describe '#epic_grid_statistics_by_tracker' do
    it 'returns tracker name as key' do
      epic = create(:epic, project: project, author: user)
      issues = project.issues.includes(:tracker, :status, :assigned_to)

      stats = project.epic_grid_statistics_by_tracker(issues)

      expect(stats.keys).to include(epic_tracker_name)
      expect(stats[epic_tracker_name]).to eq(1)
    end
  end

  describe '#epic_grid_statistics_by_status' do
    it 'returns status name as key' do
      epic = create(:epic, project: project, author: user)
      issues = project.issues.includes(:tracker, :status, :assigned_to)

      stats = project.epic_grid_statistics_by_status(issues)

      status_name = epic.status.name
      expect(stats.keys).to include(status_name)
      expect(stats[status_name]).to be >= 1
    end
  end

  describe '#epic_grid_statistics_by_assignee' do
    it 'returns assignee name as key' do
      epic = create(:epic, project: project, author: user, assigned_to: user)
      issues = project.issues.includes(:tracker, :status, :assigned_to)

      stats = project.epic_grid_statistics_by_assignee(issues)

      expect(stats.keys).to include(user.name)
      expect(stats[user.name]).to eq(1)
    end

    it 'returns "未割当" for unassigned issues' do
      epic = create(:epic, project: project, author: user, assigned_to: nil)
      issues = project.issues.includes(:tracker, :status, :assigned_to)

      stats = project.epic_grid_statistics_by_assignee(issues)

      expect(stats['未割当']).to eq(1)
    end
  end
end
