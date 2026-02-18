# frozen_string_literal: true

puts "🌸 === [4/5] Issue階層構造投入 === 🌸"

# プロジェクトとバージョンを取得
sakura_ec = Project.find_by(identifier: 'sakura-ec')
unless sakura_ec
  puts "  ❌ 桜商店ECサイトプロジェクトが見つかりません"
  exit
end

# バージョンをハッシュで取得
created_versions = {}
sakura_ec.versions.each do |v|
  created_versions[v.name] = v
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


puts "\n✅ [4/5] Issue階層構造投入完了"
puts "    Epic: #{epic_count}個, Feature: #{feature_count}個, UserStory: #{us_count}個, Task: #{task_count}個"
