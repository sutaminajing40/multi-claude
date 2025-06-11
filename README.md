# 🤖 Multi-Claude System

グローバルで動作するマルチエージェント Claude Code システム

> **📍 プロジェクトについて**  
> このプロジェクトは [Akira-Papa/Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication) からフォークし、大幅な機能拡張を行ったものです。元のtmux-based multi-agent demoを基に、グローバルインストール機能、動的指示書システム、エラーハンドリング改善等を追加しています。

## 🎯 デモ概要

PRESIDENT → BOSS → Workers の階層型指示システムを体感できます

### 👥 エージェント構成

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト統括責任者

📊 multiagent セッション (4ペイン)  
├── boss1: チームリーダー
├── worker1: 実行担当者A
├── worker2: 実行担当者B
└── worker3: 実行担当者C
```

## 🚀 クイックスタート

### 🌐 グローバルインストール（最推奨）

```bash
# 1. リポジトリクローン
git clone https://github.com/sutaminajing40/Claude-Code-Communication.git
cd Claude-Code-Communication

# 2. グローバルインストール
./install.sh

# 3. 任意のディレクトリで使用
cd ~/your-project/
multi-claude
```

これで**どこからでも**`multi-claude`コマンドが使えます！

### 🎯 ローカル起動（このディレクトリ内のみ）

```bash
# ワンコマンドで完全なマルチエージェント環境を起動
./multi-claude
```

これだけで2つのウィンドウが開いて、PRESIDENTとの対話が開始できます！

### 📖 従来の手動セットアップ

### 0. リポジトリのクローン

```bash
git clone https://github.com/nishimoto265/Claude-Code-Communication.git
cd Claude-Code-Communication
```

### 1. tmux環境構築

⚠️ **注意**: 既存の `multiagent` と `president` セッションがある場合は自動的に削除されます。

```bash
./setup.sh
```

### 2. セッションアタッチ

```bash
# マルチエージェント確認
tmux attach-session -t multiagent

# プレジデント確認（別ターミナルで）
tmux attach-session -t president
```

### 3. Claude Code起動

**手順1: President認証**
```bash
# まずPRESIDENTで認証を実施
tmux send-keys -t president 'claude' C-m
```
認証プロンプトに従って許可を与えてください。

**手順2: Multiagent一括起動**
```bash
# 認証完了後、multiagentセッションを一括起動
for i in {0..3}; do tmux send-keys -t multiagent:0.$i 'claude' C-m; done
```

### 4. デモ実行

PRESIDENTセッションで直接入力：
```
あなたはpresidentです。指示書に従って
```

## 🎯 動的指示書システム（新機能）

### 使用方法
PRESIDENTに直接タスクを依頼するだけ：
```
「Pythonでファイル一覧を取得するスクリプトを3つのファイルに分けて作って」
「ウェブサイトのスクレイピングを並行処理で実行して」
「データベースから情報を取得してCSV出力して」
```

### フロー
```
ユーザー → PRESIDENT（指示書生成） → BOSS（指示書読み込み） → WORKERs（指示書実行）
```

PRESIDENTが自動的に：
- タスクを分析
- BOSSとWORKER用の指示書を動的生成  
- 指示書をファイルに保存
- BOSSに実行指示を送信

## 📜 指示書について

各エージェントの役割別指示書：
- **PRESIDENT**: `instructions/president.md`
- **boss1**: `instructions/boss.md` 
- **worker1,2,3**: `instructions/worker.md`

**Claude Code参照**: `CLAUDE.md` でシステム構造を確認

**要点:**
- **PRESIDENT**: 「あなたはpresidentです。指示書に従って」→ boss1に指示送信
- **boss1**: PRESIDENT指示受信 → workers全員に指示 → 完了報告
- **workers**: Hello World実行 → 完了ファイル作成 → 最後の人が報告

## 🎬 期待される動作フロー

```
1. PRESIDENT → boss1: "あなたはboss1です。Hello World プロジェクト開始指示"
2. boss1 → workers: "あなたはworker[1-3]です。Hello World 作業開始"  
3. workers → ./tmp/ファイル作成 → 最後のworker → boss1: "全員作業完了しました"
4. boss1 → PRESIDENT: "全員完了しました"
```

## 🔧 手動操作

### agent-send.shを使った送信

```bash
# 基本送信
./agent-send.sh [エージェント名] [メッセージ]

# 例
./agent-send.sh boss1 "緊急タスクです"
./agent-send.sh worker1 "作業完了しました"
./agent-send.sh president "最終報告です"

# エージェント一覧確認
./agent-send.sh --list
```

## 🧪 確認・デバッグ

### ログ確認

```bash
# 送信ログ確認
cat logs/send_log.txt

# 特定エージェントのログ
grep "boss1" logs/send_log.txt

# 完了ファイル確認
ls -la ./tmp/worker*_done.txt
```

### セッション状態確認

```bash
# セッション一覧
tmux list-sessions

# ペイン一覧
tmux list-panes -t multiagent
tmux list-panes -t president
```

## 🔄 環境リセット

```bash
# セッション削除
tmux kill-session -t multiagent
tmux kill-session -t president

# 完了ファイル削除
rm -f ./tmp/worker*_done.txt

# 再構築（自動クリア付き）
./setup.sh
```

## 📜 クレジット・ライセンス

### 🍴 フォーク元
このプロジェクトは以下のフォークチェーンで作成されています：
- **オリジナル**: [nishimoto265/Claude-Code-Communication](https://github.com/nishimoto265/Claude-Code-Communication)
- **直接のフォーク元**: [Akira-Papa/Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication)
- **現在のリポジトリ**: sutaminajing40/Claude-Code-Communication

### ✨ 主な拡張機能
- **🌐 グローバルインストールシステム** (`install.sh`)
- **🎯 動的指示書生成** (president_dynamic.md, boss_dynamic.md, worker_dynamic.md)
- **🔧 エラーフリーなAppleScript実装**
- **📦 複数Claude Codeインストール方法対応**
- **🚀 ワンコマンド環境構築** (`multi-claude`)

### 🤝 オープンソースへの貢献
- 元プロジェクトのコンセプトを尊重し、大幅な機能拡張を実施
- コミュニティでの利用促進を目的としたHomebrew公開準備
- フォーク元への貢献も歓迎します

---

🚀 **Agent Communication を体感してください！** 🤖✨ 