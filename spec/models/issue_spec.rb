# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe Issue, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }
  let(:version_v1) { create(:version, project: project, name: 'v1.0') }
  let(:version_v2) { create(:version, project: project, name: 'v2.0') }

  before do
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker]
  end

  describe '.create_epic (Fat Model - 将来実装)' do
    pending 'creates epic with correct tracker and assigns to project' do
      epic = Issue.create_epic(
        { subject: 'New Epic', description: 'Epic description' },
        project,
        user
      )

      expect(epic).to be_persisted
      expect(epic.tracker).to eq(epic_tracker)
      expect(epic.project).to eq(project)
      expect(epic.author).to eq(user)
    end

    pending 'raises error when subject is blank' do
      expect {
        Issue.create_epic({ subject: '' }, project, user)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#move_to_cell (Fat Model - 将来実装)' do
    let!(:source_epic) { create(:epic, project: project, author: user) }
    let!(:target_epic) { create(:epic, project: project, author: user) }
    let!(:feature) do
      create(:feature,
        project: project,
        parent: source_epic,
        fixed_version: version_v1,
        author: user
      )
    end
    let!(:user_story) do
      create(:user_story,
        project: project,
        parent: feature,
        fixed_version: version_v1,
        author: user
      )
    end
    let!(:task) do
      create(:task,
        project: project,
        parent: user_story,
        fixed_version: version_v1,
        author: user
      )
    end

    pending 'moves feature to target epic and version' do
      feature.move_to_cell(target_epic.id, version_v2.id, user)

      feature.reload
      expect(feature.parent).to eq(target_epic)
      expect(feature.fixed_version).to eq(version_v2)
    end

    pending 'propagates version to child user stories and tasks' do
      feature.move_to_cell(target_epic.id, version_v2.id, user)

      user_story.reload
      task.reload

      expect(user_story.fixed_version).to eq(version_v2)
      expect(task.fixed_version).to eq(version_v2)
    end

    pending 'raises permission error when user lacks edit permission' do
      unauthorized_user = create(:user)

      expect {
        feature.move_to_cell(target_epic.id, version_v2.id, unauthorized_user)
      }.to raise_error(Issue::PermissionError)
    end
  end

  describe '#propagate_version_to_children (Fat Model - 将来実装)' do
    let!(:feature) { create(:feature, :with_user_stories, project: project, fixed_version: version_v1, author: user) }

    pending 'updates version for all descendants' do
      feature.propagate_version_to_children(version_v2)

      feature.children.each do |child|
        child.reload
        expect(child.fixed_version).to eq(version_v2)
      end
    end

    pending 'sets version_source to "inherited" for children' do
      feature.propagate_version_to_children(version_v2)

      feature.children.first.reload
      expect(feature.children.first.custom_field_value_by_name('version_source')).to eq('inherited')
    end
  end

  describe '#as_normalized_json (Fat Model - 将来実装)' do
    let!(:epic) { create(:epic, :with_features, project: project, author: user) }

    pending 'returns normalized API format' do
      json = epic.as_normalized_json

      expect(json).to include(
        :id,
        :subject,
        :description,
        :status,
        :feature_ids,
        :statistics,
        :created_on,
        :updated_on
      )
    end

    pending 'includes statistics for epic' do
      json = epic.as_normalized_json

      expect(json[:statistics]).to include(
        :total_features,
        :completed_features,
        :total_user_stories,
        :total_child_items,
        :completion_percentage
      )
    end
  end

  describe 'validations' do
    it 'validates tracker hierarchy on parent assignment' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      # Feature → Epic (逆方向) は無効
      epic.parent = feature

      expect(epic).not_to be_valid
      expect(epic.errors[:parent_issue_id]).to include('Invalid parent tracker')
    end
  end

  describe 'associations' do
    it 'has many children issues' do
      epic = create(:epic, :with_features, project: project, author: user)

      expect(epic.children.count).to be > 0
      expect(epic.children.first.tracker.name).to eq('Feature')
    end
  end

  describe 'hierarchy methods' do
    describe '#hierarchy_level' do
      it 'returns 0 for Epic' do
        epic = create(:epic, project: project, author: user)
        expect(epic.hierarchy_level).to eq(0)
      end

      it 'returns 1 for Feature' do
        feature = create(:feature, project: project, author: user)
        expect(feature.hierarchy_level).to eq(1)
      end

      it 'returns 2 for UserStory' do
        user_story = create(:user_story, project: project, author: user)
        expect(user_story.hierarchy_level).to eq(2)
      end
    end
  end
end
