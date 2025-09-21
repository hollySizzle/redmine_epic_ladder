# Service実装規約

## Service層の責務

### 核心機能
- ビジネスロジック実装
- データ変換・加工
- 外部システム連携
- 複雑な計算・判定

### 制約事項
- HTTP要求処理禁止
- View描画処理禁止
- 直接権限チェック禁止（Controller層の責務）

## 設計原則

### 単一責任の原則
```ruby
# ✅ Good: 単一機能特化
class Kanban::VersionPropagationService
  def self.propagate_to_children(user_story, version, options = {})
    # バージョン伝播のみに特化
  end
end

# ❌ Bad: 複数責務混在
class BadKanbanService
  def do_everything # バージョン・状態・検証すべて
end
```

### 戻り値統一規約
```ruby
# ✅ 成功時
{ success: true, data: result_data, meta: additional_info }

# ✅ 失敗時
{ success: false, error: error_message, error_code: 'CODE', details: error_details }
```

## データ変換規約

### 階層構造処理
```ruby
class Kanban::HierarchyBuilder
  def self.build_epic_tree(project, filters = {})
    epics = load_epics_with_includes(project, filters)
    epics.map { |epic| build_epic_node(epic) }
  end

  private

  def self.load_epics_with_includes(project, filters)
    # N+1対策: 必要な関連データを事前読み込み
    project.issues
           .includes(:tracker, :status, :assigned_to, :fixed_version, :children)
           .joins(:tracker)
           .where(trackers: { name: 'Epic' })
           .then { |scope| apply_filters(scope, filters) }
  end
end
```

### カスタムフィールド処理標準
```ruby
def extract_custom_fields(issue)
  custom_fields = {}

  issue.custom_field_values.each do |custom_value|
    field = custom_value.custom_field
    next unless field

    field_id = "cf_#{field.id}"
    custom_fields[field_id] = format_custom_field_value(custom_value)
  end

  custom_fields
end

def format_custom_field_value(custom_value)
  field = custom_value.custom_field
  raw_value = custom_value.value

  case field.field_format
  when 'user'
    format_user_field(raw_value)
  when 'list'
    raw_value.to_s
  when 'bool'
    raw_value.present? && raw_value != "0" ? "はい" : "いいえ"
  when 'date'
    raw_value.present? ? raw_value.to_s : ""
  else
    raw_value.to_s
  end
end
```

## パフォーマンス最適化

### クエリ最適化必須パターン
```ruby
# ✅ includes活用
issues = Issue.includes(:tracker, :status, :assigned_to, :fixed_version, :children)

# ✅ pluck活用
version_ids = issues.pluck(:fixed_version_id).compact.uniq
versions = Version.where(id: version_ids).index_by(&:id)

# ✅ バッチ処理
Issue.where(id: issue_ids).find_each(batch_size: 100) do |issue|
  # 処理
end
```

### メモリ効率化
```ruby
# ✅ 配列・ActiveRecord::Relation両対応
def extract_data(issues_relation)
  if issues_relation.respond_to?(:pluck)
    issues_relation.pluck(:id, :subject)
  else
    issues_relation.map { |issue| [issue.id, issue.subject] }
  end
end
```

## エラーハンドリング規約

### カスタム例外定義
```ruby
module Kanban
  class StateTransitionService
    class InvalidTransitionError < StandardError; end
    class TransitionBlockedError < StandardError; end

    def self.transition_to_column(issue, target_column)
      validate_transition(issue, target_column)
      # 処理実行
    rescue => e
      { success: false, error: e.message, issue_id: issue.id }
    end
  end
end
```

### 段階的例外処理
```ruby
def complex_operation
  ActiveRecord::Base.transaction do
    step1_result = execute_step1
    step2_result = execute_step2(step1_result)
    step3_result = execute_step3(step2_result)

    { success: true, data: step3_result }
  end
rescue CustomValidationError => e
  { success: false, error: e.message, error_code: 'VALIDATION_ERROR' }
rescue ActiveRecord::RecordInvalid => e
  { success: false, error: e.message, error_code: 'RECORD_INVALID' }
rescue => e
  Rails.logger.error "Unexpected error in #{self.class.name}: #{e.message}"
  { success: false, error: 'システムエラーが発生しました', error_code: 'SYSTEM_ERROR' }
end
```

## ビジネスロジック実装規約

### バリデーション分離
```ruby
class Kanban::ReleaseGuardService
  def self.validate_release(issue)
    validator = new(issue)
    validator.perform_validation
  end

  def initialize(issue)
    @issue = issue
    @validation_result = { can_release: true, blockers: [], warnings: [] }
  end

  def perform_validation
    check_child_tasks_completion
    check_blocking_tests_status
    check_critical_bugs_status

    @validation_result[:can_release] = @validation_result[:blockers].empty?
    @validation_result
  end

  private

  def check_child_tasks_completion
    incomplete_tasks = @issue.children
                             .joins(:tracker, :status)
                             .where(trackers: { name: 'Task' })
                             .where.not(statuses: { name: COMPLETION_STATUSES })

    if incomplete_tasks.exists?
      add_blocker(:incomplete_tasks, "未完了のTaskがあります",
                  { count: incomplete_tasks.count })
    end
  end
end
```

### 設定外部化
```ruby
module Kanban
  class ConfigurableService
    HIERARCHY_RULES = {
      'Epic' => { children: ['Feature'], parents: [] },
      'Feature' => { children: ['UserStory'], parents: ['Epic'] }
    }.freeze

    COMPLETION_STATUSES = ['Done', 'Closed', 'Resolved'].freeze

    def self.load_configuration
      # YAML設定ファイルから読み込み（将来対応）
      Rails.application.config_for(:kanban_settings)
    rescue
      # フォールバック: デフォルト設定
      { hierarchy_rules: HIERARCHY_RULES }
    end
  end
end
```

## 非同期処理規約

### Job実装標準
```ruby
module Kanban
  class TestGenerationJob < ApplicationJob
    queue_as :auto_generation
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(user_story)
      result = TestGenerationService.generate_test_for_user_story(user_story)

      if result[:success]
        Rails.logger.info "Test生成Job完了: Test##{result[:test_issue]&.id}"
      else
        Rails.logger.error "Test生成Job失敗: #{result[:error]}"
      end
    end
  end
end
```

### 冪等性保証
```ruby
def idempotent_operation(user_story)
  existing_test = find_existing_test(user_story)
  return existing_test if existing_test && !options[:force_recreate]

  # 作成処理
end
```

## テスト規約

### Service単体テスト必須
```ruby
RSpec.describe Kanban::VersionPropagationService do
  describe '.propagate_to_children' do
    let(:user_story) { create(:issue, tracker: create(:tracker, name: 'UserStory')) }
    let(:version) { create(:version) }

    it 'バージョンを子要素に伝播' do
      task = create(:issue, parent: user_story, tracker: create(:tracker, name: 'Task'))

      result = described_class.propagate_to_children(user_story, version)

      expect(result[:success]).to be true
      expect(task.reload.fixed_version).to eq(version)
    end
  end
end
```

## 実装テンプレート

```ruby
module Kanban
  class ExampleService
    class CustomError < StandardError; end

    def self.execute(project, params, options = {})
      new(project, params, options).execute
    end

    def initialize(project, params, options = {})
      @project = project
      @params = params
      @options = options
    end

    def execute
      validate_inputs

      ActiveRecord::Base.transaction do
        result_data = perform_main_logic
        { success: true, data: result_data }
      end
    rescue CustomError => e
      { success: false, error: e.message, error_code: 'CUSTOM_ERROR' }
    rescue => e
      handle_unexpected_error(e)
    end

    private

    def validate_inputs
      raise CustomError, "Invalid project" unless @project&.persisted?
    end

    def perform_main_logic
      # メインロジック実装
    end

    def handle_unexpected_error(error)
      Rails.logger.error "#{self.class.name} error: #{error.message}"
      { success: false, error: 'システムエラー', error_code: 'SYSTEM_ERROR' }
    end
  end
end
```