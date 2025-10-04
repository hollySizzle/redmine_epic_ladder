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
    initialize_with { Tracker.find_or_create_by(name: EpicGridTestConfig::TRACKER_NAMES[:epic]) }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    position { 1 }
  end

  # Feature Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :feature_tracker, class: 'Tracker' do
    initialize_with { Tracker.find_or_create_by(name: EpicGridTestConfig::TRACKER_NAMES[:feature]) }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    position { 2 }
  end

  # UserStory Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :user_story_tracker, class: 'Tracker' do
    initialize_with { Tracker.find_or_create_by(name: EpicGridTestConfig::TRACKER_NAMES[:user_story]) }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    position { 3 }
  end

  # Task Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :task_tracker, class: 'Tracker' do
    initialize_with { Tracker.find_or_create_by(name: EpicGridTestConfig::TRACKER_NAMES[:task]) }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    position { 4 }
  end

  # Test Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :test_tracker, class: 'Tracker' do
    initialize_with { Tracker.find_or_create_by(name: EpicGridTestConfig::TRACKER_NAMES[:test]) }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    position { 5 }
  end

  # Bug Tracker (テスト専用名で作成、find_or_create_byで再利用)
  factory :bug_tracker, class: 'Tracker' do
    initialize_with { Tracker.find_or_create_by(name: EpicGridTestConfig::TRACKER_NAMES[:bug]) }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
    position { 6 }
  end

  # Issue Status
  factory :issue_status, class: 'IssueStatus' do
    sequence(:name) { |n| "Status #{n}" }
    is_closed { false }
  end

  factory :closed_status, class: 'IssueStatus' do
    name { 'Closed' }
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
    association :tracker, factory: :epic_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority

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
    association :tracker, factory: :feature_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority

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
    association :tracker, factory: :user_story_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority

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
    association :tracker, factory: :task_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
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
    association :tracker, factory: :test_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority

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
    association :tracker, factory: :bug_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority

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
    association :tracker, factory: :epic_tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority

    after(:create) do |epic|
      # Feature 2個
      2.times do
        feature = create(:feature, parent: epic, project: epic.project)

        # 各FeatureにUserStory 2個
        2.times do
          story = create(:user_story, parent: feature, project: epic.project)

          # 各UserStoryにTask/Test/Bug各1個
          create(:task, parent: story, project: epic.project)
          create(:test, parent: story, project: epic.project)
          create(:bug, parent: story, project: epic.project)
        end
      end
    end
  end
end
