# 🤖 Multi-Claude System

グローバルで動作するマルチエージェント Claude Code システム

> **📍 プロジェクトについて**  
> このプロジェクトは [Akira-Papa/Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication) からフォークし、大幅な機能拡張を行ったものです。元の tmux-based multi-agent demo を基に、グローバルインストール機能、動的指示書システム、エラーハンドリング改善等を追加しています。

## 🎯 プロジェクト概要

### アーキテクチャ

複数の Claude Code インスタンスが協調動作する分散処理システム

```
PRESIDENT (統括) → BOSS (管理) → WORKERs (実行)
```

### 主要機能

- **🌐 グローバルインストール**: どこからでも`multi-claude`コマンドで起動
- **🎯 動的指示書システム**: タスクに応じて自動的に指示書を生成
- **🔄 エージェント間通信**: tmux を利用した高速メッセージング
- **📦 Homebrew 対応**: `brew install`でワンステップインストール（準備中）

## 🚀 インストール方法

### 方法 1: Homebrew 経由（推奨）

```bash
# リポジトリ追加
brew tap sutaminajing40/multi-claude

# インストール
brew install multi-claude

# 使用開始
multi-claude
```

### 方法 2: 手動インストール

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
multi-claude
```

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
2. BOSS と WORKER 用の指示書を生成
3. 各エージェントに指示を送信
4. 実行結果を収集・報告

## 👥 エージェント構成

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト統括責任者

📊 multiagent セッション (4ペイン)
├── boss1: チームリーダー
├── worker1: 実行担当者A
├── worker2: 実行担当者B
└── worker3: 実行担当者C
```

## 🛠️ 高度な使い方

### エージェント間メッセージ送信

```bash
./agent-send.sh [エージェント名] "[メッセージ]"

# 例
./agent-send.sh boss1 "緊急タスクです"
./agent-send.sh worker1 "作業完了しました"
```

### システム管理コマンド

```bash
# システム終了
multi-claude --exit

# ヘルプ表示
multi-claude --help

# バージョン確認
multi-claude --version
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

## 🧪 デバッグ・ログ

### ログ確認

```bash
# 送信ログ
cat logs/send_log.txt

# 特定エージェントのログ
grep "boss1" logs/send_log.txt

# 完了ファイル確認
ls -la ./tmp/worker*_done.txt
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

### 📄 ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照

---

🚀 **Multi-Claude で分散 AI エージェントシステムを体感してください！** 🤖✨
