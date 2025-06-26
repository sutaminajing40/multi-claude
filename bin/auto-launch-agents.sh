#!/bin/bash

# 🚀 Auto Launch Agents - 全エージェントの自動起動スクリプト
#
# multi-claudeスクリプトから呼び出されて、全エージェントを自動起動します

set -euo pipefail

# 設定
LAUNCHER="${MULTI_CLAUDE_LOCAL}/bin/launch-agent.sh"
STATUS_MANAGER="${MULTI_CLAUDE_LOCAL}/bin/agent-status.sh"
LOG_FILE="${MULTI_CLAUDE_LOCAL}/session/logs/auto-launch.log"

# エージェント定義
declare -A AGENTS=(
    ["boss1"]="multiagent:0.0"
    ["worker1"]="multiagent:0.1"
    ["architect"]="multiagent:0.2"
    ["worker2"]="multiagent:0.3"
    ["qa"]="multiagent:0.4"
    ["worker3"]="multiagent:0.5"
    ["president"]="president:0"
)

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ログ関数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} $*" | tee -a "$LOG_FILE"
}

# ディレクトリ作成
mkdir -p "$(dirname "$LOG_FILE")"

log "========================================="
log "Auto Launch Agents 開始"
log "========================================="

# 状態リセット
echo -e "${YELLOW}🔄 エージェント状態をリセット中...${NC}"
"$STATUS_MANAGER" reset-all

# 各エージェントを起動
echo -e "${GREEN}🚀 エージェントを起動中...${NC}"
for agent in "${!AGENTS[@]}"; do
    tmux_target="${AGENTS[$agent]}"
    echo -e "  📌 ${agent} (${tmux_target})"
    
    # バックグラウンドで起動
    "$LAUNCHER" "$agent" "$tmux_target" > "$LOG_FILE" 2>&1 &
    
    # 少し間隔を空ける
    sleep 2
done

# 初期メッセージの設定
declare -A INIT_MESSAGES=(
    ["president"]="あなたはPRESIDENTです。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/president_dynamic.mdを読み込んで、指示に従って行動してください。"
    ["boss1"]="あなたはboss1です。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/boss_dynamic.mdを読み込んで、指示に従って行動してください。"
    ["worker1"]="あなたはworker1です。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/worker_dynamic.mdを読み込んで、指示に従って行動してください。"
    ["architect"]="あなたはarchitectです。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/architect_dynamic.mdを読み込んで、指示に従って行動してください。"
    ["worker2"]="あなたはworker2です。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/worker_dynamic.mdを読み込んで、指示に従って行動してください。"
    ["qa"]="あなたはqaです。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/qa_dynamic.mdを読み込んで、指示に従って行動してください。"
    ["worker3"]="あなたはworker3です。CLAUDE.mdと@$MULTI_CLAUDE_LOCAL/instructions/worker_dynamic.mdを読み込んで、指示に従って行動してください。"
)

# 全エージェントの準備完了を待機
echo -e "${YELLOW}⏳ 全エージェントの準備完了を待機中...${NC}"
if "$STATUS_MANAGER" wait-all --timeout 60; then
    echo -e "${GREEN}✅ 全エージェントが準備完了しました${NC}"
    
    # 初期メッセージを送信
    echo -e "${GREEN}📨 初期メッセージを送信中...${NC}"
    for agent in "${!INIT_MESSAGES[@]}"; do
        tmux_target="${AGENTS[$agent]}"
        message="${INIT_MESSAGES[$agent]}"
        
        echo -e "  📤 ${agent} へメッセージ送信"
        tmux send-keys -t "$tmux_target" C-c
        sleep 0.5
        tmux send-keys -t "$tmux_target" "$message" C-m
        sleep 1
    done
    
    echo -e "${GREEN}✅ 初期メッセージ送信完了${NC}"
    log "全エージェントの起動と初期化が完了しました"
    
    # 最終状態表示
    "$STATUS_MANAGER" list
    
else
    echo -e "\033[0;31m❌ エージェントの起動に失敗しました${NC}"
    log "エージェントの起動に失敗しました"
    
    # エラー状態を表示
    "$STATUS_MANAGER" list
    
    exit 1
fi

log "Auto Launch Agents 完了"