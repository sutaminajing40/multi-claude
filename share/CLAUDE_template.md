# 🤖 Multi-Claude システム設定

## システム概要

Multi-Claudeは、複数のClaude Codeインスタンスが協調して動作するマルチエージェント開発システムです。

### プロジェクト情報
- **起動日時**: [STARTUP_TIME]
- **プロジェクトパス**: [PROJECT_PATH]
- **環境変数**:
  - `MULTI_CLAUDE_GLOBAL`: [GLOBAL_PATH]
  - `MULTI_CLAUDE_LOCAL`: [LOCAL_PATH]

## Agent Communication System

### エージェント構成

- **PRESIDENT** (別セッション): 統括責任者 + タスク概要伝達
- **boss1** (multiagent:0.0): チームリーダー + 要件整理・指示書生成
- **worker1,2,3** (multiagent:0.1-3): 実行担当 + 進捗共有

### あなたの役割（動的版）

- **PRESIDENT**: @.multi-claude/instructions/president_dynamic.md
- **boss1**: @.multi-claude/instructions/boss_dynamic.md
- **worker1,2,3**: @.multi-claude/instructions/worker_dynamic.md

### メッセージ送信

```bash
# プロジェクトルートから実行
$MULTI_CLAUDE_GLOBAL/bin/agent-send.sh [相手] "[メッセージ]"
# 注: MULTI_CLAUDE_GLOBAL は multi-claude 起動時に自動設定されます
```

### 新しい基本フロー

ユーザー → PRESIDENT（タスク概要理解） → boss1（要件整理・指示書生成） → workers（実行・進捗共有） → boss1 → PRESIDENT

### 改善されたシステム特徴

1. **役割分担の最適化**
   - PRESIDENT: ユーザーとの対話に集中
   - BOSS: 要件整理と具体的な指示書生成
   - WORKER: 進捗を共有しながら実行

2. **クリーンなファイル配置**
   - すべての作業ファイルは `.multi-claude/` フォルダ内に配置
   - プロジェクトルートを汚さない設計

3. **ワーカー間コンテキスト共有**
   - 各ワーカーが進捗を `.multi-claude/context/worker[番号]_progress.md` に記録
   - 作業の重複を防ぎ、効率的な協調作業を実現

## プロジェクト固有のデータ配置

```
.multi-claude/
├── instructions/     # 役割定義・指示書（プロジェクト固有）
│   ├── president_dynamic.md  # カスタマイズ可能
│   ├── boss_dynamic.md       # カスタマイズ可能
│   └── worker_dynamic.md     # カスタマイズ可能
├── session/          # セッション固有データ
│   ├── tmp/          # 一時ファイル（ワーカー完了状態など）
│   ├── logs/         # 通信ログ
│   └── runtime/      # ランタイム情報
├── context/          # ワーカー進捗共有
├── tasks/            # タスク管理
│   ├── current_task.md    # 現在のタスク
│   └── completion_report.md # 完了レポート
└── config/           # プロジェクト設定
```

**注**: 指示書ファイルは初回起動時にグローバルからコピーされます。プロジェクト固有の要件に合わせて自由に編集できます。

## クイックコマンドリファレンス

```bash
# エージェント間通信
$MULTI_CLAUDE_GLOBAL/bin/agent-send.sh boss1 "メッセージ"
$MULTI_CLAUDE_GLOBAL/bin/agent-send.sh --list  # 利用可能エージェント一覧

# ログ確認
tail -f .multi-claude/session/logs/send_log.txt      # リアルタイムログ監視
grep "worker1" .multi-claude/session/logs/send_log.txt # 特定エージェントのログ

# タスク・進捗確認
cat .multi-claude/tasks/current_task.md              # 現在のタスク
ls -la .multi-claude/context/worker*_progress.md     # ワーカー進捗

# セッション管理
tmux list-sessions                                   # セッション一覧
tmux attach-session -t president                     # PRESIDENTに接続
tmux attach-session -t multiagent                    # MULTIAGENTに接続

# システム制御
multi-claude --exit                                  # システム完全終了
multi-claude --help                                  # ヘルプ表示
```

## トラブルシューティング

### エージェントが応答しない場合
```bash
# システム状態確認
$MULTI_CLAUDE_GLOBAL/bin/health-check.sh

# tmuxセッション確認
tmux list-panes -t multiagent
tmux list-panes -t president
```

### ログの場所
- 通信ログ: `.multi-claude/session/logs/send_log.txt`
- エラーログ: 各tmuxペイン内で確認

---
*このファイルはmulti-claude起動時に自動生成されました*