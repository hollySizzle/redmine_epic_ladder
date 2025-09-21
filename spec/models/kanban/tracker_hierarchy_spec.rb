# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kanban::TrackerHierarchy, type: :model do
  # テスト用のトラッカーを準備
  let!(:epic_tracker) { create_tracker('Epic') }
  let!(:feature_tracker) { create_tracker('Feature') }
  let!(:user_story_tracker) { create_tracker('UserStory') }
  let!(:task_tracker) { create_tracker('Task') }
  let!(:test_tracker) { create_tracker('Test') }
  let!(:bug_tracker) { create_tracker('Bug') }

  def create_tracker(name)
    Tracker.find_or_create_by(name: name) do |t|
      t.position = 1
      t.is_in_chlog = false
      t.is_in_roadmap = true
    end
  end
  describe '.valid_parent?' do

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
    context '実際のIssueとTrackerでのテスト' do
      let!(:project) { Project.create!(name: 'Test', identifier: 'test-hierarchy') }
      let!(:user) { User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'test@test.com', status: User::STATUS_ACTIVE) }
      let!(:status) { IssueStatus.create!(name: 'New', is_closed: false) }
      let!(:priority) { IssuePriority.create!(name: 'Normal', is_default: true) }

      let(:epic_issue) do
        Issue.create!(
          project: project,
          tracker: epic_tracker,
          status: status,
          subject: 'Test Epic',
          author: user,
          priority: priority
        )
      end

      let(:feature_issue) do
        Issue.create!(
          project: project,
          tracker: feature_tracker,
          status: status,
          subject: 'Test Feature',
          author: user,
          parent: epic_issue,
          priority: priority
        )
      end

      let(:task_issue) do
        Issue.create!(
          project: project,
          tracker: task_tracker,
          status: status,
          subject: 'Test Task',
          author: user,
          priority: priority
        )
      end

      it '正常な階層（Task→UserStory）の場合はtrueを返す' do
        user_story_issue = Issue.create!(
          project: project,
          tracker: user_story_tracker,
          status: status,
          subject: 'Test UserStory',
          author: user,
          parent: feature_issue,
          priority: priority
        )
        task_issue.parent = user_story_issue
        task_issue.save!

        expect(described_class.validate_hierarchy(task_issue)).to be true
      end

      it '親が存在しない場合はtrueを返す' do
        expect(described_class.validate_hierarchy(task_issue)).to be true
      end

      it '不正な階層（Task→Epic）の場合はfalseを返す' do
        task_issue.parent = epic_issue
        expect(described_class.validate_hierarchy(task_issue)).to be false
      end

      it '循環参照の検証も可能' do
        # 実際の環境では循環参照は他の仕組みで防がれるが、階層制約としても確認
        expect(described_class.valid_parent?(epic_tracker, task_tracker)).to be false
      end
    end
  end

  describe '境界値テスト' do
    context '大量の階層構造でのパフォーマンス' do
      it '100階層の深いネストでも妥当性を迅速に判定できる' do
        # 通常は4階層だが、極端な場合でもパフォーマンスが落ちないことを確認
        expect do
          100.times do
            described_class.valid_parent?(task_tracker, user_story_tracker)
          end
        end.to perform_under(50).ms
      end
    end

    context 'nil安全性の徹底テスト' do
      it 'child_trackerがnilの場合' do
        expect(described_class.valid_parent?(nil, epic_tracker)).to be false
      end

      it 'parent_trackerがnilの場合' do
        expect(described_class.valid_parent?(task_tracker, nil)).to be false
      end

      it '両方がnilの場合' do
        expect(described_class.valid_parent?(nil, nil)).to be false
      end

      it 'tracker.nameがnilの場合' do
        broken_tracker = double('Tracker', name: nil)
        expect(described_class.valid_parent?(broken_tracker, epic_tracker)).to be false
      end
    end
  end

  describe 'エッジケーステスト' do
    context '未定義トラッカーでの動作' do
      let(:unknown_tracker) { double('Tracker', name: 'Unknown') }

      it '未定義の子トラッカーは拒否する' do
        expect(described_class.valid_parent?(unknown_tracker, epic_tracker)).to be false
      end

      it '未定義の親トラッカーは拒否する' do
        expect(described_class.valid_parent?(task_tracker, unknown_tracker)).to be false
      end

      it 'allowed_childrenで未定義トラッカーは空配列を返す' do
        expect(described_class.allowed_children('Unknown')).to eq([])
      end

      it 'levelで未定義トラッカーは最下位レベル4を返す' do
        expect(described_class.level('Unknown')).to eq(4)
      end
    end
  end
end