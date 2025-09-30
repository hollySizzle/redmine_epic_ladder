# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Test Project #{n}" }
    sequence(:identifier) { |n| "test-project-#{n}" }
    status { Project::STATUS_ACTIVE }
    is_public { false }

    trait :with_kanban_module do
      after(:create) do |project|
        project.enabled_modules.create!(name: 'kanban') unless project.module_enabled?('kanban')
      end
    end

    trait :with_trackers do
      after(:create) do |project|
        epic = Tracker.find_or_create_by!(name: 'Epic') do |t|
          t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
        end
        feature = Tracker.find_or_create_by!(name: 'Feature') do |t|
          t.default_status = IssueStatus.first || IssueStatus.create!(name: 'New', is_closed: false)
        end

        project.trackers << epic unless project.trackers.include?(epic)
        project.trackers << feature unless project.trackers.include?(feature)
      end
    end
  end
end