# frozen_string_literal: true

FactoryBot.define do
  # Generic Issue (base factory)
  factory :issue, class: 'Issue' do
    sequence(:subject) { |n| "Issue #{n}" }
    association :project
    association :tracker
    association :author, factory: :user
    status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    priority { IssuePriority.default || IssuePriority.first }
  end

  # Epic Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :epic_tracker, class: 'Tracker' do
    initialize_with do
      name = EpicGridTestConfig::TRACKER_NAMES[:epic]

      # 既存レコードを検索
      Tracker.find_by(name: name) || begin
        # 新規作成
        status = IssueStatus.find_by(name: 'New') || IssueStatus.first
        tracker = Tracker.new(name: name, default_status: status, position: 1)

        begin
          tracker.save!
          tracker
        rescue ActiveRecord::RecordInvalid => e
          # 並行実行で別スレッドが先に作成した場合、再検索
          # エラーがnameフィールドの重複に関するものか確認
          if e.record.errors[:name].any? || e.message =~ /name/i
            found = Tracker.find_by(name: name)
            found || raise # 見つからなければ元のエラーをraise
          else
            raise
          end
        end
      end
    end
  end

  # Feature Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :feature_tracker, class: 'Tracker' do
    initialize_with do
      name = EpicGridTestConfig::TRACKER_NAMES[:feature]
      Tracker.find_by(name: name) || begin
        status = IssueStatus.find_by(name: 'New') || IssueStatus.first
        tracker = Tracker.new(name: name, default_status: status, position: 2)
        begin
          tracker.save!
          tracker
        rescue ActiveRecord::RecordInvalid => e
          (e.record.errors[:name].any? || e.message =~ /name/i) ? (Tracker.find_by(name: name) || raise) : raise
        end
      end
    end
  end

  # UserStory Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :user_story_tracker, class: 'Tracker' do
    initialize_with do
      name = EpicGridTestConfig::TRACKER_NAMES[:user_story]
      Tracker.find_by(name: name) || begin
        status = IssueStatus.find_by(name: 'New') || IssueStatus.first
        tracker = Tracker.new(name: name, default_status: status, position: 3)
        begin
          tracker.save!
          tracker
        rescue ActiveRecord::RecordInvalid => e
          (e.record.errors[:name].any? || e.message =~ /name/i) ? (Tracker.find_by(name: name) || raise) : raise
        end
      end
    end
  end

  # Task Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :task_tracker, class: 'Tracker' do
    initialize_with do
      name = EpicGridTestConfig::TRACKER_NAMES[:task]
      Tracker.find_by(name: name) || begin
        status = IssueStatus.find_by(name: 'New') || IssueStatus.first
        tracker = Tracker.new(name: name, default_status: status, position: 4)
        begin
          tracker.save!
          tracker
        rescue ActiveRecord::RecordInvalid => e
          (e.record.errors[:name].any? || e.message =~ /name/i) ? (Tracker.find_by(name: name) || raise) : raise
        end
      end
    end
  end

  # Test Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :test_tracker, class: 'Tracker' do
    initialize_with do
      name = EpicGridTestConfig::TRACKER_NAMES[:test]
      Tracker.find_by(name: name) || begin
        status = IssueStatus.find_by(name: 'New') || IssueStatus.first
        tracker = Tracker.new(name: name, default_status: status, position: 5)
        begin
          tracker.save!
          tracker
        rescue ActiveRecord::RecordInvalid => e
          (e.record.errors[:name].any? || e.message =~ /name/i) ? (Tracker.find_by(name: name) || raise) : raise
        end
      end
    end
  end

  # Bug Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :bug_tracker, class: 'Tracker' do
    initialize_with do
      name = EpicGridTestConfig::TRACKER_NAMES[:bug]
      Tracker.find_by(name: name) || begin
        status = IssueStatus.find_by(name: 'New') || IssueStatus.first
        tracker = Tracker.new(name: name, default_status: status, position: 6)
        begin
          tracker.save!
          tracker
        rescue ActiveRecord::RecordInvalid => e
          (e.record.errors[:name].any? || e.message =~ /name/i) ? (Tracker.find_by(name: name) || raise) : raise
        end
      end
    end
  end

  # Issue Status
  factory :issue_status, class: 'IssueStatus' do
    sequence(:name) { |n| "Status #{n}" }
    is_closed { false }
  end

  factory :closed_status, class: 'IssueStatus' do
    initialize_with { IssueStatus.find_or_create_by(name: 'Closed') { |s| s.is_closed = true } }
    is_closed { true }
  end

  # Issue Priority
  factory :issue_priority, class: 'IssuePriority' do
    sequence(:name) { |n| "Priority #{n}" }
    position { 1 }
    is_default { false }
  end

  # Epic Issue
  factory :epic, class: 'Issue' do
    sequence(:subject) { |n| "Epic #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :epic_tracker

    trait :with_features do
      after(:create) do |epic|
        create_list(:feature, 3, parent: epic, project: epic.project)
      end
    end

    trait :with_version do
      association :fixed_version, factory: :version
    end
  end

  # Feature Issue
  factory :feature, class: 'Issue' do
    sequence(:subject) { |n| "Feature #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :feature_tracker

    trait :with_parent_epic do
      association :parent, factory: :epic
    end

    trait :with_version do
      association :fixed_version, factory: :version
    end

    trait :with_user_stories do
      after(:create) do |feature|
        create_list(:user_story, 2, parent: feature, project: feature.project)
      end
    end
  end

  # UserStory Issue
  factory :user_story, class: 'Issue' do
    sequence(:subject) { |n| "User Story #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :user_story_tracker

    trait :with_parent_feature do
      association :parent, factory: :feature
    end

    trait :with_version do
      association :fixed_version, factory: :version
    end

    trait :with_tasks do
      after(:create) do |story|
        create_list(:task, 2, parent: story, project: story.project)
      end
    end

    trait :with_tests do
      after(:create) do |story|
        create_list(:test, 2, parent: story, project: story.project)
      end
    end

    trait :with_children do
      after(:create) do |story|
        create(:task, parent: story, project: story.project)
        create(:test, parent: story, project: story.project)
        create(:bug, parent: story, project: story.project)
      end
    end
  end

  # Task Issue
  factory :task, class: 'Issue' do
    sequence(:subject) { |n| "Task #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :task_tracker
    estimated_hours { 8 }
    done_ratio { 0 }

    trait :with_parent_story do
      association :parent, factory: :user_story
    end
  end

  # Test Issue
  factory :test, class: 'Issue' do
    sequence(:subject) { |n| "Test #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :test_tracker

    trait :with_parent_story do
      association :parent, factory: :user_story
    end

    trait :passed do
      association :status, factory: :closed_status
    end
  end

  # Bug Issue
  factory :bug, class: 'Issue' do
    sequence(:subject) { |n| "Bug #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :bug_tracker

    trait :with_parent_story do
      association :parent, factory: :user_story
    end

    trait :critical do
      association :priority, factory: :issue_priority, name: 'Critical', position: 1
    end

    trait :resolved do
      association :status, factory: :closed_status
    end
  end

  # 完全な階層データ (Epic → Feature → UserStory → Task/Test/Bug)
  factory :complete_hierarchy, class: 'Issue' do
    sequence(:subject) { |n| "Complete Epic #{n}" }
    association :project
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    association :tracker, factory: :epic_tracker

    after(:create) do |epic|
      # Feature 2個
      2.times do
        epic.reload # lock_versionを最新化
        feature = create(:feature, parent: epic, project: epic.project)

        # 各FeatureにUserStory 2個
        2.times do
          feature.reload # lock_versionを最新化
          story = create(:user_story, parent: feature, project: epic.project)

          # 各UserStoryにTask/Test/Bug各1個
          story.reload # lock_versionを最新化
          create(:task, parent: story, project: epic.project)
          story.reload # lock_versionを最新化
          create(:test, parent: story, project: epic.project)
          story.reload # lock_versionを最新化
          create(:bug, parent: story, project: epic.project)
        end
      end
    end
  end
end
