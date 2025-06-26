# 🤖 Multi-Claude システム設定

## システム概要

Multi-Claudeは、複数のClaude Codeインスタンスが協調して動作するマルチエージェント開発システムです。

### プロジェクト情報
- **起動日時**: 2025-06-24 15:47:27
- **プロジェクトパス**: /Users/soh/dev/multi-agent-dev/multi-claude-dev
- **環境変数**:
  - `MULTI_CLAUDE_GLOBAL`: /Users/soh/.multi-claude
  - `MULTI_CLAUDE_LOCAL`: /Users/soh/dev/multi-agent-dev/multi-claude-dev/.multi-claude

## Agent Communication System

### エージェント構成

- **PRESIDENT** (別セッション): 統括責任者 + タスク概要伝達
- **boss1** (multiagent:0.0): チームリーダー + 要件整理・指示書生成
- **worker1** (multiagent:0.1): 実装担当 + 進捗共有
- **architect** (multiagent:0.2): 設計・アーキテクチャ担当
- **worker2** (multiagent:0.3): 実装担当 + 進捗共有
- **qa** (multiagent:0.4): 品質保証・テスト担当
- **worker3** (multiagent:0.5): 実装担当 + 進捗共有

### あなたの役割（動的版）

- **PRESIDENT**: @$MULTI_CLAUDE_LOCAL/instructions/president_dynamic.md
- **boss1**: @$MULTI_CLAUDE_LOCAL/instructions/boss_dynamic.md
- **worker1,2,3**: @$MULTI_CLAUDE_LOCAL/instructions/worker_dynamic.md
- **architect**: @$MULTI_CLAUDE_LOCAL/instructions/architect_dynamic.md
- **qa**: @$MULTI_CLAUDE_LOCAL/instructions/qa_dynamic.md

### メッセージ送信

```bash
# プロジェクトルートから実行
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh [相手] "[メッセージ]"
# 注: MULTI_CLAUDE_LOCAL は multi-claude 起動時に自動設定されます
```

### 新しい基本フロー

```
ユーザー 
  ↓
president → boss → architect設計 → qaレビュー → architect設計反映（レビュー内容が問題なくなるまで繰り返す）
  ↓
boss設計内容を確認 → worker1/2/3に割り振り → boss進捗内容を確認 → 実装完了
  ↓
qa実施 → qa未完了なら実装続き
```

詳細フロー：
1. **president**: ユーザー要件を受け取り、タスク概要を把握
2. **boss**: 要件を整理し、指示書を生成
3. **architect**: システム設計を作成
4. **qa**: 設計レビューを実施
5. **architect**: レビュー結果を反映（承認まで繰り返し）
6. **boss**: 最終設計を確認し、workerに作業を割り振り
7. **worker1/2/3**: 並行して実装作業
8. **boss**: 進捗を確認
9. **qa**: 実装内容のテストを実施
10. 未完了項目があれば実装を継続

### 改善されたシステム特徴

1. **役割分担の最適化**
   - PRESIDENT: ユーザーとの対話に集中、全体進捗管理
   - BOSS: 要件整理と5人のエージェントへの指示書生成
   - ARCHITECT: システム設計とアーキテクチャ決定
   - WORKER1/2/3: 実装担当、進捗共有
   - QA: テスト設計・実装、品質保証

2. **効率的な開発フロー**
   - 設計フェーズ: architectが全体設計を担当
   - 実装フェーズ: 3人のworkerが並行実装
   - 品質保証フェーズ: qaがテストを同時進行
   - 統合フェーズ: worker3が統合とデバッグを担当

3. **クリーンなファイル配置**
   - すべての作業ファイルは `$MULTI_CLAUDE_LOCAL/` フォルダ内に配置
   - プロジェクトルートを汚さない設計

4. **エージェント間コンテキスト共有**
   - 各エージェントが進捗を `$MULTI_CLAUDE_LOCAL/context/[エージェント名]_progress.md` に記録
   - 作業の重複を防ぎ、効率的な協調作業を実現
   - architectの設計書を全員が参照可能

## プロジェクト固有のデータ配置

```
$MULTI_CLAUDE_LOCAL/
├── instructions/     # 役割定義・指示書（プロジェクト固有）
│   ├── president_dynamic.md  # カスタマイズ可能
│   ├── boss_dynamic.md       # カスタマイズ可能
│   ├── worker_dynamic.md     # カスタマイズ可能
│   ├── architect_dynamic.md  # カスタマイズ可能
│   └── qa_dynamic.md         # カスタマイズ可能
├── session/          # セッション固有データ
│   ├── tmp/          # 一時ファイル（ワーカー完了状態など）
│   ├── logs/         # 通信ログ
│   └── runtime/      # ランタイム情報
├── context/          # エージェント進捗共有
│   ├── worker1_progress.md
│   ├── architect_progress.md
│   ├── worker2_progress.md
│   ├── qa_progress.md
│   └── worker3_progress.md
├── tasks/            # タスク管理
│   ├── current_task.md      # 現在のタスク
│   ├── worker_task.md       # WORKER用指示書
│   ├── design_doc.md        # architect作成の設計書
│   ├── test_plan.md         # qa作成のテスト計画
│   └── completion_report.md # 完了レポート
└── config/           # プロジェクト設定
```

**注**: 指示書ファイルは初回起動時にグローバルからコピーされます。プロジェクト固有の要件に合わせて自由に編集できます。

## クイックコマンドリファレンス

```bash
# エージェント間通信
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh boss1 "メッセージ"
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh worker1 "メッセージ"
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh --list  # 利用可能エージェント一覧

# architect, qaへの直接通信（agent-send.sh未対応の場合）
tmux send-keys -t multiagent:0.2 "メッセージ" C-m  # architectへ
tmux send-keys -t multiagent:0.4 "メッセージ" C-m  # qaへ

# ログ確認
tail -f $MULTI_CLAUDE_LOCAL/session/logs/send_log.txt      # リアルタイムログ監視
grep "worker1" $MULTI_CLAUDE_LOCAL/session/logs/send_log.txt # 特定エージェントのログ

# タスク・進捗確認
cat $MULTI_CLAUDE_LOCAL/tasks/current_task.md              # 現在のタスク
ls -la $MULTI_CLAUDE_LOCAL/context/*_progress.md           # 全エージェント進捗
cat $MULTI_CLAUDE_LOCAL/tasks/design_doc.md                # 設計ドキュメント
cat $MULTI_CLAUDE_LOCAL/tasks/test_plan.md                 # テスト計画

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
$MULTI_CLAUDE_LOCAL/bin/health-check.sh

# tmuxセッション確認
tmux list-panes -t multiagent
tmux list-panes -t president
```

### ログの場所
- 通信ログ: `$MULTI_CLAUDE_LOCAL/session/logs/send_log.txt`
- エラーログ: 各tmuxペイン内で確認

