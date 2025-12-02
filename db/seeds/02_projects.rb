# frozen_string_literal: true

puts "🌸 === [2/5] プロジェクト・メンバー投入 === 🌸"

# ===== 桜商店プロジェクト投入 =====
puts "\n🏪 桜商店プロジェクトを投入中..."

projects_data = [
  {
    identifier: 'sakura-ec',
    name: '桜商店ECサイト開発',
    description: '伝統的な和菓子店のオンライン販売システム開発プロジェクト',
    homepage: 'https://sakura-shop.jp',
    is_public: true,
    parent_id: nil
  },
  {
    identifier: 'sakura-mobile',
    name: '桜商店モバイルアプリ',
    description: 'iOS/Android対応の和菓子注文アプリ',
    homepage: 'https://sakura-shop.jp/mobile',
    is_public: true,
    parent_id: nil
  },
  {
    identifier: 'naisys',
    name: '社内業務システム',
    description: '在庫管理・売上分析システム開発',
    homepage: '',
    is_public: false,
    parent_id: nil
  },
  {
    identifier: 'ai-recommend',
    name: 'AIレコメンド機能開発',
    description: '機械学習を活用した商品推薦システム',
    homepage: 'https://sakura-shop.jp/ai',
    is_public: false,
    parent_id: nil
  }
]

created_projects = {}

projects_data.each do |data|
  project = Project.find_or_initialize_by(identifier: data[:identifier])
  project.assign_attributes(
    name: data[:name],
    description: data[:description],
    homepage: data[:homepage],
    is_public: data[:is_public],
    status: 1  # アクティブ
  )

  if project.save
    created_projects[data[:identifier]] = project
    puts "  ✅ #{project.name}"
  else
    puts "  ❌ #{data[:name]} の作成に失敗: #{project.errors.full_messages.join(', ')}"
  end
end

# 親子関係を設定
if created_projects['sakura-ec'] && created_projects['sakura-mobile']
  created_projects['sakura-mobile'].update(parent_id: created_projects['sakura-ec'].id)
  puts "  📁 モバイルアプリをECサイトのサブプロジェクトに設定"
end

if created_projects['sakura-ec'] && created_projects['ai-recommend']
  created_projects['ai-recommend'].update(parent_id: created_projects['sakura-ec'].id)
  puts "  📁 AIレコメンドをECサイトのサブプロジェクトに設定"
end

# ===== プロジェクトモジュール有効化 =====
puts "\n🔌 プロジェクトモジュールを有効化中..."

# 桜商店ECサイトプロジェクトにrelease_kanbanモジュールを有効化
if created_projects['sakura-ec']
  sakura_ec = created_projects['sakura-ec']

  # 有効化するモジュール一覧
  enabled_modules = [
    'issue_tracking',
    'time_tracking',
    'news',
    'documents',
    'files',
    'wiki',
    'repository',
    'boards',
    'calendar',
    'gantt',
    'epic_ladder'
  ]

  sakura_ec.enabled_module_names = enabled_modules

  if sakura_ec.save
    puts "  ✅ 桜商店ECサイト: #{enabled_modules.size}個のモジュールを有効化"
    puts "    - epic_ladder モジュールを含む"
  else
    puts "  ❌ 桜商店ECサイトのモジュール有効化に失敗: #{sakura_ec.errors.full_messages.join(', ')}"
  end

  # カンバン用トラッカーをプロジェクトに追加
  kanban_trackers = Tracker.where(name: ['エピック', '機能', 'ユーザストーリ', '作業', '評価', '不具合'])
  new_trackers = kanban_trackers.reject { |t| sakura_ec.trackers.include?(t) }
  if new_trackers.any?
    sakura_ec.trackers << new_trackers
    puts "  ✅ カンバン用トラッカー #{new_trackers.count}個を有効化"
  else
    puts "  ℹ️  カンバン用トラッカーは既に有効化済み"
  end
end

# ===== 優先度設定投入 =====
puts "\n⭐ 優先度（Enumeration）を投入中..."

priorities_data = [
  { name: '低', position: 1, is_default: false },
  { name: '通常', position: 2, is_default: true },
  { name: '高', position: 3, is_default: false },
  { name: '緊急', position: 4, is_default: false },
  { name: '即座', position: 5, is_default: false }
]

priorities_data.each do |data|
  priority = IssuePriority.find_or_initialize_by(name: data[:name])
  priority.assign_attributes(
    position: data[:position],
    is_default: data[:is_default],
    active: true
  )

  if priority.save
    puts "  ✅ #{priority.name} (Position: #{priority.position}#{priority.is_default ? ', デフォルト' : ''})"
  else
    puts "  ❌ #{data[:name]} の作成に失敗: #{priority.errors.full_messages.join(', ')}"
  end
end

# ===== プロジェクトメンバー設定 =====
puts "\n👥 プロジェクトメンバーを設定中..."

sakura_ec = created_projects['sakura-ec']
if sakura_ec
  # ロールを取得または作成
  role = Role.find_or_create_by(name: '開発者') do |r|
    r.permissions = [:view_issues, :add_issues, :edit_issues, :delete_issues, :manage_versions, :view_time_entries]
    r.issues_visibility = 'all'
    r.position = 3
  end

  # ユーザーをメンバーに追加
  [
    User.find_by(login: 'tanaka'),
    User.find_by(login: 'suzuki'),
    User.find_by(login: 'sato'),
    User.find_by(login: 'watanabe'),
    User.find_by(login: 'yamada')
  ].compact.each do |user|
    member = Member.find_or_initialize_by(project: sakura_ec, user: user)
    member.roles = [role] if member.new_record?
    if member.save
      puts "  ✅ #{user.lastname} #{user.firstname} をメンバーに追加"
    else
      puts "  ❌ #{user.lastname} #{user.firstname} の追加に失敗: #{member.errors.full_messages.join(', ')}"
    end
  end
end

# ===== プラグイン設定投入 =====
puts "\n🔧 カンバンプラグイン設定を投入中..."

plugin_settings = {
  'epic_tracker' => 'エピック',
  'feature_tracker' => '機能',
  'user_story_tracker' => 'ユーザストーリ',
  'task_tracker' => '作業',
  'test_tracker' => '評価',
  'bug_tracker' => '不具合',
  # MCP API設定（グローバル有効）
  'mcp_enabled' => '1'
}

# Settingモデルを使用してプラグイン設定を保存
Setting.plugin_redmine_epic_ladder = plugin_settings
puts "  ✅ カンバントラッカー設定完了"
plugin_settings.each do |key, value|
  puts "    - #{key}: #{value}"
end

# ===== プロジェクト単位MCP設定 =====
puts "\n🔌 プロジェクト単位のMCP設定を投入中..."

# sakura-ecプロジェクトでMCPを有効化
if created_projects['sakura-ec']
  setting = EpicLadder::ProjectSetting.find_or_initialize_by(project: created_projects['sakura-ec'])
  setting.mcp_enabled = true
  if setting.save
    puts "  ✅ 桜商店ECサイト: MCP API有効化"
  else
    puts "  ❌ MCP設定の保存に失敗: #{setting.errors.full_messages.join(', ')}"
  end
end

# ai-recommendプロジェクトでもMCPを有効化
if created_projects['ai-recommend']
  setting = EpicLadder::ProjectSetting.find_or_initialize_by(project: created_projects['ai-recommend'])
  setting.mcp_enabled = true
  if setting.save
    puts "  ✅ AIレコメンド機能開発: MCP API有効化"
  else
    puts "  ❌ MCP設定の保存に失敗: #{setting.errors.full_messages.join(', ')}"
  end
end

puts "\n✅ [2/5] プロジェクト・メンバー投入完了"
