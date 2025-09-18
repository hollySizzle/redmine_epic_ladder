# Vibes ドキュメント生成

以下の手順でドキュメントを生成してください：

1. cd vibes/scripts
2. npm run generate-doc を実行
3. 対話式でカテゴリとファイル名を入力
4. 生成後、npm run update-toc を実行

生成可能なカテゴリ：
- rules: プロジェクト規約
- specs: 技術仕様書  
- tasks: 作業手順書
- logics: ビジネスロジック
- apis: 外部API仕様書
- temps: 一時ドキュメント

必ず @vibes/docs/ 記法を使用してください。