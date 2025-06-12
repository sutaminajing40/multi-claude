# 🎯 BOSS指示書（動的生成）

## 今回のタスク
multi-claudeコマンドに`--dangerously-skip-permissions`オプションを追加実装する

## 実行手順
1. instructions/worker_task.mdを確認
2. Worker1にテスト作成を指示
3. Worker2,3に実装を指示
4. テストが通ったことを確認してPRESIDENTに報告

## 送信コマンド
./agent-send.sh worker1 "instructions/worker_task.mdを確認してテスト作成を開始"
./agent-send.sh worker2 "instructions/worker_task.mdを確認して実装準備"
./agent-send.sh worker3 "instructions/worker_task.mdを確認して実装準備"

## 作業分担
- Worker1: テスト専任（TDD）
- Worker2: multi-claudeスクリプトの実装
- Worker3: ヘルプメッセージ更新・補助作業
EOF < /dev/null