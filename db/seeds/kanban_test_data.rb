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
    'epic_grid'  # Epic Grid モジュール追加
  ]

  sakura_ec.enabled_module_names = enabled_modules

  if sakura_ec.save
    puts "  ✅ 桜商店ECサイト: #{enabled_modules.size}個のモジュールを有効化"
    puts "    - epic_grid モジュールを含む"
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
Setting.plugin_redmine_epic_grid = plugin_settings
puts "  ✅ カンバントラッカー設定完了"
plugin_settings.each do |key, value|
  puts "    - #{key}: #{value}"
end

# ===== バージョン投入 =====
puts "\n📅 バージョンを投入中..."

sakura_ec = created_projects['sakura-ec']
if sakura_ec
  versions_data = [
    { name: 'v1.0.0 - MVP', description: '最小限の機能で早期リリース', effective_date: '2025-03-31', status: 'open' },
    { name: 'v1.1.0 - 拡張機能', description: 'ユーザー要望を反映した機能追加', effective_date: '2025-06-30', status: 'open' },
    { name: 'v2.0.0 - 大型アップデート', description: 'UIリニューアルとパフォーマンス改善', effective_date: '2025-09-30', status: 'open' },
    { name: 'v2.1.0 - モバイル対応', description: 'レスポンシブデザイン対応', effective_date: '2025-12-31', status: 'open' },
    { name: 'v3.0.0 - AI統合', description: 'AIレコメンド機能の本格導入', effective_date: '2026-03-31', status: 'open' }
  ]

  created_versions = {}
  versions_data.each_with_index do |data, index|
    version = sakura_ec.versions.find_or_initialize_by(name: data[:name])
    version.assign_attributes(
      description: data[:description],
      effective_date: Date.parse(data[:effective_date]),
      status: data[:status]
    )

    if version.save
      created_versions["v#{index + 1}"] = version
      puts "  ✅ #{version.name} (#{version.effective_date})"
    else
      puts "  ❌ #{data[:name]} の作成に失敗: #{version.errors.full_messages.join(', ')}"
    end
  end

  # ===== Issue投入（Epic/Feature/UserStory階層構造） =====
  puts "\n🎯 Issue階層構造を投入中..."

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
  priority_normal = IssuePriority.find_by(name: '通常')
  priority_high = IssuePriority.find_by(name: '高')
  priority_urgent = IssuePriority.find_by(name: '緊急')

  # ===== Epic 1: 会員機能 =====
  epic1 = Issue.create!(
    project: sakura_ec,
    tracker: epic_tracker,
    subject: '会員機能',
    description: 'ユーザー登録・ログイン・プロフィール管理',
    status: status_in_progress,
    priority: priority_high,
    author: tanaka,
    fixed_version: created_versions['v1']
  )
  puts "  ✅ Epic: #{epic1.subject} (Version: #{epic1.fixed_version.name})"

  # Feature 1-1: ログイン機能
  feature1_1 = Issue.create!(
    project: sakura_ec,
    tracker: feature_tracker,
    subject: 'ログイン機能',
    description: 'メール/SNSログイン対応',
    status: status_in_progress,
    priority: priority_high,
    author: suzuki,
    assigned_to: suzuki,
    parent_issue_id: epic1.id,
    fixed_version: created_versions['v1']
  )
  puts "    ├─ Feature: #{feature1_1.subject} (Version: #{feature1_1.fixed_version.name})"

  # UserStory 1: メールログイン（Featureと同じVersion）
  us1 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'メールアドレスでログインできる',
    description: 'ユーザーがメールアドレスとパスワードでログインできる',
    status: status_resolved,
    priority: priority_normal,
    author: sato,
    assigned_to: sato,
    parent_issue_id: feature1_1.id,
    fixed_version: created_versions['v1'],
    estimated_hours: 8.0
  )
  puts "      ├─ UserStory: #{us1.subject} (Version: #{us1.fixed_version.name}) ✓同じ"

  # UserStory 2: SNSログイン（Featureと異なるVersion）
  us2 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'SNSアカウントでログインできる',
    description: 'Google/Twitter/Facebook連携ログイン',
    status: status_new,
    priority: priority_normal,
    author: sato,
    assigned_to: watanabe,
    parent_issue_id: feature1_1.id,
    fixed_version: created_versions['v2'],
    estimated_hours: 16.0
  )
  puts "      └─ UserStory: #{us2.subject} (Version: #{us2.fixed_version.name}) ⚠️異なる！"

  # Feature 1-2: プロフィール機能
  feature1_2 = Issue.create!(
    project: sakura_ec,
    tracker: feature_tracker,
    subject: 'プロフィール機能',
    description: 'ユーザー情報編集・アバター設定',
    status: status_in_progress,
    priority: priority_normal,
    author: suzuki,
    assigned_to: watanabe,
    parent_issue_id: epic1.id,
    fixed_version: created_versions['v2']
  )
  puts "    └─ Feature: #{feature1_2.subject} (Version: #{feature1_2.fixed_version.name})"

  # UserStory 3: プロフィール編集（Featureと同じVersion）
  us3 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'プロフィール情報を編集できる',
    description: '氏名・住所・電話番号を編集',
    status: status_in_progress,
    priority: priority_normal,
    author: watanabe,
    assigned_to: watanabe,
    parent_issue_id: feature1_2.id,
    fixed_version: created_versions['v2'],
    estimated_hours: 6.0
  )
  puts "      ├─ UserStory: #{us3.subject} (Version: #{us3.fixed_version.name}) ✓同じ"

  # UserStory 4: アバター設定（Featureと異なるVersion）
  us4 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'アバター画像を設定できる',
    description: 'プロフィール画像のアップロード',
    status: status_new,
    priority: priority_normal,
    author: watanabe,
    assigned_to: watanabe,
    parent_issue_id: feature1_2.id,
    fixed_version: created_versions['v3'],
    estimated_hours: 8.0
  )
  puts "      └─ UserStory: #{us4.subject} (Version: #{us4.fixed_version.name}) ⚠️異なる！"

  # ===== Epic 2: 商品機能 =====
  epic2 = Issue.create!(
    project: sakura_ec,
    tracker: epic_tracker,
    subject: '商品機能',
    description: '商品検索・閲覧・詳細表示',
    status: status_in_progress,
    priority: priority_high,
    author: tanaka,
    fixed_version: nil  # Versionなし
  )
  puts "  ✅ Epic: #{epic2.subject} (Version: なし)"

  # Feature 2-1: 商品検索
  feature2_1 = Issue.create!(
    project: sakura_ec,
    tracker: feature_tracker,
    subject: '商品検索機能',
    description: 'キーワード・カテゴリ検索',
    status: status_in_progress,
    priority: priority_high,
    author: suzuki,
    assigned_to: sato,
    parent_issue_id: epic2.id,
    fixed_version: created_versions['v3']
  )
  puts "    ├─ Feature: #{feature2_1.subject} (Version: #{feature2_1.fixed_version.name})"

  # UserStory 5: キーワード検索（Versionなし、Featureと異なる）
  us5 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'キーワードで商品を検索できる',
    description: '商品名・説明文から部分一致検索',
    status: status_resolved,
    priority: priority_high,
    author: sato,
    assigned_to: sato,
    parent_issue_id: feature2_1.id,
    fixed_version: nil,
    estimated_hours: 12.0
  )
  puts "      ├─ UserStory: #{us5.subject} (Version: なし) ⚠️異なる！"

  # UserStory 6: カテゴリ絞込（Featureと同じVersion）
  us6 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'カテゴリで商品を絞り込める',
    description: '和菓子・洋菓子・季節限定などで絞込',
    status: status_in_progress,
    priority: priority_normal,
    author: sato,
    assigned_to: watanabe,
    parent_issue_id: feature2_1.id,
    fixed_version: created_versions['v3'],
    estimated_hours: 8.0
  )
  puts "      └─ UserStory: #{us6.subject} (Version: #{us6.fixed_version.name}) ✓同じ"

  # Feature 2-2: 商品詳細
  feature2_2 = Issue.create!(
    project: sakura_ec,
    tracker: feature_tracker,
    subject: '商品詳細表示',
    description: '商品画像・説明・レビュー表示',
    status: status_in_progress,
    priority: priority_normal,
    author: suzuki,
    assigned_to: watanabe,
    parent_issue_id: epic2.id,
    fixed_version: created_versions['v4']
  )
  puts "    └─ Feature: #{feature2_2.subject} (Version: #{feature2_2.fixed_version.name})"

  # UserStory 7: 画像ギャラリー（Featureと同じVersion）
  us7 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: '商品画像をギャラリー表示できる',
    description: '複数の商品画像をスライド表示',
    status: status_in_progress,
    priority: priority_normal,
    author: watanabe,
    assigned_to: watanabe,
    parent_issue_id: feature2_2.id,
    fixed_version: created_versions['v4'],
    estimated_hours: 10.0
  )
  puts "      ├─ UserStory: #{us7.subject} (Version: #{us7.fixed_version.name}) ✓同じ"

  # UserStory 8: レビュー表示（Featureと異なるVersion）
  us8 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'ユーザーレビューを表示できる',
    description: '星評価とコメントを表示',
    status: status_new,
    priority: priority_normal,
    author: watanabe,
    parent_issue_id: feature2_2.id,
    fixed_version: created_versions['v5'],
    estimated_hours: 12.0
  )
  puts "      └─ UserStory: #{us8.subject} (Version: #{us8.fixed_version.name}) ⚠️異なる！"

  # ===== Epic 3: 決済機能 =====
  epic3 = Issue.create!(
    project: sakura_ec,
    tracker: epic_tracker,
    subject: '決済機能',
    description: 'カート・決済処理',
    status: status_new,
    priority: priority_urgent,
    author: tanaka,
    fixed_version: created_versions['v5']
  )
  puts "  ✅ Epic: #{epic3.subject} (Version: #{epic3.fixed_version.name})"

  # Feature 3-1: カート機能
  feature3_1 = Issue.create!(
    project: sakura_ec,
    tracker: feature_tracker,
    subject: 'ショッピングカート',
    description: '商品追加・削除・数量変更',
    status: status_in_progress,
    priority: priority_high,
    author: suzuki,
    assigned_to: sato,
    parent_issue_id: epic3.id,
    fixed_version: created_versions['v1']
  )
  puts "    ├─ Feature: #{feature3_1.subject} (Version: #{feature3_1.fixed_version.name})"

  # UserStory 9: カート追加（Featureと同じVersion）
  us9 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: '商品をカートに追加できる',
    description: '商品詳細からカート追加',
    status: status_resolved,
    priority: priority_high,
    author: sato,
    assigned_to: sato,
    parent_issue_id: feature3_1.id,
    fixed_version: created_versions['v1'],
    estimated_hours: 8.0
  )
  puts "      ├─ UserStory: #{us9.subject} (Version: #{us9.fixed_version.name}) ✓同じ"

  # UserStory 10: 数量変更（Featureと異なるVersion）
  us10 = Issue.create!(
    project: sakura_ec,
    tracker: user_story_tracker,
    subject: 'カート内の商品数量を変更できる',
    description: '数量の増減・削除',
    status: status_in_progress,
    priority: priority_normal,
    author: sato,
    assigned_to: watanabe,
    parent_issue_id: feature3_1.id,
    fixed_version: created_versions['v2'],
    estimated_hours: 6.0
  )
  puts "      └─ UserStory: #{us10.subject} (Version: #{us10.fixed_version.name}) ⚠️異なる！"

  # Feature 3-2: 決済処理
  feature3_2 = Issue.create!(
    project: sakura_ec,
    tracker: feature_tracker,
    subject: '決済処理機能',
    description: 'クレジットカード・コンビニ決済',
    status: status_new,
    priority: priority_urgent,
    author: suzuki,
    parent_issue_id: epic3.id,
    fixed_version: created_versions['v5']
  )
  puts "    └─ Feature: #{feature3_2.subject} (Version: #{feature3_2.fixed_version.name})"

  puts "\n  📝 UserStory配置の検証ポイント:"
  puts "    ⚠️ US2, US4, US5, US8, US10 は親Featureと異なるVersionを持つ"
  puts "    ⚠️ 修正前の実装では、これらがFeatureのVersionに引きずられて誤配置される"
  puts "    ✅ 修正後は、各UserStory自身のVersionでセル配置される"

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
puts "  Issue数: #{Issue.count}"
puts "    - Epic: #{Issue.joins(:tracker).where(trackers: { name: 'エピック' }).count}"
puts "    - Feature: #{Issue.joins(:tracker).where(trackers: { name: '機能' }).count}"
puts "    - UserStory: #{Issue.joins(:tracker).where(trackers: { name: 'ユーザストーリ' }).count}"
puts "  プラグイン設定: #{Setting.plugin_redmine_epic_grid.present? ? '設定済み' : '未設定'}"

puts "\n🌸 === 桜商店カンバンテストデータ投入完了！ === 🌸"
puts "以下のコマンドで実行:"
puts "  cd /usr/src/redmine"
puts "  RAILS_ENV=development rails runner plugins/redmine_epic_grid/db/seeds/kanban_test_data.rb"
