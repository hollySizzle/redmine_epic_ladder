# Backend Testing Standards

バックエンドテスト規約 - RSpec/FactoryBot/Playwright環境構築・実行・デバッグ

## テスト環境セットアップ

### 初回セットアップ

```bash
cd /usr/src/redmine/plugins/redmine_epic_grid
bash bin/setup_test_env.sh
```

**自動実行内容:**
1. DATABASE_URLバックアップ
2. database.yml再生成（test環境追加）
3. DATABASE_URL削除（database.yml優先）
4. redmine_test DB作成
5. Redmine default dataロード
6. RSpec/Playwright環境構築

### DATABASE_URL 環境変数問題

**問題:** `DATABASE_URL`設定時、`database.yml`が無視され、test環境でもdevelopment DBに接続

**解決:**

```bash
# テスト実行前（必須）
unset DATABASE_URL

# テスト実行
RAILS_ENV=test bundle exec rspec spec/models

# development復帰
export DATABASE_URL="postgresql://postgres:example@db:5432/redmine_dev"
```

### database.yml 構造

自動生成: `config/database.yml`

```yaml
development:
  database: redmine_dev

test:
  database: redmine_test  # 別DB

production:
  database: redmine_dev
```

## テストフレームワーク

- **RSpec**: テストフレームワーク
- **FactoryBot**: テストデータ生成（YAMLフィクスチャ不使用）
- **DatabaseCleaner**: テストデータクリーンアップ
- **Playwright**: E2E ブラウザ自動化

## ディレクトリ構成

```
spec/
├── models/epic_grid/        # Model（ビジネスロジック）
├── controllers/epic_grid/   # Controller（HTTP層のみ）
├── system/epic_grid/        # E2E (Playwright)
├── factories/               # FactoryBot定義
├── support/                 # ヘルパー
├── rails_helper.rb          # RSpec設定
└── spec_helper.rb           # 基本設定
```

**削除:**
- `spec/fixtures/` - FactoryBotに統一
- `spec/requests/` - Model + Controller + Systemで充足

## Test Pyramid

```
        ┌─────────────┐
        │  E2E Tests  │  ← 少数（遅い、壊れやすい）
        │   (System)  │
        ├─────────────┤
        │ Controller  │  ← 中量（HTTP層のみ）
        │   Tests     │
        ├─────────────┤
        │   Model     │  ← 大量（速い、安定）
        │   Tests     │  ← ビジネスロジック
        └─────────────┘
```

**原則:**
1. **Model Tests（最優先）**: ビジネスロジックは全てModelに実装し、Modelでテスト
2. **Controller Tests**: HTTP処理と認可のみテスト（ビジネスロジックはテストしない）
3. **System Tests**: 重要なユーザーフロー全体のみテスト

### 2.1 Model テスト

**対象**: `app/models/` - ビジネスロジック (Fat Model原則)
**場所**: `spec/models/`

```ruby
# spec/models/epic_grid/tracker_hierarchy_spec.rb
require_relative '../../rails_helper'

RSpec.describe EpicGrid::TrackerHierarchy, type: :model do
  describe '.level' do
    it { expect(described_class.level('Epic')).to eq(0) }
    it { expect(described_class.level('Unknown')).to be_nil }
  end

  describe '.valid_parent?' do
    it 'allows Feature as child of Epic' do
      expect(described_class.valid_parent?(feature_tracker, epic_tracker)).to be true
    end
  end
end
```

**pending で将来実装を文書化:**

```ruby
# spec/models/issue_spec.rb
RSpec.describe Issue, type: :model do
  describe '#move_to_cell (Fat Model - 将来実装)' do
    pending 'moves feature to target epic and version'
    pending 'propagates version to child user stories'
  end
end
```

### 2.2 Controller テスト

**対象**: `app/controllers/` - HTTP処理と認可のみ (Skinny Controller原則)
**場所**: `spec/controllers/`

```ruby
# spec/controllers/epic_grid/grid_controller_spec.rb
require_relative '../../rails_helper'

RSpec.describe EpicGrid::GridController, type: :controller do
  before do
    allow(User).to receive(:current).and_return(user)
    @request.session[:user_id] = user.id
  end

  describe 'GET #show' do
    it 'returns 200 and JSON response' do
      get :show, params: { project_id: project.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('entities', 'grid')
    end

    context 'without permission' do
      it 'returns 403' do
        # unauthorized setup
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
```

**テスト範囲:**
- ✅ HTTPステータス、レスポンス形式、認可
- ❌ ビジネスロジック（→ Modelでテスト）

### 2.3 E2E テスト (System spec)

**対象**: ブラウザを使用した統合テスト
**場所**: `spec/system/`
**ツール**: RSpec + FactoryBot + Playwright

**参照実装**: `spec/system/epic_grid/simple_e2e_spec.rb`

## 3. テスト実行方法

### ✅ 推奨: プラグインディレクトリから実行

```bash
cd /usr/src/redmine/plugins/redmine_epic_grid

# DATABASE_URLを削除（重要！）
unset DATABASE_URL

# Model テスト
RAILS_ENV=test bundle exec rspec spec/models --format documentation

# 特定のファイル
RAILS_ENV=test bundle exec rspec spec/models/epic_grid/tracker_hierarchy_spec.rb

# 特定の行
RAILS_ENV=test bundle exec rspec spec/models/epic_grid/tracker_hierarchy_spec.rb:22

# Controller テスト
RAILS_ENV=test bundle exec rspec spec/controllers --format documentation

# System テスト
RAILS_ENV=test bundle exec rspec spec/system --format documentation
```

### Redmineルートから実行（従来通り）

```bash
cd /usr/src/redmine

# DATABASE_URLを削除（重要！）
unset DATABASE_URL

# Model テスト
RAILS_ENV=test bundle exec rspec plugins/redmine_epic_grid/spec/models --format documentation
```

**どちらのディレクトリからでも実行可能:**
- `spec/rails_helper.rb` が自動的にカレントディレクトリをRedmineルートに変更します

## 4. FactoryBot テストデータ

**場所**: `spec/factories/epic_grid_issues.rb`

```ruby
FactoryBot.define do
  factory :epic_tracker, class: 'Tracker' do
    sequence(:name) { 'Epic' }
    default_status { IssueStatus.find_by(name: 'New') || IssueStatus.first }
  end

  factory :epic, class: 'Issue' do
    association :project
    association :tracker, factory: :epic_tracker
    sequence(:subject) { |n| "Epic #{n}" }

    trait :with_features do
      after(:create) { |epic| create_list(:feature, 3, parent: epic, project: epic.project) }
    end
  end
end
```

**使用例:**
```ruby
epic = create(:epic, subject: 'My Epic')
epic = create(:epic, :with_features)  # 3つのFeature付き
```

**ベストプラクティス:**
- ✅ `sequence` でユニーク値、`trait` でバリエーション
- ✅ Redmine default data再利用 (`IssueStatus.first`)
- ❌ `find_or_create_by!` で固定ID（DB衝突）
- ❌ YAMLフィクスチャ混在

## 5. rails_helper.rb 重要設定

### 5.1 RAILS_ENV強制 (development DB保護)

```ruby
# spec/rails_helper.rb:40-42
ENV['RAILS_ENV'] = 'test' unless ENV['RAILS_ENV']
```

### 5.2 プラグインディレクトリ実行対応

```ruby
# spec/rails_helper.rb:44-48
REDMINE_ROOT = File.expand_path('../../..', __dir__)
Dir.chdir(REDMINE_ROOT) unless Dir.pwd == REDMINE_ROOT
```

### 5.3 DatabaseCleaner安全装置

```ruby
# spec/rails_helper.rb:127-131
config.before(:suite) do
  raise "Must run in test env!" unless Rails.env.test?
end
```

### 5.4 require_relative 必須

```ruby
# ✅ GOOD
require_relative '../../rails_helper'

# ❌ BAD (RSpecはspec/を含まない)
require 'rails_helper'
```

## 6. DatabaseCleaner

**保護テーブル** (truncation除外):
```ruby
%w[roles trackers issue_statuses enumerations workflows custom_fields settings groups_users]
```

**削除テーブル**: `users`, `projects`, `issues`, `versions`, `members`

**戦略切り替え:**
```ruby
config.around(:each) do |example|
  if example.metadata[:type] == :system
    DatabaseCleaner.strategy = :truncation, { except: protected_tables }  # 別プロセス対応
  else
    DatabaseCleaner.strategy = :transaction  # 高速
  end
end
```

## 7. トラブルシューティング

### 実行前チェック

```bash
echo $DATABASE_URL           # 空ならOK
echo $RAILS_ENV              # "test"ならOK
RAILS_ENV=test bundle exec rails runner "puts ActiveRecord::Base.connection.current_database"
# → "redmine_test"ならOK
```

### development DB破壊時

```bash
export DATABASE_URL="postgresql://postgres:example@db:5432/redmine_dev"
bash bin/reset_db
```

### テスト環境リセット

```bash
bash bin/setup_test_env.sh  # 自動

# 手動リセット
unset DATABASE_URL
RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data
```

### その他

```bash
# Playwright
npx playwright install chromium

# ポート3001使用中
lsof -ti:3001 | xargs -r kill -9
```

## 8. E2E テスト

### 作成方法

```bash
cp spec/system/epic_grid/simple_e2e_spec.rb spec/system/epic_grid/my_feature_spec.rb
```

**基本構造そのまま使用**: プロジェクト/ユーザー作成、ログインフロー

**変更箇所のみ修正**:
```ruby
before(:each) { @data = create(:issue, project: project) }

it 'displays feature' do
  @playwright_page.goto("/projects/#{project.identifier}/my_route")
  @playwright_page.wait_for_selector('.my-component')
  expect(@playwright_page.query_selector("text='#{@data.subject}'")).not_to be_nil
end
```

### デバッグ手順

**Phase 1: Reference Test実行**
```bash
RAILS_ENV=test bundle exec rspec spec/system/epic_grid/simple_e2e_spec.rb
```
- ✅ 成功 → コードに問題
- ❌ 失敗 → 環境に問題（default dataロード、組み込みグループ確認）

**Phase 2: 詳細調査**
```bash
# スクリーンショット
ls -lth tmp/test_artifacts/screenshots/ | head -3

# ログ
tail -50 log/test.log | grep ERROR

# セレクタ確認
grep -r "className" assets/javascripts/ | grep -i "grid"
```

## 10. 参考

- `bin/setup_test_env.sh` - セットアップスクリプト
- `spec/system/epic_grid/simple_e2e_spec.rb` - E2Eテンプレート
- `spec/rails_helper.rb` - RSpec設定
- `spec/factories/` - FactoryBot定義
- `vibes/docs/rules/backend_standards.md` - Backend規約
