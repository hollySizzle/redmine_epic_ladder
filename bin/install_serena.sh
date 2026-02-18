#!/bin/bash
# https://zenn.dev/koki_n22/articles/a02e0e9138c959

# bashで実行されているかチェック
if [ -z "$BASH_VERSION" ]; then
    echo "エラー: このスクリプトはbashで実行してください"
    echo "実行方法: bash $0"
    exit 1
fi

# uvxがインストールされているかチェック
if ! command -v uvx &> /dev/null; then
    echo "uvxがインストールされていません。インストールを開始します..."
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && \
    source ~/.bashrc && \
    uvx --version

    if [ $? -ne 0 ]; then
        echo "エラー: uvxのインストールに失敗しました"
        exit 1
    fi
    echo "uvxのインストールが完了しましたぁ"
else
    echo "uvxは既にインストールされています (version: $(uvx --version))"
fi

install_serena() {
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
}

# 引数チェックと関数呼び出し
if [ $# -eq 0 ]; then
    echo "使用方法: bash $0 <プロジェクトディレクトリパス>"
    echo "例: bash $0 /usr/src/redmine/plugins/redmine_epic_ladder"
    exit 1
fi

install_serena "$1"