# Vibes クイックスタート（15分体験）

## ステップ1: 環境確認
```bash
cd vibes/scripts
npm run update-toc
```

## ステップ2: サンプルドキュメント作成
```bash
npm run generate-doc
# → temps を選択
# → ファイル名: quick_test
# → タイトル: クイックテスト
```

## ステップ3: 動作確認
```bash
npm run update-toc           # 目次に追加確認
npm run check-references     # 参照チェック
```

## ステップ4: 実際の使用
生成されたファイルを編集して実際の開発で使用してください。