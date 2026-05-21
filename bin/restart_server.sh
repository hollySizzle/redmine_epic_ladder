#!/bin/bash

# Railsサーバー再起動スクリプト（ログバッファ付き）

echo "Railsサーバーを停止中..."
pkill -f "puma.*redmine"

echo "Railsサーバーを起動中..."
echo "ログは /tmp/rails_server_logs.buffer に保存されます"

# Redmineディレクトリに移動してサーバー起動
cd /usr/src/redmine && \
ruby bin/rails server -b 0.0.0.0 -p 3000  2>&1 | tee -a /tmp/rails_server_logs.buffer