# テスト自動化・CI/CD統合戦略

## 🔗 関連ドキュメント
- @vibes/rules/testing/kanban_test_strategy.md
- @vibes/rules/testing/redmine_test_implementation_guide.md

## 1. GitHub Actions CI/CD設定

### 1.1 基本ワークフロー
```yaml
# .github/workflows/test.yml
name: Redmine Plugin Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        redmine_version: ['5.0.10', '5.1.9', '6.0.6']
        ruby_version: ['3.1', '3.2', '3.3']
        db: ['sqlite3', 'mysql', 'postgresql']

    steps:
    - uses: actions/checkout@v4

    - name: Setup Redmine Plugin Test Environment
      uses: two-pack/redmine-plugin-test-action@v2
      with:
        plugin_name: redmine_release_kanban
        redmine_version: ${{ matrix.redmine_version }}
        ruby_version: ${{ matrix.ruby_version }}
        database: ${{ matrix.db }}

    - name: Run Plugin Tests
      run: |
        cd redmine
        bundle exec rake redmine:plugins:test PLUGIN=redmine_release_kanban
```

### 1.2 マトリックステスト理由
- **多バージョン対応** - Redmine 5.x〜6.x互換性保証
- **Ruby互換性** - Ruby 3.1〜3.3対応
- **DB環境網羅** - SQLite/MySQL/PostgreSQL対応

## 2. テスト段階別自動化

### 2.1 Pre-commit フック
```bash
#!/bin/sh
# .git/hooks/pre-commit

# 静的解析
bundle exec rubocop plugins/redmine_release_kanban/

# 高速テスト（Unit + Functional）
cd plugins/redmine_release_kanban/
./vibes/scripts/testing/test_runner.sh quick

if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

### 2.2 CI段階定義
```yaml
# 段階別テスト実行
jobs:
  lint:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: RuboCop
        run: bundle exec rubocop

  unit-tests:
    name: Unit Tests
    needs: lint
    strategy:
      matrix:
        ruby: ['3.1', '3.2', '3.3']
    steps:
      - name: Unit Tests
        run: rake redmine:plugins:test:units

  integration-tests:
    name: Integration Tests
    needs: unit-tests
    steps:
      - name: Integration Tests
        run: rake redmine:plugins:test:integration

  system-tests:
    name: E2E Tests
    needs: integration-tests
    steps:
      - name: System Tests
        run: rake redmine:plugins:test:system
```

## 3. カスタムtest_runner.sh活用

### 3.1 CI環境での実行
```bash
# CI環境変数設定
export CI=true
export RAILS_ENV=test

# フェーズ別実行
./vibes/scripts/testing/test_runner.sh phase1  # Critical機能
./vibes/scripts/testing/test_runner.sh phase2  # High機能
./vibes/scripts/testing/test_runner.sh phase3  # Integration
./vibes/scripts/testing/test_runner.sh phase4  # System

# 結果集約
if [ $? -eq 0 ]; then
  echo "::notice::All tests passed"
else
  echo "::error::Tests failed"
  exit 1
fi
```

### 3.2 並列実行最適化
```yaml
# 並列ジョブ設定
jobs:
  test-matrix:
    strategy:
      matrix:
        test_phase: [phase1, phase2, phase3, phase4]
    steps:
      - name: Run Test Phase
        run: ./vibes/scripts/testing/test_runner.sh ${{ matrix.test_phase }}
```

## 4. 品質ゲート設定

### 4.1 必須品質基準
```yaml
# 品質ゲート定義
quality_gates:
  - name: "All Tests Pass"
    condition: "test_result == 'success'"
    required: true

  - name: "Critical Coverage 100%"
    condition: "critical_coverage >= 100"
    required: true

  - name: "Overall Coverage 85%"
    condition: "overall_coverage >= 85"
    required: true

  - name: "No RuboCop Violations"
    condition: "rubocop_violations == 0"
    required: true
```

### 4.2 リリースブロック条件
```bash
# リリース判定スクリプト
check_release_ready() {
  local failed=0

  # Critical機能100%テスト
  if ! ./vibes/scripts/testing/test_runner.sh phase1; then
    echo "❌ Critical tests failed"
    failed=1
  fi

  # 全体カバレッジ85%以上
  # coverage_check.sh実行（実装後）

  # RuboCop violations 0
  if ! bundle exec rubocop; then
    echo "❌ Code quality check failed"
    failed=1
  fi

  if [ $failed -eq 0 ]; then
    echo "✅ Release ready"
    return 0
  else
    echo "❌ Release blocked"
    return 1
  fi
}
```

## 5. パフォーマンス監視

### 5.1 継続的パフォーマンステスト
```ruby
# test/performance/kanban_performance_test.rb
require File.expand_path('../../test_helper', __FILE__)
require 'benchmark'

class KanbanPerformanceTest < ActiveSupport::TestCase
  def test_api_response_benchmark
    # API応答時間ベンチマーク
    time = Benchmark.realtime do
      # KanbanController#data 実行
    end

    # CI環境での閾値チェック
    max_time = ENV['CI'] ? 0.5 : 0.2  # CI環境では緩め
    assert time < max_time, "API too slow: #{time}s > #{max_time}s"
  end
end
```

### 5.2 メモリ使用量監視
```ruby
def test_memory_usage
  GC.start
  before = GC.stat[:total_allocated_objects]

  # テスト対象実行
  perform_kanban_operations

  GC.start
  after = GC.stat[:total_allocated_objects]

  allocated = after - before
  assert allocated < 10000, "Too many objects allocated: #{allocated}"
end
```

## 6. 障害時対応

### 6.1 テスト失敗時の自動対応
```yaml
# テスト失敗時通知
- name: Notify on Test Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    text: "Release Kanban tests failed on ${{ matrix.redmine_version }}"
```

### 6.2 フレーキーテスト対策
```bash
# フレーキーテスト検出・再実行
run_flaky_test_detection() {
  local test_file=$1
  local retry_count=3

  for i in $(seq 1 $retry_count); do
    if rake redmine:plugins:test:units TEST="$test_file"; then
      return 0
    fi
    echo "Retry $i/$retry_count failed"
  done

  echo "❌ Consistently failing test: $test_file"
  return 1
}
```

## 7. 開発ワークフロー統合

### 7.1 開発者向けローカルテスト
```bash
# 開発前チェック
pre_development_check() {
  echo "🔍 Pre-development checks..."

  # 環境確認
  if ! bundle check; then
    echo "Run: bundle install"
    return 1
  fi

  # 高速テスト
  if ! ./vibes/scripts/testing/test_runner.sh quick; then
    echo "❌ Quick tests failed"
    return 1
  fi

  echo "✅ Ready for development"
}

# 開発後チェック
post_development_check() {
  echo "🔍 Post-development checks..."

  # 影響範囲テスト
  ./vibes/scripts/testing/test_runner.sh phase1  # Critical
  ./vibes/scripts/testing/test_runner.sh phase2  # High

  # 静的解析
  bundle exec rubocop

  echo "✅ Ready for commit"
}
```

### 7.2 PR作成時自動チェック
```yaml
# PR作成時の自動品質チェック
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  pr-quality-check:
    runs-on: ubuntu-latest
    steps:
      - name: Code Quality Check
        run: |
          bundle exec rubocop --format github

      - name: Test Coverage Check
        run: |
          ./vibes/scripts/testing/test_runner.sh full
          # カバレッジレポート生成・コメント
```

---

*継続的品質保証でRedmineプラグイン開発効率と信頼性を最大化*