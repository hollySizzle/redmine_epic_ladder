# テストディレクトリ構成

このディレクトリには、Redmine React Gantt Chartプラグインのテスト関連ファイルが整理されています。

## ディレクトリ構成

```
testing/
├── README.md              # このファイル
├── scripts/               # テスト実行スクリプト
│   ├── test_quick_run.rb           # RSpec簡単実行スクリプト
│   ├── test_server_side_filter.rb  # サーバーサイドフィルタテスト
│   └── test_gantt_api.rb           # Gantt API テスト
├── docs/                  # テスト関連ドキュメント
└── examples/             # テストコード例
└── minitest/             # Minitest用テスト（既存）
    └── unit/
        └── gantt_data_builder_test.rb
```

## 主要テストファイルの場所

### RSpec（推奨テストフレームワーク）
- `spec/controllers/` - コントローラーテスト
- `spec/requests/` - パフォーマンステスト
- `spec/support/` - テストヘルパー

### Jest（フロントエンド）
- `assets/javascripts/react_gantt_chart/__tests__/` - React コンポーネントテスト

### 実行スクリプト
- `testing/scripts/test_quick_run.rb` - RSpec簡単実行
- `npm run test:*` - Jest実行コマンド

## 使用方法

### RSpecテスト実行
```bash
# 簡単実行
./testing/scripts/test_quick_run.rb all

# 手動実行
bundle exec rspec spec/
```

### フロントエンドテスト実行
```bash
npm run test:full        # 全テスト
npm run test:limited     # CPU制限モード  
npm run test:watch       # ファイル監視モード
```

## 関連ドキュメント
- @vibes/tasks/testing_guide.md - 詳細テストガイド
- @vibes/rules/testing_standards.md - テスト規約