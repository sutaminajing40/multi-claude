#!/bin/bash

# 🚀 エージェント起動・管理スクリプト
# Claude Codeの確実な起動とヘルスチェック機能

# 設定
MULTI_CLAUDE_LOCAL="${MULTI_CLAUDE_LOCAL:-$HOME/.multi-claude}"
STATUS_DIR="$MULTI_CLAUDE_LOCAL/session/runtime/agent_status"
LOG_FILE="$MULTI_CLAUDE_LOCAL/session/logs/launch-agent.log"

# ログイン完了を示すパターン（login_detection.shから統合）
LOGIN_COMPLETE_PATTERNS=(
    "⏵⏵ auto-accept edits on"
    "shift+tab to cycle"
    "Press up to edit queued messages"
    "ready"
    "claude"
    "assistant"
    "how can i help"
    "what can i do"
    "ready to assist"
    "Hello! I'm Claude"
)

# ログイン要求パターン
LOGIN_REQUIRED_PATTERNS=(
    "login"
    "sign in"
    "authenticate"
    "Please log in"
    "Authentication required"
    "Enter your credentials"
)

# エラーパターン
ERROR_PATTERNS=(
    "Error"
    "Failed"
    "crash"
    "terminated"
    "Cannot start"
    "Permission denied"
)

# ログ関数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# ディレクトリ初期化
init_directories() {
    mkdir -p "$STATUS_DIR" "$(dirname "$LOG_FILE")"
}

# Claude Codeのステータス検出（timing_control.shから統合）
detect_claude_status() {
    local pane_id="$1"
    local pane_content=$(tmux capture-pane -t "$pane_id" -p -S -30 2>/dev/null)
    
    if [ -z "$pane_content" ]; then
        echo "NO_CONTENT"
        return 1
    fi
    
    # エラーパターンチェック
    for pattern in "${ERROR_PATTERNS[@]}"; do
        if echo "$pane_content" | grep -qi "$pattern"; then
            echo "ERROR"
            return 1
        fi
    done
    
    # ログイン完了パターンチェック
    for pattern in "${LOGIN_COMPLETE_PATTERNS[@]}"; do
        if echo "$pane_content" | grep -qi "$pattern"; then
            echo "READY"
            return 0
        fi
    done
    
    # ログイン要求パターンチェック  
    for pattern in "${LOGIN_REQUIRED_PATTERNS[@]}"; do
        if echo "$pane_content" | grep -qi "$pattern"; then
            echo "LOGIN_REQUIRED"
            return 0
        fi
    done
    
    echo "STARTING"
    return 0
}

# エージェント起動（エラーハンドリング強化）
launch_agent() {
    local agent_name="$1"
    local pane_id="$2"
    local claude_options="${3:-}"
    local max_wait="${4:-120}"  # デフォルト2分待機
    local retry_count=0
    local max_retries=3
    
    log "INFO" "$agent_name の起動を開始 (ペイン: $pane_id)"
    
    while [ $retry_count -lt $max_retries ]; do
        # ステータスをSTARTINGに設定
        echo "STARTING" > "$STATUS_DIR/${agent_name}.status"
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_DIR/${agent_name}.timestamp"
        
        # 既存プロセスのクリーンアップ
        tmux send-keys -t "$pane_id" C-c
        sleep 1
        
        # プロセスが完全に終了したか確認
        local pane_pid=$(tmux list-panes -t "$pane_id" -F "#{pane_pid}" 2>/dev/null)
        if [ -n "$pane_pid" ] && ps -p "$pane_pid" > /dev/null 2>&1; then
            # プロセスがまだ生きている場合は強制終了
            tmux send-keys -t "$pane_id" C-d
            sleep 1
        fi
        
        # Claude Codeの起動コマンド送信
        log "INFO" "$agent_name にClaude Code起動コマンドを送信 (試行 $((retry_count + 1))/$max_retries)"
        tmux send-keys -t "$pane_id" "claude $claude_options" Enter
        
        # 起動待機とステータス監視
        local start_time=$(date +%s)
        local status="STARTING"
        local login_required_notified=false
        local error_detected=false
        
        while true; do
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            
            # タイムアウトチェック
            if [ $elapsed -gt $max_wait ]; then
                log "ERROR" "$agent_name の起動がタイムアウトしました (${max_wait}秒)"
                echo "TIMEOUT" > "$STATUS_DIR/${agent_name}.status"
                break
            fi
            
            # ステータス検出
            status=$(detect_claude_status "$pane_id")
            
            case "$status" in
                "READY")
                    log "INFO" "$agent_name が正常に起動しました"
                    echo "READY" > "$STATUS_DIR/${agent_name}.status"
                    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_DIR/${agent_name}.timestamp"
                    return 0
                    ;;
                    
                "LOGIN_REQUIRED")
                    if [ "$login_required_notified" == "false" ]; then
                        log "WARN" "$agent_name でログインが必要です。手動でログインしてください"
                        echo "LOGIN_REQUIRED" > "$STATUS_DIR/${agent_name}.status"
                        login_required_notified=true
                    fi
                    ;;
                    
                "ERROR")
                    log "ERROR" "$agent_name でエラーが検出されました"
                    error_detected=true
                    break
                    ;;
                    
                "STARTING"|"NO_CONTENT")
                    # 起動中
                    ;;
            esac
            
            # 進捗表示
            echo -ne "\r⏳ $agent_name 起動待機中... ($elapsed/${max_wait}秒)"
            
            sleep 2
        done
        
        echo  # 改行
        
        # エラーまたはタイムアウトの場合、リトライ
        retry_count=$((retry_count + 1))
        
        if [ $retry_count -lt $max_retries ]; then
            log "WARN" "$agent_name の起動に失敗しました。5秒後にリトライします..."
            sleep 5
        fi
    done
    
    # 全てのリトライが失敗
    log "ERROR" "$agent_name の起動に失敗しました（最大リトライ回数超過）"
    echo "FAILED" > "$STATUS_DIR/${agent_name}.status"
    return 1
}

# 全エージェント起動
launch_all_agents() {
    local agents=(
        "president:president:0:"
        "boss1:multiagent:0.0:"
        "worker1:multiagent:0.1:-m sonnet"
        "architect:multiagent:0.2:"
        "worker2:multiagent:0.3:-m sonnet"
        "qa:multiagent:0.4:"
        "worker3:multiagent:0.5:-m sonnet"
    )
    
    local failed_agents=()
    
    for agent_info in "${agents[@]}"; do
        IFS=':' read -r agent_name pane_id options <<< "$agent_info"
        
        echo
        if ! launch_agent "$agent_name" "$pane_id" "$options"; then
            failed_agents+=("$agent_name")
        fi
    done
    
    echo
    
    if [ ${#failed_agents[@]} -gt 0 ]; then
        log "ERROR" "以下のエージェントの起動に失敗しました: ${failed_agents[*]}"
        return 1
    else
        log "INFO" "✅ 全エージェントの起動に成功しました"
        return 0
    fi
}

# 特定エージェントの再起動
restart_agent() {
    local agent_name="$1"
    local agent_map=(
        "president:president:0:"
        "boss1:multiagent:0.0:"
        "worker1:multiagent:0.1:-m sonnet"
        "architect:multiagent:0.2:"
        "worker2:multiagent:0.3:-m sonnet"
        "qa:multiagent:0.4:"
        "worker3:multiagent:0.5:-m sonnet"
    )
    
    for agent_info in "${agent_map[@]}"; do
        IFS=':' read -r name pane_id options <<< "$agent_info"
        
        if [ "$name" == "$agent_name" ]; then
            log "INFO" "$agent_name を再起動します"
            launch_agent "$name" "$pane_id" "$options"
            return $?
        fi
    done
    
    log "ERROR" "エージェント $agent_name が見つかりません"
    return 1
}

# 使用方法
show_usage() {
    cat << EOF
🚀 エージェント起動管理

使用方法:
  $0                          - 全エージェントを起動
  $0 --agent <name>           - 特定エージェントを起動/再起動
  $0 --status                 - 全エージェントのステータス確認
  $0 --help                   - このヘルプを表示

エージェント名:
  president, boss1, worker1, architect, worker2, qa, worker3

例:
  $0
  $0 --agent worker1
  $0 --status
EOF
}

# ステータス表示
show_status() {
    echo "📊 エージェント起動ステータス:"
    echo "=============================="
    
    local agents=("president" "boss1" "worker1" "architect" "worker2" "qa" "worker3")
    
    for agent in "${agents[@]}"; do
        local status_file="$STATUS_DIR/${agent}.status"
        local timestamp_file="$STATUS_DIR/${agent}.timestamp"
        
        if [ -f "$status_file" ]; then
            local status=$(cat "$status_file")
            local timestamp="不明"
            
            if [ -f "$timestamp_file" ]; then
                timestamp=$(cat "$timestamp_file")
            fi
            
            # ステータスに応じて色分け
            case "$status" in
                "READY"|"ACTIVE")
                    status_display="\033[0;32m$status\033[0m"  # 緑
                    ;;
                "LOGIN_REQUIRED")
                    status_display="\033[1;33m$status\033[0m"  # 黄
                    ;;
                "FAILED"|"TIMEOUT"|"ERROR")
                    status_display="\033[0;31m$status\033[0m"  # 赤
                    ;;
                *)
                    status_display="$status"
                    ;;
            esac
            
            printf "%-12s: %-25b (更新: %s)\n" "$agent" "$status_display" "$timestamp"
        else
            printf "%-12s: %-25s\n" "$agent" "未起動"
        fi
    done
}

# メイン処理
main() {
    init_directories
    
    case "${1:-}" in
        "--agent")
            if [ -z "$2" ]; then
                echo "エラー: エージェント名を指定してください"
                show_usage
                exit 1
            fi
            restart_agent "$2"
            ;;
            
        "--status")
            show_status
            ;;
            
        "--help"|"-h")
            show_usage
            ;;
            
        *)
            echo "🚀 全エージェントを起動します"
            echo "============================="
            launch_all_agents
            ;;
    esac
}

# スクリプト実行
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi