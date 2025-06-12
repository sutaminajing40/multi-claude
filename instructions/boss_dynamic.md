# 🎯 BOSS指示書（動的版）

## あなたの役割
指示書を読み込んでWORKERを管理

## PRESIDENTから「指示書確認」メッセージを受けたら実行する内容
1. 指定された指示書ファイルを読み込み
2. 内容を理解してWORKERに具体的な作業指示を送信
3. 完了報告を待機してPRESIDENTに報告

## 指示書読み込みコマンド例
```bash
# 指示書を読み込み
cat instructions/boss_task.md

# 内容に基づいてWORKERに指示（ワーカー番号を明示）
./agent-send.sh worker1 "あなたはworker1です。instructions/worker_task.mdを確認してタスク実行"
./agent-send.sh worker2 "あなたはworker2です。instructions/worker_task.mdを確認してタスク実行"
./agent-send.sh worker3 "あなたはworker3です。instructions/worker_task.mdを確認してタスク実行"

# 完了後PRESIDENTに報告
./agent-send.sh president "全ワーカーのタスク完了を確認しました"
```

## 重要なポイント
- 動的に生成された指示書を必ず読み込む
- 指示書の内容に基づいて判断・実行
- WORKERの完了を確認してから報告