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

    # セキュリティ通知メールを送信しない
    after(:build) do |user|
      def user.deliver_security_notification
        # メール送信をスキップ
      end
    end

    trait :admin do
      admin { true }
    end
  end
end