# 🚨 Release Kanban アンチモック テスト戦略

## 🎯 **基本原則：実際の動作のみテスト**

**モック禁止・実装必須の現実的テスト規約**

### ❌ **絶対禁止事項**
```ruby
# ❌ 外部依存モック化（APIエンドポイント存在不明）
jest.mock('dhtmlx-gantt');
allow(ApiController).to receive(:kanban_data).and_return({success: true})

# ❌ プレースホルダーテスト（無意味）
assert true, 'Card movement test placeholder'

# ❌ 未実装機能テスト
expect(Kanban::NonExistentController).to respond_to(:some_method)
```

### ✅ **必須実装原則**
```ruby
# ✅ 実際のHTTPリクエスト
get "/kanban/projects/#{project.id}/cards"
assert_response :success

# ✅ 実際のDB操作
issue = Issue.create!(tracker: test_tracker)
assert issue.persisted?

# ✅ 実際のサービス呼び出し
result = Kanban::TestGenerationService.generate_test_for_user_story(user_story)
assert result[:test_issue].is_a?(Issue)
```

## 🔥 **段階的実装戦略**

### **フェーズ1: 基盤修復（最優先）**
1. **APIコントローラー最低限実装** → 404エラー根絶
2. **実際のHTTPテスト** → モック依存脱却
3. **データベーステスト** → 実際のCRUD確認

### **フェーズ2: 統合確認（高優先）**
1. **フロント-バック通信** → 実際のJSON確認
2. **サービス間連携** → 実際のトランザクション確認
3. **権限システム** → 実際のアクセス制御確認

## 📋 **実装必須テストケース**

### **1. HTTPエンドポイントテスト（最優先）**
```ruby
# test/integration/kanban_api_integration_test.rb
class KanbanApiIntegrationTest < ActionDispatch::IntegrationTest
  test "GET /kanban/projects/:id/cards returns 200" do
    project = projects(:projects_001)
    get "/kanban/projects/#{project.id}/cards"
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('cards') || json.key?('message')
  end
end
```

### **2. サービス実動テスト**
```ruby
# test/unit/kanban_tracker_hierarchy_test.rb
class KanbanTrackerHierarchyTest < ActiveSupport::TestCase
  test "valid_parent validates actual tracker relationships" do
    task_tracker = Tracker.find_by(name: 'Task') || Tracker.create!(name: 'Task')
    user_story_tracker = Tracker.find_by(name: 'UserStory') || Tracker.create!(name: 'UserStory')

    assert Kanban::TrackerHierarchy.valid_parent?(task_tracker, user_story_tracker)
    refute Kanban::TrackerHierarchy.valid_parent?(user_story_tracker, task_tracker)
  end
end
```

### **3. データベース永続化テスト**
```ruby
# test/unit/kanban_test_generation_service_test.rb
class KanbanTestGenerationServiceTest < ActiveSupport::TestCase
  test "generate_test_for_user_story creates actual database records" do
    user_story = issues(:issues_001)
    user_story.update!(tracker: trackers(:tracker_002)) # UserStory tracker

    result = Kanban::TestGenerationService.generate_test_for_user_story(user_story)

    assert result[:test_issue].persisted?
    assert_equal 'Test', result[:test_issue].tracker.name
    assert_equal user_story, result[:test_issue].parent
  end
end
```

## 🚨 **実装順序（厳守）**

### **ステップ1: APIコントローラー作成**
```bash
# 必須ファイル（404エラー解決）
app/controllers/kanban/api_controller.rb
app/controllers/kanban/hierarchy_controller.rb
# 他5つのコントローラー
```

### **ステップ2: HTTPテスト実行**
```bash
# 統合テストで404を検出
cd /usr/src/redmine && ruby -I test plugins/redmine_release_kanban/test/integration/kanban_api_integration_test.rb
```

### **ステップ3: 単体テスト修正**
```bash
# プレースホルダー削除、実際のテストに変更
cd /usr/src/redmine && ruby -I test plugins/redmine_release_kanban/test/unit/kanban_tracker_hierarchy_test.rb
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