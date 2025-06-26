# 🤖 Multi-Claude System

グローバルで動作するマルチエージェント Claude Code システム

> **📍 プロジェクトについて**  
> このプロジェクトは [Akira-Papa/Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication) からフォークし、大幅な機能拡張を行ったものです。元の tmux-based multi-agent demo を基に、グローバルインストール機能、動的指示書システム、エラーハンドリング改善等を追加しています。

## 🎯 プロジェクト概要

### アーキテクチャ

複数の Claude Code インスタンスが協調動作する分散処理システム

```
PRESIDENT (統括) → BOSS (管理) → Architect/QA/WORKERs (実行)
```

### 主要機能

- **🌐 グローバルインストール**: どこからでも`multi-claude`コマンドで起動
- **🎯 動的指示書システム**: タスクに応じて自動的に指示書を生成
- **🔄 エージェント間通信**: tmux を利用した高速メッセージング
- **📦 Homebrew 対応**: `brew install`でワンステップインストール
- **🔍 堅牢な役割判定システム**: 多層防御による確実な役割認識（v1.3.0〜）
- **🚀 完全自動起動**: Claude Codeの自動起動と初期メッセージ送信（v1.4.0〜）

## 🚀 インストール方法

### 方法 1: Homebrew 経由←（尾原の手元では考慮していないです）

```bash
# リポジトリ追加
brew tap sutaminajing40/multi-claude

# インストール
brew install multi-claude

# 使用開始
multi-claude
```

### 方法 2: 手動インストール（dog fooding 段階ではこちらが推奨）

```bash
# リポジトリクローン
git clone https://github.com/sutaminajing40/multi-claude.git
cd multi-claude

# グローバルインストール
./install.sh

# 使用開始
multi-claude
```

## 💻 基本的な使い方

### 1. システム起動

```bash
# 任意のディレクトリで実行可能
# 事前に claude コマンドを実行してログインしておくと各種エージェントの立ち上がりがスムーズになります
multi-claude
```

起動時に自動的に：
- 7つのClaude Codeインスタンスが起動
- 各エージェントに役割が割り当てられる
- 初期メッセージが自動送信される
- 全エージェントが準備完了状態になる

### 2. PRESIDENT へタスク依頼

PRESIDENT ウィンドウで直接タスクを入力：

```
「Pythonでファイル一覧を取得するスクリプトを3つのファイルに分けて作って」
「ウェブサイトのスクレイピングを並行処理で実行して」
「データベースから情報を取得してCSV出力して」
```

### 3. 自動実行

PRESIDENT が自動的に：

1. タスクを分析
2. BOSS 用の指示書を生成
3. 各エージェントに指示を送信
4. 実行結果を収集・報告

## 👥 エージェント構成

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト統括責任者

📊 multiagent セッション (6ペイン)
├── boss1: チームリーダー（要件整理・指示書生成）
├── worker1: 実装担当（コア機能）
├── architect: 設計・アーキテクチャ担当
├── worker2: 実装担当（サブ機能）
├── qa: 品質保証・テスト担当
└── worker3: 実装担当（統合・デバッグ）
```

### 開発フロー

```
ユーザー 
  ↓
PRESIDENT（タスク概要理解）
  ↓
boss1（要件整理・指示書生成）
  ↓
第1段階（設計・テスト準備）：
  - architect: Design Doc作成
  - qa: テストシナリオ作成
  ↓
第2段階（実装・品質保証）：
  - worker1: コア機能実装
  - worker2: サブ機能実装
  - worker3: 統合・デバッグ
  - qa: テスト実行・品質保証
  ↓
boss1（進捗管理・完了確認）
  ↓
PRESIDENT（ユーザーへ報告）
```

## 🛠️ 高度な使い方

### エージェント間メッセージ送信

```bash
# プロジェクトルートから実行
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh [エージェント名] "[メッセージ]"

# 例
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh boss1 "緊急タスクです"
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh worker1 "作業完了しました"
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh architect "設計レビューお願いします"
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh qa "テスト実施してください"

# 利用可能なエージェント一覧
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh --list
```

### システム管理コマンド

```bash
# システム終了
multi-claude --exit

# ヘルプ表示
multi-claude --help

# バージョン確認
multi-claude --version

# 権限確認をスキップして起動（開発用）
multi-claude --dangerously-skip-permissions

# ターミナル設定をリセット
multi-claude --reset-terminal

# PRESIDENTに直接指示を送信
multi-claude "Pythonでファイル処理スクリプトを作成して"
```

### 自動起動機能

```bash
# エージェントの状態確認
$MULTI_CLAUDE_LOCAL/bin/agent-status.sh list

# 特定エージェントの状態確認
$MULTI_CLAUDE_LOCAL/bin/agent-status.sh check worker1

# システム健全性チェック
$MULTI_CLAUDE_LOCAL/bin/health-check.sh

# エラーハンドリングとリカバリ
$MULTI_CLAUDE_LOCAL/bin/error-handler.sh recover
```

## うまく動かないな？と思ったら

multi-claude を起動した path （$MULTI_CLAUDE_LOCAL) の instructions 配下で、各種エージェントに対して送信した指示書が入っています。  
ここの内容をアップデートしてから、再起動をするといい感じになります。
```sh
multi-claude --exit
multi-claude
```

## 🔄 CI/CD システム

### 自動リリースパイプライン

```
git tag → GitHub Actions → Homebrew Formula更新
```

### リリース方法

```bash
# バージョンタグを付けてプッシュ
git tag v1.0.8 -m "新機能追加"
git push origin v1.0.8

# 15-18秒後にHomebrewで利用可能
```

### GitHub Actions 設定

- **update-homebrew.yml**: タグプッシュで自動実行
- **update-homebrew-manual.yml**: 手動で Formula 更新

詳細は[CLAUDE.md](CLAUDE.md)の CI/CD セクションを参照してください。

## 📜 指示書システム

### 動的指示書

- `instructions/boss_task.md`: BOSS 用タスク指示
- `instructions/worker_task.md`: WORKER 用実行指示

### 役割別指示書

- `instructions/president_dynamic.md`: PRESIDENT 役割定義
- `instructions/boss_dynamic.md`: BOSS 役割定義
- `instructions/worker_dynamic.md`: WORKER 役割定義
- `instructions/architect_dynamic.md`: ARCHITECT 役割定義
- `instructions/qa_dynamic.md`: QA 役割定義

## 🧪 デバッグ・ログ

### ログ確認

```bash
# 送信ログ
tail -f $MULTI_CLAUDE_LOCAL/session/logs/send_log.txt

# 特定エージェントのログ
grep "boss1" $MULTI_CLAUDE_LOCAL/session/logs/send_log.txt

# エージェント起動ログ
cat $MULTI_CLAUDE_LOCAL/session/logs/launch-agent.log

# エージェント進捗確認
ls -la $MULTI_CLAUDE_LOCAL/context/*_progress.md

# 現在のタスク確認
cat $MULTI_CLAUDE_LOCAL/tasks/current_task.md
```

### セッション確認

```bash
# tmuxセッション一覧
tmux list-sessions

# ペイン構成確認
tmux list-panes -t multiagent
```

## 🤝 コントリビューション

### 開発フロー

1. feature/\* ブランチで開発
2. ローカルテスト実施
3. Pull Request 作成
4. main ブランチへマージ
5. タグ付けで自動リリース

### イシュー・PR

- バグ報告・機能要望は[Issues](https://github.com/sutaminajing40/multi-claude/issues)へ
- PR は大歓迎です！

## 📜 クレジット・ライセンス

### 🍴 フォークチェーン

- **オリジナル**: [nishimoto265/Claude-Code-Communication](https://github.com/nishimoto265/Claude-Code-Communication)
- **直接のフォーク元**: [Akira-Papa/Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication)
- **現在のリポジトリ**: sutaminajing40/multi-claude

### ✨ 主な拡張機能

- 🌐 グローバルインストールシステム
- 🎯 動的指示書生成機能
- 🔧 エラーフリーな AppleScript 実装
- 📦 Homebrew Formula 対応
- 🚀 CI/CD 自動化システム
- 🤖 完全自動起動機能（Claude Code自動起動・初期メッセージ送信）
- 🏗️ アーキテクト・QAエージェント追加（6エージェント体制）
- 📊 高度な状態管理システム（JSON形式での状態追跡）
- 🔄 エラーハンドリングとリカバリー機能

### 📄 ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照

---

🚀 **Multi-Claude で分散 AI エージェントシステムを体感してください！** 🤖✨
