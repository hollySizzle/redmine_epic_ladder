# frozen_string_literal: true

FactoryBot.define do
  factory :mcp_tool_hint, class: 'EpicLadder::McpToolHint' do
    association :project
    tool_key { 'create_task' }
    hint_text { 'テスト用ヒント' }
    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :for_add_issue_comment do
      tool_key { 'add_issue_comment' }
      hint_text { 'コメント追加時のヒント' }
    end

    trait :for_create_epic do
      tool_key { 'create_epic' }
      hint_text { 'Epic作成時のヒント' }
    end
  end
end
