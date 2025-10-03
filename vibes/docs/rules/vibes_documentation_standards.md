# Vibesドキュメント規約

## ディレクトリ構成

**apis/**: 外部サービス連携（API 仕様書、連携プロトコル）原則変更不可
**logics/**: ビジネスロジック(機能設計書/実装設計書)
**rules/**: プロジェクト規約（コーディング規約、命名規則、実装設計書規約）チーム合意に基づく変更
**tasks/**: 作業手順書（手順書、チェックリスト、ガイド）実作業に応じて柔軟に更新
**specs/**: 技術仕様（システム仕様、アーキテクチャ設計）アーキテクチャ変更時のみ
**temps/**: 一時ドキュメント（進行中タスク、検討事項、実装メモ）作業完了後削除


## 規約

### 基本原則

- **簡潔性**: 専門用語活用、情報集約、繰り返し回避による圧縮言語での記載

### 作成手順

1. **必要性確認**: @vibes/INDEX.md で新規ドキュメント必要性を検討
2. **規約確認**: @vibes/rules/documentation_standards.md 参照
3. **目次更新**: `python3 /usr/src/redmine/plugins/redmine_release_kanban/vibes/scripts/main.py --direct doc --action update_all`
4. **整合性確認**: `python3 /usr/src/redmine/plugins/redmine_release_kanban/vibes/scripts/main.py --direct doc --action check_all`


## 責務分離

- **バージョン管理は Git の責務**、ドキュメント内容とは別の関心事
- ドキュメントは「何を」「なぜ」「どのように」に集中
- バージョン情報とドキュメント内容を分離し、各々の責務を明確化