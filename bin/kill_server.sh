#!/bin/bash

# 現在のPumaのプロセス番号を取得
if [ -f "/usr/src/redmine/tmp/pids/server.pid" ]; then
  pid=$(cat /usr/src/redmine/tmp/pids/server.pid)

  # Pumaのプロセスを強制終了
  if [ -n "$pid" ]; then
    echo "Pumaのプロセスを強制終了します... PID: $pid"
    kill -9 $pid
    echo "完了しました。"
  else
    echo "PIDファイルは存在しますが、中身が空です。"
  fi
else
  # pgrep でプロセスを探す（代替手段）
  puma_pid=$(pgrep -f puma)
  if [ -n "$puma_pid" ]; then
    echo "Pumaのプロセスを強制終了します... PID: $puma_pid (pgrepで検出)"
    kill -9 $puma_pid
    echo "完了しました。"
  else
    echo "Pumaのプロセスは実行されていません。"
  fi
fi

# PIDファイルが残っている場合は削除
if [ -f "/usr/src/redmine/tmp/pids/server.pid" ]; then
  rm /usr/src/redmine/tmp/pids/server.pid
  echo "server.pid ファイルを削除しました。"
fi