# frozen_string_literal: true

FactoryBot.define do
  factory :version do
    project
    sequence(:name) { |n| "Version #{n}" }
    status { 'open' }
    sharing { 'none' }

    trait :closed do
      status { 'closed' }
    end
  end
end