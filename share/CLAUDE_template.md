# 🤖 Multi-Claude システム設定

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
# プロジェクトルートから実行（後方互換性のため両方対応）
./agent-send.sh [相手] "[メッセージ]"
# または
./.multi-claude/bin/agent-send.sh [相手] "[メッセージ]"
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