# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    position { 1 }
    assignable { true }
    permissions { [:view_issues, :add_issues, :edit_issues] }

    trait :with_kanban_permissions do
      permissions { [:view_issues, :add_issues, :edit_issues, :view_kanban, :manage_kanban, :manage_versions] }
    end

    trait :with_version_permissions do
      permissions { [:view_issues, :manage_versions] }
    end

    trait :admin_role do
      permissions { Role.new.setable_permissions.map(&:name) }
    end

    trait :with_epic_grid_permissions do
      permissions { [:view_issues, :add_issues, :edit_issues, :view_epic_grid, :manage_epic_grid, :manage_versions] }
    end

    trait :with_view_epic_grid_only do
      permissions { [:view_issues, :view_epic_grid] }
    end
  end
end
