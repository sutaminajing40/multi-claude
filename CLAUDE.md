# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 🤖 Multi-Claude システム

Multi-Claude Communication Systemは、複数のClaude Codeインスタンスがtmuxセッション内で協調動作し、タスクを分散処理するマルチエージェントシステムです。

## アーキテクチャ

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: プロジェクト統括・指示書生成

📊 multiagent セッション (4ペイン)  
├── boss1: チームリーダー・タスク管理
├── worker1: 実行担当者A
├── worker2: 実行担当者B
└── worker3: 実行担当者C

通信フロー: ユーザー → PRESIDENT → boss1 → workers → boss1 → PRESIDENT
```

## あなたの役割

このシステムでは、あなたがどのtmuxペインで実行されているかによって役割が決まります：

- **president:0** → あなたは **PRESIDENT** です
- **multiagent:0.0** → あなたは **boss1** です
- **multiagent:0.1** → あなたは **worker1** です
- **multiagent:0.2** → あなたは **worker2** です
- **multiagent:0.3** → あなたは **worker3** です

各役割の詳細は `instructions/` ディレクトリの対応するファイルを参照してください。

## 開発コマンド

### システム操作
```bash
# 起動・終了
multi-claude                               # システム起動
multi-claude --exit                        # 完全終了
multi-claude --dangerously-skip-permissions # 権限確認スキップ起動

# エージェント間通信
./agent-send.sh [エージェント名] "[メッセージ]"
./agent-send.sh --list                     # 利用可能エージェント一覧
```

### テスト実行
```bash
cd tests && ./test_claude_detection.sh              # Claude検出テスト
cd tests && ./test_dangerously_skip_permissions.sh  # オプションテスト
cd tests && ./test_terminal_control.sh              # ターミナル制御テスト
```

### デバッグ
```bash
# tmuxセッション管理
tmux list-sessions                    # 全セッション表示
tmux list-panes -t multiagent         # ペイン構成確認
tmux attach-session -t president      # presidentセッションにアタッチ
tmux kill-server                      # 全セッション強制終了

# ログ確認
cat logs/send_log.txt                 # 全送信ログ
grep "boss1" logs/send_log.txt        # 特定エージェントのログ
ls -la ./tmp/worker*_done.txt         # 完了ファイル確認
```

## リリースワークフロー

### 自動リリース（推奨）
```bash
git tag v1.0.X -m "Release: 変更内容"
git push origin v1.0.X

# 15-18秒後に自動的にHomebrewで利用可能
brew update && brew upgrade multi-claude
```

### GitHub Actions設定
- **必須シークレット**: `HOMEBREW_GITHUB_TOKEN` (homebrew-multi-claudeリポジトリへの`repo`権限)
- **自動処理**: tarball生成、SHA256計算、Formula更新

## 技術仕様

### Claude Code検出優先順位
1. `$HOME/.claude/local/claude` (直接パス)
2. `which claude` (PATH検索)
3. `command -v claude` (bashビルトイン)
4. `claude-code`, `claude.code` (バリエーション)

### コマンドラインオプション
- `--exit`: システム完全終了
- `--help`: ヘルプ表示
- `--version`: バージョン情報（現在: v1.0.16）
- `--dangerously-skip-permissions`: 権限確認スキップ

### ファイル構成
```
./
├── multi-claude          # メインコマンド
├── setup.sh              # tmux環境構築
├── agent-send.sh         # エージェント間通信
├── instructions/         # 役割定義・タスク指示
│   ├── president_dynamic.md
│   ├── boss_dynamic.md
│   ├── worker_dynamic.md
│   ├── boss_task.md      # 動的生成
│   └── worker_task.md    # 動的生成
├── logs/send_log.txt     # 通信ログ
└── tmp/                  # 一時ファイル
```

### 動的指示書システム
PRESIDENTがユーザー要求を解析し、`boss_task.md`と`worker_task.md`を動的生成。各エージェントは役割定義ファイル（`*_dynamic.md`）に従って動作します。

## トラブルシューティング

### Claude Codeが見つからない場合
```bash
# 実行ファイル検索
find "$HOME" -name "claude*" -type f -perm +111 2>/dev/null | grep -E "(bin|\.local|\.claude)"

# PATH追加
export PATH="$HOME/.claude/local:$PATH"
```

### 初回セットアップ
Homebrewインストール時、初回実行で必要なファイルを自動コピー。既存のCLAUDE.mdがある場合はMulti-Claude設定を追加。