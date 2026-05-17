# frozen_string_literal: true

puts "🌸 === [6/6] MCPサンドボックス検証データ投入 === 🌸"

unless Rails.env.development?
  puts "❌ このスクリプトは開発環境でのみ実行可能です"
  exit
end

ai_recommend = Project.find_by(identifier: 'ai-recommend')
unless ai_recommend
  puts "  ❌ AIレコメンド機能開発プロジェクトが見つかりません"
  exit
end

admin_user = User.find_by(login: 'admin') || User.find_by(login: 'admin_kanban') || User.find_by(login: 'tanaka')
unless admin_user
  puts "  ❌ MCPサンドボックス用ユーザーが見つかりません"
  exit
end

epic_tracker = Tracker.find_by(name: 'エピック')
feature_tracker = Tracker.find_by(name: '機能')
user_story_tracker = Tracker.find_by(name: 'ユーザストーリ')
task_tracker = Tracker.find_by(name: '作業')
test_tracker = Tracker.find_by(name: '評価')
bug_tracker = Tracker.find_by(name: '不具合')

status_new = IssueStatus.find_by(name: '新規') || IssueStatus.first
status_in_progress = IssueStatus.find_by(name: '進行中') || status_new
priority_normal = IssuePriority.find_by(name: '通常') || IssuePriority.default || IssuePriority.first

required_records = {
  epic_tracker: epic_tracker,
  feature_tracker: feature_tracker,
  user_story_tracker: user_story_tracker,
  task_tracker: task_tracker,
  test_tracker: test_tracker,
  bug_tracker: bug_tracker,
  status_new: status_new,
  priority_normal: priority_normal
}

missing = required_records.select { |_name, record| record.nil? }.keys
if missing.any?
  puts "  ❌ 必須データが不足しています: #{missing.join(', ')}"
  exit
end

[epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker].each do |tracker|
  ai_recommend.trackers << tracker unless ai_recommend.trackers.include?(tracker)
end

setting = EpicLadder::ProjectSetting.find_or_initialize_by(project: ai_recommend)
setting.mcp_enabled = true

alpha = ai_recommend.versions.find_or_create_by!(name: 'MCP-SEED Alpha') do |version|
  version.description = 'MCP検証用Alphaバージョン'
  version.effective_date = Date.parse('2026-10-31')
  version.status = 'open'
end
beta = ai_recommend.versions.find_or_create_by!(name: 'MCP-SEED Beta') do |version|
  version.description = 'MCP検証用Betaバージョン'
  version.effective_date = Date.parse('2026-11-30')
  version.status = 'open'
end
gamma = ai_recommend.versions.find_or_create_by!(name: 'MCP-SEED Gamma') do |version|
  version.description = 'MCP検証用Gammaバージョン'
  version.effective_date = Date.parse('2026-12-31')
  version.status = 'open'
end

[alpha, beta, gamma].each do |version|
  version.update!(status: 'open') unless version.status == 'open'
end

puts "  ✅ MCP-SEED Versions: #{[alpha.name, beta.name, gamma.name].join(', ')}"

def find_or_create_seed_issue(project:, tracker:, subject:, attrs:)
  issue = project.issues.find_or_initialize_by(tracker: tracker, subject: subject)
  issue.assign_attributes(attrs)
  issue.save!
  issue
end

epic = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: epic_tracker,
  subject: 'MCP-SEED Epic',
  attrs: {
    description: 'MCP検証用の固定Epic',
    status: status_new,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    fixed_version: alpha
  }
)

feature = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: feature_tracker,
  subject: 'MCP-SEED Feature',
  attrs: {
    description: 'MCP検証用の固定Feature',
    status: status_new,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    parent_issue_id: epic.id,
    fixed_version: alpha
  }
)

inquiry_feature = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: feature_tracker,
  subject: 'MCP-SEED 問合せ Feature',
  attrs: {
    description: 'create_inquiry_tool検証用の固定問合せFeature',
    status: status_new,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    parent_issue_id: epic.id,
    fixed_version: alpha
  }
)

setting.inquiry_feature_id = inquiry_feature.id
setting.save!
puts "  ✅ inquiry_feature_id: ##{inquiry_feature.id}"

user_story = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: user_story_tracker,
  subject: 'MCP-SEED UserStory',
  attrs: {
    description: 'MCP検証用の固定UserStory。親チケット進捗派生の検証にも使う。',
    status: status_in_progress,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    parent_issue_id: feature.id,
    fixed_version: alpha
  }
)

task = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: task_tracker,
  subject: 'MCP-SEED Task',
  attrs: {
    description: 'update_issue_progress_tool正常系用のleaf Task',
    status: status_new,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    parent_issue_id: user_story.id,
    fixed_version: alpha,
    done_ratio: 0
  }
)

bug = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: bug_tracker,
  subject: 'MCP-SEED Bug',
  attrs: {
    description: 'relation/promote検証用の固定Bug',
    status: status_new,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    parent_issue_id: user_story.id,
    fixed_version: alpha
  }
)

test_issue = find_or_create_seed_issue(
  project: ai_recommend,
  tracker: test_tracker,
  subject: 'MCP-SEED Test',
  attrs: {
    description: 'MCP検証用の固定Test',
    status: status_new,
    priority: priority_normal,
    author: admin_user,
    assigned_to: admin_user,
    parent_issue_id: user_story.id,
    fixed_version: alpha
  }
)

puts "  ✅ MCP-SEED Issues: ##{epic.id}, ##{feature.id}, ##{user_story.id}, ##{task.id}, ##{bug.id}, ##{test_issue.id}"

text_field = IssueCustomField.find_or_initialize_by(name: 'MCP Sandbox Text')
text_field.assign_attributes(
  field_format: 'string',
  is_for_all: false,
  is_required: false,
  trackers: [task_tracker, bug_tracker, test_tracker, user_story_tracker]
)
text_field.save!

ai_recommend.issue_custom_fields << text_field unless ai_recommend.issue_custom_fields.include?(text_field)
puts "  ✅ IssueCustomField: #{text_field.name}"

puts "\n✅ [6/6] MCPサンドボックス検証データ投入完了"
