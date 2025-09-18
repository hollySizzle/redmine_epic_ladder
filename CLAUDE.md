
# プロジェクト規約

## プロジェクト概要

- **ワークスペース**: /usr/src/redmine/plugins/redmine_react_gantt_chart

## アーキテクチャ概要

### バックエンド (Ruby/Rails)

- **Controller**: `app/controllers/react_gantt_chart_controller.rb` - API エンドポイント提供
  - `index` - React アプリをマウントする HTML
  - `data` - Gantt チャートデータ(JSON)
  - `filters` - フィルター定義
  - `bulk_update` - 一括更新
- **Service**: `app/services/redmine_react_gantt_chart/gantt_data_builder.rb` - データ変換ロジック
- **Routes**: `config/routes.rb` - プラグインルート定義

### フロントエンド (React)

- **Entry**: `assets/javascripts/react_gantt_chart/index.jsx`
- **Components**:
  - `App.jsx` - メインコンテナ
  - `FilterPanel.jsx` - フィルター UI
  - `DHMLXGanttChart.jsx` - DHTMLX Gantt ラッパー
  - **Gantt Modules**:
    - `gantt/config/index.js` - 基本設定・ローカライズ
    - `gantt/columns/index.js` - カラム定義・カスタムフィールド
    - `gantt/handlers/taskHandlers.js` - タスク操作（作成・移動・削除）
    - `gantt/handlers/eventHandlers.js` - イベントシステム管理
    - `gantt/handlers/linkHandlers.js` - 依存関係管理
    - `gantt/utils/helpers.js` - データ操作・UI操作
    - `gantt/utils/validation.js` - データ検証・整合性チェック
- **Utils**: カラム管理、ローカルストレージ

### 統合ポイント

- Redmine の権限システム (`view_react_gantt_chart`)
- IssueQuery を使用したフィルタリング
- カスタムフィールドサポート

## 重要な制約事項

### 絶対的禁止事項

- **Redmine コアクラスへの変更禁止**: Redmine のコアモデル、コントローラーへの直接変更は禁止
- **機密情報 commit 禁止**：API キー、認証情報、データベース接続情報
- **詳細**: @vibes/rules/design_compliance_standards.md

## 推奨ワークフロー: **Explore→Plan→Code→Verify**

- **Explore**: "think hard"で設計書確認・影響範囲特定
- **Plan**: 実装方針明文化・機能 ID 対応確認
- **Code**: 最小単位実装 → テスト → 改善サイクル
- **Verify**: 自動チェック・設計書準拠性確認


**AI 思考レベル**: "think hard"(設計書確認)、"think harder"(アーキテクチャ変更)
詳細手順: @vibes/docs/tasks/development_workflow_guide.md

## コマンド

```bash
# 開発環境セットアップ
npm install                             # Node.js依存関係インストール
./_dev/install_playwright_mcp.sh        # Playwright MCP サーバーセットアップ（E2E テスト用）

# テスト実行
npm run test:limited                    # CPU制限モード（他の作業をしながら）
npm run test:full                       # フルパワーモード（高速実行）
npm run test:single                     # シングルワーカーモード（最小リソース）
npm run test:watch                      # ウォッチモード（ファイル変更監視）
npm run test:coverage                   # カバレッジ計測モード
./_dev/test_runner.sh limited           # テスト実行スクリプト（CPU制限）
./_dev/test_runner.sh full              # テスト実行スクリプト（フルパワー）

# ビルド
npm run build                           # 開発ビルド
npm run build-production                # 本番ビルド
npm run watch                           # 開発モード（ファイル監視）

# 自動配置（推奨）
npm run deploy                          # 開発ビルド & Redmineに自動配置
npm run deploy:prod                     # 本番ビルド & Redmineに自動配置
npm run deploy:watch                    # ファイル監視 & 自動ビルド & 自動配置
npm run dev                             # 開発モード（deploy:watchのエイリアス）

# 手動デプロイ（非推奨）
cp ./assets/javascripts/react_gantt_chart/dist/bundle.js /usr/src/redmine/public/plugin_assets/redmine_react_gantt_chart/

# 開発用スクリプト（_dev/ディレクトリ）
./_dev/setup.sh                         # Node.js 18インストール & 初回ビルド
./_dev/auto_deploy.sh build             # 自動配置スクリプト（ビルド）
./_dev/auto_deploy.sh watch             # 自動配置スクリプト（監視）
./_dev/auto_deploy.sh production        # 自動配置スクリプト（本番）

# ドキュメント管理
cd vibes/scripts && npm install         # 初回のみ: 依存関係インストール
cd vibes/scripts && npm run update-toc                      # 目次更新
cd vibes/scripts && npm run check-references                # 参照整合性チェック
cd vibes/scripts && npm run doc-help                        # ドキュメント生成ヘルプ

# 新規ドキュメント生成（引数必須）
cd vibes/scripts && node generate-document.js -c <category> -f <filename> -t "<title>"
# 例: cd vibes/scripts && node generate-document.js -c tasks -f user_guide -t "ユーザーガイド"
```

## 品質・セキュリティ基準

### コード品質

- **ESLint 準拠必須**：JavaScript/JSX コードの静的解析
- **テスト必須**：新機能は必ずテスト実装（現在テストインフラ未整備）
- **コメント日本語**: コードのコメントは日本語であること
- **クリーンアーキテクチャ**: app/adapters, app/domain, app/usecases の構造（現在未実装）
- **緩やかな DRY 原則**: DRY 原則は適用しつつ､過剰な抽象化は避け､最小限の反復とする

**設計書準拠確認**: 機能 ID 存在・シーケンス図一致・未定義機能追加なし・権限整合性
詳細: @vibes/rules/design_compliance_standards.md

## ドキュメント

**参照順序**: @vibes/INDEX.md → 定型タスクは@vibes/tasks → 複雑タスクは@vibes/temps でチェックリスト作成

### **重要**

- ドキュメントは､情報量を損なわないよう圧縮し短くすること
  - 簡潔な文章表現/情報の集約/繰り返しを避ける 等を実行すること
- 作成ルールに従うこと
  - **重要** : 手動でドキュメントを作成せず､自動生成ツールを使用すること
  - @vibes/INDEX.md を確認し新規ドキュメントの必要性を再考
  - 新規作成(`npm run generate-document`)
  - ガイドラインの確認(@vibes/docs/rules/documentation_standards.md)
  - 目次更新(`npm run update-toc`)
  - 参照整合性チェック(`npm run check-references`)

### vibes/docs ディレクトリ構成

- **apis**: 外部サービスの前提条件（原則変更不可）
- **logics**: ビジネスロジック記載
- **rules**: プロジェクト規約・制約事項
- **tasks**: 作業手順書・ガイド
- **specs**: ドメイン仕様（ビジネスロジック非依存）
- **temps**: 一時ドキュメント・チェックリスト
