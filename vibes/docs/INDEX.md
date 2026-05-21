# ドキュメントガイド

## 各ドキュメント一覧

2025/08/09/21/43

このドキュメントは階層的に整理されています。各カテゴリのINDEXから詳細なドキュメントにアクセスしてください。

### rules - プロジェクト規約
- [[TODO: 規約名]](@vibes/rules/_template.md)
- [AIエージェント協働実装例・チェックリスト](@vibes/rules/ai_collaboration_examples_checklists.md)
- [AIエージェント協働規約](@vibes/rules/ai_collaboration_standards.md)
- [AIエージェント協働トラブルシューティング](@vibes/rules/ai_collaboration_troubleshooting.md)
- [コーディング規約](@vibes/rules/coding_standards.md)
- [設計書準拠規約](@vibes/rules/design_compliance_standards.md)
- [ドキュメント規約](@vibes/rules/documentation_standards.md)
- [命名規則](@vibes/rules/naming_conventions.md)
- [NPMパッケージ統合規約](@vibes/rules/npm_package_integration_standards.md)
- [Seeds.rb コーディング規約](@vibes/rules/seeds_standards.md)
- [技術アーキテクチャ規約](@vibes/rules/technical_architecture_standards.md)
- [detailed_spec_docs](@vibes/rules/detailed_spec_docs/INDEX.md)
  - [機能設計書規約](@vibes/rules/detailed_spec_docs/functional_design_standards.md)
  - [実装設計書規約](@vibes/rules/detailed_spec_docs/implementation_design_standards.md)
- [testing](@vibes/rules/testing/INDEX.md)
  - [非定型テスト（Jobs, Services, Tasks, Support）規約](@vibes/rules/testing/non_standard_test_conventions.md)
  - [テストディレクトリ構成と役割規約](@vibes/rules/testing/test_directory_structure.md)

### apis - 外部連携仕様
- [ChatWork 公式アカウント 連携インターフェース仕様書](@vibes/apis/chatwork_official.md)
- [LINE モック API 利用ガイド](@vibes/apis/line_mock_usage.md)
- [LINE 公式アカウント 連携インターフェース仕様書](@vibes/apis/line_official.md)
- [claudeCode](@vibes/apis/claudeCode/INDEX.md)
  - [ClaudeCodeBestPracticesAnthropic](@vibes/apis/claudeCode/ClaudeCodeBestPracticesAnthropic.md)
  - [ClaudeCodeHooks](@vibes/apis/claudeCode/ClaudeCodeHooks.md)
- [plantuml](@vibes/apis/plantuml/INDEX.md)
  - [Command Line](@vibes/apis/plantuml/command_line.md)
  - [Component Diagram Syntax And Features](@vibes/apis/plantuml/component_diagram_syntax_and_features.md)
  - [Deployment Diagram Syntax And Features](@vibes/apis/plantuml/deployment_diagram_syntax_and_features.md)
  - [Draw Gui Mockup With Salt](@vibes/apis/plantuml/draw_gui_mockup_with_salt.md)
  - [New Activity Diagram Beta Syntax And Features](@vibes/apis/plantuml/new_activity_diagram_beta_syntax_and_features.md)
  - [Object Diagram Syntax And Features](@vibes/apis/plantuml/object_diagram_syntax_and_features.md)
  - [Plantuml Preprocessing](@vibes/apis/plantuml/plantuml_preprocessing.md)
  - [Sequence Diagram Syntax And Features](@vibes/apis/plantuml/sequence_diagram_syntax_and_features.md)
  - [State Diagram Syntax And Features](@vibes/apis/plantuml/state_diagram_syntax_and_features.md)
  - [Timing Diagram Syntax And Features](@vibes/apis/plantuml/timing_diagram_syntax_and_features.md)
  - [Use Case Diagram Syntax And Features](@vibes/apis/plantuml/use_case_diagram_syntax_and_features.md)

### specs - システム仕様
- [[TODO: 基幹機能名]仕様書](@vibes/specs/_template.md)
- [feature_lists_users による権限管理システム仕様書](@vibes/specs/feature_based_authorization_spec.md)
- [機能ID仕様書](@vibes/specs/feature_id_specification.md)
- [Presenter基幹システム仕様書](@vibes/specs/presenter_core_system_spec.md)
- [Seeds データベース初期化システム仕様書](@vibes/specs/seeds_system_spec.md)
- [技術スタック仕様書](@vibes/specs/tech_stack.md)
- [ユーザタイプ（権限グループ）定義 仕様書](@vibes/specs/user_types.md)
- [integrations](@vibes/specs/integrations/INDEX.md)
  - [バッチ処理システム仕様書](@vibes/specs/integrations/batch_processing_system.md)
  - [Chatwork連携システム仕様書](@vibes/specs/integrations/chatwork_integration_spec.md)
- [others](@vibes/specs/others/INDEX.md)
  - [基幹クラス業務ロジック分離 仕様書](@vibes/specs/others/core_class_business_logic_separation.md)
  - [欠落ファイル仕様書](@vibes/specs/others/missing_file.md)
- [patient](@vibes/specs/patient/INDEX.md)
  - [患者向け予約システム（静的サイト）仕様書](@vibes/specs/patient/patient_portal_static_site_spec.md)
  - [患者ポータルシステム仕様書](@vibes/specs/patient/patient_portal_system_spec.md)
- [tools](@vibes/specs/tools/INDEX.md)
  - [ドキュメント参照チェックシステム仕様書](@vibes/specs/tools/doc_reference_checker_spec.md)
  - [ドキュメント目次自動生成システム仕様書](@vibes/specs/tools/doc_toc_generator_spec.md)
  - [ドキュメント生成システム仕様書](@vibes/specs/tools/document_generator_system_spec.md)
  - [View Test Generator 仕様書](@vibes/specs/tools/view_test_generator_spec.md)
- [ui](@vibes/specs/ui/INDEX.md)
  - [AG-Grid統合仕様書](@vibes/specs/ui/ag_grid_integration_spec.md)
  - [ボタン定義YAML各キーの詳細](@vibes/specs/ui/button_yaml_keys_detail.md)
  - [SVGベース帳票印刷システム仕様書](@vibes/specs/ui/svg_report_system_spec.md)

### logics - ビジネスロジック
- [[機能名]](@vibes/logics/_template_機能設計.pu) 🔷
- [実装設計書](@vibes/logics/_template_実装設計.pu) 🔷
- [事前作業](@vibes/logics/10_事前作業/INDEX.md)
  - [施設・ユーザー管理](@vibes/logics/10_事前作業/01_施設・ユーザー管理/INDEX.md) 📄 **→1階層**
  - [開診スケジュール設定](@vibes/logics/10_事前作業/02_開診スケジュール設定/INDEX.md) 📁 **→2階層**
  - [集荷スケジュール設定](@vibes/logics/10_事前作業/03_集荷スケジュール設定/INDEX.md) 📁 **→2階層**
  - [帳票管理設定](@vibes/logics/10_事前作業/04_帳票管理設定/INDEX.md) 📄 **→1階層**
- [予約](@vibes/logics/11_予約/INDEX.md)
  - [患者予約フロー](@vibes/logics/11_予約/01_患者予約フロー/INDEX.md) 📁 **→2階層**
  - [施設予約管理](@vibes/logics/11_予約/02_施設予約管理/INDEX.md) 📄 **→1階層**
  - [LINE連携](@vibes/logics/11_予約/03_LINE連携/INDEX.md) 📁 **→2階層**
  - [検査機関確認](@vibes/logics/11_予約/04_検査機関確認/INDEX.md) 📄 **→1階層**
- [受診・検体採取](@vibes/logics/12_受診・検体採取/INDEX.md)
  - [患者情報登録](@vibes/logics/12_受診・検体採取/01_患者情報登録/INDEX.md) 📄 **→1階層**
  - **電子的検査依頼書提出**
  - **検体採取・管理**
  - [電子的検査依頼書提出](@vibes/logics/12_受診・検体採取/02_電子的検査依頼書提出/INDEX.md) 📄 **→1階層**
  - [同時編集制御](@vibes/logics/12_受診・検体採取/03_同時編集制御/INDEX.md) 📄 **→1階層**
- [集荷](@vibes/logics/13_集荷/INDEX.md)
  - [集荷依頼作成](@vibes/logics/13_集荷/01_集荷依頼作成/INDEX.md) 📁 **→2階層**
  - [ChatWork通知](@vibes/logics/13_集荷/02_ChatWork通知/INDEX.md) 📁 **→2階層**
  - [病院集荷作業](@vibes/logics/13_集荷/03_病院集荷作業/INDEX.md) 📄 **→1階層**
  - [統合ワークフロー](@vibes/logics/13_集荷/04_統合ワークフロー/INDEX.md) 📄 **→1階層**
  - [集荷情報変更依頼](@vibes/logics/13_集荷/05_集荷情報変更依頼/INDEX.md) 📄 **→1階層**
  - [営業部確認](@vibes/logics/13_集荷/06_営業部確認/INDEX.md) 📄 **→1階層**
- [受領](@vibes/logics/14_受領/INDEX.md)
  - [NIPT検査依頼印刷](@vibes/logics/14_受領/01_NIPT検査依頼印刷/INDEX.md) 📄 **→1階層**
  - [荷受情報登録](@vibes/logics/14_受領/02_荷受情報登録/INDEX.md) 📄 **→1階層**
  - [検体ボックスチェック](@vibes/logics/14_受領/03_検体ボックスチェック/INDEX.md) 📄 **→1階層**
- [検査](@vibes/logics/15_検査/INDEX.md)
  - [検査依頼登録](@vibes/logics/15_検査/01_検査依頼登録/INDEX.md) 📁 **→2階層**
  - [当日検査検体選定](@vibes/logics/15_検査/02_当日検査検体選定/INDEX.md) 📄 **→1階層**
  - [設定ファイル作成](@vibes/logics/15_検査/05_設定ファイル作成/INDEX.md) 📄 **→1階層**
  - [シーケンサー検査開始](@vibes/logics/15_検査/06_シーケンサー検査開始/INDEX.md) 📄 **→1階層**
- [判定](@vibes/logics/16_判定/INDEX.md)
  - [検査結果登録](@vibes/logics/16_判定/01_検査結果登録/INDEX.md) 📄 **→1階層**
  - [陽性者対応](@vibes/logics/16_判定/02_陽性者対応/INDEX.md) 📄 **→1階層**
  - [確定検査管理](@vibes/logics/16_判定/03_確定検査管理/INDEX.md) 📄 **→1階層**
  - [帳票作成](@vibes/logics/16_判定/04_帳票作成/INDEX.md) 📄 **→1階層**
- [結果通知](@vibes/logics/17_結果通知/INDEX.md)
  - [システム送付](@vibes/logics/17_結果通知/01_システム送付/INDEX.md) 📄 **→1階層**
  - [郵送](@vibes/logics/17_結果通知/02_郵送/INDEX.md) 📄 **→1階層**
  - [メール送付](@vibes/logics/17_結果通知/03_メール送付/INDEX.md) 📄 **→1階層**
  - [Googleドライブ格納](@vibes/logics/17_結果通知/04_Googleドライブ格納/INDEX.md) 📄 **→1階層**
  - [SMS送付](@vibes/logics/17_結果通知/05_SMS送付/INDEX.md) 📄 **→1階層**
- [その後](@vibes/logics/18_その後/INDEX.md)
  - [検体破棄](@vibes/logics/18_その後/01_検体破棄/INDEX.md) 📄 **→1階層**
  - [保健所提出書類](@vibes/logics/18_その後/02_保健所提出書類/INDEX.md) 📁 **→2階層**

### tasks - 開発タスクガイド
- [[TODO: タスク名]ガイド](@vibes/tasks/_template.md)
- [共通設定ガイド](@vibes/tasks/common_settings_guide.md)
- [マイグレーションエラー解決手順](@vibes/tasks/migration_error_resolution.md)
- [Presenter開発ガイド](@vibes/tasks/presenter_development.md)
- [Scaffold 実行手順ガイド](@vibes/tasks/scaffold_procedures.md)
- [テストデータ管理ガイド](@vibes/tasks/test_data_management.md)
- [documentation](@vibes/tasks/documentation/INDEX.md)
  - [ドキュメント作成ガイド](@vibes/tasks/documentation/document_creation_guide.md)
- [implementation](@vibes/tasks/implementation/INDEX.md)
  - [権限・認証実装ガイド](@vibes/tasks/implementation/authentication_authorization_guide.md)
  - [ボタン開発ガイド](@vibes/tasks/implementation/button_development.md)
  - [画像アップロードシステム実装ガイド](@vibes/tasks/implementation/image_upload_system_guide.md)
  - [SVGベース帳票印刷システム 使用ガイド](@vibes/tasks/implementation/svg_report_system_usage_guide.md)
- [testing](@vibes/tasks/testing/INDEX.md)
  - [Capybara自動ポート振り分け機能](@vibes/tasks/testing/capybara_port_auto_assignment.md)
  - [Controller テストベストプラクティスガイド](@vibes/tasks/testing/controller_testing_guide.md)
  - [E2E テストガイド（BDD 日本語 DSL 版）](@vibes/tasks/testing/e2e_testing_guide.md)
  - [Rails モデルテストベストプラクティスガイド](@vibes/tasks/testing/model_testing_guide.md)
- [troubleshooting](@vibes/tasks/troubleshooting/INDEX.md)
  - [設計書不整合トラブルシューティングガイド](@vibes/tasks/troubleshooting/design_inconsistency_troubleshooting.md)
  - [開発タスクガイド](@vibes/tasks/troubleshooting/development_tasks_guide.md)

