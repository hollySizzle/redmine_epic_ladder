# frozen_string_literal: true

puts "🌸 === 桜商店カンバンテストデータ投入開始 === 🌸"

# 開発環境のみで実行
unless Rails.env.development?
  puts "❌ このスクリプトは開発環境でのみ実行可能です"
  exit
end

# ===== Redmine基本ステータス投入 =====
puts "\n🏷️ Redmine基本ステータスを投入中..."

statuses_data = [
  { id: 1, name: '新規', is_closed: false, position: 1, description: '新しく作成されたチケット' },
  { id: 2, name: '進行中', is_closed: false, position: 2, description: '作業が進行中のチケット' },
  { id: 3, name: '解決済み', is_closed: false, position: 3, description: '作業が完了したチケット' },
  { id: 4, name: 'フィードバック', is_closed: false, position: 4, description: 'フィードバック待ちのチケット' },
  { id: 5, name: '終了', is_closed: true, position: 5, description: '完全に終了したチケット' },
  { id: 6, name: '却下', is_closed: true, position: 6, description: '却下されたチケット' }
]

statuses_data.each do |data|
  status = IssueStatus.find_or_initialize_by(id: data[:id])
  status.assign_attributes(
    name: data[:name],
    is_closed: data[:is_closed],
    position: data[:position],
    description: data[:description]
  )

  if status.save
    puts "  ✅ #{status.name} (ID: #{status.id})"
  else
    puts "  ❌ #{data[:name]} の作成に失敗: #{status.errors.full_messages.join(', ')}"
  end
end

# ===== カンバン用日本語トラッカー投入 =====
puts "\n📋 カンバン用日本語トラッカーを投入中..."

trackers_data = [
  { id: 101, name: 'エピック', description: '大きな機能やビジネス価値を表すトラッカー', position: 10 },
  { id: 102, name: '機能', description: '具体的な機能を表すトラッカー', position: 11 },
  { id: 103, name: 'ユーザストーリ', description: 'ユーザー視点での要求を表すトラッカー', position: 12 },
  { id: 104, name: '作業', description: '具体的な作業を表すトラッカー', position: 13 },
  { id: 105, name: '評価', description: '品質評価項目を表すトラッカー', position: 14 },
  { id: 106, name: '不具合', description: '不具合を表すトラッカー', position: 15 }
]

trackers_data.each do |data|
  tracker = Tracker.find_or_initialize_by(id: data[:id])
  tracker.assign_attributes(
    name: data[:name],
    description: data[:description],
    position: data[:position],
    default_status_id: 1,
    is_in_roadmap: true,
    fields_bits: 0
  )

  if tracker.save
    puts "  ✅ #{tracker.name} (ID: #{tracker.id})"
  else
    puts "  ❌ #{data[:name]} の作成に失敗: #{tracker.errors.full_messages.join(', ')}"
  end
end

# ===== 桜商店チームユーザー投入 =====
puts "\n👥 桜商店チームユーザーを投入中..."

users_data = [
  {
    login: 'tanaka',
    firstname: '太郎',
    lastname: '田中',
    mail: 'tanaka@sakura-shop.jp',
    language: 'ja',
    admin: false,
    role: 'プロジェクトマネージャー'
  },
  {
    login: 'suzuki',
    firstname: '花子',
    lastname: '鈴木',
    mail: 'suzuki@sakura-shop.jp',
    language: 'ja',
    admin: false,
    role: 'チームリーダー'
  },
  {
    login: 'sato',
    firstname: '一郎',
    lastname: '佐藤',
    mail: 'sato@sakura-shop.jp',
    language: 'ja',
    admin: false,
    role: 'シニアデベロッパー'
  },
  {
    login: 'watanabe',
    firstname: '美咲',
    lastname: '渡辺',
    mail: 'watanabe@sakura-shop.jp',
    language: 'ja',
    admin: false,
    role: 'ジュニアデベロッパー'
  },
  {
    login: 'yamada',
    firstname: '次郎',
    lastname: '山田',
    mail: 'yamada@sakura-shop.jp',
    language: 'ja',
    admin: false,
    role: 'QAエンジニア'
  },
  {
    login: 'admin_kanban',
    firstname: '管理',
    lastname: 'かんばん',
    mail: 'admin@sakura-shop.jp',
    language: 'ja',
    admin: true,
    role: 'システム管理者'
  }
]

users_data.each do |data|
  user = User.find_or_initialize_by(login: data[:login])
  user.assign_attributes(
    firstname: data[:firstname],
    lastname: data[:lastname],
    mail: data[:mail],
    language: data[:language],
    admin: data[:admin],
    status: 1  # アクティブ
  )

  if user.save
    puts "  ✅ #{user.lastname} #{user.firstname} (#{data[:role]})"
  else
    puts "  ❌ #{data[:lastname]} #{data[:firstname]} の作成に失敗: #{user.errors.full_messages.join(', ')}"
  end
end

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
    parent_id: nil  # 後で設定
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
    parent_id: nil  # 後で設定
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
    'release_kanban'  # カンバンモジュール追加
  ]

  sakura_ec.enabled_module_names = enabled_modules

  if sakura_ec.save
    puts "  ✅ 桜商店ECサイト: #{enabled_modules.size}個のモジュールを有効化"
    puts "    - release_kanban モジュールを含む"
  else
    puts "  ❌ 桜商店ECサイトのモジュール有効化に失敗: #{sakura_ec.errors.full_messages.join(', ')}"
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

# ===== プラグイン設定投入 =====
puts "\n🔧 カンバンプラグイン設定を投入中..."

plugin_settings = {
  'epic_tracker' => 'エピック',
  'feature_tracker' => '機能',
  'user_story_tracker' => 'ユーザストーリ',
  'task_tracker' => '作業',
  'test_tracker' => '評価',
  'bug_tracker' => '不具合'
}

# Settingモデルを使用してプラグイン設定を保存
Setting.plugin_redmine_release_kanban = plugin_settings
puts "  ✅ カンバントラッカー設定完了"
plugin_settings.each do |key, value|
  puts "    - #{key}: #{value}"
end

# ===== 投入結果確認 =====
puts "\n📊 === 投入結果確認 ==="
puts "  トラッカー数: #{Tracker.count}"
puts "  ユーザー数: #{User.count}"
puts "  プロジェクト数: #{Project.count}"
puts "  優先度数: #{IssuePriority.count}"
puts "  プラグイン設定: #{Setting.plugin_redmine_release_kanban.present? ? '設定済み' : '未設定'}"

puts "\n🌸 === 桜商店カンバンテストデータ投入完了！ === 🌸"
puts "以下のコマンドで実行:"
puts "  cd /usr/src/redmine"
puts "  RAILS_ENV=development ruby plugins/redmine_release_kanban/db/seeds/kanban_test_data.rb"