#!/bin/bash

# 🏥 Multi-Claude ヘルスチェック＆自動復旧スクリプト
# システムの健全性を確認し、問題があれば自動復旧を試みる

# 設定
MULTI_CLAUDE_LOCAL="${MULTI_CLAUDE_LOCAL:-$HOME/.multi-claude}"
LOG_FILE="$MULTI_CLAUDE_LOCAL/session/logs/health-check.log"
STATUS_DIR="$MULTI_CLAUDE_LOCAL/session/runtime/agent_status"

# 色設定
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ログ関数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    log "INFO" "$1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log "WARN" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR" "$1"
}

# tmuxセッション確認
check_tmux_sessions() {
    local sessions=("multiagent" "president")
    local healthy=true
    
    echo "🔍 tmuxセッション確認中..."
    for session in "${sessions[@]}"; do
        if tmux has-session -t "$session" 2>/dev/null; then
            log_info "✅ $session セッション: 稼働中"
        else
            log_error "❌ $session セッション: 停止"
            healthy=false
        fi
    done
    
    return $([ "$healthy" == "true" ] && echo 0 || echo 1)
}

# エージェント状態確認
check_agent_health() {
    local agent="$1"
    local pane_info="$2"
    
    # tmuxペインの存在確認
    if ! tmux list-panes -t "$pane_info" &>/dev/null; then
        log_error "$agent のペインが存在しません"
        return 1
    fi
    
    # claude-codeプロセスの確認
    local pane_pid=$(tmux list-panes -t "$pane_info" -F "#{pane_pid}" 2>/dev/null)
    if [ -z "$pane_pid" ]; then
        log_error "$agent のプロセスIDが取得できません"
        return 1
    fi
    
    # プロセスが生きているか確認
    if ! ps -p "$pane_pid" > /dev/null 2>&1; then
        log_error "$agent のプロセスが停止しています"
        return 1
    fi
    
    # ステータスファイル確認
    local status_file="$STATUS_DIR/${agent}.status"
    if [ -f "$status_file" ]; then
        local status=$(cat "$status_file")
        local timestamp_file="$STATUS_DIR/${agent}.timestamp"
        local last_update="不明"
        
        if [ -f "$timestamp_file" ]; then
            last_update=$(cat "$timestamp_file")
        fi
        
        log_info "$agent 状態: $status (最終更新: $last_update)"
        
        # 最終更新が古すぎないか確認（10分以上古い場合は警告）
        if [ -f "$timestamp_file" ]; then
            local last_update_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$last_update" "+%s" 2>/dev/null || date -d "$last_update" "+%s" 2>/dev/null)
            local current_epoch=$(date +%s)
            local diff=$((current_epoch - last_update_epoch))
            
            if [ $diff -gt 600 ]; then
                log_warn "$agent の状態が10分以上更新されていません"
            fi
        fi
    else
        log_warn "$agent のステータスファイルが存在しません"
    fi
    
    return 0
}

# 全エージェントの健全性確認
check_all_agents() {
    local agents=(
        "president:president:0"
        "boss1:multiagent:0.0"
        "worker1:multiagent:0.1"
        "architect:multiagent:0.2"
        "worker2:multiagent:0.3"
        "qa:multiagent:0.4"
        "worker3:multiagent:0.5"
    )
    
    local unhealthy_agents=()
    
    echo "🏥 エージェント健全性確認中..."
    for agent_info in "${agents[@]}"; do
        IFS=':' read -r agent_name pane_info <<< "$agent_info"
        
        if ! check_agent_health "$agent_name" "$pane_info"; then
            unhealthy_agents+=("$agent_name")
        fi
    done
    
    if [ ${#unhealthy_agents[@]} -gt 0 ]; then
        log_error "不健全なエージェント: ${unhealthy_agents[*]}"
        return 1
    else
        log_info "✅ 全エージェント正常稼働中"
        return 0
    fi
}

# エージェントの再起動
restart_agent() {
    local agent_name="$1"
    local pane_info="$2"
    
    log_info "$agent_name を再起動中..."
    
    # 現在のプロセスを停止
    tmux send-keys -t "$pane_info" C-c
    sleep 1
    
    # Claude Codeを再起動
    local claude_options=""
    if [ -n "$CLAUDE_OPTIONS" ]; then
        claude_options="$CLAUDE_OPTIONS"
    fi
    
    tmux send-keys -t "$pane_info" "claude $claude_options" Enter
    sleep 2
    
    # ステータスをSTARTINGに更新
    mkdir -p "$STATUS_DIR"
    echo "STARTING" > "$STATUS_DIR/${agent_name}.status"
    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_DIR/${agent_name}.timestamp"
    
    log_info "$agent_name の再起動コマンドを送信しました"
}

# システム復旧試行
attempt_recovery() {
    local recovery_needed=false
    
    # tmuxセッション確認
    if ! check_tmux_sessions; then
        log_error "tmuxセッションに問題があります。multi-claudeの再起動が必要です"
        recovery_needed=true
        return 1
    fi
    
    # エージェント確認
    local agents=(
        "president:president:0"
        "boss1:multiagent:0.0"
        "worker1:multiagent:0.1"
        "architect:multiagent:0.2"
        "worker2:multiagent:0.3"
        "qa:multiagent:0.4"
        "worker3:multiagent:0.5"
    )
    
    for agent_info in "${agents[@]}"; do
        IFS=':' read -r agent_name pane_info <<< "$agent_info"
        
        if ! check_agent_health "$agent_name" "$pane_info"; then
            recovery_needed=true
            
            # 自動復旧を試みる
            if [ "$1" == "--auto-recover" ]; then
                restart_agent "$agent_name" "$pane_info"
            fi
        fi
    done
    
    if [ "$recovery_needed" == "true" ] && [ "$1" != "--auto-recover" ]; then
        log_warn "問題が検出されました。--auto-recover オプションで自動復旧を試みることができます"
        return 1
    fi
    
    return 0
}

# メッセージ配信状態確認
check_message_queue() {
    local queue_dir="$MULTI_CLAUDE_LOCAL/session/runtime/message_queue"
    
    if [ -d "$queue_dir" ]; then
        local pending_count=$(grep -l "STATUS=pending" "$queue_dir"/*.msg 2>/dev/null | wc -l | tr -d ' ')
        local delivered_count=$(grep -l "STATUS=delivered" "$queue_dir"/*.msg 2>/dev/null | wc -l | tr -d ' ')
        
        echo "📬 メッセージキュー状態:"
        echo "  待機中: $pending_count"
        echo "  配信済: $delivered_count"
        
        if [ "$pending_count" -gt 0 ]; then
            log_warn "未配信のメッセージが $pending_count 件あります"
        fi
    fi
}

# 使用方法
show_usage() {
    cat << EOF
🏥 Multi-Claude ヘルスチェック

使用方法:
  $0              - システム健全性確認
  $0 --auto-recover   - 問題検出時に自動復旧を試行
  $0 --agents         - エージェントの詳細確認
  $0 --messages       - メッセージキュー確認
  $0 --full           - 完全診断

オプション:
  --help              - このヘルプを表示
EOF
}

# メイン処理
main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        "--auto-recover")
            echo "🏥 Multi-Claude ヘルスチェック (自動復旧モード)"
            echo "====================================="
            attempt_recovery "--auto-recover"
            ;;
            
        "--agents")
            echo "🏥 エージェント詳細確認"
            echo "====================="
            check_all_agents
            ;;
            
        "--messages")
            echo "📬 メッセージキュー確認"
            echo "====================="
            check_message_queue
            ;;
            
        "--full")
            echo "🏥 Multi-Claude 完全診断"
            echo "======================="
            check_tmux_sessions
            echo
            check_all_agents
            echo
            check_message_queue
            ;;
            
        "--help"|"-h")
            show_usage
            ;;
            
        *)
            echo "🏥 Multi-Claude ヘルスチェック"
            echo "============================="
            if attempt_recovery; then
                log_info "✅ システムは正常に稼働しています"
            else
                log_error "❌ システムに問題が検出されました"
                echo
                echo "詳細確認: $0 --full"
                echo "自動復旧: $0 --auto-recover"
                exit 1
            fi
            ;;
    esac
}

# スクリプト実行
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi