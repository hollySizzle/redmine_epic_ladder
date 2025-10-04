# https://zenn.dev/koki_n22/articles/a02e0e9138c959

# install_serena() {
    if [ ! -d "$1" ]; then
        echo "エラー: ディレクトリ '$1' が存在しません"
        return 1
    fi

    local original_dir=$(pwd)

    cd "$1"

    claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)

    echo "プロジェクト '$(basename $(pwd))' にSerenaが設定されました"
    echo "Serenaを初期化しています..."
    claude --print --dangerously-skip-permissions "/mcp__serena__initial_instructions"
    echo "セットアップ完了: Serenaが使用可能です"

    cd "$original_dir"
# }