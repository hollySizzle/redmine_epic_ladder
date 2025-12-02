# frozen_string_literal: true

puts "🌸 === 桜商店カンバンテストデータ投入開始 === 🌸"

# 開発環境のみで実行
unless Rails.env.development?
  puts "❌ このスクリプトは開発環境でのみ実行可能です"
  exit
end

# ===== デフォルトadminユーザーのパスワード変更強制を無効化 =====
puts "\n👤 デフォルトadminユーザーの設定を更新中..."

admin = User.find_by(login: 'admin')
if admin
  admin.must_change_passwd = false
  if admin.save(validate: false)
    puts "  ✅ adminユーザーのパスワード変更強制を無効化しました"
  else
    puts "  ⚠️  adminユーザーの更新に失敗: #{admin.errors.full_messages.join(', ')}"
  end
else
  puts "  ⚠️  adminユーザーが見つかりません（Redmineのデフォルトデータ投入が必要です）"
end

# ===== REST API & JSONP有効化 =====
puts "\n🔌 REST API設定を投入中..."

Setting['rest_api_enabled'] = '1'
Setting['jsonp_enabled'] = '1'

puts "  ✅ REST APIを有効化しました"
puts "  ✅ JSONPを有効化しました"

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

# ===== ワークフロー設定（全ステータス遷移を許可） =====
puts "\n🔄 ワークフロー設定を投入中..."

trackers = Tracker.all
roles = Role.where(builtin: 0)  # 通常のロール（開発者など）のみ
statuses = IssueStatus.all

workflow_count = 0
trackers.each do |tracker|
  roles.each do |role|
    statuses.each do |old_status|
      statuses.each do |new_status|
        # 同じステータスへの遷移は不要
        next if old_status.id == new_status.id

        workflow = WorkflowTransition.find_or_initialize_by(
          tracker_id: tracker.id,
          role_id: role.id,
          old_status_id: old_status.id,
          new_status_id: new_status.id
        )

        # 起票者・担当者ともに変更可能に設定
        workflow.author = true
        workflow.assignee = true

        if workflow.new_record?
          workflow.save
          workflow_count += 1
        else
          # 既存レコードも更新
          workflow.save if workflow.changed?
        end
      end
    end
  end
end

puts "  ✅ #{workflow_count}件のワークフロー遷移を作成しました"
puts "    トラッカー: #{trackers.count}種類"
puts "    ロール: #{roles.count}種類"
puts "    ステータス: #{statuses.count}種類"

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
    'epic_ladder'  # Epic Grid モジュール追加
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
  'bug_tracker' => '不具合'
}

# Settingモデルを使用してプラグイン設定を保存
Setting.plugin_redmine_epic_ladder = plugin_settings
puts "  ✅ カンバントラッカー設定完了"
plugin_settings.each do |key, value|
  puts "    - #{key}: #{value}"
end

# ===== バージョン投入 =====
puts "\n📅 バージョンを投入中..."

sakura_ec = created_projects['sakura-ec']
if sakura_ec
  versions_data = [
    { name: 'v0.8.0 - アルファ版', description: '社内テスト版・基本機能検証', effective_date: '2025-05-31', status: 'closed' },
    { name: 'v0.9.0 - ベータ版', description: 'クローズドベータテスト版・限定公開', effective_date: '2025-06-30', status: 'closed' },
    { name: 'v1.0.0 - MVP', description: '最小限の機能で早期リリース', effective_date: '2025-08-31', status: 'open' },
    { name: 'v1.1.0 - 初期フィードバック対応', description: 'ベータユーザーからのフィードバック反映', effective_date: '2025-10-15', status: 'open' },
    { name: 'v1.2.0 - 機能拡張', description: '商品管理・検索機能の強化', effective_date: '2025-11-30', status: 'open' },
    { name: 'v2.0.0 - 大型アップデート', description: 'UIリニューアルとパフォーマンス改善', effective_date: '2026-01-31', status: 'open' },
    { name: 'v2.1.0 - UI改善', description: 'モバイル対応とアクセシビリティ向上', effective_date: '2026-03-31', status: 'open' },
    { name: 'v2.2.0 - パフォーマンス改善', description: 'キャッシュ最適化とDB高速化', effective_date: '2026-05-31', status: 'open' },
    { name: 'v2.3.0 - AI機能統合', description: 'AIレコメンド機能の段階的導入', effective_date: '2026-07-31', status: 'open' },
    { name: 'v3.0.0 - 次世代プラットフォーム', description: 'マイクロサービス化と新アーキテクチャ', effective_date: '2026-09-30', status: 'open' }
  ]

  created_versions = {}
  versions_data.each do |data|
    version = sakura_ec.versions.find_or_initialize_by(name: data[:name])
    version.assign_attributes(
      description: data[:description],
      effective_date: Date.parse(data[:effective_date]),
      status: data[:status]
    )

    if version.save
      created_versions[data[:name]] = version
      puts "  ✅ #{version.name} (#{version.effective_date})"
    else
      puts "  ❌ #{data[:name]} の作成に失敗: #{version.errors.full_messages.join(', ')}"
    end
  end

  # ===== Issue投入（Epic/Feature/UserStory/Task階層構造） =====
  puts "\n🎯 大規模Issue階層構造を投入中..."
  puts "  📊 目標: Epic×6, Feature×25, UserStory×70, Task×50"

  # app_notificationsプラグインの通知を一時無効化
  begin
    # Journal作成後の通知を無効化
    AppNotificationsJournalsPatch.module_eval do
      alias_method :orig_create_app_notifications_after_create_journal, :create_app_notifications_after_create_journal
      def create_app_notifications_after_create_journal; end
    end
    # Issue作成後の通知を無効化
    AppNotificationsIssuesPatch.module_eval do
      alias_method :orig_create_app_notifications_after_create_issue, :create_app_notifications_after_create_issue
      def create_app_notifications_after_create_issue; end
    end
    puts "  ⚙️  app_notifications一時無効化"
  rescue NameError => e
    puts "  ⚠️  app_notificationsプラグインパッチ無効化に失敗: #{e.message}"
  end

  # トラッカー取得
  epic_tracker = Tracker.find_by(name: 'エピック')
  feature_tracker = Tracker.find_by(name: '機能')
  user_story_tracker = Tracker.find_by(name: 'ユーザストーリ')
  task_tracker = Tracker.find_by(name: '作業')
  test_tracker = Tracker.find_by(name: '評価')
  bug_tracker = Tracker.find_by(name: '不具合')

  # ステータス取得
  status_new = IssueStatus.find_by(name: '新規')
  status_in_progress = IssueStatus.find_by(name: '進行中')
  status_resolved = IssueStatus.find_by(name: '解決済み')
  status_closed = IssueStatus.find_by(name: '終了')

  # ユーザー取得
  tanaka = User.find_by(login: 'tanaka')
  suzuki = User.find_by(login: 'suzuki')
  sato = User.find_by(login: 'sato')
  watanabe = User.find_by(login: 'watanabe')
  yamada = User.find_by(login: 'yamada')

  # 優先度取得
  priority_low = IssuePriority.find_by(name: 'Low')
  priority_normal = IssuePriority.find_by(name: 'Normal')
  priority_high = IssuePriority.find_by(name: 'High')
  priority_urgent = IssuePriority.find_by(name: 'Urgent')

  # カウンター初期化
  epic_count = 0
  feature_count = 0
  us_count = 0
  task_count = 0

  # ========================================
  # Epic 0-1: 開発環境構築 (v0.8.0 - locked) ✅完了
  # ========================================
  epic0_1 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: '開発環境構築', description: 'ローカル開発環境・CI/CD・テスト基盤の整備',
    status: status_closed, priority: priority_high,
    author: tanaka, fixed_version: created_versions['v0.8.0 - アルファ版']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic0_1.subject} (#{epic0_1.fixed_version.name}) [CLOSED]"

  # Feature 0-1-1: Docker環境構築
  f0_1_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'Docker開発環境構築', description: 'Rails/PostgreSQL/Redis構成',
    status: status_closed, priority: priority_high,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic0_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 16.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f0_1_1.subject} (#{f0_1_1.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'docker-composeで起動できる',
    description: 'ワンコマンドで開発環境起動', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f0_1_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'Dockerfile作成',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 3.0)
  task_count += 1
  puts "        ├─ T#{task_count}: #{task.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'docker-compose.yml作成',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 3.0)
  task_count += 1
  puts "        └─ T#{task_count}: #{task.subject} [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'ホットリロードが動作する',
    description: 'コード変更時の自動反映', status: status_closed, priority: priority_normal,
    author: sato, assigned_to: watanabe, parent_issue_id: f0_1_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # Feature 0-1-2: CI/CDパイプライン構築
  f0_1_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'CI/CDパイプライン構築', description: 'GitHub Actions自動テスト・デプロイ',
    status: status_closed, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic0_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 20.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f0_1_2.subject} (#{f0_1_2.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'プルリク時に自動テストが走る',
    description: 'RSpec/Rubocop自動実行', status: status_closed, priority: priority_high,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f0_1_2.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'main マージ時にステージング自動デプロイ',
    description: 'AWS ECS自動デプロイ', status: status_closed, priority: priority_high,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f0_1_2.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 12.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # Feature 0-1-3: テストフレームワーク導入
  f0_1_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'テストフレームワーク導入', description: 'RSpec/FactoryBot/VCR設定',
    status: status_closed, priority: priority_normal,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic0_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 12.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f0_1_3.subject} (#{f0_1_3.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'RSpecでテストが書ける',
    description: 'rails_helper設定完了', status: status_closed, priority: priority_normal,
    author: sato, assigned_to: sato, parent_issue_id: f0_1_3.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # ========================================
  # Epic 0-2: βテスト準備 (v0.9.0 - closed) ✅完了
  # ========================================
  epic0_2 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: 'βテスト準備', description: 'クローズドβ向けの基本機能実装とテスト環境整備',
    status: status_closed, priority: priority_high,
    author: tanaka, fixed_version: created_versions['v0.9.0 - ベータ版']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic0_2.subject} (#{epic0_2.fixed_version.name}) [CLOSED]"

  # Feature 0-2-1: ログイン機能MVP
  f0_2_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'ログイン機能MVP', description: 'βテスト用の簡易ログイン',
    status: status_closed, priority: priority_urgent,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic0_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 16.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f0_2_1.subject} (#{f0_2_1.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'βテスターがログインできる',
    description: '固定アカウントでのログイン', status: status_closed, priority: priority_urgent,
    author: sato, assigned_to: sato, parent_issue_id: f0_2_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'Devise導入',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0)
  task_count += 1
  puts "        ├─ T#{task_count}: #{task.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'ログイン画面実装',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0)
  task_count += 1
  puts "        └─ T#{task_count}: #{task.subject} [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'セッション管理ができる',
    description: 'Cookie/Session保持', status: status_closed, priority: priority_high,
    author: sato, assigned_to: watanabe, parent_issue_id: f0_2_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # Feature 0-2-2: 商品一覧表示MVP
  f0_2_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '商品一覧表示MVP', description: 'βテスト用の簡易商品一覧',
    status: status_closed, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic0_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 20.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f0_2_2.subject} (#{f0_2_2.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品リストが表示される',
    description: 'グリッド形式で商品表示', status: status_closed, priority: priority_high,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f0_2_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 10.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'Product モデル作成',
    status: status_closed, priority: priority_normal, author: watanabe, assigned_to: watanabe,
    parent_issue_id: us.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 3.0)
  task_count += 1
  puts "        ├─ T#{task_count}: #{task.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '商品一覧API実装',
    status: status_closed, priority: priority_normal, author: watanabe, assigned_to: watanabe,
    parent_issue_id: us.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0)
  task_count += 1
  puts "        ├─ T#{task_count}: #{task.subject} [CLOSED]"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '一覧画面UI実装',
    status: status_closed, priority: priority_normal, author: watanabe, assigned_to: watanabe,
    parent_issue_id: us.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 3.0)
  task_count += 1
  puts "        └─ T#{task_count}: #{task.subject} [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品画像が表示される',
    description: 'ActiveStorage画像表示', status: status_closed, priority: priority_normal,
    author: watanabe, assigned_to: yamada, parent_issue_id: f0_2_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 10.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # Feature 0-2-3: βテスター招待機能
  f0_2_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'βテスター招待機能', description: '招待コード生成・メール送信',
    status: status_closed, priority: priority_normal,
    author: suzuki, assigned_to: yamada,
    parent_issue_id: epic0_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 16.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f0_2_3.subject} (#{f0_2_3.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '招待コードを生成できる',
    description: 'ユニークコード生成', status: status_closed, priority: priority_normal,
    author: yamada, assigned_to: yamada, parent_issue_id: f0_2_3.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '招待メールが送信される',
    description: 'ActionMailer招待メール', status: status_closed, priority: priority_normal,
    author: yamada, assigned_to: yamada, parent_issue_id: f0_2_3.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # Feature 0-2-4: フィードバック収集機能
  f0_2_4 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'フィードバック収集機能', description: 'βテスター向けフィードバックフォーム',
    status: status_closed, priority: priority_normal,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic0_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 12.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f0_2_4.subject} (#{f0_2_4.fixed_version.name}) [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'フィードバックを投稿できる',
    description: 'フォーム投稿機能', status: status_closed, priority: priority_normal,
    author: sato, assigned_to: sato, parent_issue_id: f0_2_4.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} [CLOSED]"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'フィードバックを管理画面で確認できる',
    description: '管理者向けフィードバック一覧', status: status_closed, priority: priority_normal,
    author: sato, assigned_to: watanabe, parent_issue_id: f0_2_4.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} [CLOSED]"

  # ========================================
  # Epic 1: 会員機能（Authentication & Profile）
  # ========================================
  epic1 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: '会員機能', description: 'ユーザー登録・ログイン・認証・プロフィール管理',
    status: status_in_progress, priority: priority_high,
    author: tanaka, fixed_version: created_versions['v1.0.0 - MVP']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic1.subject} (#{epic1.fixed_version.name})"

  # Feature 1-1: メール認証ログイン
  f1_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'メール認証ログイン', description: 'メールアドレス/パスワードでのログイン',
    status: status_resolved, priority: priority_high,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 24.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f1_1.subject} (#{f1_1.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'メールアドレスでログインできる',
    description: 'メール/パスワードでログイン', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f1_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  # Task例
  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'ログインAPIエンドポイント実装',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  task_count += 1
  puts "        ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'JWT認証トークン生成処理',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  task_count += 1
  puts "        └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'ログイン失敗時にエラーメッセージが表示される',
    description: '認証失敗時の適切なエラー表示', status: status_closed, priority: priority_normal,
    author: sato, assigned_to: watanabe, parent_issue_id: f1_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'パスワード再設定メールを送信できる',
    description: 'パスワード忘れ時の再設定フロー', status: status_resolved, priority: priority_normal,
    author: sato, assigned_to: watanabe, parent_issue_id: f1_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 1-2: SNS連携ログイン
  f1_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'SNS連携ログイン', description: 'Google/Twitter/LINE連携',
    status: status_in_progress, priority: priority_normal,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 32.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f1_2.subject} (#{f1_2.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'Googleアカウントでログインできる',
    description: 'Google OAuth連携', status: status_in_progress, priority: priority_normal,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f1_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'LINEアカウントでログインできる',
    description: 'LINE OAuth連携', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f1_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 12.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 1-3: プロフィール管理
  f1_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'プロフィール管理', description: 'ユーザー情報編集・アバター設定',
    status: status_in_progress, priority: priority_normal,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 24.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f1_3.subject} (#{f1_3.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'プロフィール情報を編集できる',
    description: '氏名・住所・電話番号編集', status: status_in_progress, priority: priority_normal,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f1_3.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'アバター画像をアップロードできる',
    description: 'プロフィール画像設定', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f1_3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject} ⚠️異Version"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'メール通知設定を変更できる',
    description: '通知ON/OFF設定', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f1_3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 4.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 1-4: 会員登録
  f1_4 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '会員登録機能', description: '新規ユーザー登録フロー',
    status: status_resolved, priority: priority_high,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 20.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f1_4.subject} (#{f1_4.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'メールアドレスで会員登録できる',
    description: '新規登録フォーム', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f1_4.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '登録確認メールが送信される',
    description: 'メールアドレス確認', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f1_4.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # ========================================
  # Epic 2: 商品機能（Product Management）
  # ========================================
  epic2 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: '商品機能', description: '商品検索・閲覧・詳細表示・在庫管理',
    status: status_in_progress, priority: priority_high,
    author: tanaka, fixed_version: created_versions['v0.9.0 - ベータ版']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic2.subject} (#{epic2.fixed_version.name})"

  # Feature 2-1: 商品検索
  f2_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '商品検索機能', description: 'キーワード・カテゴリ・価格帯検索',
    status: status_in_progress, priority: priority_high,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 28.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f2_1.subject} (#{f2_1.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'キーワードで商品を検索できる',
    description: '商品名・説明文から部分一致検索', status: status_resolved, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f2_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 10.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'カテゴリで商品を絞り込める',
    description: '和菓子・洋菓子・季節限定で絞込', status: status_in_progress, priority: priority_normal,
    author: sato, assigned_to: watanabe, parent_issue_id: f2_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '価格帯で商品を絞り込める',
    description: '価格レンジ指定検索', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f2_1.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 6.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 2-2: 商品詳細表示
  f2_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '商品詳細表示', description: '商品画像・説明・レビュー・在庫状況',
    status: status_in_progress, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 24.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f2_2.subject} (#{f2_2.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品画像をギャラリー表示できる',
    description: '複数画像のスライド表示', status: status_in_progress, priority: priority_normal,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f2_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 10.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品説明と原材料が表示される',
    description: '商品詳細情報・アレルギー情報', status: status_in_progress, priority: priority_high,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f2_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '在庫状況がリアルタイム表示される',
    description: '在庫数・入荷予定表示', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f2_2.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 2-3: 商品レビュー
  f2_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '商品レビュー機能', description: 'レビュー投稿・表示・評価集計',
    status: status_new, priority: priority_normal,
    author: suzuki, assigned_to: yamada,
    parent_issue_id: epic2.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 32.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f2_3.subject} (#{f2_3.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'レビューを投稿できる',
    description: '星評価・コメント投稿', status: status_new, priority: priority_normal,
    author: yamada, parent_issue_id: f2_3.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'レビューを一覧表示できる',
    description: 'レビュー一覧・ソート', status: status_new, priority: priority_normal,
    author: yamada, parent_issue_id: f2_3.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 2-4: 商品一覧表示
  f2_4 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '商品一覧表示', description: 'グリッド/リスト表示切替・ソート',
    status: status_resolved, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic2.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 20.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f2_4.subject} (#{f2_4.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品をグリッド表示できる',
    description: 'サムネイルグリッド表示', status: status_closed, priority: priority_high,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f2_4.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品をリスト表示できる',
    description: '詳細情報付きリスト表示', status: status_closed, priority: priority_normal,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f2_4.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # ========================================
  # Epic 3: 決済機能（Payment & Cart）
  # ========================================
  epic3 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: '決済機能', description: 'カート・決済処理・領収書発行',
    status: status_in_progress, priority: priority_urgent,
    author: tanaka, fixed_version: created_versions['v0.8.0 - アルファ版']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic3.subject} (#{epic3.fixed_version.name})"

  # Feature 3-1: ショッピングカート
  f3_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'ショッピングカート', description: '商品追加・削除・数量変更',
    status: status_resolved, priority: priority_high,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic3.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 28.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f3_1.subject} (#{f3_1.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品をカートに追加できる',
    description: '商品詳細からカート追加', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f3_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'カートAPIエンドポイント実装',
    status: status_closed, priority: priority_normal, author: sato, assigned_to: sato,
    parent_issue_id: us.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  task_count += 1
  puts "        ├─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'カート内商品数量を変更できる',
    description: '数量増減・削除', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f3_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'カート合計金額が表示される',
    description: '小計・税込価格表示', status: status_closed, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f3_1.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 3-2: クレジットカード決済
  f3_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'クレジットカード決済', description: 'Stripe連携決済',
    status: status_in_progress, priority: priority_urgent,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic3.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 40.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f3_2.subject} (#{f3_2.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'クレジットカード情報を入力できる',
    description: 'カード番号・有効期限入力', status: status_in_progress, priority: priority_urgent,
    author: sato, assigned_to: sato, parent_issue_id: f3_2.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '決済処理が正常に完了する',
    description: 'Stripe決済API連携', status: status_in_progress, priority: priority_urgent,
    author: sato, assigned_to: sato, parent_issue_id: f3_2.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 16.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '決済エラー時に適切なメッセージが表示される',
    description: 'エラーハンドリング', status: status_new, priority: priority_high,
    author: sato, parent_issue_id: f3_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 3-3: コンビニ決済
  f3_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'コンビニ決済', description: 'コンビニ払込票発行',
    status: status_new, priority: priority_normal,
    author: suzuki,
    parent_issue_id: epic3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 32.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f3_3.subject} (#{f3_3.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'コンビニ支払い番号が発行される',
    description: '払込票番号生成', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f3_3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 12.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 3-4: 領収書発行
  f3_4 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '領収書発行機能', description: 'PDF領収書生成・ダウンロード',
    status: status_new, priority: priority_normal,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 20.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f3_4.subject} (#{f3_4.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '領収書をPDFダウンロードできる',
    description: 'PDF生成・ダウンロード', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f3_4.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 12.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # ========================================
  # Epic 4: 配送機能（Shipping & Delivery）
  # ========================================
  epic4 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: '配送機能', description: '配送先管理・配送状況追跡・通知',
    status: status_in_progress, priority: priority_high,
    author: tanaka, fixed_version: created_versions['v0.9.0 - ベータ版']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic4.subject} (#{epic4.fixed_version.name})"

  # Feature 4-1: 配送先管理
  f4_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '配送先管理', description: '配送先登録・編集・複数管理',
    status: status_in_progress, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic4.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 24.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f4_1.subject} (#{f4_1.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '配送先住所を登録できる',
    description: '郵便番号・住所入力', status: status_in_progress, priority: priority_high,
    author: watanabe, assigned_to: watanabe, parent_issue_id: f4_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '複数の配送先を管理できる',
    description: '配送先一覧・編集・削除', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f4_1.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 10.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 4-2: 配送日時指定
  f4_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '配送日時指定', description: '希望配送日・時間帯指定',
    status: status_new, priority: priority_normal,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic4.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 20.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f4_2.subject} (#{f4_2.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '希望配送日を選択できる',
    description: 'カレンダーから日付選択', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f4_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 8.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '配送時間帯を指定できる',
    description: '午前・午後・夜間指定', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f4_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 6.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 4-3: 配送状況追跡
  f4_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '配送状況追跡', description: '配送ステータス・伝票番号確認',
    status: status_new, priority: priority_normal,
    author: suzuki, assigned_to: yamada,
    parent_issue_id: epic4.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 28.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f4_3.subject} (#{f4_3.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '配送ステータスを確認できる',
    description: '出荷準備中・配送中・配達完了', status: status_new, priority: priority_normal,
    author: yamada, parent_issue_id: f4_3.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '配送業者の追跡ページにリンクできる',
    description: '伝票番号から追跡URL生成', status: status_new, priority: priority_normal,
    author: yamada, parent_issue_id: f4_3.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 4-4: 配送通知
  f4_4 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '配送通知機能', description: '出荷・配達完了メール通知',
    status: status_new, priority: priority_normal,
    author: suzuki,
    parent_issue_id: epic4.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 16.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f4_4.subject} (#{f4_4.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '出荷時にメール通知される',
    description: '出荷通知メール送信', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f4_4.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # ========================================
  # Epic 5: 管理機能（Admin & Analytics）
  # ========================================
  epic5 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: '管理機能', description: '管理ダッシュボード・売上分析・在庫管理',
    status: status_new, priority: priority_normal,
    author: tanaka, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic5.subject} (#{epic5.fixed_version.name})"

  # Feature 5-1: 管理ダッシュボード
  f5_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '管理ダッシュボード', description: '売上・注文数・アクセス数グラフ',
    status: status_new, priority: priority_normal,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic5.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 32.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f5_1.subject} (#{f5_1.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '売上グラフを表示できる',
    description: '日別・月別売上グラフ', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f5_1.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '注文数の推移を確認できる',
    description: '期間別注文数グラフ', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f5_1.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 10.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 5-2: 商品管理
  f5_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '商品管理機能', description: '商品登録・編集・削除・在庫管理',
    status: status_new, priority: priority_high,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic5.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 40.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f5_2.subject} (#{f5_2.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '新規商品を登録できる',
    description: '商品情報・画像登録', status: status_new, priority: priority_high,
    author: sato, parent_issue_id: f5_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品情報を編集できる',
    description: '価格・説明・在庫数編集', status: status_new, priority: priority_high,
    author: sato, parent_issue_id: f5_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 10.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '在庫数を一括更新できる',
    description: 'CSV一括インポート', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f5_2.id, fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 16.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 5-3: 注文管理
  f5_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '注文管理機能', description: '注文一覧・ステータス更新・キャンセル',
    status: status_new, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    parent_issue_id: epic5.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 36.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f5_3.subject} (#{f5_3.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '注文一覧を確認できる',
    description: '注文検索・フィルタ', status: status_new, priority: priority_high,
    author: watanabe, parent_issue_id: f5_3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '注文ステータスを更新できる',
    description: '発送済み・配達完了に変更', status: status_new, priority: priority_high,
    author: watanabe, parent_issue_id: f5_3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 8.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 5-4: 顧客管理
  f5_4 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '顧客管理機能', description: '顧客一覧・購入履歴・問い合わせ管理',
    status: status_new, priority: priority_normal,
    author: suzuki,
    parent_issue_id: epic5.id, fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 32.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f5_4.subject} (#{f5_4.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '顧客一覧を確認できる',
    description: '登録日・購入回数で検索', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f5_4.id, fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 12.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '顧客の購入履歴を確認できる',
    description: '過去注文一覧表示', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f5_4.id, fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 10.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # ========================================
  # Epic 6: AI機能（AI & Recommendation）
  # ========================================
  epic6 = Issue.create!(
    project: sakura_ec, tracker: epic_tracker,
    subject: 'AI機能', description: 'AIレコメンド・チャットボット・需要予測',
    status: status_new, priority: priority_normal,
    author: tanaka, fixed_version: created_versions['v2.0.0 - 大型アップデート']
  )
  epic_count += 1
  puts "\n  ✅ Epic#{epic_count}: #{epic6.subject} (#{epic6.fixed_version.name})"

  # Feature 6-1: AIレコメンド
  f6_1 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'AIレコメンド機能', description: '購入履歴ベースのおすすめ商品',
    status: status_new, priority: priority_normal,
    author: suzuki, assigned_to: sato,
    parent_issue_id: epic6.id, fixed_version: created_versions['v2.0.0 - 大型アップデート'], estimated_hours: 48.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f6_1.subject} (#{f6_1.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'おすすめ商品が表示される',
    description: '協調フィルタリング', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_1.id, fixed_version: created_versions['v2.0.0 - 大型アップデート'], estimated_hours: 20.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '閲覧履歴から関連商品を提案',
    description: 'セッションベースレコメンド', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_1.id, fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 24.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject} ⚠️異Version"

  # Feature 6-2: チャットボット
  f6_2 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: 'AIチャットボット', description: '商品問い合わせ自動応答',
    status: status_new, priority: priority_normal,
    author: suzuki,
    parent_issue_id: epic6.id, fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 56.0
  )
  feature_count += 1
  puts "    ├─ F#{feature_count}: #{f6_2.subject} (#{f6_2.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'チャットで商品を検索できる',
    description: '自然言語検索', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_2.id, fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 24.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'よくある質問に自動回答する',
    description: 'FAQ自動応答', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_2.id, fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 20.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # Feature 6-3: 需要予測
  f6_3 = Issue.create!(
    project: sakura_ec, tracker: feature_tracker,
    subject: '需要予測機能', description: '売上予測・在庫最適化提案',
    status: status_new, priority: priority_normal,
    author: suzuki,
    parent_issue_id: epic6.id, fixed_version: created_versions['v2.2.0 - パフォーマンス改善'], estimated_hours: 60.0
  )
  feature_count += 1
  puts "    └─ F#{feature_count}: #{f6_3.subject} (#{f6_3.fixed_version.name})"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品別売上予測を確認できる',
    description: '時系列予測モデル', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_3.id, fixed_version: created_versions['v2.2.0 - パフォーマンス改善'], estimated_hours: 28.0)
  us_count += 1
  puts "      ├─ US#{us_count}: #{us.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '適正在庫数の提案を受ける',
    description: '在庫最適化アルゴリズム', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_3.id, fixed_version: created_versions['v2.2.0 - パフォーマンス改善'], estimated_hours: 24.0)
  us_count += 1
  puts "      └─ US#{us_count}: #{us.subject}"

  # ========================================
  # 追加UserStory & Task（目標達成のため）
  # ========================================
  puts "\n  ➕ 追加UserStory & Task生成中..."

  # Epic1 追加US
  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '二段階認証を設定できる',
    description: 'SMSまたはTOTPでの二段階認証', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f1_1.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 16.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic1追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'TOTP認証ライブラリ調査',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 4.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'パスワード強度チェックが機能する',
    description: '弱いパスワードを拒否', status: status_resolved, priority: priority_normal,
    author: sato, parent_issue_id: f1_4.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic1追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'パスワードバリデーションロジック実装',
    status: status_resolved, priority: priority_normal, author: sato, assigned_to: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 3.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'パスワード強度メーター実装',
    status: status_resolved, priority: priority_normal, author: watanabe, assigned_to: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 3.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  # Epic2 追加US
  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品をお気に入り登録できる',
    description: 'お気に入りリスト機能', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f2_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 10.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic2追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'お気に入りテーブル設計',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 2.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'お気に入りAPI実装',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 4.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '商品比較機能を使える',
    description: '複数商品のスペック比較', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f2_4.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 14.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic2追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '比較UIコンポーネント設計',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 6.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '新着商品バッジが表示される',
    description: '登録7日以内の商品にNEWマーク', status: status_in_progress, priority: priority_normal,
    author: watanabe, parent_issue_id: f2_4.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic2追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'NEWバッジ条件判定ロジック',
    status: status_in_progress, priority: priority_normal, author: watanabe, assigned_to: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 2.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  # Epic3 追加US
  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'カート内商品の保存期限を設定できる',
    description: '30日間カート保持', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f3_1.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic3追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'カート有効期限バッチ処理',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'クーポンコードを適用できる',
    description: '割引クーポン入力機能', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f3_2.id, fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 12.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic3追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'クーポンマスタテーブル設計',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 3.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'クーポン適用ロジック実装',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 5.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '決済完了メールが送信される',
    description: '注文確認メール自動送信', status: status_in_progress, priority: priority_high,
    author: sato, assigned_to: sato, parent_issue_id: f3_2.id, fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic3追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'メールテンプレート作成',
    status: status_in_progress, priority: priority_normal, author: sato, assigned_to: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 3.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'メール送信バッチ実装',
    status: status_in_progress, priority: priority_normal, author: sato, assigned_to: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  # Epic4 追加US
  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '配送先候補を郵便番号から検索できる',
    description: '住所自動補完機能', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f4_1.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 10.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic4追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '郵便番号API連携',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 5.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '再配達を依頼できる',
    description: '不在時の再配達依頼', status: status_new, priority: priority_normal,
    author: watanabe, parent_issue_id: f4_3.id, fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 12.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic4追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '再配達依頼フォーム作成',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 4.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '配送業者API連携',
    status: status_new, priority: priority_normal, author: yamada, parent_issue_id: us.id,
    fixed_version: created_versions['v1.1.0 - 初期フィードバック対応'], estimated_hours: 6.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  # Epic5 追加US
  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '売上レポートをPDF出力できる',
    description: '月次レポートPDF生成', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f5_1.id, fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 14.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic5追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'PDF生成ライブラリ選定',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 3.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'レポートテンプレート作成',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v1.2.0 - 機能拡張'], estimated_hours: 6.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '在庫アラートを設定できる',
    description: '在庫閾値でメール通知', status: status_new, priority: priority_high,
    author: sato, parent_issue_id: f5_2.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 10.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic5追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '在庫監視バッチ処理',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 4.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '注文キャンセル処理ができる',
    description: 'キャンセルと返金処理', status: status_new, priority: priority_high,
    author: watanabe, parent_issue_id: f5_3.id, fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 16.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic5追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'キャンセルワークフロー設計',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 4.0)
  task_count += 1
  puts "      ├─ T#{task_count}: #{task.subject}"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '返金API実装',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 6.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  # Epic6 追加US
  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'レコメンド精度を評価できる',
    description: 'A/Bテスト機能', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_1.id, fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 20.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic6追加) ⚠️異Version"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: 'A/Bテスト基盤構築',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 10.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: 'チャットボット学習データを管理できる',
    description: '学習データ登録・編集', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_2.id, fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 16.0)
  us_count += 1
  puts "    ├─ US#{us_count}: #{us.subject} (Epic6追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '学習データ管理画面',
    status: status_new, priority: priority_normal, author: watanabe, parent_issue_id: us.id,
    fixed_version: created_versions['v2.1.0 - UI改善'], estimated_hours: 8.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  us = Issue.create!(project: sakura_ec, tracker: user_story_tracker, subject: '季節トレンドを予測できる',
    description: '季節性を考慮した需要予測', status: status_new, priority: priority_normal,
    author: sato, parent_issue_id: f6_3.id, fixed_version: created_versions['v2.2.0 - パフォーマンス改善'], estimated_hours: 24.0)
  us_count += 1
  puts "    └─ US#{us_count}: #{us.subject} (Epic6追加)"

  task = Issue.create!(project: sakura_ec, tracker: task_tracker, subject: '季節性分析アルゴリズム実装',
    status: status_new, priority: priority_normal, author: sato, parent_issue_id: us.id,
    fixed_version: created_versions['v2.2.0 - パフォーマンス改善'], estimated_hours: 12.0)
  task_count += 1
  puts "      └─ T#{task_count}: #{task.subject}"

  puts "    ✅ 追加完了: UserStory +20個, Task +27個"

  # ========================================
  # Bug追加（実践的な不具合管理）
  # ========================================
  puts "\n  🐛 不具合チケット追加中..."

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'ログイン時にセッションが切れる',
    description: 'Safariブラウザでログイン後、5分でセッションタイムアウト',
    status: status_resolved, priority: priority_high,
    author: yamada, assigned_to: sato,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0
  )
  puts "    🐛 Bug#1: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'カート合計金額の計算誤り',
    description: '税込価格が小数点以下で誤差が発生',
    status: status_in_progress, priority: priority_urgent,
    author: yamada, assigned_to: sato,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 4.0
  )
  puts "    🐛 Bug#2: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'モバイル表示で商品画像が崩れる',
    description: 'iPhone13で画像アスペクト比が崩れる',
    status: status_new, priority: priority_normal,
    author: yamada,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 6.0
  )
  puts "    🐛 Bug#3: #{bug.subject} (#{bug.fixed_version.name})"

  # === フロントエンド系バグ ===
  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: '商品検索結果が無限スクロールで重複表示される',
    description: 'スクロールで次ページ読み込み時、前ページの最後の商品が重複表示される',
    status: status_new, priority: priority_high,
    author: yamada, assigned_to: watanabe,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0
  )
  puts "    🐛 Bug#4: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'ブラウザバックでカート内容が消える',
    description: 'カートに商品追加後、ブラウザバックボタンでカートが空になる',
    status: status_in_progress, priority: priority_urgent,
    author: tanaka, assigned_to: sato,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 6.0
  )
  puts "    🐛 Bug#5: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'ダークモードで文字が読めない',
    description: 'iOS/Androidのダークモード有効時、白背景に白文字になる箇所がある',
    status: status_resolved, priority: priority_normal,
    author: suzuki, assigned_to: watanabe,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 3.0
  )
  puts "    🐛 Bug#6: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'お気に入りボタンの連打で複数登録される',
    description: 'ハートアイコン連打で同一商品が複数お気に入り登録される',
    status: status_new, priority: priority_low,
    author: yamada,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 2.0
  )
  puts "    🐛 Bug#7: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'レスポンシブメニューがタップできない',
    description: 'タブレット横向き表示時、ハンバーガーメニューがタップ反応しない',
    status: status_in_progress, priority: priority_high,
    author: suzuki, assigned_to: watanabe,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 5.0
  )
  puts "    🐛 Bug#8: #{bug.subject} (#{bug.fixed_version.name})"

  # === バックエンド系バグ ===
  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: '商品一覧APIのレスポンスが遅い（5秒以上）',
    description: '1000件以上の商品がある場合、一覧取得に5秒以上かかる。N+1問題の可能性',
    status: status_new, priority: priority_urgent,
    author: tanaka, assigned_to: sato,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0
  )
  puts "    🐛 Bug#9: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: '在庫数が負の値になる',
    description: '同時購入発生時、在庫管理のロック処理が不十分で在庫数がマイナスになる',
    status: status_in_progress, priority: priority_urgent,
    author: tanaka, assigned_to: sato,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 10.0
  )
  puts "    🐛 Bug#10: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'ユーザー削除時に関連データが残る',
    description: 'ユーザー削除時、カート・お気に入り・注文履歴が削除されずに残る',
    status: status_resolved, priority: priority_high,
    author: suzuki, assigned_to: sato,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 6.0
  )
  puts "    🐛 Bug#11: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'CSVエクスポートで文字化けが発生',
    description: '注文一覧CSVダウンロード時、商品名が文字化けする（UTF-8/Shift_JIS問題）',
    status: status_new, priority: priority_normal,
    author: yamada,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 3.0
  )
  puts "    🐛 Bug#12: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'ログファイルが肥大化してディスク容量を圧迫',
    description: 'application.logが50GB超え。ログローテーション設定が未実施',
    status: status_in_progress, priority: priority_high,
    author: tanaka, assigned_to: sato,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 4.0
  )
  puts "    🐛 Bug#13: #{bug.subject} (#{bug.fixed_version.name})"

  # === 統合系バグ ===
  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'クレジットカード決済で稀にタイムアウト',
    description: '決済API呼び出し時、ネットワーク遅延で5%程度の確率でタイムアウト発生',
    status: status_new, priority: priority_urgent,
    author: tanaka, assigned_to: sato,
    fixed_version: created_versions['v0.9.0 - ベータ版'], estimated_hours: 8.0
  )
  puts "    🐛 Bug#14: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: '注文確認メールが送信されない',
    description: 'SMTP設定エラーで注文完了メールが送信失敗するが、エラーログが出ない',
    status: status_resolved, priority: priority_urgent,
    author: yamada, assigned_to: suzuki,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 5.0
  )
  puts "    🐛 Bug#15: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: '配送業者APIから404エラーが返る',
    description: '配送状況取得API呼び出しで404エラー。APIバージョンアップに未対応',
    status: status_in_progress, priority: priority_high,
    author: suzuki, assigned_to: sato,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 6.0
  )
  puts "    🐛 Bug#16: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'Google Analytics トラッキングコードが重複',
    description: 'GAタグが複数箇所に記述され、PV数が2倍でカウントされている',
    status: status_new, priority: priority_normal,
    author: suzuki,
    fixed_version: created_versions['v1.0.0 - MVP'], estimated_hours: 2.0
  )
  puts "    🐛 Bug#17: #{bug.subject} (#{bug.fixed_version.name})"

  # === セキュリティ/データ系バグ ===
  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'SQLインジェクション脆弱性（商品検索）',
    description: '商品検索クエリパラメータでSQLインジェクション可能。早急な対応必要',
    status: status_in_progress, priority: priority_urgent,
    author: tanaka, assigned_to: sato,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 12.0
  )
  puts "    🐛 Bug#18: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: '他人の注文履歴が閲覧できる',
    description: 'URL直接入力で他ユーザーの注文詳細ページにアクセス可能。権限チェック漏れ',
    status: status_resolved, priority: priority_urgent,
    author: yamada, assigned_to: sato,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 8.0
  )
  puts "    🐛 Bug#19: #{bug.subject} (#{bug.fixed_version.name})"

  bug = Issue.create!(
    project: sakura_ec, tracker: bug_tracker,
    subject: 'パスワードがログに平文出力される',
    description: 'ログイン失敗時のログにパスワードが平文で記録されている',
    status: status_resolved, priority: priority_urgent,
    author: tanaka, assigned_to: suzuki,
    fixed_version: created_versions['v0.8.0 - アルファ版'], estimated_hours: 3.0
  )
  puts "    🐛 Bug#20: #{bug.subject} (#{bug.fixed_version.name})"

  # ========================================
  # 統計表示
  # ========================================
  puts "\n  📊 === Issue生成完了 ==="
  puts "    Epic: #{epic_count}個"
  puts "    Feature: #{feature_count}個"
  puts "    UserStory: #{us_count}個"
  puts "    Task: #{task_count}個"
  puts "    Bug: 3個"
  puts "    合計: #{epic_count + feature_count + us_count + task_count + 3}個"

  puts "\n  📝 検証ポイント:"
  puts "    ✅ 各Epic配下に3-5個のFeature"
  puts "    ✅ 各Feature配下に2-4個のUserStory"
  puts "    ✅ 一部UserStoryは親Featureと異なるVersionを持つ"
  puts "    ✅ Taskはv1の主要UserStoryにのみ付与"
  puts "    ✅ Bugは実践的なシナリオを想定"

  # app_notificationsの通知を復元
  begin
    AppNotificationsJournalsPatch.module_eval do
      alias_method :create_app_notifications_after_create_journal, :orig_create_app_notifications_after_create_journal
    end
    AppNotificationsIssuesPatch.module_eval do
      alias_method :create_app_notifications_after_create_issue, :orig_create_app_notifications_after_create_issue
    end
    puts "  ⚙️  app_notifications復元"
  rescue NameError
    # 何もしない
  end

else
  puts "  ❌ 桜商店ECサイトプロジェクトが見つかりません"
end

# ===== 投入結果確認 =====
puts "\n📊 === 投入結果確認 ==="
puts "  トラッカー数: #{Tracker.count}"
puts "  ユーザー数: #{User.count}"
puts "  プロジェクト数: #{Project.count}"
puts "  優先度数: #{IssuePriority.count}"
puts "  バージョン数: #{Version.count}"
puts "  Issue総数: #{Issue.count}"
puts "    - Epic: #{Issue.joins(:tracker).where(trackers: { name: 'エピック' }).count}個"
puts "    - Feature: #{Issue.joins(:tracker).where(trackers: { name: '機能' }).count}個"
puts "    - UserStory: #{Issue.joins(:tracker).where(trackers: { name: 'ユーザストーリ' }).count}個"
puts "    - Task: #{Issue.joins(:tracker).where(trackers: { name: '作業' }).count}個"
puts "    - Test: #{Issue.joins(:tracker).where(trackers: { name: '評価' }).count}個"
puts "    - Bug: #{Issue.joins(:tracker).where(trackers: { name: '不具合' }).count}個"
puts "  プラグイン設定: #{Setting.plugin_redmine_epic_ladder.present? ? '設定済み' : '未設定'}"

puts "\n✨ === 実践的データ特徴 ==="
puts "  📅 プロジェクト期間: 2025年8月〜2026年9月 (14ヶ月)"
puts "  🚀 バージョン: 8回のリリース (月次〜隔月)"
puts "  👥 チームメンバー: 6名 (PM、リーダー、シニア、ジュニア、QA、管理者)"
puts "  🎯 複雑な依存関係: UserStoryの一部が親Featureと異なるVersion"
puts "  📈 ステータス配分: 完了/進行中/新規/解決済みが混在"
puts "  🐛 不具合管理: リアルな不具合シナリオを含む"

puts "\n🌸 === 桜商店カンバンテストデータ投入完了！ === 🌸"
puts "以下のコマンドで実行:"
puts "  cd /usr/src/redmine"
puts "  RAILS_ENV=development rails runner plugins/redmine_epic_ladder/db/seeds/kanban_test_data.rb"
puts ""
puts "💡 使い方:"
puts "  1. ブラウザで http://localhost:3000 にアクセス"
puts "  2. ログイン: admin / admin"
puts "  3. プロジェクト「桜商店ECサイト開発」を選択"
puts "  4. Epic Grid タブをクリック"
puts ""
puts "🎨 確認ポイント:"
puts "  - 6つのEpicが横軸に配置されているか"
puts "  - 8つのバージョンが縦軸に配置されているか"
puts "  - UserStoryが親Featureではなく自身のVersionに配置されているか"
puts "  - 大量のカード表示でパフォーマンスに問題がないか"
