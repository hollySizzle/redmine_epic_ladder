# Claude Web MCP Live E2E テストケース

## 目的

Claude Web Custom Connector が、実際に `redmine_epic_ladder` MCP に接続し、OAuth 認証後に Bearer token 付きで tool call できることを確認する。

ローカル自動テストや HTTP/API key テストで網羅性を担保し、このテストでは Claude Web 固有の境界だけを確認する。

## 前提

- 公開URL: `https://mcp-test.giken.or.jp/mcp/rpc`
- 検証プロジェクト: `ai-recommend`
- `ai-recommend` はMCP検証用サンドボックスとして扱う。
- 事前に `db/seeds/06_mcp_sandbox.rb` を投入し、`MCP-SEED` 系のVersion/Issue、`inquiry_feature_id`、`MCP Sandbox Text` custom field が存在する状態にする。
- Claude Web Custom Connector には Redmine OAuth application の Client ID / Secret を設定する。
- OAuth application scope は以下を含む。
  - `view_project`
  - `view_issues`
  - `add_issues`
  - `edit_issues`
  - `add_issue_notes`
  - `manage_versions`
  - `manage_issue_relations`
  - `add_subprojects`

## サーバ側監視

Claude Web で接続・実行する間、別シェルでログを監視する。

```bash
tail -f /tmp/redmine_mcp_dev.log /tmp/redmine_mcp_cloudflared.log
```

見るべき事実:

- `GET /authorize` または `/oauth/authorize`
- `POST /token` または `/oauth/token`
- `POST /mcp/rpc`
- MCP tool call 時に 401 ではなく認証済みユーザーとして処理されること
- 失敗時に Claude 側の `ofid_` request id と Redmine log の request id を突き合わせられること

## Test 1: Connector 接続

Claude Web Custom Connector に以下を登録する。

```text
URL:
https://mcp-test.giken.or.jp/mcp/rpc

OAuth Client ID:
Redmine OAuth application UID

OAuth Client Secret:
Redmine OAuth application secret
```

期待結果:

- Claude Web でOAuth認可画面が開く。
- Redmineにログインして認可できる。
- Claude Web が connector を接続済みとして扱う。
- Redmine log に OAuth authorization code flow のアクセスが残る。

失敗時の判定:

- OAuth画面が出ない: discovery / challenge / metadata 問題。
- `invalid_client`: Client ID / Secret の取り違え。
- callback後に失敗: redirect URI または token endpoint 問題。

## Test 2: 参照系

Claude Web で以下を実行する。

```text
redmine_epic_ladder MCPを使って、ai-recommend のプロジェクト構造、バージョン一覧、Epic一覧、メンバー一覧を取得してください。取得できたproject ID、version数、Epic数、メンバー数を簡潔に報告してください。
```

期待結果:

- `get_project_structure_tool`
- `list_versions_tool`
- `list_epics_tool`
- `list_project_members_tool`

のいずれか、または同等の参照系toolが呼ばれる。

合格条件:

- `ai-recommend` が見つかる。
- 「チケット閲覧権限がありません」にならない。
- Redmine log に `POST /mcp/rpc` が記録される。
- Claudeの回答が実データに基づく。

## Test 3: 軽い書き込み

Claude Web で以下を実行する。

```text
ai-recommend はMCP検証用サンドボックスです。Redmine MCPを使って、名前に [CLAUDE LIVE TEST 20260517] を含むテスト用Versionを1件作成し、そのVersion IDを報告してください。業務データとして使わない検証データであることが分かるdescriptionにしてください。
```

期待tool:

- `create_version_tool`

合格条件:

- Version が作成される。
- Claude が作成された version ID を返す。
- Redmine log に `create_version_tool` 相当の処理が残る。

## Test 4: 階層作成

Claude Web で以下を実行する。

```text
ai-recommend はMCP検証用サンドボックスです。Redmine MCPを使って、[CLAUDE LIVE TEST 20260517] を含むEpic、Feature、UserStory、Taskを1件ずつ作成してください。Epic→Feature→UserStory→Task の親子関係にしてください。最後に作成された各Issue IDを報告してください。
```

期待tool:

- `create_epic_tool`
- `create_feature_tool`
- `create_user_story_tool`
- `create_task_tool`

合格条件:

- 4件すべて作成される。
- 親子関係が成立する。
- Claude が各IDを返す。

注意:

- `create_user_story_tool` は `version_id` 未指定時に、親FeatureのVersionを継承する。親にVersionがなければプロジェクト内で最も早いopen Versionを使う。
- 検証DBに過去のテストVersionが残っている場合、意図しないVersionが付くことがある。業務利用時は `version_id` を明示するか、作成後に `assign_to_version_tool` で上書きする。

## Test 5: 更新と再取得

Test 4 で作成した Task ID を使って実行する。

```text
先ほど作成したTaskにコメントを追加し、進捗を40%に更新してください。その後、詳細を再取得して、コメント追加と進捗更新が反映されているか確認してください。
```

期待tool:

- `add_issue_comment_tool`
- `update_issue_progress_tool`
- `get_issue_detail_tool`

合格条件:

- コメント追加が成功する。
- `done_ratio` が40になる。
- Claude が再取得結果に基づいて確認結果を返す。

注意:

- UserStoryなど子チケットを持つ親チケットは、Redmine設定により進捗率が子チケットから自動計算される場合がある。その場合、親チケットの進捗率を直接更新する操作は失敗するのが正しい。

## Test 6: 代表的な異常系

Claude Web で以下を実行する。

```text
Redmine MCPで、存在しないIssue ID 999999999 の詳細取得を試してください。失敗した場合は、返ってきたエラーメッセージをそのまま要約してください。
```

期待tool:

- `get_issue_detail_tool`

合格条件:

- tool call 自体は実行される。
- MCPから「チケットが見つかりません」系の業務エラーが返る。
- Claudeがエラーを隠さず説明する。

## 判定

合格:

- Test 1からTest 6まで通る。
- Claude Webからの tool call が Redmine log に残る。
- 参照・書き込み・更新・業務エラーがすべて確認できる。

条件付き合格:

- Test 1からTest 3まで通り、Test 4以降がClaudeのtool選択揺れで失敗する。
- この場合、ローカル `mcp_tool_matrix_test` が通っていれば、MCP実装側の網羅性は別途担保済みと扱う。

不合格:

- OAuth接続できない。
- Claude WebがBearer tokenを付けてこない。
- `tools/list` はできるが、参照系toolが権限エラーになる。
- 書き込み系toolがscope不足で失敗する。
