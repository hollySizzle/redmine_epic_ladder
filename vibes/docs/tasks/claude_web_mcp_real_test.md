# Claude Web MCP 実接続テスト手順

## 目的

Claude Web Custom Connector から `redmine_epic_ladder` の `/mcp/rpc` に接続できることを確認する。

## 前提

- Redmine は `/usr/src/redmine` を起点に起動する。
- ローカル開発サーバは `bin/dev` で `http://localhost:8500` に起動する。
- Claude Web 実接続には公開 HTTPS URL が必要。localhost は Claude Web から到達できない。
- Redmine OAuth application secret は作成時しか表示できない。

## 自動テスト

Redmine ルートから実行する。

```bash
cd /usr/src/redmine
env RAILS_ENV=test bundle exec rspec \
  plugins/redmine_epic_ladder/spec/requests/mcp/server_controller_spec.rb \
  plugins/redmine_epic_ladder/spec/controllers/mcp/server_controller_spec.rb
```

期待結果:

```text
38 examples, 0 failures, 1 pending
```

## ローカル疎通テスト

サーバ起動:

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
bin/dev
```

別シェルで smoke test:

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
bin/mcp_oauth_smoke_test http://localhost:8500
```

API key 認証まで確認する場合:

```bash
MCP_API_KEY=redmine_api_key \
bin/mcp_oauth_smoke_test http://localhost:8500
```

OAuth Bearer token まで確認する場合:

```bash
MCP_BEARER_TOKEN=oauth_access_token \
bin/mcp_oauth_smoke_test http://localhost:8500
```

確認対象:

- `/.well-known/oauth-protected-resource/mcp/rpc`
- `/.well-known/oauth-authorization-server`
- `/mcp/rpc` 未認証時の `401` + `WWW-Authenticate`
- `/authorize` -> `/oauth/authorize` redirect alias
- 任意で API key / Bearer token による `tools/list`

## 書き込み系スモークテスト

ローカルMCP経由で、作成・更新・関連付け・コピー・詳細取得までまとめて確認する。

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
MCP_API_KEY=redmine_api_key \
MCP_TEST_PROJECT=sakura-ec \
bin/mcp_write_smoke_test http://localhost:8500
```

別プロジェクトを確認する場合は `MCP_TEST_PROJECT` を変更する。

```bash
MCP_API_KEY=redmine_api_key \
MCP_TEST_PROJECT=ai-recommend \
bin/mcp_write_smoke_test http://localhost:8500
```

確認対象:

- `list_statuses_tool`
- `list_project_members_tool`
- `create_version_tool`
- `create_epic_tool`
- `create_feature_tool`
- `create_user_story_tool`
- `create_task_tool`
- `create_bug_tool`
- `create_test_tool`
- `add_issue_comment_tool`
- `update_issue_subject_tool`
- `update_issue_description_tool`
- `update_issue_progress_tool`
- `update_issue_assignee_tool`
- `assign_to_version_tool`
- `bulk_update_issue_status_tool`
- `update_issue_status_tool`
- `add_related_issue_tool`
- `remove_related_issue_tool`
- `copy_issue_tool`
- `update_issue_parent_tool`
- `get_issue_detail_tool`

このテストは実データを作成・更新する。開発DBまたは検証用プロジェクトで実行する。
進捗更新の正常系は、子チケットを持つ親チケットではなく Task/Bug/Test などのleaf issueで確認する。Redmine設定で親チケットの進捗が子から自動計算される場合、親チケットへの直接更新は失敗するのが正しい。

## 複合シナリオテスト

単発ツールの疎通ではなく、複数ツールを組み合わせた業務フローの整合性を確認する。
検証用サンドボックスとして `ai-recommend` を使う。

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
MCP_API_KEY=redmine_api_key \
MCP_TEST_PROJECT=ai-recommend \
bin/mcp_complex_scenario_test http://localhost:8500
```

確認対象:

- Alpha / Beta の2バージョンを作成する。
- 1つのEpic配下に Feature A / Feature B と UserStory A / UserStory B を作成する。
- UserStory A 配下に Task / Bug / Test を作成する。
- UserStory A に Alpha version を割り当て、子チケットへの伝播を実データで検証する。
- UserStory B に Beta version を割り当てる。
- Task A を UserStory B 配下へ移動し、親から Beta version を継承することを検証する。
- Epic を子孫配下へ移動する循環参照操作が拒否されることを検証する。
- Bug A と Task A に `blocks` relation を追加し、詳細取得で確認してから削除する。
- 移動済みTaskを UserStory A 配下へコピーし、Alpha version override が効くことを検証する。
- 一括ステータス更新に存在しないIDを混ぜ、部分成功・部分失敗が返ることを検証する。
- `get_project_structure_tool` の version filter で Alpha 側だけが返ることを検証する。

2026-05-17 の `ai-recommend` 実行結果:

```text
MCP complex scenario test passed.
Created issue IDs: 155, 156, 157, 158, 159, 160, 161, 162, 163
Created version IDs: 17, 18
Branch A user story: #157
Branch B user story: #159
```

## ツールマトリクステスト

Claude Web ではなく HTTP/API key 経由で、全MCPツールの公開状態と代表動作を確認する。

`ai-recommend` で安定して実行する場合は、先にMCPサンドボックス用seedを投入する。

```bash
cd /usr/src/redmine
RAILS_ENV=development bundle exec rails runner plugins/redmine_epic_ladder/db/seeds/02_projects.rb
RAILS_ENV=development bundle exec rails runner plugins/redmine_epic_ladder/db/seeds/03_versions.rb
RAILS_ENV=development bundle exec rails runner plugins/redmine_epic_ladder/db/seeds/06_mcp_sandbox.rb
```

このseedは以下を保証する。

- `ai-recommend` で `epic_ladder` module が有効。
- `admin` が `MCPテスター` role でメンバー登録済み。
- `MCP-SEED Alpha` / `MCP-SEED Beta` / `MCP-SEED Gamma` が存在する。
- `MCP-SEED Epic` / `Feature` / `問合せ Feature` / `UserStory` / `Task` / `Bug` / `Test` が存在する。
- `inquiry_feature_id` が `MCP-SEED 問合せ Feature` を指す。
- `MCP Sandbox Text` カスタムフィールドが `ai-recommend` で利用可能。

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
MCP_API_KEY=redmine_api_key \
MCP_TEST_PROJECT=ai-recommend \
bin/mcp_tool_matrix_test http://localhost:8500
```

確認対象:

- `tools/list` で全31ツールが公開されていること
- 各ツールに `description` と `inputSchema` があること
- 実データで成立するツールの最小正常系
- 代表的な異常系
  - 存在しない issue
  - 存在しない project
  - 無効な relation type
  - 循環参照 parent update
  - 存在しない custom field
  - bulk update の部分失敗
  - 子チケットから進捗が自動計算される親チケットへの progress 直接更新拒否

2026-05-17 の `ai-recommend` 実行結果:

```text
MCP tool matrix test passed.
Tool count: 31
Created issue IDs: 225, 226, 227, 228, 229, 230, 231, 232, 233, 234
Created version IDs: 37, 38, 39
```

注意:

- `update_custom_fields_tool` は `MCP Sandbox Text` が存在する場合、正常系と「存在しないcustom fieldの異常系」の両方を検証する。
- `create_inquiry_tool` は「問合せ」を含むFeatureを自動検出する。検証DBに複数の問合せFeatureがある場合、今回作成したFeatureが選ばれるとは限らない。
- `move_to_next_version_tool` は現在Versionより後で最も近いopen Versionへ移動する。検証DBに既存Versionがある場合、今回作成したV2が選ばれるとは限らない。
- `create_user_story_tool` は `version_id` 未指定時に、親FeatureのVersion、またはプロジェクト内で最も早いopen Versionを自動採用する。業務データでは `version_id` を明示する。

## Claude Web 実接続テスト結果

2026-05-17 に Claude Web Custom Connector 経由で `ai-recommend` に対し実行した。

実行ID:

```text
MCP-WEB-TEST 20260517T135350Z
```

総合結果:

```text
合格
```

確認した内容:

- 書き込みスモーク
- 複合シナリオ
- ツールマトリクス相当
- 代表異常系

作成リソース:

```text
Issues: 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207
Versions: 28, 29, 30
```

重要な確認事項:

- Claude Web から参照・作成・更新・関連・階層操作・部分失敗ハンドリングが動作した。
- leaf Task の `update_issue_progress_tool` は実データに反映された。
- 子チケットを持つ親UserStoryは `done_ratio_derived=true` のため、進捗率は子から自動計算される。
- `create_inquiry_tool` は複数の「問合せ」Featureがある場合、最も古いIDのFeatureを選ぶ。
- `create_user_story_tool` は `version_id` 未指定時に自動でVersionを採用する。

残課題:

- `ai-recommend` の `[MCP ... TEST]` 系データのクリーンアップ方針を決める。
- 実運用プロジェクトでは `inquiry_feature_id` と `version_id` の明示運用を標準化する。

## Cloudflare Tunnel で仮サブドメインを公開

Claude Web から接続するには、Claude 側サーバーから到達できる HTTPS URL が必要。
Cloudflare 管理ドメイン配下の仮サブドメインを使う場合は named tunnel を作成して DNS route を張る。

初回だけ `cloudflared` をログインする。

```bash
cloudflared tunnel login
```

Redmine をローカルで起動する。

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
bin/dev
```

別シェルで Tunnel を起動する。

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
TUNNEL_HOSTNAME=mcp-test.example.com \
bin/cloudflare_tunnel_mcp run
```

このスクリプトは以下を実行する。

- `cloudflared tunnel create`
- `cloudflared tunnel route dns`
- `/tmp/redmine-epic-ladder-mcp.cloudflared.yml` への設定ファイル生成
- `cloudflared tunnel --config ... run`

公開URLに対して smoke test を実行する。

```bash
TUNNEL_HOSTNAME=mcp-test.example.com \
bin/cloudflare_tunnel_mcp smoke
```

Rails が公開 hostname を拒否する場合だけ、origin への Host header を localhost に変える。
ただしこの場合、OAuth metadata の URL が localhost になる可能性があるため、Claude Web 実接続前に smoke test の出力を確認する。

```bash
TUNNEL_HOSTNAME=mcp-test.example.com \
ORIGIN_HOST_HEADER=localhost \
bin/cloudflare_tunnel_mcp run
```

## Claude Web 用 OAuth application 作成

開発環境に作る場合:

```bash
cd /usr/src/redmine/plugins/redmine_epic_ladder
RAILS_ENV=development bin/create_claude_oauth_app
```

本番環境に作る場合:

```bash
RAILS_ENV=production \
CLAUDE_MCP_APP_NAME="Claude Web MCP" \
CLAUDE_MCP_REDIRECT_URI="https://claude.ai/api/mcp/auth_callback" \
CLAUDE_MCP_SCOPES="view_project view_issues add_issues edit_issues add_issue_notes manage_versions manage_issue_relations" \
bin/create_claude_oauth_app
```

出力される値を Claude Web Custom Connector の Advanced settings に入力する。

```text
OAuth Client ID
OAuth Client Secret
```

## Claude Web Custom Connector 登録

Claude Web の Custom Connector に以下を登録する。

```text
URL:
https://redmine.example.com/mcp/rpc

OAuth Client ID:
bin/create_claude_oauth_app が出力した uid

OAuth Client Secret:
bin/create_claude_oauth_app が出力した secret
```

## 失敗時の確認

Redmine 側:

```bash
tail -f /tmp/rails_server_logs.buffer
tail -f /usr/src/redmine/log/production.log
```

Claude 側:

- Custom Connector の接続エラー表示
- `ofid_` request id が出る場合は Redmine access log と突き合わせる

典型的な切り分け:

- discovery が 404: route / middleware が反映されていない
- `/mcp/rpc` が 401 だが `WWW-Authenticate` がない: challenge 実装不備
- `/authorize` が 404: root alias 不備
- OAuth 後に `invalid_client`: client secret の取り違え
- OAuth 後に MCP が 401: Bearer token が送られていない、または Redmine access token 検証失敗
