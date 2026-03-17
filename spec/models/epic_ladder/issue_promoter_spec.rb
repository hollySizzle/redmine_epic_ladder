# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::IssuePromoter, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:user) }

  let(:epic_tracker) { FactoryBot.create(:epic_tracker) }
  let(:feature_tracker) { FactoryBot.create(:feature_tracker) }
  let(:user_story_tracker) { FactoryBot.create(:user_story_tracker) }
  let(:task_tracker) { FactoryBot.create(:task_tracker) }
  let(:test_tracker) { FactoryBot.create(:test_tracker) }
  let(:bug_tracker) { FactoryBot.create(:bug_tracker) }

  let(:version_v1) { FactoryBot.create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }
  let(:priority) { IssuePriority.default || IssuePriority.first }

  before do
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
  end

  describe '.validate_promotable' do
    context '昇格可能なトラッカー' do
      let(:epic) { FactoryBot.create(:epic, project: project) }
      let(:feature) { FactoryBot.create(:feature, project: project, parent: epic) }
      let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature) }

      it 'Taskはvalid: trueを返す' do
        task = FactoryBot.create(:task, project: project, parent: user_story)
        result = described_class.validate_promotable(task)
        expect(result[:valid]).to be true
        expect(result[:error]).to be_nil
      end

      it 'Bugはvalid: trueを返す' do
        bug = FactoryBot.create(:bug, project: project, parent: user_story)
        result = described_class.validate_promotable(bug)
        expect(result[:valid]).to be true
        expect(result[:error]).to be_nil
      end

      it 'Testはvalid: trueを返す' do
        test_issue = FactoryBot.create(:test, project: project, parent: user_story)
        result = described_class.validate_promotable(test_issue)
        expect(result[:valid]).to be true
        expect(result[:error]).to be_nil
      end
    end

    context '昇格不可なトラッカー' do
      let(:epic) { FactoryBot.create(:epic, project: project) }
      let(:feature) { FactoryBot.create(:feature, project: project, parent: epic) }

      it 'UserStoryはvalid: falseを返す' do
        user_story = FactoryBot.create(:user_story, project: project, parent: feature)
        result = described_class.validate_promotable(user_story)
        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
      end

      it 'Featureはvalid: falseを返す' do
        result = described_class.validate_promotable(feature)
        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
      end

      it 'Epicはvalid: falseを返す' do
        result = described_class.validate_promotable(epic)
        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
      end
    end

    context '親USが存在しない' do
      it 'valid: falseを返す' do
        task = FactoryBot.create(:task, project: project, parent: nil)
        result = described_class.validate_promotable(task)
        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
      end
    end

    context '親USの上位にFeatureが存在しない' do
      it 'valid: falseを返す' do
        user_story = FactoryBot.create(:user_story, project: project, parent: nil)
        task = FactoryBot.create(:task, project: project, parent: user_story)
        result = described_class.validate_promotable(task)
        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
      end
    end
  end

  describe '.promote_to_user_story' do
    let(:epic) { FactoryBot.create(:epic, project: project) }
    let(:feature) { FactoryBot.create(:feature, project: project, parent: epic) }
    let(:user_story) { FactoryBot.create(:user_story, project: project, parent: feature, fixed_version: version_v1) }

    context '正常系' do
      let(:task) do
        FactoryBot.create(:task, project: project, parent: user_story, fixed_version: version_v1,
                                 start_date: Date.new(2025, 10, 1), due_date: Date.new(2025, 10, 5))
      end

      it '新USが作成される' do
        task # ensure all hierarchy issues are created first
        expect {
          described_class.promote_to_user_story(task, user: user)
        }.to change(Issue, :count).by(1)
      end

      it '新USがFeature配下に作成される' do
        result = described_class.promote_to_user_story(task, user: user)
        new_us = result[:new_user_story]
        expect(new_us.parent_id).to eq(feature.id)
        expect(new_us.tracker.name).to eq(user_story_tracker.name)
      end

      it '元issueの親が新USに付け替えられる' do
        result = described_class.promote_to_user_story(task, user: user)
        task.reload
        expect(task.parent_id).to eq(result[:new_user_story].id)
      end

      it '元の親USと新USがrelates関連で紐づく' do
        result = described_class.promote_to_user_story(task, user: user)
        relation = result[:relation]
        expect(relation.issue_from).to eq(user_story)
        expect(relation.issue_to).to eq(result[:new_user_story])
        expect(relation.relation_type).to eq('relates')
      end

      it '新USの件名がデフォルトで元issueの件名' do
        result = described_class.promote_to_user_story(task, user: user)
        expect(result[:new_user_story].subject).to eq(task.subject)
      end

      it '新USが元issueのバージョンを引き継ぐ' do
        result = described_class.promote_to_user_story(task, user: user)
        expect(result[:new_user_story].fixed_version).to eq(version_v1)
      end

      it '新USが元issueの優先度を引き継ぐ' do
        result = described_class.promote_to_user_story(task, user: user)
        expect(result[:new_user_story].priority).to eq(task.priority)
      end

      it '新USが元issueの日付を引き継ぐ' do
        result = described_class.promote_to_user_story(task, user: user)
        expect(result[:new_user_story].start_date).to eq(Date.new(2025, 10, 1))
        expect(result[:new_user_story].due_date).to eq(Date.new(2025, 10, 5))
      end

      it 'original_parent_usが返される' do
        result = described_class.promote_to_user_story(task, user: user)
        expect(result[:original_parent_us]).to eq(user_story)
      end
    end

    context 'us_subject指定時' do
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story) }

      it '指定した件名でUSが作成される' do
        result = described_class.promote_to_user_story(task, user: user, us_subject: 'カスタム件名')
        expect(result[:new_user_story].subject).to eq('カスタム件名')
      end
    end

    context 'target_feature指定時' do
      let(:task) { FactoryBot.create(:task, project: project, parent: user_story) }
      let(:another_feature) { FactoryBot.create(:feature, project: project, parent: epic) }

      it '指定したFeature配下にUSが作成される' do
        result = described_class.promote_to_user_story(task, user: user, target_feature: another_feature)
        expect(result[:new_user_story].parent_id).to eq(another_feature.id)
      end
    end

    context 'Bugからの昇格' do
      let(:bug) { FactoryBot.create(:bug, project: project, parent: user_story) }

      it '新USが作成され、Bugの親が新USになる' do
        result = described_class.promote_to_user_story(bug, user: user)
        bug.reload
        expect(bug.parent_id).to eq(result[:new_user_story].id)
        expect(result[:new_user_story].tracker.name).to eq(user_story_tracker.name)
      end
    end

    context 'Testからの昇格' do
      let(:test_issue) { FactoryBot.create(:test, project: project, parent: user_story) }

      it '新USが作成され、Testの親が新USになる' do
        result = described_class.promote_to_user_story(test_issue, user: user)
        test_issue.reload
        expect(test_issue.parent_id).to eq(result[:new_user_story].id)
        expect(result[:new_user_story].tracker.name).to eq(user_story_tracker.name)
      end
    end
  end
end
