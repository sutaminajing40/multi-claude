# Agent Communication System

## エージェント構成
- **PRESIDENT** (別セッション): 統括責任者 + 動的指示書生成
- **boss1** (multiagent:0.0): チームリーダー + 指示書読み込み
- **worker1,2,3** (multiagent:0.1-3): 実行担当 + 指示書実行

## あなたの役割（動的版）
- **PRESIDENT**: @instructions/president_dynamic.md
- **boss1**: @instructions/boss_dynamic.md  
- **worker1,2,3**: @instructions/worker_dynamic.md

## メッセージ送信
```bash
./agent-send.sh [相手] "[メッセージ]"
```

## 新しい基本フロー
ユーザー → PRESIDENT（指示書生成） → boss1（指示書読み込み） → workers（指示書実行） → boss1 → PRESIDENT

## 動的指示書システム
- ユーザーの要求に応じてPRESIDENTが指示書を自動生成
- BOSSとWORKERは生成された指示書を読み込んで実行
- 柔軟でスケーラブルなタスク管理が可能