#!/bin/bash

# 🚀 Multi-Claude システム グローバルインストール

set -e

# Claude Codeのパス検出
CLAUDE_PATH=""
# 一般的なClaude Codeインストールパス
COMMON_CLAUDE_PATHS=(
    "$HOME/.claude/local/claude"
    "/usr/local/bin/claude"
    "/opt/homebrew/bin/claude"
)

for path in "${COMMON_CLAUDE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        CLAUDE_PATH="$path"
        break
    fi
done

# パスが見つからなければ、コマンドとして確認
if [ -z "$CLAUDE_PATH" ] && command -v claude &> /dev/null; then
    CLAUDE_PATH="claude"
fi

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

echo "🤖 Multi-Claude システム グローバルインストール"
echo "============================================="
echo ""

# インストール先ディレクトリ
INSTALL_DIR="$HOME/.multi-claude"
BIN_DIR="$HOME/bin"

# STEP 1: 環境チェック
log_info "🔍 環境チェック中..."

# tmuxの存在確認
if ! command -v tmux &> /dev/null; then
    log_error "tmuxがインストールされていません"
    echo "インストール: brew install tmux"
    exit 1
fi

# claudeの存在確認
if [ -z "$CLAUDE_PATH" ]; then
    log_error "claude commandが見つかりません"
    echo "Claude Codeがインストールされていることを確認してください"
    echo "一般的なパス: ~/.claude/local/claude"
    exit 1
fi

log_info "Claude Code検出: $CLAUDE_PATH"

log_success "✅ 環境チェック完了"

# STEP 2: インストールディレクトリ作成
log_info "📁 インストールディレクトリ作成中..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/instructions"

log_success "✅ ディレクトリ作成完了: $INSTALL_DIR"

# STEP 3: ファイルコピー
log_info "📋 ファイルコピー中..."

# テンプレートファイルをコピー
cp setup.sh "$INSTALL_DIR/"
cp agent-send.sh "$INSTALL_DIR/"
cp instructions/*_dynamic.md "$INSTALL_DIR/instructions/"

# CLAUDE.mdテンプレート作成
cat > "$INSTALL_DIR/CLAUDE_template.md" << 'EOF'
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
EOF

log_success "✅ ファイルコピー完了"

# STEP 4: グローバルコマンド作成
log_info "🌐 グローバルコマンド作成中..."

cat > "$INSTALL_DIR/multi-claude-global" << 'EOF'
#!/bin/bash

# 🚀 Multi-Claude システム グローバルコマンド（起動・終了）

set -e

# 使用方法表示
show_usage() {
    cat << 'EOFUSAGE'
🤖 Multi-Claude システム

使用方法:
  multi-claude         - システム起動
  multi-claude --exit  - システム完全終了
  multi-claude --help  - このヘルプを表示

機能:
  起動: tmux環境構築 + ターミナルウィンドウ起動 + Claude Code起動
  終了: 全tmuxセッション停止 + ターミナル閉鎖 + 一時ファイル削除
EOFUSAGE
}

# システム終了機能
exit_system() {
    echo "🛑 Multi-Claude システム終了中..."
    echo "================================="
    
    # STEP 1: tmuxセッション終了
    log_info "🔌 tmuxセッション終了中..."
    
    if tmux has-session -t multiagent 2>/dev/null; then
        tmux kill-session -t multiagent
        log_info "multiagentセッション終了"
    fi
    
    if tmux has-session -t president 2>/dev/null; then
        tmux kill-session -t president  
        log_info "presidentセッション終了"
    fi
    
    # 他のmulti-claude関連セッションも終了
    tmux list-sessions 2>/dev/null | grep -E "(multiagent|president)" | cut -d: -f1 | xargs -I {} tmux kill-session -t {} 2>/dev/null || true
    
    # STEP 2: 一時ファイル削除
    log_info "🧹 一時ファイル削除中..."
    rm -f ./tmp/worker*_done.txt 2>/dev/null || true
    rmdir ./tmp 2>/dev/null || true
    
    # STEP 3: ターミナルウィンドウ閉鎖（macOSのみ）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "🪟 ターミナルウィンドウ閉鎖中..."
        osascript << 'EOL2' 2>/dev/null || true
tell application "Terminal"
    repeat with w in windows
        repeat with t in tabs of w
            if name of t contains "Multi-Claude" then
                close t
            end if
        end repeat
    end repeat
end tell
EOL2
    fi
    
    log_success "✅ Multi-Claude システム完全終了"
    echo ""
    echo "👋 お疲れさまでした！"
    exit 0
}

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# 現在のディレクトリ
CURRENT_DIR=$(pwd)
MULTI_CLAUDE_DIR="$HOME/.multi-claude"

# コマンドライン引数処理
case "${1:-}" in
    --exit)
        exit_system
        ;;
    --help|-h)
        show_usage
        exit 0
        ;;
    "")
        # 通常起動（既存処理続行）
        ;;
    *)
        echo "❌ 不明なオプション: $1"
        show_usage
        exit 1
        ;;
esac

echo "🤖 Multi-Claude システム起動"
echo "============================="
echo "📁 作業ディレクトリ: $CURRENT_DIR"
echo ""

# STEP 1: プロジェクト固有の環境セットアップ
log_info "🏗️  プロジェクト環境セットアップ中..."

# 必要なファイルを現在のディレクトリにコピー（存在しない場合のみ）
if [ ! -f "./setup.sh" ]; then
    cp "$MULTI_CLAUDE_DIR/setup.sh" ./
    log_info "setup.sh をコピーしました"
fi

if [ ! -f "./agent-send.sh" ]; then
    cp "$MULTI_CLAUDE_DIR/agent-send.sh" ./
    log_info "agent-send.sh をコピーしました"
fi

if [ ! -f "./CLAUDE.md" ]; then
    cp "$MULTI_CLAUDE_DIR/CLAUDE_template.md" "./CLAUDE.md"
    log_info "CLAUDE.md をコピーしました"
fi

if [ ! -d "./instructions" ]; then
    cp -r "$MULTI_CLAUDE_DIR/instructions" ./
    log_info "instructions/ をコピーしました"
fi

# tmp ディレクトリ作成
mkdir -p ./tmp

log_success "✅ プロジェクト環境セットアップ完了"

# STEP 2: 権限設定
chmod +x ./setup.sh
chmod +x ./agent-send.sh

# STEP 3: tmux環境構築
log_info "🏗️  tmux環境構築中..."
./setup.sh

# STEP 4: ターミナルウィンドウ起動
log_info "💻 ターミナルウィンドウ起動中..."

# OSの検出
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    TERMINAL_APP="Terminal"
    
    # ウィンドウ1: PRESIDENT（メインウィンドウ）
    osascript << EOL
tell application "$TERMINAL_APP"
    activate
    set president_window to do script "cd '$CURRENT_DIR' && echo '🎯 PRESIDENT ウィンドウ' && tmux attach-session -t president"
    set name of president_window to "Multi-Claude: PRESIDENT"
end tell
EOL

    sleep 2

    # ウィンドウ2: MULTIAGENT（サブウィンドウ）
    osascript << EOL
tell application "$TERMINAL_APP"
    set multiagent_window to do script "cd '$CURRENT_DIR' && echo '👥 MULTIAGENT ウィンドウ' && tmux attach-session -t multiagent"
    set name of multiagent_window to "Multi-Claude: MULTIAGENT"
end tell
EOL

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --title="Multi-Claude: PRESIDENT" -- bash -c "cd '$CURRENT_DIR' && echo '🎯 PRESIDENT ウィンドウ' && tmux attach-session -t president; exec bash" &
        sleep 2
        gnome-terminal --title="Multi-Claude: MULTIAGENT" -- bash -c "cd '$CURRENT_DIR' && echo '👥 MULTIAGENT ウィンドウ' && tmux attach-session -t multiagent; exec bash" &
    elif command -v xterm &> /dev/null; then
        xterm -title "Multi-Claude: PRESIDENT" -e "cd '$CURRENT_DIR' && echo '🎯 PRESIDENT ウィンドウ' && tmux attach-session -t president" &
        sleep 2
        xterm -title "Multi-Claude: MULTIAGENT" -e "cd '$CURRENT_DIR' && echo '👥 MULTIAGENT ウィンドウ' && tmux attach-session -t multiagent" &
    else
        log_error "対応するターミナルが見つかりません"
        exit 1
    fi
else
    log_error "対応していないOS: $OSTYPE"
    exit 1
fi

log_success "✅ ターミナルウィンドウ起動完了"

# STEP 5: Claude Code自動起動
sleep 3
log_info "🤖 Claude Code自動起動中..."

# PRESIDENT起動
tmux send-keys -t president 'claude' C-m
sleep 2

# MULTIAGENT起動（全ペイン）
for i in {0..3}; do
    tmux send-keys -t multiagent:0.$i 'claude' C-m
    sleep 1
done

log_success "✅ Claude Code起動完了"

echo ""
echo "🎉 Multi-Claude システム起動完了！"
echo "=================================="
echo "📁 プロジェクト: $CURRENT_DIR"
echo ""
echo "📋 使用方法:"
echo "  1. 🎯 PRESIDENTウィンドウ: メインの対話窓口"
echo "  2. 👥 MULTIAGENTウィンドウ: BOSS+WORKERs監視用"
echo ""
echo "💬 PRESIDENTに話しかけてタスクを依頼してください："
echo "     例: 「Pythonスクリプトを3人で作って」"
echo ""
echo "🔧 システム制御:"
echo "  終了: Ctrl+C でClaude終了、tmux kill-server で完全リセット"
echo "  再起動: multi-claude"
EOF

chmod +x "$INSTALL_DIR/multi-claude-global"

# STEP 5: ローカルbinディレクトリにリンク作成
log_info "🔗 ローカルコマンドリンク作成中..."

# ~/binディレクトリ作成
mkdir -p "$BIN_DIR"

# 既存のリンクを削除（存在する場合）
rm -f "$BIN_DIR/multi-claude"

# 新しいシンボリックリンクを作成
ln -s "$INSTALL_DIR/multi-claude-global" "$BIN_DIR/multi-claude"

log_success "✅ グローバルコマンド作成完了"

echo ""
echo "🎉 Multi-Claude システム ローカルインストール完了！"
echo "=============================================="
echo ""
echo "⚠️  PATH設定確認:"
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "  $BIN_DIR がPATHに含まれていません。"
    echo "  以下を ~/.zshrc または ~/.bashrc に追加してください："
    echo "    export PATH=\"\$HOME/bin:\$PATH\""
    echo "  その後、ターミナルを再起動してください。"
else
    echo "  ✅ PATH設定OK"
fi
echo ""
echo "📋 使用方法:"
echo "  任意のディレクトリで以下を実行："
echo "    multi-claude"
echo ""
echo "🔧 システム情報:"
echo "  インストール先: $INSTALL_DIR"
echo "  コマンドパス: $BIN_DIR/multi-claude"
echo ""
echo "🗑️  アンインストール:"
echo "  rm $BIN_DIR/multi-claude"
echo "  rm -rf $INSTALL_DIR"