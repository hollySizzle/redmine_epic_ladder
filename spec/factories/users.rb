# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:login) { |n| "user#{n}" }
    sequence(:firstname) { |n| "First#{n}" }
    sequence(:lastname) { |n| "Last#{n}" }
    sequence(:mail) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    status { User::STATUS_ACTIVE }
    admin { false }
    language { 'en' }

    trait :admin do
      admin { true }
    end
  end
end