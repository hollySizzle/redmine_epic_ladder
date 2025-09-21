# 🎯 Release Kanban テスト戦略

## 📋 概要

Release Kanbanプラグインの7つのコアコンポーネントに対する包括的テスト戦略とテストピラミッド実装規約

### 🎯 テスト対象コンポーネント

| コンポーネント | 重要度 | 説明 |
|---|---|---|
| 📊 TrackerHierarchy | 🔴 Critical | Epic→Feature→UserStory→Task/Test の4段階階層制約 |
| 🔄 VersionManagement | 🟡 High | UserStoryから子要素への自動バージョン伝播ロジック |
| 🤖 AutoGeneration | 🟡 High | UserStory作成時のTest自動生成 + blocks関係作成 |
| 🚦 StateTransition | 🟡 High | カンバンカラム移動時の状態遷移制御 |
| 🛡️ ValidationGuard | 🔴 Critical | 3層ガード検証（Task完了・Test合格・重大Bug解決） |
| 🎨 KanbanUI | 🟢 Medium | ドラッグ&ドロップ、Epic Swimlane表示 |
| 🔌 APIIntegration | 🔴 Critical | React-Rails間データ交換の正確性 |

## 🏗️ テストピラミッド構造

```
       /\
      /  \     Phase 4: System/E2E Tests
     /____\    - ユーザージャーニー
    /      \   - ブラウザ統合テスト
   /        \  - パフォーマンステスト
  /__________\
 /            \ Phase 3: Integration Tests
/              \- API統合テスト
\              /- サービス間連携テスト
 \____________/ - コントローラーテスト
/              \
\              / Phase 2: Service Tests
 \____________/  - ビジネスロジックテスト
/              \ - 状態遷移テスト
\              / - 検証ガードテスト
 \____________/
/              \
\    Phase 1   / Unit Tests
 \____________/  - モデル単体テスト
                 - バリデーションテスト
                 - ヘルパーテスト
```

## 📊 Phase 1: 単体テスト（Unit Tests）

### 目的
- 個別クラス・メソッドの動作保証
- ビジネスルールの厳密な検証
- 高速フィードバックループの構築

### 対象
- `app/models/kanban/tracker_hierarchy.rb`
- `app/services/kanban/*_service.rb`
- `lib/kanban/helpers/*`

### テスト観点
```ruby
# 正常系
- 期待される入力に対する正しい出力
- ビジネスルールの遵守

# 境界値
- 最大・最小・空値での動作
- edge caseの処理

# 異常系
- 不正入力の拒否
- 適切なエラーメッセージ

# パフォーマンス
- 大量データでの性能維持
- メモリリーク防止
```

### 実装例
```ruby
RSpec.describe Kanban::TrackerHierarchy do
  describe '.valid_parent?' do
    it '正常な親子関係を許可する' do
      expect(described_class.valid_parent?(task_tracker, user_story_tracker)).to be true
    end

    it '不正な関係を拒否する' do
      expect(described_class.valid_parent?(task_tracker, feature_tracker)).to be false
    end

    it 'nil安全性を保証する' do
      expect(described_class.valid_parent?(nil, user_story_tracker)).to be false
    end
  end
end
```

## 🤖 Phase 2: サービステスト（Service Tests）

### 目的
- ビジネスロジックの統合動作確認
- サービス間の連携検証
- トランザクション制御の確認

### 対象
- `app/services/kanban/test_generation_service.rb`
- `app/services/kanban/version_propagation_service.rb`
- `app/services/kanban/state_transition_service.rb`
- `app/services/kanban/validation_guard_service.rb`

### テスト観点
```ruby
# サービス連携
- 複数サービスの協調動作
- データ整合性の維持

# トランザクション
- 成功時のコミット
- 失敗時のロールバック

# 状態変化
- 前状態と後状態の確認
- 副作用の検証

# エラーハンドリング
- 適切なエラー情報返却
- ログ出力の確認
```

### 実装例
```ruby
RSpec.describe Kanban::TestGenerationService do
  describe '.generate_test_for_user_story' do
    it 'Testを生成しblocks関係を作成する' do
      result = described_class.generate_test_for_user_story(user_story)

      expect(result[:test_issue]).to be_a(Issue)
      expect(result[:relation_created]).to be true

      # blocks関係の確認
      relation = IssueRelation.find_by(
        issue_from: result[:test_issue],
        issue_to: user_story,
        relation_type: 'blocks'
      )
      expect(relation).to be_present
    end

    it 'エラー時はロールバックされる' do
      allow(IssueRelation).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      initial_count = Issue.count
      result = described_class.generate_test_for_user_story(user_story)

      expect(result[:error]).to be_present
      expect(Issue.count).to eq(initial_count)
    end
  end
end
```

## 🔌 Phase 3: 統合テスト（Integration Tests）

### 目的
- API層からサービス層までの統合動作確認
- React-Rails間のデータ交換検証
- 権限・認証システムの確認

### 対象
- `app/controllers/kanban/api_controller.rb`
- `app/controllers/kanban_controller.rb`
- APIエンドポイント全体
- サービス間ワークフロー

### テスト観点
```ruby
# API統合
- HTTPリクエスト・レスポンス
- JSON形式の正確性
- ステータスコードの適切性

# 権限制御
- 認証・認可の動作
- プロジェクトアクセス制御
- ロールベース権限

# ワークフロー統合
- 複数サービスの連続実行
- データ流れの確認
- エラー伝播の検証
```

### 実装例
```ruby
RSpec.describe Kanban::ApiController, type: :request do
  describe 'POST /kanban/api/transition_issue' do
    it 'UserStoryの状態遷移が成功する' do
      post "/kanban/api/transition_issue", params: {
        project_id: project.id,
        issue_id: user_story.id,
        target_column: 'ready'
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['issue']['status']).to eq('Ready')

      user_story.reload
      expect(user_story.status.name).to eq('Ready')
    end

    it 'ブロック条件違反時はエラーを返す' do
      incomplete_task = create(:task, parent: user_story, status: 'New')

      post "/kanban/api/transition_issue", params: {
        project_id: project.id,
        issue_id: user_story.id,
        target_column: 'done'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include('未完了のTask')
    end
  end
end
```

## 🎨 Phase 4: システムテスト（System/E2E Tests）

### 目的
- ユーザー視点でのエンドツーエンド動作確認
- ブラウザでの実際の操作シミュレーション
- パフォーマンス・アクセシビリティの検証

### 対象
- カンバンページ全体
- ドラッグ&ドロップ操作
- Epic Swimlane表示
- フィルタリング機能

### テスト観点
```ruby
# ユーザージャーニー
- 典型的な作業フローの完全実行
- 複数画面にわたる操作

# ブラウザ統合
- JavaScript動作確認
- DOM操作の検証

# パフォーマンス
- ページ読み込み時間
- 大量データでの応答性

# アクセシビリティ
- キーボードナビゲーション
- スクリーンリーダー対応
```

### 実装例
```ruby
RSpec.describe 'Release Kanban System', type: :system, js: true do
  scenario 'ユーザーがカードをドラッグ&ドロップで移動する' do
    visit "/projects/#{project.identifier}/kanban"

    # Epic Swimlaneの表示確認
    expect(page).to have_selector('.epic-swimlane')

    # カードのドラッグ&ドロップ
    user_story_card = find('.issue-card[data-tracker="UserStory"]')
    in_progress_column = find('.kanban-column[data-column-id="in_progress"]')

    user_story_card.drag_to(in_progress_column)

    # 状態更新の確認
    expect(page).to have_content('In Progress')

    # データベース更新の確認
    user_story.reload
    expect(user_story.status.name).to eq('In Progress')
  end

  scenario 'Test自動生成機能が正常動作する' do
    visit "/projects/#{project.identifier}/kanban"

    within('.issue-card[data-tracker="UserStory"]') do
      click_button 'Test作成'
    end

    # Testカードの表示確認
    expect(page).to have_selector('.issue-card[data-tracker="Test"]')

    # データベース作成確認
    test_issue = Issue.joins(:tracker).find_by(
      trackers: { name: 'Test' },
      parent: user_story
    )
    expect(test_issue).to be_present
  end
end
```

## 📈 品質基準・成功指標

### カバレッジ目標
```yaml
全体カバレッジ: 80%以上
Critical要素: 95%以上
各コンポーネント: 85%以上

詳細:
  - models/: 90%以上
  - services/: 85%以上
  - controllers/: 80%以上
  - javascripts/: 75%以上
```

### パフォーマンス基準
```yaml
実行時間:
  - 全テスト: 5分以内
  - Phase 1+2: 2分以内
  - Phase 3: 1分以内
  - Phase 4: 2分以内

API応答:
  - 通常API: 200ms以内
  - 複雑処理: 500ms以内
  - 大量データ: 1秒以内
```

### 安定性基準
```yaml
CI成功率: 95%以上
フレーキーテスト: 0個
再現性: 100%（同条件で必ず同結果）
```

## 🛠️ テスト環境・ツール

### 必要なGem
```ruby
group :test do
  gem 'rspec-rails', '~> 5.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'capybara', '~> 3.0'
  gem 'selenium-webdriver', '~> 4.0'
  gem 'shoulda-matchers', '~> 5.3'
  gem 'rspec-benchmark', '~> 0.6'
  gem 'timecop', '~> 0.9'
  gem 'database_cleaner', '~> 2.0'
  gem 'simplecov', '~> 0.21'
end
```

### ブラウザ環境
```bash
# ChromeDriver（必須）
sudo apt-get install chromium-chromedriver

# または
npm install -g chromedriver
```

### Capybara設定
```ruby
# spec/rails_helper.rb
Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5
```

## 🚀 テスト実行戦略

### 開発フロー統合
```bash
# 1. ローカル開発時
./bin/test_runner.sh quick    # Phase 1+2のみ高速実行

# 2. フィーチャー完成時
./bin/test_runner.sh unit     # 詳細な単体・サービステスト

# 3. PR作成前
./bin/test_runner.sh full     # 全Phase実行

# 4. リリース前
./bin/test_runner.sh full && run_performance_tests
```

### CI/CD統合
```yaml
# .github/workflows/test.yml
strategy:
  matrix:
    phase: [phase1, phase2, phase3, phase4]
parallel: true
timeout: 10分
```

### 段階的テスト実行
```bash
# 緊急時の段階実行
./bin/test_runner.sh phase1   # Critical要素のみ
./bin/test_runner.sh phase2   # + サービス層
./bin/test_runner.sh phase3   # + API統合
./bin/test_runner.sh phase4   # + E2E（フル実行）
```

## 🔧 デバッグ・トラブルシューティング

### よくある問題と解決法

#### 1. System/E2Eテストの不安定性
```ruby
# 解決策: 適切な待機処理
expect(page).to have_selector('.issue-card', wait: 10)

# 動的要素の確実な待機
wait_for { page.has_content?('Expected Text') }
```

#### 2. データベース状態の不整合
```ruby
# 解決策: トランザクション分離
config.use_transactional_fixtures = true

# または明示的クリーンアップ
after(:each) do
  DatabaseCleaner.clean
end
```

#### 3. 非同期処理のテスト
```ruby
# 解決策: Timecop活用
Timecop.freeze(Time.current) do
  # テスト実行
end

# 非同期ジョブのテスト
expect(TestGenerationJob).to have_been_enqueued
```

### パフォーマンス改善
```ruby
# 1. テストデータの最小化
let!(:minimal_user_story) { build_minimal(:user_story) }

# 2. 並列実行の活用
RSpec.configure do |config|
  config.default_formatter = 'ParallelTests::RSpec::RuntimeLogger'
end

# 3. 重いセットアップの共有
before(:all) do
  @shared_project = create(:project_with_trackers)
end
```

## 📞 テスト規約遵守チェックリスト

### PR作成前チェック
- [ ] 新機能に対応するテストを全Phase作成
- [ ] カバレッジ基準を満たしている
- [ ] CI/CDが全て緑色で通過
- [ ] フレーキーテストが0個
- [ ] パフォーマンス基準を満たしている

### リリース前チェック
- [ ] 本番類似環境でのE2Eテスト実行
- [ ] 負荷テストの実施
- [ ] セキュリティテストの確認
- [ ] ブラウザ互換性テストの完了
- [ ] アクセシビリティテストの通過

### コードレビュー観点
- [ ] テストケースの網羅性
- [ ] テストの可読性・保守性
- [ ] 適切なテスト粒度の選択
- [ ] モックの適切な使用
- [ ] テストデータの適切性

---

**🎯 最終目標**: このテスト戦略により、Release Kanbanの品質向上・開発効率30%改善・バグ混入リスク80%削減を実現し、安心してリリースできる体制を構築する