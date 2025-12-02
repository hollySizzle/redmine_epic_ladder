# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::TrackerHierarchy, type: :model do
  describe '.tracker_names' do
    it 'returns tracker name mappings' do
      names = described_class.tracker_names

      expect(names).to include(
        epic: epic_tracker_name,
        feature: feature_tracker_name,
        user_story: user_story_tracker_name,
        task: task_tracker_name,
        test: test_tracker_name,
        bug: bug_tracker_name
      )
    end
  end

  describe '.level' do
    it 'returns correct hierarchy level for Epic' do
      expect(described_class.level(epic_tracker_name)).to eq(0)
    end

    it 'returns correct hierarchy level for Feature' do
      expect(described_class.level(feature_tracker_name)).to eq(1)
    end

    it 'returns correct hierarchy level for UserStory' do
      expect(described_class.level(user_story_tracker_name)).to eq(2)
    end

    it 'returns correct hierarchy level for Task/Test/Bug' do
      expect(described_class.level(task_tracker_name)).to eq(3)
      expect(described_class.level(test_tracker_name)).to eq(3)
      expect(described_class.level(bug_tracker_name)).to eq(3)
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
      expect(described_class.root_tracker).to eq(epic_tracker_name)
    end
  end

  describe '.children_trackers' do
    it 'returns valid child trackers for Epic' do
      children = described_class.children_trackers(epic_tracker_name)
      expect(children).to eq([feature_tracker_name])
    end

    it 'returns valid child trackers for Feature' do
      children = described_class.children_trackers(feature_tracker_name)
      expect(children).to eq([user_story_tracker_name])
    end

    it 'returns valid child trackers for UserStory' do
      children = described_class.children_trackers(user_story_tracker_name)
      expect(children).to contain_exactly(task_tracker_name, test_tracker_name, bug_tracker_name)
    end

    it 'returns empty array for leaf trackers' do
      expect(described_class.children_trackers(task_tracker_name)).to eq([])
    end
  end
end
