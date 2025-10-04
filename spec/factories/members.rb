# frozen_string_literal: true

FactoryBot.define do
  factory :member do
    association :user
    association :project

    after(:build) do |member|
      member.roles << (member.roles.first || create(:role)) if member.roles.empty?
    end

    trait :with_kanban_role do
      after(:build) do |member|
        member.roles = [create(:role, :with_kanban_permissions)]
      end
    end

    trait :admin_member do
      after(:build) do |member|
        member.roles = [create(:role, :admin_role)]
      end
    end
  end
end
