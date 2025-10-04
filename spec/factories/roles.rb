# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    position { 1 }
    assignable { true }
    permissions { [:view_issues, :add_issues, :edit_issues] }

    trait :with_kanban_permissions do
      permissions { [:view_issues, :add_issues, :edit_issues, :view_kanban, :manage_kanban] }
    end

    trait :with_version_permissions do
      permissions { [:view_issues, :manage_versions] }
    end

    trait :admin_role do
      permissions { Role.new.setable_permissions.map(&:name) }
    end
  end
end
