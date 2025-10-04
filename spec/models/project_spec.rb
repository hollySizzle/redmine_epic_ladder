# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe Project, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:version) { create(:version, project: project) }

  before do
    project.trackers << [epic_tracker, feature_tracker]
  end

  describe '#epic_grid_data (Fat Model - 将来実装)' do
    let!(:epic) { create(:epic, :with_features, project: project, author: user) }

    pending 'returns normalized API response structure' do
      grid_data = project.epic_grid_data(user)

      expect(grid_data).to include(
        :entities,
        :grid,
        :metadata,
        :statistics
      )
    end

    pending 'includes entities hash with all tracker types' do
      grid_data = project.epic_grid_data(user)

      expect(grid_data[:entities]).to include(
        :epics,
        :features,
        :user_stories,
        :tasks,
        :tests,
        :bugs,
        :versions
      )
    end

    pending 'includes grid index mapping epic×version' do
      grid_data = project.epic_grid_data(user)

      expect(grid_data[:grid]).to include(
        :index,
        :epic_order,
        :version_order
      )
    end

    pending 'includes project metadata' do
      grid_data = project.epic_grid_data(user)

      expect(grid_data[:metadata][:project]).to include(
        :id,
        :name,
        :identifier
      )
    end

    pending 'includes user permissions' do
      grid_data = project.epic_grid_data(user)

      expect(grid_data[:metadata][:user_permissions]).to include(
        :view_issues,
        :edit_issues,
        :add_issues,
        :delete_issues,
        :manage_versions
      )
    end

    pending 'includes statistics overview' do
      grid_data = project.epic_grid_data(user)

      expect(grid_data[:statistics][:overview]).to include(
        :total_issues,
        :completed_issues,
        :completion_rate,
        :total_epics,
        :total_features,
        :total_user_stories
      )
    end

    pending 'filters by include_closed parameter' do
      closed_status = create(:closed_status)
      create(:feature, project: project, status: closed_status, author: user)

      grid_data = project.epic_grid_data(user, { include_closed: false })

      closed_features = grid_data[:entities][:features].select do |_, feature|
        feature[:status] == 'closed'
      end

      expect(closed_features).to be_empty
    end
  end

  describe '#kanban_statistics (Fat Model - 将来実装)' do
    pending 'calculates overview statistics' do
      create_list(:epic, 3, project: project, author: user)

      stats = project.kanban_statistics

      expect(stats[:overview]).to include(
        total_issues: be >= 3,
        completed_issues: be_a(Integer),
        completion_rate: be_a(Numeric)
      )
    end

    pending 'calculates statistics by version' do
      version = create(:version, project: project)
      create(:feature, project: project, fixed_version: version, author: user)

      stats = project.kanban_statistics

      expect(stats[:by_version][version.id.to_s]).to be_present
    end

    pending 'calculates statistics by status' do
      open_status = create(:issue_status, name: 'Open')
      create(:feature, project: project, status: open_status, author: user)

      stats = project.kanban_statistics

      expect(stats[:by_status]).to have_key('Open')
    end

    pending 'calculates statistics by tracker' do
      create(:epic, project: project, author: user)
      create(:feature, project: project, author: user)

      stats = project.kanban_statistics

      expect(stats[:by_tracker]).to include(
        'Epic' => be >= 1,
        'Feature' => be >= 1
      )
    end
  end

  describe '#epic_issues' do
    it 'returns issues with Epic tracker' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      epics = project.epic_issues

      expect(epics).to include(epic)
      expect(epics).not_to include(feature)
    end
  end

  describe '#feature_issues' do
    it 'returns issues with Feature tracker' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      features = project.feature_issues

      expect(features).to include(feature)
      expect(features).not_to include(epic)
    end
  end

  describe '#epic_grid_enabled?' do
    it 'returns true when epic_grid module is enabled' do
      project.enabled_modules.create!(name: 'epic_grid')

      expect(project).to be_epic_grid_enabled
    end

    it 'returns false when epic_grid module is not enabled' do
      expect(project).not_to be_epic_grid_enabled
    end
  end
end
