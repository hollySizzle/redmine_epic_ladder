# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicGrid::TrackerHierarchy, type: :model do
  describe '.tracker_names' do
    it 'returns tracker name mappings' do
      names = described_class.tracker_names

      expect(names).to include(
        epic: 'Epic',
        feature: 'Feature',
        user_story: 'UserStory',
        task: 'Task',
        test: 'Test',
        bug: 'Bug'
      )
    end
  end

  describe '.level' do
    it 'returns correct hierarchy level for Epic' do
      expect(described_class.level('Epic')).to eq(0)
    end

    it 'returns correct hierarchy level for Feature' do
      expect(described_class.level('Feature')).to eq(1)
    end

    it 'returns correct hierarchy level for UserStory' do
      expect(described_class.level('UserStory')).to eq(2)
    end

    it 'returns correct hierarchy level for Task/Test/Bug' do
      expect(described_class.level('Task')).to eq(3)
      expect(described_class.level('Test')).to eq(3)
      expect(described_class.level('Bug')).to eq(3)
    end

    it 'returns nil for unknown tracker' do
      expect(described_class.level('Unknown')).to be_nil
    end
  end

  describe '.valid_parent?' do
    let(:epic_tracker) { create(:epic_tracker) }
    let(:feature_tracker) { create(:feature_tracker) }
    let(:user_story_tracker) { create(:user_story_tracker) }
    let(:task_tracker) { create(:task_tracker) }

    it 'allows Feature as child of Epic' do
      expect(described_class.valid_parent?(feature_tracker, epic_tracker)).to be true
    end

    it 'allows UserStory as child of Feature' do
      expect(described_class.valid_parent?(user_story_tracker, feature_tracker)).to be true
    end

    it 'allows Task as child of UserStory' do
      expect(described_class.valid_parent?(task_tracker, user_story_tracker)).to be true
    end

    it 'rejects Epic as child of Feature (invalid hierarchy)' do
      expect(described_class.valid_parent?(epic_tracker, feature_tracker)).to be false
    end

    it 'rejects Task as child of Epic (skipping levels)' do
      expect(described_class.valid_parent?(task_tracker, epic_tracker)).to be false
    end
  end

  describe '.root_tracker' do
    it 'returns Epic tracker name' do
      expect(described_class.root_tracker).to eq('Epic')
    end
  end

  describe '.children_trackers' do
    it 'returns valid child trackers for Epic' do
      children = described_class.children_trackers('Epic')
      expect(children).to eq(['Feature'])
    end

    it 'returns valid child trackers for Feature' do
      children = described_class.children_trackers('Feature')
      expect(children).to eq(['UserStory'])
    end

    it 'returns valid child trackers for UserStory' do
      children = described_class.children_trackers('UserStory')
      expect(children).to contain_exactly('Task', 'Test', 'Bug')
    end

    it 'returns empty array for leaf trackers' do
      expect(described_class.children_trackers('Task')).to eq([])
    end
  end
end
