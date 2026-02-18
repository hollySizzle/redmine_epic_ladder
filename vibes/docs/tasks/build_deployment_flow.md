# ビルド & デプロイメントフロー

## 概要

このドキュメントは redmine_epic_ladder プラグインのフロントエンドビルドとデプロイメントの正規フローを記載します。

## ディレクトリ構造

```
plugins/redmine_epic_ladder/
├── assets/
│   ├── javascripts/epic_ladder/     # フロントエンドソースコード
│   │   ├── src/                   # TypeScript/React ソース
│   │   ├── webpack.config.js      # Webpack設定
│   │   ├── package.json           # npm設定
│   │   └── public/                # 静的ファイル (mockServiceWorker.js等)
│   └── build/                     # ✅ Webpack ビルド出力先（正規）
│       ├── kanban_bundle.js
│       ├── asset-manifest.json
│       └── mockServiceWorker.js
└── vibes/docs/                    # ドキュメント (Vibes規約)
```

## 配信フロー

```
[1. ソースコード編集]
  assets/javascripts/epic_ladder/src/**/*.tsx

        ↓

[2. Webpack ビルド]
  $ npm run build
  → webpack.config.js に従い assets/build/ に出力

        ↓

[3. Redmine Public へデプロイ]
  $ npm run deploy
  → cp assets/build/*.js /usr/src/redmine/public/plugin_assets/redmine_epic_ladder/

        ↓

[4. Redmine Helper 経由で配信]
  app/helpers/epic_ladder_helper.rb
  → asset-manifest.json を読み込み
  → ハッシュ付きファイル名解決

        ↓

[5. ブラウザ配信]
  /plugin_assets/redmine_epic_ladder/kanban_bundle.js
```

## npm スクリプト一覧

### 開発用

| コマンド | 説明 | 用途 |
|---------|------|------|
| `npm run dev` | ビルド + Watch + 自動デプロイ | ローカル開発 |
| `npm run dev:server` | Webpack Dev Server 起動 (port 9000) | スタンドアロン開発 |
| `npm run build` | 開発モードビルド | 手動ビルド確認 |
| `npm run deploy` | build + public/へコピー | 手動デプロイ |

### 本番用

| コマンド | 説明 | 用途 |
|---------|------|------|
| `npm run build:prod` | 本番ビルド (圧縮・最適化) | リリース前 |
| `npm run deploy:prod` | build:prod + ハッシュ付きファイル名でデプロイ | 本番デプロイ |
| `npm run build:release` | リリースパッケージ生成 | 配布用 |

### テスト用

| コマンド | 説明 |
|---------|------|
| `npm run test` | Vitest 実行 (Run once) |
| `npm run test:watch` | Vitest Watch モード |
| `npm run test:coverage` | カバレッジ計測 |

## Webpack 設定 (webpack.config.js)

### ビルド出力

```javascript
output: {
  path: path.resolve(__dirname, '../../build'),  // → assets/build/
  filename: isProduction
    ? 'kanban_bundle.[contenthash:8].js'  // 本番: ハッシュ付き
    : 'kanban_bundle.js',                  // 開発: 固定名
  clean: true,  // ビルド前にクリーンアップ
}
```

### 環境別エントリポイント

- **開発**: `src/index.tsx` (MSW有効)
- **本番**: `src/index.production.tsx` (MSW無効)

### 最適化設定

```javascript
optimization: {
  splitChunks: false,  // Redmineアセットパイプライン対応のため無効化
}
```

## Redmine アセット配信の仕組み

### Helper によるパス解決

`app/helpers/epic_ladder_helper.rb` が `asset-manifest.json` を読み込み、正しいファイル名を解決します。

```ruby
def epic_ladder_asset_path(asset_name)
  manifest_path = File.join(Rails.public_path, 'plugin_assets', 'redmine_epic_ladder', 'asset-manifest.json')

  # manifest.json からハッシュ付きファイル名取得
  manifest = JSON.parse(File.read(manifest_path))
  hashed_name = manifest[asset_name]

  "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_epic_ladder/#{hashed_name}"
end
```

### View での使用例

```erb
<%= javascript_include_tag epic_ladder_asset_path('kanban_bundle.js'), defer: true %>
```

## トラブルシューティング

### ❌ ビルドファイルが反映されない

**原因**: デプロイスクリプトを実行していない

**解決策**:
```bash
npm run deploy      # 開発環境
npm run deploy:prod # 本番環境
```

### ❌ asset-manifest.json が見つからない

**原因**: ビルドが未実行、または webpack.config.js の WebpackManifestPlugin 設定ミス

**解決策**:
```bash
# 1. ビルド実行
npm run build

# 2. manifest.json 存在確認
ls assets/build/asset-manifest.json
```

### ❌ ブラウザでファイルが404

**原因**: public/plugin_assets/ へのコピーが失敗

**解決策**:
```bash
# 1. 配信先ディレクトリ確認
ls /usr/src/redmine/public/plugin_assets/redmine_epic_ladder/

# 2. 手動コピー
cp assets/build/*.js assets/build/*.json /usr/src/redmine/public/plugin_assets/redmine_epic_ladder/
```

## 注意事項

### ⚠️ 削除されたディレクトリ

- **`assets/javascripts/epic_ladder/dist/`**: 旧ビルド出力先（2025-10-20 削除）
  - webpack.config.js 変更前の遺物
  - 現在は `assets/build/` が正規パス

### ⚠️ gitignore 設定

以下のディレクトリはGit管理対象外:

```gitignore
# Build outputs
assets/javascripts/epic_ladder/dist/  # 旧パス（削除済み）
assets/build/                        # 正規ビルド出力先
```

## 関連ドキュメント

- **技術アーキテクチャ**: @vibes/docs/rules/technical_architecture_quickstart.md
- **AIエージェント協働規約**: @vibes/docs/rules/ai_collaboration_redmine.md
- **webpack公式**: https://webpack.js.org/configuration/

---

**更新履歴**:
- 2025-10-20: 初版作成（dist/ クリーンアップ後）
