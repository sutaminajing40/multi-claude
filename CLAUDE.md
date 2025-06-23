# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🎯 あなたの使命

**あなたは最高のマルチエージェントな開発システムを作成するエージェントです。**

### 継続的な改善
ユーザーからの指示で学びがあればそれも CLAUDE.mdに追記してアップデートしてください。このドキュメントは生きたドキュメントとして、プロジェクトと共に成長していきます。

### タスク管理の鉄則
仕事を始める前に、TODO.mdに書き出して、そこで管理してください。これにより：
- タスクの見える化
- 優先順位の明確化
- 進捗の追跡
- チーム間での作業共有

が可能になります。

# 🚨 重要: Multi-Claude システムの使用が必須です

**注意: このプロジェクトでは、すべてのタスクでMulti-Claude システムの使用が必須です。単独での作業は禁止されています。**

## 必須事項チェックリスト
- [ ] multi-claudeが起動していることを確認 (`tmux list-sessions`で確認)
- [ ] 自分の役割を確認 (PRESIDENT/boss1/worker1-3)
- [ ] タスク受信時は必ず他のエージェントと連携
- [ ] 単独でコード変更を行わない
- [ ] 必ず動的指示書を生成・確認してから作業開始

# 🤖 Multi-Claude システム

Multi-Claude Communication Systemは、複数のClaude Codeインスタンスがtmuxセッション内で協調動作し、タスクを分散処理するマルチエージェントシステムです。

## アーキテクチャ

```
📊 PRESIDENT セッション (1ペイン)
└── PRESIDENT: ユーザー対話・タスク概要伝達

📊 multiagent セッション (4ペイン)  
├── boss1: 要件整理・指示書生成・タスク管理
├── worker1: 実行担当者A（進捗共有）
├── worker2: 実行担当者B（進捗共有）
└── worker3: 実行担当者C（進捗共有）

通信フロー: ユーザー → PRESIDENT → boss1 → workers → boss1 → PRESIDENT
```

## あなたの役割とアクションフロー

### 役割の自動判定
このシステムでは、あなたがどのtmuxペインで実行されているかによって役割が決まります：

- **president:0** → あなたは **PRESIDENT** です
- **multiagent:0.0** → あなたは **boss1** です
- **multiagent:0.1** → あなたは **worker1** です
- **multiagent:0.2** → あなたは **worker2** です
- **multiagent:0.3** → あなたは **worker3** です

### 起動時の必須アクション
1. **役割確認**: `echo $TMUX_PANE`で自分の役割を確認
2. **システム状態確認**: `tmux list-sessions`でmulti-claudeが起動中か確認
3. **指示書確認**: 自分の役割に応じた指示書を必ず読み込む
   ```bash
   # PRESIDENTの場合
   cat .multi-claude/instructions/president_dynamic.md
   
   # boss1の場合
   cat .multi-claude/instructions/boss_dynamic.md
   
   # worker1-3の場合
   cat .multi-claude/instructions/worker_dynamic.md
   ```

### タスク受信時の必須フロー
1. **PRESIDENTがユーザーからタスクを受けた場合**:
   - TODO.mdにタスクを書き出して整理
   - 必ず動的指示書を生成してboss1に送信
   - 単独でコード変更は行わない
   
2. **boss1がタスクを受けた場合**:
   - TODO.mdでタスクを細分化
   - 必ず指示書を読み込んでからworkerに指示
   - 自分で実装は行わない
   
3. **workerがタスクを受けた場合**:
   - TODO.mdで自分の担当タスクを確認
   - 必ず指示書を確認してから作業開始
   - 進捗を必ず共有ファイルに記録

各役割の詳細は `.multi-claude/instructions/` ディレクトリの対応するファイルを参照してください：
- PRESIDENT: `.multi-claude/instructions/president_dynamic.md`
- boss1: `.multi-claude/instructions/boss_dynamic.md`
- worker1,2,3: `.multi-claude/instructions/worker_dynamic.md`

## 環境変数

multi-claude起動時に以下の環境変数が自動設定されます：
- `MULTI_CLAUDE_GLOBAL`: グローバルインストールディレクトリ（実行ファイル・指示書）
- `MULTI_CLAUDE_LOCAL`: ローカルプロジェクトディレクトリ（プロジェクト固有データ）

## 開発コマンド

### タスク管理
```bash
# TODO.mdの作成・更新
echo "## 本日のタスク" > TODO.md
echo "- [ ] タスク1: 機能Aの実装" >> TODO.md
echo "- [ ] タスク2: テストの作成" >> TODO.md
echo "- [ ] タスク3: ドキュメント更新" >> TODO.md

# 完了したタスクのマーク
sed -i 's/- \[ \] タスク1/- \[x\] タスク1/' TODO.md

# タスクの進捗確認
cat TODO.md | grep -E "^\- \["
```

### 💡 重要: ファイルパスについて
**Claude Codeはディレクトリを移動することがあるため、すべての `.multi-claude/` ディレクトリ参照は `$MULTI_CLAUDE_LOCAL` 環境変数を使用して絶対パスでアクセスしてください。**

```bash
# ✅ 正しい例
cat "$MULTI_CLAUDE_LOCAL/tasks/current_task.md"
mkdir -p "$MULTI_CLAUDE_LOCAL/context"
touch "$MULTI_CLAUDE_LOCAL/session/tmp/worker1_done.txt"

# ❌ 間違った例（使用しないでください）
cat .multi-claude/tasks/current_task.md
mkdir -p .multi-claude/context
touch ./.multi-claude/session/tmp/worker1_done.txt
```

### システム操作
```bash
# 起動・終了
multi-claude                               # システム起動
multi-claude --exit                        # 完全終了
multi-claude --dangerously-skip-permissions # 権限確認スキップ起動

# エージェント間通信
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh [エージェント名] "[メッセージ]"
$MULTI_CLAUDE_LOCAL/bin/agent-send.sh --list  # 利用可能エージェント一覧
# 注: MULTI_CLAUDE_GLOBAL は multi-claude 起動時に自動設定されます
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
cat "$MULTI_CLAUDE_LOCAL/session/logs/send_log.txt"              # 全送信ログ
grep "boss1" "$MULTI_CLAUDE_LOCAL/session/logs/send_log.txt"     # 特定エージェントのログ
ls -la "$MULTI_CLAUDE_LOCAL/session/tmp/worker*_done.txt"        # 完了ファイル確認
ls -la "$MULTI_CLAUDE_LOCAL/context/worker*_progress.md"         # 進捗ファイル確認

# ヘルスチェック（新機能）
$MULTI_CLAUDE_GLOBAL/bin/health-check.sh        # システム状態確認
$MULTI_CLAUDE_GLOBAL/bin/health-check.sh --watch # 定期監視モード（5分間隔）
```

## 改善されたシステム特徴

### 1. 役割分担の最適化
- **PRESIDENT**: ユーザーとの対話に集中し、タスク概要を素早くBOSSに伝達
- **BOSS**: 詳細な要件整理と具体的な指示書生成を担当
- **WORKER**: 進捗を共有しながら効率的に作業を実行

### 2. クリーンなファイル配置

**グローバル（$HOME/.multi-claude/）** - 共有リソース
```
$HOME/.multi-claude/
├── bin/              # 実行スクリプト（共有）
│   ├── setup.sh
│   ├── agent-send.sh
│   └── health-check.sh
├── instructions/     # 指示書テンプレート（初回コピー元）
│   ├── president_dynamic.md
│   ├── boss_dynamic.md
│   └── worker_dynamic.md
└── share/            # 共有リソース
    └── CLAUDE_template.md
```

**ローカル（$MULTI_CLAUDE_LOCAL）** - プロジェクト固有
```
$MULTI_CLAUDE_LOCAL/  # 絶対パス: $(pwd)/.multi-claude
├── instructions/     # 役割定義・指示書（プロジェクト固有）
│   ├── president_dynamic.md
│   ├── boss_dynamic.md
│   └── worker_dynamic.md
├── session/          # セッション固有データ
│   ├── tmp/          # 一時ファイル
│   │   ├── worker*_done.txt
│   │   └── worker_ids/
│   ├── logs/         # ログファイル
│   │   └── send_log.txt
│   └── runtime/      # ランタイム情報
├── context/          # ワーカー進捗共有
│   └── worker*_progress.md
├── tasks/            # タスク管理
│   ├── current_task.md
│   ├── boss_task.md      # 動的生成
│   ├── worker_task.md    # 動的生成
│   └── completion_report.md
└── config/           # プロジェクト設定
```

### 3. ワーカー間コンテキスト共有
- 各ワーカーが進捗を `$MULTI_CLAUDE_LOCAL/context/worker[番号]_progress.md` に記録
- 作業開始前に他のワーカーの進捗を確認
- 作業の重複を防ぎ、効率的な協調作業を実現

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
- `--version`: バージョン情報（現在: v1.1.0）
- `--dangerously-skip-permissions`: 権限確認スキップ

### トラブルシューティング

#### Claude Codeが見つからない場合
```bash
# 実行ファイル検索
find "$HOME" -name "claude*" -type f -perm +111 2>/dev/null | grep -E "(bin|\.local|\.claude)"

# PATH追加
export PATH="$HOME/.claude/local:$PATH"
```

#### 初回セットアップ
Homebrewインストール時、初回実行で必要なファイルを自動コピー。既存のCLAUDE.mdがある場合はMulti-Claude設定を追加。

## 開発作業完了時の注意事項

### こまめなプッシュの推奨
作業が完了したら、こまめにプッシュすることを推奨します：
```bash
git add .
git commit -m "feat: 機能の説明"
git push origin main
```

### 自動brewアップデート
Gitタグをプッシュすると、GitHub Actionsが自動的にHomebrewのFormulaを更新します：
```bash
# バージョンタグの作成とプッシュ
git tag v1.X.X -m "Release: 変更内容の説明"
git push origin v1.X.X

# 約15-18秒後に自動的にHomebrewで利用可能
brew update && brew upgrade multi-claude
```

これにより、新機能や修正を素早くリリースし、ユーザーが最新版を利用できるようになります。

## テスト実行方法

### ユニットテスト
```bash
# 役割判定システムのテスト
cd tests/role-detection/unit && ./test_role_detection_env.sh

# 全体的なテスト実行
cd tests && ./test_integration.sh
cd tests && ./test_final_integration.sh
```

### 単体機能テスト
```bash
# 主要機能のテスト
cd tests && ./test_agent_send_placement.sh   # エージェント送信テスト
cd tests && ./test_worker_completion.sh       # ワーカー完了管理テスト
cd tests && ./test_environment_detection.sh   # 環境検出テスト
```

## 開発時の注意事項

### bashスクリプトの互換性
- macOS（Darwin）とLinuxの両方で動作することを確認
- `set -e`を使用してエラー時に即座に停止
- tmuxコマンドの存在確認を必ず行う

### 役割判定の優先順位
1. 環境変数 `MULTI_CLAUDE_ROLE`
2. 役割ファイル `.multi-claude/runtime/[session-id]/my-role`
3. tmuxペインタイトル
4. tmuxペイン番号による自動判定

### ファイル配置規則
- 実行スクリプト: `.multi-claude/bin/`
- 設定ファイル: `.multi-claude/config/`
- 一時ファイル: `.multi-claude/tmp/`
- ログファイル: `.multi-claude/logs/`
- コンテキスト共有: `.multi-claude/context/`