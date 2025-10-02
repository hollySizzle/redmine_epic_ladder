# Backend Testing Guide

Redmine Release Kanban プラグインのバックエンドテスト規約

## 1. テスト構成

### テストフレームワーク

- **RSpec**: テストフレームワーク
- **FactoryBot**: テストデータ生成
- **DatabaseCleaner**: テストデータクリーンアップ
- **Playwright**: E2E テスト用ブラウザ自動化

### ディレクトリ構成

```
spec/
├── models/           # Model テスト
├── controllers/      # Controller テスト
├── requests/         # API リクエストテスト
├── system/           # E2E テスト (Playwright)
├── factories/        # FactoryBot ファクトリー定義
├── fixtures/         # テストフィクスチャ
└── support/          # ヘルパーモジュール
```

## 2. テスト種別

### 2.1 Model テスト

**対象**: `app/models/` 配下のモデルクラス
**場所**: `spec/models/`
**ツール**: RSpec + shoulda-matchers + FactoryBot

**テストパターン**:
```ruby
# spec/models/issue_spec.rb
require 'rails_helper'

RSpec.describe Issue, type: :model do
  describe 'associations' do
    it { should belong_to(:project) }
    it { should have_many(:children).class_name('Issue') }
  end

  describe 'validations' do
    it { should validate_presence_of(:subject) }
  end

  describe 'methods' do
    it 'returns epic issues' do
      epic = create(:issue, tracker: Tracker.find_by(name: 'Epic'))
      expect(Issue.epics).to include(epic)
    end
  end
end
```

### 2.2 Controller テスト

**対象**: `app/controllers/` 配下のコントローラー
**場所**: `spec/controllers/`, `spec/requests/`
**ツール**: RSpec + FactoryBot

**テストパターン**:
```ruby
# spec/requests/kanban_api_spec.rb
require 'rails_helper'

RSpec.describe 'Kanban API', type: :request do
  let(:project) { create(:project) }
  let(:user) { create(:user, admin: true) }

  before { sign_in user }

  describe 'GET /projects/:project_id/kanban/api/data' do
    it 'returns kanban data as JSON' do
      get "/projects/#{project.identifier}/kanban/api/data"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json')

      json = JSON.parse(response.body)
      expect(json).to have_key('epics')
      expect(json).to have_key('versions')
    end
  end
end
```

### 2.3 E2E テスト (System spec)

**対象**: ブラウザを使用した統合テスト
**場所**: `spec/system/`
**ツール**: RSpec + FactoryBot + Playwright

**参照実装**: `spec/system/kanban/simple_e2e_spec.rb`

## 3. E2E テスト詳細

### 3.1 新規 E2E テスト作成方法

**ステップ 1: Reference Test をコピー**

```bash
cp spec/system/kanban/simple_e2e_spec.rb spec/system/kanban/my_feature_spec.rb
```

**ステップ 2: 基本構造はそのまま使用**

以下の部分は `simple_e2e_spec.rb` のパターンをそのまま使用:
- プロジェクト作成 (`let(:project)`)
- ユーザー作成と権限設定 (`let(:user)`, `before(:each)`)
- ログインフロー

**ステップ 3: テストデータとアサーションを変更**

```ruby
# テストデータ作成
before(:each) do
  @my_data = create(:issue, project: project, ...)
end

# アサーション
it 'displays my feature' do
  # ... ログイン処理 (simple_e2e_spec.rb と同じ) ...

  # ページ遷移
  @playwright_page.goto("/projects/#{project.identifier}/my_route")

  # 要素確認
  @playwright_page.wait_for_selector('.my-component')
  expect(@playwright_page.query_selector("text='#{@my_data.subject}'")).not_to be_nil
end
```

### 3.2 テスト失敗時のデバッグ手順

#### Phase 1: 環境 vs コードの切り分け

**まず Reference Test を実行**:

```bash
cd /usr/src/redmine
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system/kanban/simple_e2e_spec.rb
```

- ✅ **成功** → あなたのテストコードに問題があります
  - → Phase 2 へ進む

- ❌ **失敗** → 環境設定に問題があります
  - → 以下を確認:

```bash
# 組み込みグループ確認
RAILS_ENV=test bundle exec rails runner "puts \"Groups: #{Group.count}\""

# 組み込みグループ再作成
RAILS_ENV=test bundle exec rails runner "
GroupAnonymous.load_instance
GroupNonMember.load_instance
puts '✅ Built-in groups created'
"

# デフォルトデータロード
RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data
```

#### Phase 2: テストコードのデバッグ

**1. スクリーンショット確認**

```bash
# 最新のスクリーンショットを確認
ls -lth /usr/src/redmine/tmp/test_artifacts/screenshots/ | head -3
```

- 何が表示されているか？
- 期待した要素はあるか？
- CSS クラス名は正しいか？

**2. Rails サーバーログ確認**

```bash
# 最新 50 行を確認
tail -50 /usr/src/redmine/log/test.log

# エラー行のみ
tail -100 /usr/src/redmine/log/test.log | grep -A 5 ERROR
```

- 500 エラーが出ていないか？
- API エンドポイントは正しいか？
- データベースクエリは成功しているか？

**3. セレクタ確認**

```bash
# React コンポーネントの className を検索
cd /workspace/containers/202501_redmine/app/plugins/redmine_release_kanban
grep -r "className" assets/javascripts/kanban/src/components/ | grep -i "grid\|kanban\|epic"
```

- テストで使用しているセレクタが実際に存在するか確認
- スクリーンショットと照らし合わせる

### 3.3 よくあるエラーと対処法

#### エラー 1: "Timeout on /login"

```
Playwright::TimeoutError:
  Timeout 30000ms exceeded.
  - navigating to "http://localhost:3001/login", waiting until "load"
```

**原因**: Rails サーバーが 500 エラーでクラッシュしている

**対処法**:
1. Rails ログ確認: `tail -50 log/test.log`
2. よくある原因:
   - `GroupAnonymous` / `GroupNonMember` が存在しない
   - `User.current` が nil
   - データベース不整合

```bash
# 組み込みグループ確認と再作成
RAILS_ENV=test bundle exec rails runner "
GroupAnonymous.load_instance rescue nil
GroupNonMember.load_instance rescue nil
puts \"Groups: #{Group.count}\"
"
```

#### エラー 2: "Element not found"

```
Playwright::TimeoutError:
  Timeout 15000ms exceeded.
  - waiting for locator(".some-class") to be visible
```

**原因**: CSS セレクタが間違っている、または React コンポーネントが読み込まれていない

**対処法**:
1. スクリーンショット確認: 実際に何が表示されているか
2. React コンポーネントで実際に使われている className を検索:
   ```bash
   grep -r "className" assets/javascripts/kanban/src/ | grep "some-class"
   ```
3. ブラウザの開発者ツール相当の情報を取得:
   ```ruby
   # テストに追加
   puts @playwright_page.content  # HTML 全体を出力
   ```

#### エラー 3: "Expected 'Text' but got nil"

```ruby
expect(@playwright_page.query_selector("text='E2E Test Epic'")).not_to be_nil
# expected: not nil
#      got: nil
```

**原因**: テストデータが表示されていない

**対処法**:
1. スクリーンショット確認: 何が表示されているか
2. よくある原因:
   - **API コントローラーが未実装** (MSW モックデータが表示されている)
   - テストデータが作成されていない
   - DatabaseCleaner でデータが削除された
3. API 実装確認:
   ```bash
   # コントローラーが存在するか
   ls -la app/controllers/ | grep kanban

   # ルーティング確認
   bundle exec rake routes | grep kanban
   ```

#### エラー 4: "データが作成されているのに表示されない"

**原因**: API コントローラーが未実装で、フロントエンドが MSW モックデータを表示している

**判別方法**:
- スクリーンショットに「別のプロジェクトのデータ」が表示されている
- `assets/javascripts/kanban/src/mocks/handlers.ts` のサンプルデータが見える

**対処法**:
- Redmine プラグインの API コントローラーを実装する
- `app/controllers/kanban_controller.rb` を作成
- `config/routes.rb` にルート追加

## 4. テストデータ作成

### 4.1 FactoryBot の使用

Factクトリー定義: `spec/factories/`

```ruby
# spec/factories/projects.rb
FactoryBot.define do
  factory :project do
    sequence(:identifier) { |n| "project-#{n}" }
    sequence(:name) { |n| "Project #{n}" }
    status { Project::STATUS_ACTIVE }
  end
end
```

**使用例**:
```ruby
# デフォルト値で作成
project = create(:project)

# 属性を上書き
project = create(:project, identifier: 'my-project', name: 'My Project')

# 関連を設定
issue = create(:issue, project: project, author: user)
```

### 4.2 組み込みグループ

Redmine の `User.current.roles` メソッドは `GroupAnonymous` と `GroupNonMember` に依存します。

**自動作成**: `spec/rails_helper.rb` の `before(:suite)` で自動作成されます

**手動作成が必要な場合**:
```bash
RAILS_ENV=test bundle exec rails runner "
GroupAnonymous.load_instance
GroupNonMember.load_instance
"
```

### 4.3 DatabaseCleaner の挙動

**保護されるテーブル** (truncation で削除されない):
- `roles`
- `trackers`
- `issue_statuses`
- `enumerations`
- `workflows`
- `custom_fields`
- `settings`

**削除されるテーブル**:
- `users` (組み込みグループも削除される → 毎回再作成)
- `projects`
- `issues`
- `versions`

## 5. テスト実行

### 全テスト実行

```bash
cd /usr/src/redmine
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/
```

### 特定のテストのみ

```bash
# ファイル単位
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system/kanban/simple_e2e_spec.rb

# 行番号指定
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system/kanban/simple_e2e_spec.rb:58

# パターン指定
RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/system/
```

### カバレッジ測定

```bash
COVERAGE=1 RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/
```

カバレッジレポート: `tmp/test_artifacts/coverage/index.html`

## 6. CI/CD での実行

### GitHub Actions 設定例

```yaml
- name: Setup test database
  run: |
    cd /usr/src/redmine
    RAILS_ENV=test bundle exec rake db:schema:load
    RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data

- name: Run backend tests
  run: |
    cd /usr/src/redmine
    RAILS_ENV=test bundle exec rspec plugins/redmine_release_kanban/spec/

- name: Upload screenshots on failure
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: test-screenshots
    path: /usr/src/redmine/tmp/test_artifacts/screenshots/
```

## 7. トラブルシューティング

### テスト環境のリセット

```bash
# データベースリセット
cd /usr/src/redmine
RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load

# デフォルトデータロード
RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data

# 組み込みグループ作成
RAILS_ENV=test bundle exec rails runner "
GroupAnonymous.load_instance
GroupNonMember.load_instance
puts '✅ Test environment reset complete'
"
```

### Playwright が動かない場合

```bash
# Playwright ブラウザインストール
npx playwright install chromium

# 権限確認
ls -la node_modules/.bin/playwright
```

### ポート 3001 が使用中

```bash
# プロセス確認
lsof -ti:3001

# 強制終了
lsof -ti:3001 | xargs -r kill -9
```

## 8. 参考リンク

- **Reference Test**: `spec/system/kanban/simple_e2e_spec.rb`
- **RSpec 設定**: `spec/rails_helper.rb`
- **FactoryBot 定義**: `spec/factories/`
- **Playwright 公式ドキュメント**: https://playwright.dev/
- **RSpec 公式ドキュメント**: https://rspec.info/
