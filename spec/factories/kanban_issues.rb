# frozen_string_literal: true

FactoryBot.define do
  # シンプルな Issue factory
  factory :issue do
    project
    association :tracker
    association :author, factory: :user
    sequence(:subject) { |n| "Test Issue #{n}" }
    description { 'Test issue description' }

    # デフォルト値（見つからない場合は作成）
    status { IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false) }
    priority { IssuePriority.first || IssuePriority.create!(name: 'Normal', position: 1) }

    trait :epic do
      tracker { Tracker.find_or_create_by!(name: 'Epic') { |t| t.default_status = IssueStatus.first } }
    end

    trait :feature do
      tracker { Tracker.find_or_create_by!(name: 'Feature') { |t| t.default_status = IssueStatus.first } }
      association :parent, factory: [:issue, :epic]
    end
  end
end
