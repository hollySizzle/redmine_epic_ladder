# Git 操作規約

## 概要

実装損失を防止し、安全な Git 操作を実現するための規約。チーム開発における Git ワークフロー基準を定義。

## **重要** - 実装損失防止対策

**基本原則**: 作業開始前は必ず現在の状態を保護し、破壊的操作は慎重に実行する

## 安全な Git ワークフロー

### 作業前の準備

```bash
# 作業開始前：現在の状態を必ずバックアップ
git stash push -m "作業開始前のバックアップ_$(date +%Y%m%d_%H%M%S)"
git branch backup/before_$(date +%Y%m%d_%H%M%S)

# 新機能開発時：専用ブランチを作成
git checkout -b feature/機能名_$(date +%m%d)
```

### **禁止操作** - 実装損失リスクあり

```bash
# 絶対禁止：未commit の変更が失われる
git checkout .              # すべての変更を破棄
git reset --hard HEAD       # HEAD まで強制リセット
git clean -fd               # 未追跡ファイル削除

# 危険操作：必ず事前確認
git reset --hard <commit>   # 指定commit まで強制リセット
git rebase -i               # 履歴書き換え
git push --force            # 強制プッシュ
```

### **推奨操作** - 安全なコマンド

```bash
# 変更確認（安全）
git status                  # 現在の状態確認
git diff                    # 差分確認
git diff --staged           # ステージ済み差分

# 安全な変更保存
git add .                   # ステージング
git commit -m "作業内容説明" # コミット
git stash push -m "作業途中" # 一時保存

# 安全な復元
git stash list              # stash 一覧
git stash apply stash@{0}   # stash 適用（保持）
git stash pop               # stash 適用（削除）
```

### 緊急時復旧手順

```bash
# 1. panic 状態時：まず現状確認
git status
git log --oneline -10

# 2. 最近の stash 確認
git stash list

# 3. backup ブランチ確認
git branch | grep backup

# 4. RefLog で履歴確認（30日保持）
git reflog

# 5. 復旧実行
git stash apply stash@{最新番号}  # または
git checkout backup/ブランチ名    # または  
git reset --soft HEAD~1          # 最新commit を取り消し（変更は保持）
```

### 作業完了時の整理

```bash
# 作業完了後：不要な backup 削除
git branch -d backup/古いブランチ名
git stash drop stash@{不要な番号}

# メインブランチ統合
git checkout main
git merge feature/機能名 --no-ff  # マージコミット作成
git branch -d feature/機能名       # 作業ブランチ削除
```

## チーム協働 Git ルール

### コミットメッセージ規約

**形式**: `機能ID: 変更内容 (影響範囲)`

**例**:
- `F001: ユーザ登録機能実装 (auth, user model)`
- `BUG-123: パスワード検証エラー修正 (validation)`
- `REFACTOR: プレゼンター共通化 (presenters)`

### ブランチ命名規則

- **機能開発**: `feature/機能名` 
- **バグ修正**: `fix/バグ名`
- **ドキュメント**: `docs/ドキュメント名`
- **リファクタリング**: `refactor/対象範囲`

### プルリクエスト規則

- **必須**: すべての変更はプルリクエスト経由
- **レビュー**: 1名以上の承認必須
- **マージ方式**: `--no-ff` でマージコミット作成
- **ブランチ削除**: マージ後は作業ブランチ削除

## 推奨設定

### グローバル設定

```bash
# 安全性向上設定
git config --global pull.rebase false    # merge 優先
git config --global push.default simple  # 安全なプッシュ
git config --global core.editor vim      # エディタ設定

# 日本語ファイル名対応
git config --global core.quotepath false

# 改行コード設定（Windows環境）
git config --global core.autocrlf input
```

### エイリアス推奨

```bash
# よく使うコマンドのエイリアス
git config --global alias.st status
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.cm commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
```

## トラブルシューティング

### よくある問題と対処法

1. **間違ってファイルを削除してしまった**
   ```bash
   git checkout HEAD -- <ファイル名>  # 最新commitから復元
   ```

2. **間違ったコミットをしてしまった**
   ```bash
   git reset --soft HEAD~1  # コミット取り消し、変更は保持
   ```

3. **マージでコンフリクトが発生**
   ```bash
   git status              # コンフリクトファイル確認
   # ファイル編集でコンフリクト解決
   git add <解決済みファイル>
   git commit              # マージコミット作成
   ```

4. **間違ったブランチで作業してしまった**
   ```bash
   git stash               # 変更を一時保存
   git checkout 正しいブランチ
   git stash apply         # 変更を適用
   ```

## 監査・レビューポイント

### コミット履歴チェック

- コミットメッセージの形式遵守
- 1コミット1機能の原則
- 機密情報の混入チェック

### ブランチ管理チェック

- 古い feature ブランチの残存確認
- backup ブランチの定期清掃
- 不要な stash の蓄積確認

## 関連ドキュメント

- `@vibes/rules/coding_standards.md`: コード品質基準
- `@vibes/rules/ai_collaboration_standards.md`: AI協働規約
- `@vibes/docs/tasks/development_workflow_guide.md`: 開発ワークフロー