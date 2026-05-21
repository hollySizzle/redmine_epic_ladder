# フックリファレンス

> このページでは、Claude Codeでフックを実装するためのリファレンスドキュメントを提供します。

<Tip>
  例を含むクイックスタートガイドについては、[Claude Codeフックの開始](/ja/docs/claude-code/hooks-guide)を参照してください。
</Tip>

## 設定

Claude Codeフックは[設定ファイル](/ja/docs/claude-code/settings)で設定されます：

* `~/.claude/settings.json` - ユーザー設定
* `.claude/settings.json` - プロジェクト設定
* `.claude/settings.local.json` - ローカルプロジェクト設定（コミットされない）
* エンタープライズ管理ポリシー設定

### 構造

フックはマッチャーによって整理され、各マッチャーは複数のフックを持つことができます：

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here"
          }
        ]
      }
    ]
  }
}
```

* **matcher**: ツール名にマッチするパターン、大文字小文字を区別（`PreToolUse`と`PostToolUse`にのみ適用）
  * 単純な文字列は完全一致：`Write`はWriteツールのみにマッチ
  * 正規表現をサポート：`Edit|Write`または`Notebook.*`
  * すべてのツールにマッチするには`*`を使用。空文字列（`""`）を使用するか、`matcher`を空白のままにすることもできます。
* **hooks**: パターンがマッチしたときに実行するコマンドの配列
  * `type`: 現在は`"command"`のみサポート
  * `command`: 実行するbashコマンド（`$CLAUDE_PROJECT_DIR`環境変数を使用可能）
  * `timeout`: （オプション）特定のコマンドをキャンセルするまでの実行時間（秒）

`UserPromptSubmit`、`Notification`、`Stop`、`SubagentStop`などのマッチャーを使用しないイベントの場合、matcherフィールドを省略できます：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/prompt-validator.py"
          }
        ]
      }
    ]
  }
}
```

### プロジェクト固有のフックスクリプト

環境変数`CLAUDE_PROJECT_DIR`（Claude Codeがフックコマンドを起動するときのみ利用可能）を使用して、プロジェクトに保存されたスクリプトを参照でき、Claudeの現在のディレクトリに関係なく動作することを保証できます：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-style.sh"
          }
        ]
      }
    ]
  }
}
```

## フックイベント

### PreToolUse

Claudeがツールパラメータを作成した後、ツール呼び出しを処理する前に実行されます。

**一般的なマッチャー：**

* `Task` - サブエージェントタスク（[サブエージェントドキュメント](/ja/docs/claude-code/sub-agents)を参照）
* `Bash` - シェルコマンド
* `Glob` - ファイルパターンマッチング
* `Grep` - コンテンツ検索
* `Read` - ファイル読み取り
* `Edit`、`MultiEdit` - ファイル編集
* `Write` - ファイル書き込み
* `WebFetch`、`WebSearch` - Web操作

### PostToolUse

ツールが正常に完了した直後に実行されます。

PreToolUseと同じマッチャー値を認識します。

### Notification

Claude Codeが通知を送信するときに実行されます。通知は以下の場合に送信されます：

1. Claudeがツールを使用する許可が必要な場合。例：「ClaudeはBashを使用する許可が必要です」
2. プロンプト入力が少なくとも60秒間アイドル状態の場合。「Claudeはあなたの入力を待っています」

### UserPromptSubmit

ユーザーがプロンプトを送信したとき、Claudeが処理する前に実行されます。これにより、プロンプト/会話に基づいて追加のコンテキストを追加したり、プロンプトを検証したり、特定のタイプのプロンプトをブロックしたりできます。

### Stop

メインのClaude Codeエージェントが応答を完了したときに実行されます。ユーザーの中断による停止の場合は実行されません。

### SubagentStop

Claude Codeサブエージェント（Taskツール呼び出し）が応答を完了したときに実行されます。

### SessionEnd

Claude Codeセッションが終了するときに実行されます。クリーンアップタスク、セッション統計のログ記録、またはセッション状態の保存に便利です。

フック入力の`reason`フィールドは以下のいずれかになります：

* `clear` - /clearコマンドでセッションがクリアされた
* `logout` - ユーザーがログアウトした
* `prompt_input_exit` - プロンプト入力が表示されている間にユーザーが終了した
* `other` - その他の終了理由

### PreCompact

Claude Codeがコンパクト操作を実行しようとする前に実行されます。

**マッチャー：**

* `manual` - `/compact`から呼び出された
* `auto` - 自動コンパクト（コンテキストウィンドウが満杯のため）から呼び出された

### SessionStart

Claude Codeが新しいセッションを開始するか、既存のセッションを再開するとき（現在は内部的に新しいセッションを開始）に実行されます。既存の問題やコードベースへの最近の変更などの開発コンテキストを読み込むのに便利です。

**マッチャー：**

* `startup` - 起動から呼び出された
* `resume` - `--resume`、`--continue`、または`/resume`から呼び出された
* `clear` - `/clear`から呼び出された

## フック入力

フックはセッション情報とイベント固有のデータを含むJSONデータをstdinを介して受信します：

```typescript
{
  // 共通フィールド
  session_id: string
  transcript_path: string  // 会話JSONへのパス
  cwd: string              // フックが呼び出されたときの現在の作業ディレクトリ

  // イベント固有のフィールド
  hook_event_name: string
  ...
}
```

### PreToolUse入力

`tool_input`の正確なスキーマはツールによって異なります。

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  }
}
```

### PostToolUse入力

`tool_input`と`tool_response`の正確なスキーマはツールによって異なります。

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  },
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  }
}
```

### Notification入力

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "hook_event_name": "Notification",
  "message": "Task completed successfully"
}
```

### UserPromptSubmit入力

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "Write a function to calculate the factorial of a number"
}
```

### StopとSubagentStop入力

`stop_hook_active`は、Claude Codeがすでにストップフックの結果として継続している場合にtrueになります。Claude Codeが無限に実行されることを防ぐために、この値をチェックするか、トランスクリプトを処理してください。

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "hook_event_name": "Stop",
  "stop_hook_active": true
}
```

### PreCompact入力

`manual`の場合、`custom_instructions`はユーザーが`/compact`に渡すものから来ます。`auto`の場合、`custom_instructions`は空です。

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "hook_event_name": "PreCompact",
  "trigger": "manual",
  "custom_instructions": ""
}
```

### SessionStart入力

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

### SessionEnd入力

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "hook_event_name": "SessionEnd",
  "reason": "exit"
}
```

## フック出力

フックがClaude Codeに出力を返す方法は2つあります。出力は、ブロックするかどうかと、Claudeとユーザーに表示すべきフィードバックを伝達します。

### シンプル：終了コード

フックは終了コード、stdout、stderrを通じてステータスを伝達します：

* **終了コード0**: 成功。`stdout`はトランスクリプトモード（CTRL-R）でユーザーに表示されますが、`UserPromptSubmit`と`SessionStart`では、stdoutがコンテキストに追加されます。
* **終了コード2**: ブロッキングエラー。`stderr`がClaudeに自動的にフィードバックされ処理されます。以下のフックイベント別の動作を参照してください。
* **その他の終了コード**: 非ブロッキングエラー。`stderr`がユーザーに表示され、実行が継続されます。

<Warning>
  注意：終了コードが0の場合、Claude Codeはstdoutを見ません。ただし、`UserPromptSubmit`フックでは、stdoutがコンテキストとして注入されます。
</Warning>

#### 終了コード2の動作

| フックイベント            | 動作                                       |
| ------------------ | ---------------------------------------- |
| `PreToolUse`       | ツール呼び出しをブロックし、stderrをClaudeに表示           |
| `PostToolUse`      | stderrをClaudeに表示（ツールは既に実行済み）             |
| `Notification`     | N/A、stderrをユーザーにのみ表示                     |
| `UserPromptSubmit` | プロンプト処理をブロックし、プロンプトを消去し、stderrをユーザーにのみ表示 |
| `Stop`             | 停止をブロックし、stderrをClaudeに表示                |
| `SubagentStop`     | 停止をブロックし、stderrをClaudeサブエージェントに表示        |
| `PreCompact`       | N/A、stderrをユーザーにのみ表示                     |
| `SessionStart`     | N/A、stderrをユーザーにのみ表示                     |
| `SessionEnd`       | N/A、stderrをユーザーにのみ表示                     |

### 高度：JSON出力

フックはより洗練された制御のために、`stdout`で構造化されたJSONを返すことができます：

#### 共通JSONフィールド

すべてのフックタイプは、これらのオプションフィールドを含めることができます：

```json
{
  "continue": true, // フック実行後にClaudeが継続すべきかどうか（デフォルト：true）
  "stopReason": "string", // continueがfalseの場合に表示されるメッセージ

  "suppressOutput": true, // トランスクリプトモードからstdoutを隠す（デフォルト：false）
  "systemMessage": "string" // ユーザーに表示されるオプションの警告メッセージ
}
```

`continue`がfalseの場合、フック実行後にClaudeは処理を停止します。

* `PreToolUse`の場合、これは`"permissionDecision": "deny"`とは異なり、特定のツール呼び出しのみをブロックし、Claudeに自動フィードバックを提供します。
* `PostToolUse`の場合、これは`"decision": "block"`とは異なり、Claudeに自動フィードバックを提供します。
* `UserPromptSubmit`の場合、これはプロンプトが処理されることを防ぎます。
* `Stop`と`SubagentStop`の場合、これは任意の`"decision": "block"`出力よりも優先されます。
* すべての場合において、`"continue" = false`は任意の`"decision": "block"`出力よりも優先されます。

`stopReason`は`continue`に伴い、ユーザーに表示される理由を提供しますが、Claudeには表示されません。

#### `PreToolUse`決定制御

`PreToolUse`フックはツール呼び出しが進行するかどうかを制御できます。

* `"allow"`は許可システムをバイパスします。`permissionDecisionReason`はユーザーに表示されますが、Claudeには表示されません。
* `"deny"`はツール呼び出しの実行を防ぎます。`permissionDecisionReason`はClaudeに表示されます。
* `"ask"`はUIでツール呼び出しを確認するようユーザーに求めます。`permissionDecisionReason`はユーザーに表示されますが、Claudeには表示されません。

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow" | "deny" | "ask",
    "permissionDecisionReason": "My reason here"
  }
}
```

<Note>
  PreToolUseフックの`decision`と`reason`フィールドは非推奨です。
  代わりに`hookSpecificOutput.permissionDecision`と
  `hookSpecificOutput.permissionDecisionReason`を使用してください。非推奨フィールド
  `"approve"`と`"block"`はそれぞれ`"allow"`と`"deny"`にマップされます。
</Note>

#### `PostToolUse`決定制御

`PostToolUse`フックはツール実行後にClaudeにフィードバックを提供できます。

* `"block"`は自動的にClaudeに`reason`でプロンプトします。
* `undefined`は何もしません。`reason`は無視されます。
* `"hookSpecificOutput.additionalContext"`はClaudeが考慮するコンテキストを追加します。

```json
{
  "decision": "block" | undefined,
  "reason": "Explanation for decision",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Additional information for Claude"
  }
}
```

#### `UserPromptSubmit`決定制御

`UserPromptSubmit`フックはユーザープロンプトが処理されるかどうかを制御できます。

* `"block"`はプロンプトが処理されることを防ぎます。送信されたプロンプトはコンテキストから消去されます。`"reason"`はユーザーに表示されますが、コンテキストには追加されません。
* `undefined`はプロンプトが正常に進行することを許可します。`"reason"`は無視されます。
* `"hookSpecificOutput.additionalContext"`はブロックされていない場合、文字列をコンテキストに追加します。

```json
{
  "decision": "block" | undefined,
  "reason": "Explanation for decision",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "My additional context here"
  }
}
```

#### `Stop`/`SubagentStop`決定制御

`Stop`と`SubagentStop`フックはClaudeが継続しなければならないかどうかを制御できます。

* `"block"`はClaudeが停止することを防ぎます。Claudeがどのように進行すべきかを知るために、`reason`を設定する必要があります。
* `undefined`はClaudeが停止することを許可します。`reason`は無視されます。

```json
{
  "decision": "block" | undefined,
  "reason": "Must be provided when Claude is blocked from stopping"
}
```

#### `SessionStart`決定制御

`SessionStart`フックはセッションの開始時にコンテキストを読み込むことができます。

* `"hookSpecificOutput.additionalContext"`は文字列をコンテキストに追加します。
* 複数のフックの`additionalContext`値は連結されます。

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "My additional context here"
  }
}
```

#### `SessionEnd`決定制御

`SessionEnd`フックはセッション終了時に実行されます。セッション終了をブロックすることはできませんが、クリーンアップタスクを実行できます。

#### 終了コード例：Bashコマンド検証

```python
#!/usr/bin/env python3
import json
import re
import sys

# 検証ルールを（正規表現パターン、メッセージ）のタプルのリストとして定義
VALIDATION_RULES = [
    (
        r"\bgrep\b(?!.*\|)",
        "Use 'rg' (ripgrep) instead of 'grep' for better performance and features",
    ),
    (
        r"\bfind\s+\S+\s+-name\b",
        "Use 'rg --files | rg pattern' or 'rg --files -g pattern' instead of 'find -name' for better performance",
    ),
]


def validate_command(command: str) -> list[str]:
    issues = []
    for pattern, message in VALIDATION_RULES:
        if re.search(pattern, command):
            issues.append(message)
    return issues


try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

if tool_name != "Bash" or not command:
    sys.exit(1)

# コマンドを検証
issues = validate_command(command)

if issues:
    for message in issues:
        print(f"• {message}", file=sys.stderr)
    # 終了コード2はツール呼び出しをブロックし、stderrをClaudeに表示
    sys.exit(2)
```

#### JSON出力例：コンテキスト追加と検証のためのUserPromptSubmit

<Note>
  `UserPromptSubmit`フックの場合、どちらの方法でもコンテキストを注入できます：

  * 終了コード0とstdout：Claudeがコンテキストを見る（`UserPromptSubmit`の特別なケース）
  * JSON出力：動作をより詳細に制御
</Note>

```python
#!/usr/bin/env python3
import json
import sys
import re
import datetime

# stdinから入力を読み込み
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

prompt = input_data.get("prompt", "")

# 機密パターンをチェック
sensitive_patterns = [
    (r"(?i)\b(password|secret|key|token)\s*[:=]", "Prompt contains potential secrets"),
]

for pattern, message in sensitive_patterns:
    if re.search(pattern, prompt):
        # JSON出力を使用して特定の理由でブロック
        output = {
            "decision": "block",
            "reason": f"Security policy violation: {message}. Please rephrase your request without sensitive information."
        }
        print(json.dumps(output))
        sys.exit(0)

# 現在時刻をコンテキストに追加
context = f"Current time: {datetime.datetime.now()}"
print(context)

"""
以下も同等です：
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": context,
  },
}))
"""

# 追加コンテキストでプロンプトの進行を許可
sys.exit(0)
```

#### JSON出力例：承認付きPreToolUse

```python
#!/usr/bin/env python3
import json
import sys

# stdinから入力を読み込み
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

# 例：ドキュメントファイルのファイル読み取りを自動承認
if tool_name == "Read":
    file_path = tool_input.get("file_path", "")
    if file_path.endswith((".md", ".mdx", ".txt", ".json")):
        # JSON出力を使用してツール呼び出しを自動承認
        output = {
            "decision": "approve",
            "reason": "Documentation file auto-approved",
            "suppressOutput": True  # トランスクリプトモードで表示しない
        }
        print(json.dumps(output))
        sys.exit(0)

# その他の場合は、通常の許可フローを進行させる
sys.exit(0)
```

## MCPツールとの連携

Claude Codeフックは[Model Context Protocol（MCP）ツール](/ja/docs/claude-code/mcp)とシームレスに連携します。MCPサーバーがツールを提供する場合、フックでマッチできる特別な命名パターンで表示されます。

### MCPツールの命名

MCPツールは`mcp__<server>__<tool>`のパターンに従います。例：

* `mcp__memory__create_entities` - Memoryサーバーのエンティティ作成ツール
* `mcp__filesystem__read_file` - Filesystemサーバーのファイル読み取りツール
* `mcp__github__search_repositories` - GitHubサーバーの検索ツール

### MCPツール用のフック設定

特定のMCPツールまたはMCPサーバー全体をターゲットにできます：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__memory__.*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Memory operation initiated' >> ~/mcp-operations.log"
          }
        ]
      },
      {
        "matcher": "mcp__.*__write.*",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/scripts/validate-mcp-write.py"
          }
        ]
      }
    ]
  }
}
```

## 例

<Tip>
  コードフォーマット、通知、ファイル保護を含む実用的な例については、開始ガイドの[その他の例](/ja/docs/claude-code/hooks-guide#more-examples)を参照してください。
</Tip>

## セキュリティに関する考慮事項

### 免責事項

**自己責任で使用してください**：Claude Codeフックはシステム上で任意のシェルコマンドを自動的に実行します。フックを使用することで、以下を認めることになります：

* 設定するコマンドについて単独で責任を負う
* フックはユーザーアカウントがアクセスできる任意のファイルを変更、削除、またはアクセスできる
* 悪意のあるまたは不適切に書かれたフックはデータ損失やシステム損傷を引き起こす可能性がある
* Anthropicは保証を提供せず、フック使用による損害について一切の責任を負わない
* 本番環境で使用する前に、安全な環境でフックを十分にテストすべきである

設定に追加する前に、常にフックコマンドを確認し理解してください。

### セキュリティのベストプラクティス

より安全なフックを書くための主要な実践方法：

1. **入力を検証・サニタイズ** - 入力データを盲目的に信頼しない
2. **常にシェル変数を引用符で囲む** - `$VAR`ではなく`"$VAR"`を使用
3. **パストラバーサルをブロック** - ファイルパスの`..`をチェック
4. **絶対パスを使用** - スクリプトの完全パスを指定（プロジェクトパスには`$CLAUDE_PROJECT_DIR`を使用）
5. **機密ファイルをスキップ** - `.env`、`.git/`、キーなどを避ける

### 設定の安全性

設定ファイルでのフックの直接編集は即座に有効になりません。Claude Codeは：

1. 起動時にフックのスナップショットを取得
2. セッション全体でこのスナップショットを使用
3. フックが外部で変更された場合に警告
4. 変更を適用するために`/hooks`メニューでの確認が必要

これにより、悪意のあるフック変更が現在のセッションに影響することを防ぎます。

## フック実行の詳細

* **タイムアウト**：デフォルトで60秒の実行制限、コマンドごとに設定可能。
  * 個別のコマンドのタイムアウトは他のコマンドに影響しません。
* **並列化**：マッチするすべてのフックが並列実行
* **重複排除**：同一のフックコマンドは自動的に重複排除
* **環境**：Claude Codeの環境で現在のディレクトリで実行
  * `CLAUDE_PROJECT_DIR`環境変数が利用可能で、プロジェクトルートディレクトリ（Claude Codeが開始された場所）の絶対パスが含まれます
* **入力**：stdinを介したJSON
* **出力**：
  * PreToolUse/PostToolUse/Stop/SubagentStop：トランスクリプト（Ctrl-R）に進行状況表示
  * Notification/SessionEnd：デバッグのみにログ記録（`--debug`）
  * UserPromptSubmit/SessionStart：stdoutがClaudeのコンテキストとして追加

## デバッグ

### 基本的なトラブルシューティング

フックが動作しない場合：

1. **設定を確認** - `/hooks`を実行してフックが登録されているか確認
2. **構文を検証** - JSON設定が有効であることを確認
3. **コマンドをテスト** - まずフックコマンドを手動で実行
4. **権限を確認** - スクリプトが実行可能であることを確認
5. **ログを確認** - `claude --debug`を使用してフック実行の詳細を確認

一般的な問題：

* **引用符がエスケープされていない** - JSON文字列内で`\"`を使用
* **間違ったマッチャー** - ツール名が正確にマッチしているか確認（大文字小文字を区別）
* **コマンドが見つからない** - スクリプトの完全パスを使用

### 高度なデバッグ

複雑なフックの問題の場合：

1. **フック実行を検査** - `claude --debug`を使用して詳細なフック実行を確認
2. **JSONスキーマを検証** - 外部ツールでフック入力/出力をテスト
3. **環境変数を確認** - Claude Codeの環境が正しいことを確認
4. **エッジケースをテスト** - 異常なファイルパスや入力でフックを試す
5. **システムリソースを監視** - フック実行中のリソース枯渇をチェック
6. **構造化ログを使用** - フックスクリプトでログを実装

### デバッグ出力例

`claude --debug`を使用してフック実行の詳細を確認：

```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Getting matching hook commands for PostToolUse with query: Write
[DEBUG] Found 1 hook matchers in settings
[DEBUG] Matched 1 hooks for query "Write"
[DEBUG] Found 1 hook commands to execute
[DEBUG] Executing hook command: <Your command> with timeout 60000ms
[DEBUG] Hook command completed with status 0: <Your stdout>
```

進行状況メッセージはトランスクリプトモード（Ctrl-R）に表示され、以下を示します：

* 実行中のフック
* 実行されるコマンド
* 成功/失敗ステータス
* 出力またはエラーメッセージ
