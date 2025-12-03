# MCP HTTPサーバー実装計画

## 概要
- **目的**: Claude DesktopからHTTP経由でRedmine Epic Ladderを操作可能にする
- **方式**: Streamable HTTP Transport（MCP公式仕様準拠）
- **認証**: Redmine APIキー認証（既存インフラ活用）
- **工数**: 2日

## 背景
- gem 'mcp' v0.4.0 が Streamable HTTP 対応済みを確認
- Claude Desktop が2025年3月よりStreamable HTTPサポート
- 既存の `bin/mcp-server` (STDIO版) は削除（HTTP版に一本化）
- サーバーサイド型により、プラグイン独自ロジック（自動推論等）を活用可能

## アーキテクチャ
```
[Claude Desktop]
  ↓ HTTPS (Streamable HTTP)
[Redmine Server: POST /mcp/rpc]
  ↓ Mcp::ServerController
  ↓ MCP::Server (gem 'mcp')
  ↓ EpicLadder::McpTools::CreateTaskTool
  ↓ Rails Models (Issue, Tracker, Version)
  ↓ PostgreSQL
```

## 実装対象ファイル

### 新規作成
- `app/controllers/mcp/server_controller.rb` - MCPエンドポイント
- `spec/requests/mcp/server_controller_spec.rb` - RSpecテスト
- `vibes/docs/tasks/mcp_http_server_implementation.md` - 本ドキュメント

### 修正
- `config/routes.rb` - ルート追加
- `README.md` - セットアップ手順追加

### 削除
- `bin/mcp-server` - STDIO版削除（HTTP版に一本化）

### 変更不要
- `Dockerfile.redmine` - 変更なし（既存gem使用）
- `PluginGemfile` - gem 'mcp' 既に定義済み
- `lib/epic_ladder/mcp_tools/create_task_tool.rb` - そのまま使用

## 実装詳細

### 1. Routes追加 (config/routes.rb)

**追加箇所**: 既存APIルート定義の後
```ruby
# MCP Server (Streamable HTTP)
namespace :mcp do
  post '/rpc', to: 'server#handle'
  options '/rpc', to: 'server#options' # CORS Preflight対応
end
```

**エンドポイント**:
- `POST /mcp/rpc` - JSON-RPC 2.0リクエスト処理
- `OPTIONS /mcp/rpc` - CORSプリフライトリクエスト対応

### 2. Controller実装 (app/controllers/mcp/server_controller.rb)

**責務**:
- JSON-RPC 2.0リクエストの受信
- Redmine APIキー認証
- MCP::Serverへのリクエスト委譲
- エラーハンドリング
- CORS対応

**主要メソッド**:
- `handle` - メインエンドポイント
- `options` - CORSプリフライト
- `set_cors_headers` - CORSヘッダー設定
- `mcp_server` - MCP::Serverインスタンス生成（Statelessモード）

**認証方式**:
- `accept_api_auth :handle` - Redmine標準のAPIキー認証
- `User.current` で認証済みユーザー取得
- server_contextにユーザー情報を渡す

**エラーレスポンス**:
- JSON-RPC 2.0仕様準拠
- エラーコード: -32603 (Internal error)
- HTTPステータス: 500 (Internal Server Error)

**CORS設定**:
- `Access-Control-Allow-Origin: *` (本番では要検討)
- `Access-Control-Allow-Methods: POST, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization, X-Redmine-API-Key`

### 3. MCP::Server設定

**モード**: Stateless (マルチノード展開対応)
```ruby
MCP::Server.new(
  name: "redmine_epic_ladder",
  version: "1.0.0",
  tools: [EpicLadder::McpTools::CreateTaskTool],
  server_context: { user: User.current }
)
```

**Statelessモード選択理由**:
- セッション維持不要（各リクエストが独立）
- 水平スケーリング可能
- メモリ効率◎

### 4. README.md更新

**追加セクション**:
- ## 🤖 MCP Server (AI連携機能)
  - 概要説明
  - Claude Desktop設定手順
  - APIキー取得方法
  - トラブルシューティング

**設定例**:
```
Claude Desktop → Settings → Connectors → Add Connector
  URL: https://your-redmine.com/mcp/rpc
  Name: Redmine Epic Ladder
  Authorization Token: [Your Redmine API Key]
```

## テスト計画

### RSpecテスト（自動テスト）

**ファイル**: `spec/requests/mcp/server_controller_spec.rb`

```ruby
RSpec.describe "Mcp::ServerController", type: :request do
  let(:user) { User.find(1) }
  let(:api_key) { user.api_key }

  describe "POST /mcp/rpc" do
    context "tools/list request" do
      it "returns available tools" do
        post "/mcp/rpc",
          params: {
            jsonrpc: "2.0",
            method: "tools/list",
            id: 1
          }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-Redmine-API-Key" => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["result"]["tools"]).to be_present
        expect(json["result"]["tools"].first["name"]).to eq("create_task")
      end
    end

    context "tools/call request" do
      it "creates a task via CreateTaskTool" do
        project = Project.find_by(identifier: "sakura-ec")

        post "/mcp/rpc",
          params: {
            jsonrpc: "2.0",
            method: "tools/call",
            params: {
              name: "create_task",
              arguments: {
                project_id: project.identifier,
                description: "カートのリファクタリング"
              }
            },
            id: 2
          }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-Redmine-API-Key" => api_key
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["result"]["content"].first["text"]).to include("task_id")
      end
    end

    context "authentication" do
      it "rejects request without API key" do
        post "/mcp/rpc",
          params: { jsonrpc: "2.0", method: "tools/list", id: 1 }.to_json,
          headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "CORS headers" do
      it "includes CORS headers in response" do
        post "/mcp/rpc",
          params: { jsonrpc: "2.0", method: "tools/list", id: 1 }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-Redmine-API-Key" => api_key
          }

        expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
        expect(response.headers["Access-Control-Allow-Methods"]).to include("POST")
      end
    end
  end
end
```

**テスト項目**:
- [ ] tools/list リクエスト（利用可能ツール一覧取得）
- [ ] tools/call リクエスト（CreateTaskTool実行）
- [ ] APIキー認証（正常系・異常系）
- [ ] JSON-RPC 2.0エラーレスポンス形式
- [ ] CORS ヘッダー確認

### ローカルテスト（開発環境での手動確認）

```bash
# Railsサーバー起動
bundle exec rails s

# curlでテスト（HTTPで十分）
curl http://localhost:3000/mcp/rpc \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### 手動テスト項目（Claude Desktop連携）
- [ ] Claude Desktopから接続確認
- [ ] 実際のタスク作成動作確認（自然言語→Task作成）
- [ ] 親UserStory自動推論の動作確認
- [ ] エラーハンドリング確認（権限不足、無効なパラメータ）

### テストシナリオ
1. **正常系**: 「カートリファクタリングタスクを作って」
   - 期待結果: Taskチケット作成成功、親UserStory自動推論
2. **権限不足**: APIキーなしでリクエスト
   - 期待結果: 401 Unauthorized
3. **無効なプロジェクト**: 存在しないproject_id指定
   - 期待結果: JSON-RPCエラーレスポンス

## セキュリティ考慮事項

### HTTPS要件
- **Claude Desktop接続時**: HTTPS必須（セキュリティポリシー）
- **ローカルcurlテスト**: HTTP OK（開発・デバッグ用）
- **本番環境**: HTTPS推奨（Let's Encrypt等）

### APIキー保護
- Claude Desktop設定ファイルに平文保存される点に注意
- ユーザーに適切な権限設定を案内

### CORS設定
- 本番環境では `Access-Control-Allow-Origin` を特定ドメインに限定検討
- 現状は `*` で全許可（Claude Desktopのドメイン不明のため）

## 既知の制限事項

### Claude Desktop側
- GUI設定が必須（claude_desktop_config.jsonでは設定不可）
- Pro/Max/Team/Enterpriseプランのみサポート

### MCP機能
- 進捗通知 (progress) 未サポート（Statelessモードのため）
- リソース購読 (resource subscriptions) 未サポート
- ログレベル調整未サポート

### 現在のツール
- CreateTaskTool のみ実装
- 今後追加予定: CreateFeatureTool, CreateUserStoryTool等

## 今後の拡張予定

### Phase 2: 追加ツール実装
- CreateFeatureTool - Feature作成
- CreateUserStoryTool - UserStory作成
- AssignVersionTool - Version割り当て
- MoveCardTool - カード移動

### Phase 3: OAuth対応
- Redmine OAuthプラグイン統合
- よりセキュアな認証フロー

### Phase 4: WebSocket対応（検討）
- ActionCable統合
- リアルタイム通知
- 進捗レポート機能

## 参考資料
- MCP Ruby SDK: https://github.com/modelcontextprotocol/ruby-sdk
- Claude MCP Connector: https://platform.claude.com/docs/en/agents-and-tools/mcp-connector
- Redmine API: https://www.redmine.org/projects/redmine/wiki/Rest_api
