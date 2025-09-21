# カンバンテスト戦略規約

## 🔗 関連ドキュメント
- @vibes/rules/technical_architecture_standards.md
- @vibes/rules/testing/test_directory_structure.md

## 1. テストピラミッド

```
      /\      E2E（10%）
     /  \     統合テスト（30%）
    /    \    ユニットテスト（60%）
   /______\
```

## 2. テスト戦略

### 2.1 ユニットテスト（60%）
**対象**: モデル、サービス、React コンポーネント

**Ruby（RSpec）**:
```ruby
# spec/services/kanban/auto_propagation_service_spec.rb
describe Kanban::AutoPropagationService do
  describe '#propagate_version' do
    it 'バージョンを子Taskに伝播する'
  end
end
```

**JavaScript（Jest）**:
```javascript
// spec/javascript/kanban/hooks/useCardActions.test.js
describe('useCardActions', () => {
  test('カード移動でAPI呼び出し');
});
```

### 2.2 統合テスト（30%）
**対象**: API エンドポイント、DB トランザクション

```ruby
# spec/requests/kanban_controller_spec.rb
describe 'POST /kanban/move_card' do
  it '自動化ルールが発火する'
  it 'blocks関係が作成される'
end
```

### 2.3 E2Eテスト（10%）
**対象**: D&D操作、ワークフロー

```ruby
# spec/system/kanban_workflow_spec.rb
scenario 'UserStory作成時にTest自動生成' do
  visit kanban_path
  drag_and_drop('[data-card="123"]', '[data-column="ready_for_test"]')
  expect(page).to have_content('Test-456')
end
```

## 3. 重点テスト項目

### 3.1 自動化ルール
- バージョン伝播ロジック
- Test自動生成
- blocks関係作成
- 条件分岐処理

### 3.2 権限制御
- ロール別操作制限
- プロジェクト別アクセス
- カード移動権限

### 3.3 データ整合性
- 階層構造保持
- リレーション整合性
- トランザクション境界

### 3.4 UI操作
- D&D動作
- 楽観的更新
- エラーハンドリング

## 4. 品質基準

### 4.1 カバレッジ要求
- **全体**: 80%以上
- **サービス層**: 90%以上
- **自動化ロジック**: 100%

### 4.2 パフォーマンス
- **API応答**: 200ms以下
- **UI反応**: 16ms以下（60FPS）
- **N+1問題**: 発生禁止

### 4.3 テストデータ
- **FactoryBot**: テストデータ生成
- **DatabaseCleaner**: DB状態管理
- **VCR**: 外部API通信記録

## 5. CI/CD連携

### 5.1 自動実行
```yaml
# .github/workflows/test.yml
- name: Run RSpec
  run: bundle exec rspec
- name: Run Jest
  run: npm test
- name: Check Coverage
  run: bundle exec rspec --coverage
```

### 5.2 品質ゲート
- **全テスト成功**: 必須
- **カバレッジ基準達成**: 必須
- **リンター警告0**: 必須

---

*カンバン機能の品質保証のため、自動化ルールとワークフロー整合性を重点的にテストする*