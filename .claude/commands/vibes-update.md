# Vibes 目次・参照更新

以下のコマンドを順番に実行してください：

1. cd vibes/scripts
2. npm run update-toc        # 目次更新
3. npm run check-references  # 参照整合性チェック

エラーが出た場合：
- 存在しないファイルへの参照を修正
- 相対パス参照を @vibes/docs/ 記法に変更