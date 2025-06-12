# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 🤖 Multi-Claude システム設定

## 🎯 動的タスク指示（2025-01-12_15:30:00）
### 今回のタスク
multi-claudeコマンドに--dangerously-skip-permissionsオプションを追加実装

### 指示書ファイル
- BOSS用: @instructions/boss_task.md
- WORKER用: @instructions/worker_task.md

### タスク管理
- ステータス: 実行中
- 優先度: 高

## 開発環境セットアップ

### 初回インストール
```bash
# Homebrewでインストール（推奨）
brew tap sutaminajing40/multi-claude
brew install multi-claude

# または手動インストール
./install.sh
```

### 開発用コマンド

```bash
# システム起動
multi-claude

# システム終了
multi-claude --exit

# エージェント間通信
./agent-send.sh [エージェント名] "[メッセージ]"
./agent-send.sh --list  # 利用可能エージェント一覧

# テスト実行
cd tests && ./test_claude_detection.sh
```

## アーキテクチャ

### Multi-Agent System構成

本システムは、複数のClaude Codeインスタンスがtmuxセッション内で協調動作する分散処理システムです。

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト統括・指示書生成

📊 multiagent セッション (4ペイン)  
├── boss1: チームリーダー・タスク管理
├── worker1: 実行担当者A
├── worker2: 実行担当者B
└── worker3: 実行担当者C
```

### 動的指示書システム

PRESIDENTがユーザー要求を解析し、以下の指示書を自動生成：
- `instructions/boss_task.md`: BOSSのタスク管理指示
- `instructions/worker_task.md`: WORKER共通の実行指示

各エージェントの役割定義：
- `instructions/president_dynamic.md`: PRESIDENT役割
- `instructions/boss_dynamic.md`: BOSS役割  
- `instructions/worker_dynamic.md`: WORKER役割

### 通信フロー

1. ユーザー → PRESIDENT: タスク依頼
2. PRESIDENT: 指示書生成 → boss1に通知
3. boss1: 指示書読み込み → 各workerに実行指示
4. workers: タスク実行 → 完了報告
5. boss1 → PRESIDENT: 全体完了報告

## リリース手順

### 自動リリース（推奨）
```bash
# バージョンタグを作成してプッシュ
git tag v1.0.X -m "Release message"
git push origin v1.0.X

# 15-18秒後に自動的にHomebrewで利用可能
```

#### GitHub Actions ワークフロー

##### 1. update-homebrew.yml (自動実行)
- **トリガー**: タグプッシュ (v*)
- **処理**:
  1. tarball URL生成
  2. SHA256計算
  3. homebrew-multi-claude リポジトリへ自動更新
  4. 約15-18秒で完了

##### 2. update-homebrew-manual.yml (手動実行)
- **用途**: 特定バージョンの再配布
- **実行**: GitHub Actions画面から手動トリガー

### GitHub Actions設定

**必要なシークレット:**
- `HOMEBREW_GITHUB_TOKEN`: homebrew-multi-claudeリポジトリへのアクセストークン（`repo`権限）

## 重要な技術的詳細

### Claude Code検出メカニズム

`multi-claude`スクリプトは以下の優先順位でClaude Codeを検出：
1. `$HOME/.claude/local/claude`
2. `which claude`
3. バリエーション検索（claude-code、claude.code等）

### tmuxセッション管理

- **multiagent**: 4ペインレイアウト（boss1, worker1-3）
- **president**: 単独ペイン
- 各ペインでカラープロンプト設定（視覚的識別）
- AppleScriptでターミナルウィンドウ自動配置

### ログ・デバッグ

```bash
# 送信ログ確認
cat logs/send_log.txt

# tmuxセッション確認
tmux list-sessions
tmux list-panes -t multiagent

# 完了ファイル確認
ls -la ./tmp/worker*_done.txt
```
