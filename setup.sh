#!/bin/bash

# 🚀 Multi-Agent Communication Demo 環境構築
# 参考: setup_full_environment.sh

set -e  # エラー時に停止

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

echo "🤖 Multi-Agent Communication Demo 環境構築"
echo "==========================================="
echo ""

# STEP 1: 既存セッションクリーンアップ
log_info "🧹 既存セッションクリーンアップ開始..."

# 既存のセッションを強制的に削除
tmux kill-session -t multiagent 2>/dev/null && log_info "multiagentセッション削除完了" || log_info "multiagentセッションは存在しませんでした"
tmux kill-session -t president 2>/dev/null && log_info "presidentセッション削除完了" || log_info "presidentセッションは存在しませんでした"

# 既存のtmuxプロセスが完全に終了するまで待機
sleep 0.5

# 環境変数設定
export MULTI_CLAUDE_LOCAL="$(pwd)/.multi-claude"

# ローカルディレクトリ作成（プロジェクト固有データ用）
mkdir -p "$MULTI_CLAUDE_LOCAL/session/tmp"
mkdir -p "$MULTI_CLAUDE_LOCAL/session/logs"
mkdir -p "$MULTI_CLAUDE_LOCAL/session/runtime"
mkdir -p "$MULTI_CLAUDE_LOCAL/context"
mkdir -p "$MULTI_CLAUDE_LOCAL/tasks"
mkdir -p "$MULTI_CLAUDE_LOCAL/config"

# 完了ファイルクリア
rm -f "$MULTI_CLAUDE_LOCAL/session/tmp/worker*_done.txt" 2>/dev/null && log_info "既存の完了ファイルをクリア" || log_info "完了ファイルは存在しませんでした"

# ワーカーIDディレクトリ作成
mkdir -p "$MULTI_CLAUDE_LOCAL/session/tmp/worker_ids"
rm -f "$MULTI_CLAUDE_LOCAL/session/tmp/worker_ids/*.id" 2>/dev/null && log_info "既存のワーカーIDファイルをクリア" || log_info "ワーカーIDファイルは存在しませんでした"

# 役割判定システム用ディレクトリ作成
mkdir -p "$MULTI_CLAUDE_LOCAL/session/runtime/session-setup"

# agent-send.shをローカルにコピー
if [ -f "$HOME/.multi-claude/bin/agent-send.sh" ]; then
    mkdir -p "$MULTI_CLAUDE_LOCAL/bin"
    cp "$HOME/.multi-claude/bin/agent-send.sh" "$MULTI_CLAUDE_LOCAL/bin/agent-send.sh"
    chmod +x "$MULTI_CLAUDE_LOCAL/bin/agent-send.sh"
    log_info "agent-send.shをローカルにコピー完了"
fi

# health-check.shをローカルにコピー
if [ -f "$HOME/.multi-claude/bin/health-check.sh" ]; then
    cp "$HOME/.multi-claude/bin/health-check.sh" "$MULTI_CLAUDE_LOCAL/bin/health-check.sh"
    chmod +x "$MULTI_CLAUDE_LOCAL/bin/health-check.sh"
    log_info "health-check.shをローカルにコピー完了"
fi

log_success "✅ クリーンアップ完了"
echo ""

# STEP 2: multiagentセッション作成（6ペイン：boss1, architect, qa + worker1,2,3）
log_info "📺 multiagentセッション作成開始 (6ペイン - 3x2レイアウト)..."

# 最初のペイン作成
tmux new-session -d -s multiagent -n "agents"

# 3x2グリッド作成（合計6ペイン）
# まず3列に分割
tmux split-window -h -t "multiagent:0" -p 66   # 最初の分割（33%:66%）
tmux split-window -h -t "multiagent:0.1" -p 50 # 残り66%を半分に（33%:33%）

# 各列を上下に分割
tmux select-pane -t "multiagent:0.0"
tmux split-window -v -p 50                      # 左列を上下に分割
tmux select-pane -t "multiagent:0.2"
tmux split-window -v -p 50                      # 中列を上下に分割
tmux select-pane -t "multiagent:0.4"
tmux split-window -v -p 50                      # 右列を上下に分割

# ペインタイトル設定
log_info "ペインタイトル設定中..."
PANE_TITLES=("boss1" "worker1" "architect" "worker2" "qa" "worker3")

for i in {0..5}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    
    # 作業ディレクトリ設定
    tmux send-keys -t "multiagent:0.$i" "cd $(pwd)" C-m
    
    # プロンプト設定
    tmux send-keys -t "multiagent:0.$i" "export PS1='(${PANE_TITLES[$i]}) \\w\\$ '" C-m
    
    # ウェルカムメッセージ
    tmux send-keys -t "multiagent:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント ==='" C-m
    
    # 役割判定システム用の環境変数設定
    tmux send-keys -t "multiagent:0.$i" "export MULTI_CLAUDE_ROLE='${PANE_TITLES[$i]}'" C-m
    tmux send-keys -t "multiagent:0.$i" "export MULTI_CLAUDE_SESSION_ID='session-setup'" C-m
done

log_success "✅ multiagentセッション作成完了"
echo ""

# STEP 3: presidentセッション作成（1ペイン）
log_info "👑 presidentセッション作成開始..."

tmux new-session -d -s president
tmux send-keys -t president "cd $(pwd)" C-m
tmux send-keys -t president "export PS1='(PRESIDENT) \\w\\$ '" C-m
tmux send-keys -t president "echo '=== PRESIDENT セッション ==='" C-m
tmux send-keys -t president "echo 'プロジェクト統括責任者'" C-m
tmux send-keys -t president "echo '========================'" C-m

# 役割判定システム用の環境変数設定
tmux send-keys -t president "export MULTI_CLAUDE_ROLE='president'" C-m
tmux send-keys -t president "export MULTI_CLAUDE_SESSION_ID='session-setup'" C-m

log_success "✅ presidentセッション作成完了"
echo ""

# STEP 4: 環境確認・表示
log_info "🔍 環境確認中..."

echo ""
echo "📊 セットアップ結果:"
echo "==================="

# tmuxセッション確認
echo "📺 Tmux Sessions:"
tmux list-sessions
echo ""

# ペイン構成表示
echo "📋 ペイン構成:"
echo "  multiagentセッション（6ペイン - 3x2レイアウト）:"
echo "    上段:"
echo "      Pane 0: boss1     (チームリーダー)"
echo "      Pane 2: architect (システム設計者)"
echo "      Pane 4: qa        (品質保証エンジニア)"
echo "    下段:"
echo "      Pane 1: worker1   (実行担当者A)"
echo "      Pane 3: worker2   (実行担当者B)"
echo "      Pane 5: worker3   (実行担当者C)"
echo ""
echo "  presidentセッション（1ペイン）:"
echo "    Pane 0: PRESIDENT (プロジェクト統括)"

echo ""
log_success "🎉 Demo環境セットアップ完了！"
echo ""
echo "📋 次のステップ:"
echo "  1. 🔗 セッションアタッチ:"
echo "     tmux attach-session -t multiagent   # マルチエージェント確認"
echo "     tmux attach-session -t president    # プレジデント確認"
echo ""
echo "  2. 🤖 Claude Code起動:"
echo "     # 手順1: President認証"
echo "     tmux send-keys -t president 'claude' C-m"
echo "     # 手順2: 認証後、multiagent一括起動"
echo "     for i in {0..5}; do tmux send-keys -t multiagent:0.\$i 'claude' C-m; done"
echo ""
echo "  3. 📜 指示書確認:"
echo "     PRESIDENT: \$MULTI_CLAUDE_LOCAL/instructions/president_dynamic.md"
echo "     boss1: \$MULTI_CLAUDE_LOCAL/instructions/boss_dynamic.md"
echo "     architect: \$MULTI_CLAUDE_LOCAL/instructions/architect_dynamic.md"
echo "     qa: \$MULTI_CLAUDE_LOCAL/instructions/qa_dynamic.md"
echo "     worker1,2,3: \$MULTI_CLAUDE_LOCAL/instructions/worker_dynamic.md"
echo "     システム構造: CLAUDE.md"
echo ""
echo "  4. 🎯 デモ実行: PRESIDENTに「あなたはpresidentです。指示書に従って」と入力"
echo ""
echo "  5. 🔍 役割判定システム:"
echo "     # 各ペインで役割を確認"
echo "     source .multi-claude/bin/role-detection.sh && get_my_role" 