# frozen_string_literal: true

puts "🌸 === [5/5] バージョン最終化 (closed/locked設定) === 🌸"

# ===== 過去バージョンをclosed/lockedに変更 =====
puts "\n📅 過去バージョンのステータスを変更中..."

sakura_ec = Project.find_by(identifier: 'sakura-ec')
if sakura_ec
  # v0.8.0をclosedに変更
  v_alpha = sakura_ec.versions.find_by(name: 'v0.8.0 - アルファ版')
  if v_alpha
    v_alpha.update(status: 'closed')
    puts "  ✅ #{v_alpha.name} → closed"
  else
    puts "  ⚠️  v0.8.0 - アルファ版が見つかりません"
  end

  # v0.9.0をclosedに変更
  v_beta = sakura_ec.versions.find_by(name: 'v0.9.0 - ベータ版')
  if v_beta
    v_beta.update(status: 'closed')
    puts "  ✅ #{v_beta.name} → closed"
  else
    puts "  ⚠️  v0.9.0 - ベータ版が見つかりません"
  end

  puts "\n📊 最終バージョン一覧:"
  sakura_ec.versions.order(:effective_date).each do |v|
    status_icon = case v.status
                  when 'closed' then '🔒'
                  when 'locked' then '🔐'
                  else '✅'
                  end
    puts "  #{status_icon} #{v.name} (#{v.effective_date}) - #{v.status}"
  end
else
  puts "  ❌ 桜商店ECサイトプロジェクトが見つかりません"
end

puts "\n✅ [5/5] バージョン最終化完了"
puts "\n🎉 === 桜商店カンバンテストデータ投入完了！ === 🎉"
