# Redmine React Gantt Chart - 開発用スクリプト

このディレクトリには、開発とデバッグを支援するスクリプトが含まれています。

## スクリプト一覧

### 🛑 kill_server.sh
Redmineサーバーを安全に停止します。

```bash
# 通常の停止
./scripts/kill_server.sh

# ログファイルもクリア
./scripts/kill_server.sh --clear-logs
```

### 🚀 start_dev.sh
開発モードでRedmineサーバーを起動します。

```bash
# 通常の起動
./scripts/start_dev.sh

# アセットをプリコンパイルして起動
./scripts/start_dev.sh --precompile

# ログをクリアして起動
./scripts/start_dev.sh --clear-logs
```

環境変数でカスタマイズ可能:
```bash
PORT=3001 HOST=localhost ./scripts/start_dev.sh
```

### 👀 start_dev_watch.sh
開発サーバーとWebpackのwatchモードを同時に起動します。

```bash
./scripts/start_dev_watch.sh
```

tmuxが利用可能な場合:
- `tmux attach -t redmine-dev` でセッションに接続
- Ctrl+b → 0: Railsサーバー
- Ctrl+b → 1: Webpack watch
- Ctrl+b → 2: ログ監視

tmuxがない場合は、バックグラウンドプロセスとして実行されます。

## 開発フロー

1. **初回セットアップ**
   ```bash
   npm install
   npm run build
   ```

2. **開発開始**
   ```bash
   # ファイル変更を監視しながら開発
   ./scripts/start_dev_watch.sh
   ```

3. **ブラウザでアクセス**
   ```
   http://localhost:3000/projects/[project-id]/react_gantt_chart
   ```

4. **開発終了**
   ```bash
   # tmuxの場合
   tmux kill-session -t redmine-dev
   
   # または
   ./scripts/kill_server.sh
   ```

## トラブルシューティング

### ポート3000が使用中の場合
```bash
./scripts/kill_server.sh
```

### bundle.jsが見つからない場合
```bash
npm run build
# または
npm run deploy
```

### データベースエラーの場合
```bash
cd /usr/src/redmine
bundle exec rails db:migrate RAILS_ENV=development
```