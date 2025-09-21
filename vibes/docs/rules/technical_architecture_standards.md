# 技術アーキテクチャ規約（Redmine Release Kanban）

## 🔗 関連ドキュメント
- @vibes/specs/ui/kanban_ui_design_spec.md
- @vibes/rules/testing/kanban_test_strategy.md
- @vibes/rules/ai_collaboration_standards.md

## 1. システム概要

**目的**: Epic→Feature→UserStory→Task の4段階構造でプロジェクト進行を可視化。UserStoryのVersion割当を子要素へ自動伝播し、Test作成でblocks関係を強制する。

**対象環境**: Redmine 6.0.3 + Node.js 18.x

**基本構成**:
```
redmine_release_kanban/
├── app/controllers/     # API
├── app/services/        # 自動化ロジック
├── assets/javascripts/  # React UI
└── spec/               # テスト
```

## 2. アーキテクチャ構成

### レイヤー構造
```
React UI Layer → REST API Layer → Service Layer → Domain Layer → Database
```

**責務分離**:
- **UI**: カンバン表示、D&D操作
- **API**: HTTP処理、認証、レスポンス整形
- **Service**: トランザクション制御、自動化ルール
- **Domain**: ビジネスルール実装
- **DB**: データ永続化

### 主要コンポーネント

**バックエンド**:
```ruby
class KanbanController < ApplicationController
  def cards; end         # カード一覧API
  def move_card; end     # 移動API（自動化トリガー）
  def batch_update; end  # 一括更新API
end

class Kanban::AutoPropagationService
  def propagate_version(user_story, version); end
end

class Kanban::TestGenerationService
  def generate_test_with_blocks(user_story); end
end
```

**フロントエンド**:
```javascript
const KanbanApp = () => (
  <DndContext>
    <VersionBar />
    <KanbanBoard />
    <BatchActionPanel />
  </DndContext>
);
```

### データフロー
```
D&D操作 → Event Handler → API呼び出し → Service実行（自動化） → Model更新 → UI更新
```

## 3. 技術スタック

**バックエンド**: Ruby on Rails（Redmine同梱）+ Redmine::Plugin API
**フロントエンド**: React 18 + @dnd-kit/sortable + Context API
**ビルド**: Webpack 5 + Babel
**テスト**: RSpec + Jest
**品質**: RuboCop + ESLint

## 4. API設計

### Redmine標準API活用
```
GET/POST /issues.json          # Issue CRUD
POST     /issues/:id/relations.json  # リレーション作成
GET/POST /projects/:id/versions.json # バージョン管理
```

### プラグイン専用API
```
GET  /kanban/cards         # カンバン用データ取得
POST /kanban/move_card     # カード移動（自動化トリガー）
POST /kanban/batch_update  # 一括更新
POST /kanban/generate_test # Test自動生成
```

### 移動APIレスポンス例
```json
{
  "success": true,
  "card": { /* 更新後データ */ },
  "triggered_actions": [
    { "type": "test_generated", "test_id": 456 },
    { "type": "blocks_created", "relation_id": 789 }
  ]
}
```

## 5. ビジネスルール

### チケット階層構造
```
Epic → Feature → UserStory → Task/Test
                     ↑         ↓
                  blocks   (自動生成)
```

### ステータス遷移
**列定義**: ToDo → In Progress → Ready for Test → Released
**制約**: Test未完了時はUserStory進行不可

### 自動化ルール
```ruby
AUTOMATION_RULES = [
  { trigger: :user_story_created, action: :generate_test_with_blocks },
  { trigger: :version_assigned, action: :propagate_to_children },
  { trigger: :moved_to_ready_for_test, action: :ensure_test_exists }
]
```

## 6. セキュリティ・パフォーマンス・品質基準

### セキュリティ
**権限制御**: Redmine標準権限システム活用
**ロール定義**: PM/PO（全機能）、Dev/QA（操作）、Viewer（閲覧）
**対策**: CSRF（Rails標準）、XSS（React自動エスケープ）、SQLインジェクション（ActiveRecord）

### パフォーマンス
**N+1問題回避**: `Issue.includes(:tracker, :status, :assigned_to, :fixed_version)`
**キャッシング**: カード一覧5分、バージョン情報10分、権限セッション期間
**仮想スクロール**: react-window使用で大量データ対応

### 品質基準
**静的解析**: RuboCop・ESLint警告0
**テストカバレッジ**: 80%以上
**複雑度**: Cyclomaticは10以下
**監査ログ**: 自動操作をJournalに記録

---

*Redmine Release Kanbanプラグインの技術アーキテクチャ規約。実装時は本規約準拠、変更時は事前レビュー必須。*