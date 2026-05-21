# frozen_string_literal: true

FactoryBot.define do
  factory :gantt_issue, class: 'Issue' do
    sequence(:subject) { |n| "Gantt Task #{n}" }
    association :project
    association :tracker
    association :author, factory: :user
    association :status, factory: :issue_status
    association :priority, factory: :issue_priority
    
    # 日付を持つタスク
    trait :with_dates do
      start_date { Date.today }
      due_date { Date.today + 7.days }
    end
    
    # 長期タスク
    trait :long_term do
      start_date { Date.today }
      due_date { Date.today + 90.days }
    end
    
    # 過去のタスク
    trait :past do
      start_date { Date.today - 30.days }
      due_date { Date.today - 23.days }
    end
    
    # 未来のタスク
    trait :future do
      start_date { Date.today + 30.days }
      due_date { Date.today + 37.days }
    end
    
    # 親タスク
    trait :parent do
      after(:create) do |issue|
        create_list(:gantt_issue, 3, :with_dates, parent: issue, project: issue.project)
      end
    end
    
    # 完了タスク
    trait :closed do
      association :status, factory: :issue_status, name: 'Closed', is_closed: true
      done_ratio { 100 }
    end
    
    # 高優先度タスク
    trait :high_priority do
      association :priority, factory: :issue_priority, name: 'High', position: 1
    end
    
    # カスタムフィールド付き
    trait :with_custom_fields do
      after(:create) do |issue|
        custom_field = CustomField.find_or_create_by!(
          name: 'Gantt Custom Field',
          field_format: 'string',
          is_required: false
        ) do |cf|
          cf.type = 'IssueCustomField'
          cf.projects << issue.project
        end
        
        issue.custom_field_values = { custom_field.id => 'Custom Value' }
        issue.save!
      end
    end
  end
  
  # パフォーマンステスト用の大量データ生成
  factory :bulk_gantt_issues, class: 'Issue' do
    transient do
      count { 100 }
      date_range { 365 }
    end
    
    after(:build) do |_, evaluator|
      issues = []
      evaluator.count.times do |i|
        issues << {
          project_id: evaluator.project.id,
          tracker_id: evaluator.project.trackers.first.id,
          author_id: evaluator.author.id,
          subject: "Bulk Task #{i}",
          start_date: Date.today + (i % evaluator.date_range).days,
          due_date: Date.today + ((i % evaluator.date_range) + 7).days
        }
      end
      Issue.insert_all(issues)
    end
  end
end