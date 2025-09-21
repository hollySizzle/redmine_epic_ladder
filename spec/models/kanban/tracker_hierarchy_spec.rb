# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::TrackerHierarchy, type: :model do
  describe '.valid_parent?' do
    let(:epic_tracker) { double('Tracker', name: 'Epic') }
    let(:feature_tracker) { double('Tracker', name: 'Feature') }
    let(:user_story_tracker) { double('Tracker', name: 'UserStory') }
    let(:task_tracker) { double('Tracker', name: 'Task') }
    let(:test_tracker) { double('Tracker', name: 'Test') }
    let(:bug_tracker) { double('Tracker', name: 'Bug') }

    context '正常な親子関係の場合' do
      it 'Feature → Epic を許可する' do
        expect(described_class.valid_parent?(feature_tracker, epic_tracker)).to be true
      end

      it 'UserStory → Feature を許可する' do
        expect(described_class.valid_parent?(user_story_tracker, feature_tracker)).to be true
      end

      it 'Task → UserStory を許可する' do
        expect(described_class.valid_parent?(task_tracker, user_story_tracker)).to be true
      end

      it 'Test → UserStory を許可する' do
        expect(described_class.valid_parent?(test_tracker, user_story_tracker)).to be true
      end

      it 'Bug → UserStory を許可する' do
        expect(described_class.valid_parent?(bug_tracker, user_story_tracker)).to be true
      end

      it 'Bug → Feature を許可する' do
        expect(described_class.valid_parent?(bug_tracker, feature_tracker)).to be true
      end
    end

    context '不正な親子関係の場合' do
      it 'Task → Feature を拒否する' do
        expect(described_class.valid_parent?(task_tracker, feature_tracker)).to be false
      end

      it 'Epic → Feature を拒否する' do
        expect(described_class.valid_parent?(epic_tracker, feature_tracker)).to be false
      end

      it 'UserStory → Task を拒否する' do
        expect(described_class.valid_parent?(user_story_tracker, task_tracker)).to be false
      end
    end

    context 'nilが渡された場合' do
      it 'child_trackerがnilの場合はfalseを返す' do
        expect(described_class.valid_parent?(nil, epic_tracker)).to be false
      end

      it 'parent_trackerがnilの場合はfalseを返す' do
        expect(described_class.valid_parent?(task_tracker, nil)).to be false
      end
    end
  end

  describe '.allowed_children' do
    it 'Epicの許可された子要素を返す' do
      expect(described_class.allowed_children('Epic')).to eq(['Feature'])
    end

    it 'Featureの許可された子要素を返す' do
      expect(described_class.allowed_children('Feature')).to eq(['UserStory'])
    end

    it 'UserStoryの許可された子要素を返す' do
      expect(described_class.allowed_children('UserStory')).to contain_exactly('Task', 'Test', 'Bug')
    end

    it 'Taskの許可された子要素（なし）を返す' do
      expect(described_class.allowed_children('Task')).to eq([])
    end

    it '存在しないトラッカーの場合は空配列を返す' do
      expect(described_class.allowed_children('NonExistent')).to eq([])
    end
  end

  describe '.level' do
    it '各トラッカーの階層レベルを返す' do
      expect(described_class.level('Epic')).to eq(1)
      expect(described_class.level('Feature')).to eq(2)
      expect(described_class.level('UserStory')).to eq(3)
      expect(described_class.level('Task')).to eq(4)
      expect(described_class.level('Test')).to eq(4)
      expect(described_class.level('Bug')).to eq(4)
    end
  end

  describe '.validate_hierarchy' do
    let(:issue) { double('Issue') }
    let(:parent_issue) { double('Issue') }
    let(:child_tracker) { double('Tracker', name: 'Task') }
    let(:parent_tracker) { double('Tracker', name: 'UserStory') }

    before do
      allow(issue).to receive(:tracker).and_return(child_tracker)
      allow(issue).to receive(:parent).and_return(parent_issue)
      allow(parent_issue).to receive(:tracker).and_return(parent_tracker)
    end

    it '正常な階層の場合はtrueを返す' do
      expect(described_class.validate_hierarchy(issue)).to be true
    end

    it '親が存在しない場合はtrueを返す' do
      allow(issue).to receive(:parent).and_return(nil)
      expect(described_class.validate_hierarchy(issue)).to be true
    end

    it '不正な階層の場合はfalseを返す' do
      allow(child_tracker).to receive(:name).and_return('Epic')
      allow(parent_tracker).to receive(:name).and_return('Task')
      expect(described_class.validate_hierarchy(issue)).to be false
    end
  end
end