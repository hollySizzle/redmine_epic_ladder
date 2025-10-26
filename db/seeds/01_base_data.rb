# frozen_string_literal: true

puts "🌸 === [1/5] 基本データ投入 === 🌸"

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

puts "\n✅ [1/5] 基本データ投入完了"
