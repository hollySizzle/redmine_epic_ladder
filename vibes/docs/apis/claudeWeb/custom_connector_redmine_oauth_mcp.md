# Claude Web Custom Connector + Redmine OAuth2 MCP 調査

## 目的

claude.ai Web の Custom Connector から、このプラグインの MCP HTTP endpoint を利用できるかを調査する。

対象:

- Claude Web Custom Connector
- Remote MCP / Streamable HTTP
- OAuth 2.x 認証
- Redmine 6.1 内蔵 OAuth2 Provider (Doorkeeper)
- `redmine_epic_ladder` の `/mcp/rpc`

## 結論

Redmine Doorkeeper をそのまま Claude Web に見せるだけでは不十分。

ただし、Redmine OAuth2 Provider を認可サーバーとして使い、MCP 側に Claude Web 向けの discovery / auth challenge / root alias を追加すれば、Cloudflare Workers なしで接続できる可能性が高い。

採用候補:

```text
claude.ai Web
  -> https://redmine.example.com/mcp/rpc
       - OAuth protected resource metadata
       - 401 WWW-Authenticate challenge
       - Bearer token validation via Doorkeeper
       - JSON-RPC MCP server

Redmine OAuth2 Provider
  -> /oauth/authorize
  -> /oauth/token
```

Claude Web の既知挙動差を吸収するため、root alias も用意する。

```text
GET  /authorize -> /oauth/authorize
POST /token     -> /oauth/token
```

## ローカルで確認した事実

Redmine 本体:

- `/usr/src/redmine/Gemfile` に `doorkeeper ~> 5.8.2`
- `/usr/src/redmine/config/routes.rb` に `use_doorkeeper`
- `bundle exec rails routes` で以下を確認
  - `GET /oauth/authorize`
  - `POST /oauth/token`
  - `POST /oauth/revoke`
  - `GET /oauth/applications`
- `/usr/src/redmine/config/initializers/30-redmine.rb` で Doorkeeper 設定
  - `grant_flows ['authorization_code']`
  - `use_refresh_token`
  - `hash_token_secrets`
  - `hash_application_secrets`
  - `default_scopes` / `optional_scopes`
  - PKCE 用カラムあり
- `/usr/src/redmine/app/controllers/application_controller.rb` で REST API の Bearer token を `Doorkeeper.authenticate(request)` で認証している

このプラグイン:

- MCP endpoint は `POST /mcp/rpc`
- 現在の認証は `X-Redmine-API-Key` のみ
- `config/initializers/mcp_oauth_rejection.rb` が `/.well-known/*` を `405 oauth_not_supported` で拒否している
- 現状のままでは Claude Web OAuth custom connector と互換しない

## Claude Web Custom Connector の仕様事実

公式情報:

- Claude Web Custom Connector は Pro / Max でも利用可能。
- Custom Connector 追加時に URL を入力し、Advanced settings で OAuth Client ID / Secret を設定できる。
- API key をユーザーが貼り付ける方式、URL query token 方式は未対応。
- OAuth では protected resource metadata と authorization server metadata の discovery を使う。
- 未認証 MCP request には `401` と `WWW-Authenticate: Bearer resource_metadata="..."` を返すのが期待される。
- Claude は Streamable HTTP を推奨し、SSE は legacy 扱い。

参考:

- https://support.claude.com/en/articles/11175166-about-custom-connectors
- https://claude.com/docs/connectors/building
- https://claude.com/docs/connectors/building/authentication
- https://claude.com/docs/connectors/building/troubleshooting

## Redmine OAuth2 Provider の仕様事実

Redmine 6.1.0 で OAuth2 Provider が導入されている。

参考:

- https://www.redmine.org/issues/24808
- https://blog.redmine.jp/articles/oauth2/

Redmine.JP の OAuth2 手順でも、Redmine 側の OAuth application を作成し、`/oauth/authorize` と `/oauth/token` を使う authorization code flow が示されている。

## コミュニティ/Issue 情報

Claude Web Remote MCP OAuth には過去に挙動差・不具合報告がある。

### Bearer token が送られない報告

GitHub issues で、Claude Web が OAuth 完了後に MCP request へ Bearer token を付けないという報告が複数ある。

特に `anthropics/claude-ai-mcp#79` は「Claude Code は動くが Claude Web は token を付けない」という内容。

参考:

- https://github.com/anthropics/claude-ai-mcp/issues/79

### metadata endpoint を無視する報告

`anthropics/claude-ai-mcp#82` では、Claude.ai が authorization server metadata の `authorization_endpoint` / `token_endpoint` を使わず、MCP server origin の root `/authorize` / `/token` を叩くという報告がある。

この issue は `Closed as not planned`。

参考:

- https://github.com/anthropics/claude-ai-mcp/issues/82

### 最近の成功報告

Reddit には、claude.ai Web Custom Connector で self-hosted remote MCP と OAuth flow が動作したという報告がある。

PullMD v2.4.1 の報告では、OAuth 2.1 Authorization Code + PKCE S256 + DCR で Claude Web / Desktop の接続成功が述べられている。

また r/mcp でも、metadata と auth challenge を正しく実装すれば claude.ai remote connector が per-user OAuth flow を使い、MCP request に Bearer token を付けるという実運用寄りの説明がある。

参考:

- https://www.reddit.com/r/ClaudeAI/comments/1tbz2j6/pullmd_v241_is_out_claudeai_web_custom_connector/
- https://www.reddit.com/r/mcp/comments/1t9qqog/claudepower_bi_multiuser_auth_for_remote_mcp/

## 実装要件

### Redmine OAuth application

Redmine 管理画面で OAuth application を作成する。

```text
Redirect URI:
https://claude.ai/api/mcp/auth_callback
```

Claude Web Custom Connector の Advanced settings に以下を設定する。

```text
OAuth Client ID     = Redmine OAuth application UID
OAuth Client Secret = Redmine OAuth application secret
```

### Discovery endpoints

このプラグインまたは Redmine 側に以下を追加する。

```text
GET /.well-known/oauth-protected-resource
GET /.well-known/oauth-protected-resource/mcp/rpc
GET /.well-known/oauth-authorization-server
```

Authorization server metadata は root alias を返す。

```json
{
  "issuer": "https://redmine.example.com",
  "authorization_endpoint": "https://redmine.example.com/authorize",
  "token_endpoint": "https://redmine.example.com/token",
  "response_types_supported": ["code"],
  "grant_types_supported": ["authorization_code", "refresh_token"],
  "code_challenge_methods_supported": ["S256"],
  "token_endpoint_auth_methods_supported": ["client_secret_post", "client_secret_basic"]
}
```

Protected resource metadata は authorization server metadata を指す。

```json
{
  "resource": "https://redmine.example.com/mcp/rpc",
  "authorization_servers": [
    "https://redmine.example.com/.well-known/oauth-authorization-server"
  ]
}
```

### Auth challenge

未認証の `/mcp/rpc` では JSON-RPC エラーだけでなく、HTTP 401 と `WWW-Authenticate` を返す。

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer resource_metadata="https://redmine.example.com/.well-known/oauth-protected-resource/mcp/rpc"
```

### Bearer token 認証

`Mcp::ServerController#authenticate_api_user` を拡張する。

- `X-Redmine-API-Key` は Claude Code / 既存利用向けに維持
- `Authorization: Bearer ...` がある場合は `Doorkeeper.authenticate(request)` を使う
- `access_token.resource_owner_id` から `User.current` を設定
- `access_token.scopes` を `user.oauth_scope` に設定

Redmine 本体の REST API と同じ認証モデルに寄せる。

## 実装状況

2026-05-17 時点で、このプラグインに以下を実装済み。

- `GET /.well-known/oauth-protected-resource`
- `GET /.well-known/oauth-protected-resource/mcp/rpc`
- `GET /.well-known/oauth-authorization-server`
- `GET /authorize` -> `/oauth/authorize` redirect alias
- `POST /token` -> `doorkeeper/tokens#create` alias
- `/mcp/rpc` の `Authorization: Bearer ...` 認証
- 未認証時の `WWW-Authenticate: Bearer resource_metadata="..."` challenge
- 既存 `X-Redmine-API-Key` 認証の維持
- Claude Web 用 OAuth application の既定 scope
  - `view_project`
  - `view_issues`
  - `add_issues`
  - `edit_issues`
  - `add_issue_notes`
  - `manage_versions`
  - `manage_issue_relations`

主な実装ファイル:

- `app/controllers/mcp/oauth_controller.rb`
- `app/controllers/mcp/server_controller.rb`
- `config/initializers/mcp_oauth_rejection.rb`
- `config/routes.rb`
- `spec/requests/mcp/server_controller_spec.rb`
- `spec/controllers/mcp/server_controller_spec.rb`

## 採否判断

採用する:

- Redmine Doorkeeper を認可サーバーとして使う
- Claude Web 互換用 discovery / challenge / root alias をプラグイン側に足す
- `/mcp/rpc` で Bearer token を受ける
- Redmine の OAuth scope と role permission の両方で MCP 操作権限を制御する

採用しない:

- Claude Web に Redmine API key を貼り付ける方式
- URL query token 方式
- Redmine Doorkeeper をそのまま露出するだけの方式

保留:

- Cloudflare Workers + `workers-oauth-provider`
  - Claude 互換性の実績はある
  - ただし KV binding が必要
  - Redmine 内蔵 OAuth2 Provider があるため、現時点の最短経路ではない

## リスク

- Claude Web の OAuth 実装は過去 issue と現行 docs に差がある。
- `/oauth/authorize` `/oauth/token` を metadata に書くだけでは、古い挙動の Claude Web で失敗する可能性がある。
- root `/authorize` `/token` alias を置くことで、このリスクを軽減する。
- OAuth token の scope が不足すると、Redmine 側で `user.oauth_scope` により role permission が制限される。
- プロジェクト非メンバーの場合、private project の閲覧や書き込みは失敗する。
- 実装後は Claude Web の接続ログ、Redmine access log、`ofid_` request id を確認しながら実機検証する。

## 2026-05-17 実機検証結果

### 初回失敗の原因

初回の Claude Web 実接続では、MCP 接続と tool call 自体は成立していた。
失敗原因は API key ではなく、Claude Web OAuth token の scope が `view_project` のみだったこと。

Redmine は Bearer token 認証時に `user.oauth_scope` を設定し、`User#allowed_to?` で scope 外の権限を拒否する。
このため `view_issues` が scope に含まれない token では、`sakura-ec` / `ai-recommend` のチケット閲覧が失敗した。

### 対応

- Claude Web 用 OAuth application の scope を MCP 操作用に拡張した。
- `MCPテスター` role を作成し、以下 permission を付与した。
  - `view_issues`
  - `add_issues`
  - `edit_issues`
  - `add_issue_notes`
  - `manage_versions`
  - `manage_issue_relations`
- `sakura-ec` と `ai-recommend` に対象ユーザーをメンバー追加した。
- 既存 token は revoke した。Claude Web 側では再接続が必要。

### 再テスト結果

API key 経由のローカルMCP実テストで、以下のプロジェクトは書き込み系まで成功した。

- `sakura-ec`
  - 作成 issue IDs: `133`, `134`, `135`, `136`, `137`, `138`, `139`
  - 作成 version ID: `13`
  - 詳細取得 issue: `#135`
- `ai-recommend`
  - 作成 issue IDs: `140`, `141`, `142`, `143`, `144`, `145`, `146`
  - 作成 version ID: `14`
  - 詳細取得 issue: `#142`

確認済みツール:

- status / member 参照
- version 作成
- Epic / Feature / UserStory / Task / Bug / Test 作成
- コメント追加
- subject / description / progress / assignee / status 更新
- version 割当
- 一括 status 更新
- issue relation 追加・削除
- issue copy
- parent 解除・復元
- issue detail 取得

注記:

- 子チケットを持つ親チケットの `done_ratio` は、Redmine設定 `parent_issue_done_ratio = derived` の場合、子チケットから自動計算される。
- この場合、`update_issue_progress_tool` は親チケットへの直接更新を拒否する。進捗更新はTask/Bug/Testなどのleaf issueに対して実行する。
- `create_user_story_tool` は `version_id` 未指定時に親FeatureのVersionを継承し、親にもVersionがなければプロジェクト内で最も早いopen Versionを使う。Claude Webから業務データを作る場合は `version_id` を明示する。

### MCPサンドボックスseed

`ai-recommend` は実機検証用サンドボックスとして使うため、development seed に再現可能な検証データを追加した。

投入コマンド:

```bash
cd /usr/src/redmine
RAILS_ENV=development bundle exec rails runner plugins/redmine_epic_ladder/db/seeds/02_projects.rb
RAILS_ENV=development bundle exec rails runner plugins/redmine_epic_ladder/db/seeds/03_versions.rb
RAILS_ENV=development bundle exec rails runner plugins/redmine_epic_ladder/db/seeds/06_mcp_sandbox.rb
```

投入される前提:

- `ai-recommend` の `epic_ladder` module
- `admin` の `MCPテスター` membership
- `MCP-SEED Alpha` / `MCP-SEED Beta` / `MCP-SEED Gamma`
- `MCP-SEED Epic` / `Feature` / `問合せ Feature` / `UserStory` / `Task` / `Bug` / `Test`
- `inquiry_feature_id`
- `MCP Sandbox Text` issue custom field

このseed投入後、HTTP/API key経由の `bin/mcp_tool_matrix_test` で31ツールのschema公開と代表動作を確認した。

```text
MCP tool matrix test passed.
Tool count: 31
Created issue IDs: 225, 226, 227, 228, 229, 230, 231, 232, 233, 234
Created version IDs: 37, 38, 39
```

`update_custom_fields_tool` は、seedで作成した `MCP Sandbox Text` に対する正常系と、存在しないcustom fieldの異常系の両方を確認済み。

### 複合シナリオ結果

`ai-recommend` で、複数ツールを組み合わせた整合性テストも成功した。

確認したシナリオ:

- 2バージョン、1 Epic、2 Feature、2 UserStory、Task / Bug / Test の作成
- UserStory への version 割当と子チケットへの伝播確認
- 親子移動時の version / date 継承
- 循環参照 parent update の拒否
- issue relation の追加、詳細取得での確認、削除
- issue copy 時の parent / version override
- bulk status update の部分成功・部分失敗
- project structure の version filter

実行結果:

```text
Created issue IDs: 155, 156, 157, 158, 159, 160, 161, 162, 163
Created version IDs: 17, 18
Branch A user story: #157
Branch B user story: #159
```

自動テスト:

```text
38 examples, 0 failures, 1 pending
```

Docs check:

```text
問題なし
```

### Claude Web Live E2E 結果

2026-05-17 に Claude Web Custom Connector 経由で `ai-recommend` に対して実行した。

実行ID:

```text
MCP-WEB-TEST 20260517T135350Z
```

確認結果:

- 参照系
  - status / Epic / UserStory / Version / member / recently updated / project structure
- 作成系
  - Version / Epic / Feature / UserStory / Task / Bug / Test / inquiry / copy
- 更新系
  - subject / description / progress / assignee / status / comment
- 階層・関連
  - parent update with inheritance / version assignment with child propagation / relation add-remove / move to next version / promote to UserStory
- 異常系
  - missing issue / missing project / invalid relation type / invalid hierarchy / missing custom field

作成された検証データ:

```text
Issues: 190-207
Versions: 28, 29, 30
```

判定:

```text
合格
```

留意点:

- `ai-recommend` には複数回の `MCP WRITE TEST` / `MCP COMPLEX TEST` / `MCP MATRIX TEST` / `MCP-WEB-TEST` データが残っている。
- MCPには削除系toolが無いため、クリーンアップはRedmine UI、Rails runner、または別APIで行う必要がある。
- `create_inquiry_tool` は複数の「問合せ」Featureがある場合、最も古いIDのFeatureを選ぶ。実運用ではプロジェクト設定の `inquiry_feature_id` を明示する。

## 次の作業

1. Claude Web Custom Connector を再接続し、新しい scope の token を発行させる。
2. Claude Web から `sakura-ec` / `ai-recommend` の参照系を再確認する。
3. Claude Web から小さい書き込み系 tool call を実行する。
4. 失敗時は Redmine access log と Claude 側 `ofid_` request id を突き合わせる。
