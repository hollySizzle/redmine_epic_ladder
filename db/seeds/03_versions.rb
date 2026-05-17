# frozen_string_literal: true

puts "🌸 === [3/5] バージョン投入 (open状態) === 🌸"

# ===== バージョン投入 =====
puts "\n📅 バージョンを投入中..."

sakura_ec = Project.find_by(identifier: 'sakura-ec')
if sakura_ec
  versions_data = [
    { name: 'v0.8.0 - アルファ版', description: '社内テスト版・基本機能検証', effective_date: '2025-05-31', status: 'open' },
    { name: 'v0.9.0 - ベータ版', description: 'クローズドベータテスト版・限定公開', effective_date: '2025-06-30', status: 'open' },
    { name: 'v1.0.0 - MVP', description: '最小限の機能で早期リリース', effective_date: '2025-08-31', status: 'open' },
    { name: 'v1.1.0 - 初期フィードバック対応', description: 'ベータユーザーからのフィードバック反映', effective_date: '2025-10-15', status: 'open' },
    { name: 'v1.2.0 - 機能拡張', description: '商品管理・検索機能の強化', effective_date: '2025-11-30', status: 'open' },
    { name: 'v2.0.0 - 大型アップデート', description: 'UIリニューアルとパフォーマンス改善', effective_date: '2026-01-31', status: 'open' },
    { name: 'v2.1.0 - UI改善', description: 'モバイル対応とアクセシビリティ向上', effective_date: '2026-03-31', status: 'open' },
    { name: 'v2.2.0 - パフォーマンス改善', description: 'キャッシュ最適化とDB高速化', effective_date: '2026-05-31', status: 'open' },
    { name: 'v2.3.0 - AI機能統合', description: 'AIレコメンド機能の段階的導入', effective_date: '2026-07-31', status: 'open' },
    { name: 'v3.0.0 - 次世代プラットフォーム', description: 'マイクロサービス化と新アーキテクチャ', effective_date: '2026-09-30', status: 'open' }
  ]

  versions_data.each do |data|
    version = sakura_ec.versions.find_or_initialize_by(name: data[:name])
    version.assign_attributes(
      description: data[:description],
      effective_date: Date.parse(data[:effective_date]),
      status: data[:status]
    )

    if version.save
      puts "  ✅ #{version.name} (#{version.effective_date}) - #{version.status}"
    else
      puts "  ❌ #{data[:name]} の作成に失敗: #{version.errors.full_messages.join(', ')}"
    end
  end
else
  puts "  ❌ 桜商店ECサイトプロジェクトが見つかりません"
end

ai_recommend = Project.find_by(identifier: 'ai-recommend')
if ai_recommend
  puts "\n📅 AIレコメンドMCPサンドボックス用バージョンを投入中..."

  versions_data = [
    { name: 'MCP-SEED Alpha', description: 'MCP検証用Alphaバージョン', effective_date: '2026-10-31', status: 'open' },
    { name: 'MCP-SEED Beta', description: 'MCP検証用Betaバージョン', effective_date: '2026-11-30', status: 'open' },
    { name: 'MCP-SEED Gamma', description: 'MCP検証用Gammaバージョン', effective_date: '2026-12-31', status: 'open' }
  ]

  versions_data.each do |data|
    version = ai_recommend.versions.find_or_initialize_by(name: data[:name])
    version.assign_attributes(
      description: data[:description],
      effective_date: Date.parse(data[:effective_date]),
      status: data[:status]
    )

    if version.save
      puts "  ✅ #{version.name} (#{version.effective_date}) - #{version.status}"
    else
      puts "  ❌ #{data[:name]} の作成に失敗: #{version.errors.full_messages.join(', ')}"
    end
  end
else
  puts "  ⚠️  AIレコメンド機能開発プロジェクトが見つかりません"
end

puts "\n✅ [3/5] バージョン投入完了 (全てopen状態)"
puts "    ※ Issue投入後、05_finalize_versions.rbでclosed/lockedに変更されます"
