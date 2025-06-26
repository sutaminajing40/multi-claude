#!/bin/bash

# 📊 Agent Status Manager - エージェント状態管理ツール
#
# 使用方法:
#   agent-status.sh [command] [options]
#
# コマンド:
#   check <agent>     特定エージェントの状態確認
#   list              全エージェントの状態一覧
#   wait <agent>      エージェントのREADY待機
#   wait-all          全エージェントのREADY待機
#   reset <agent>     特定エージェントの状態リセット
#   reset-all         全エージェントの状態リセット

set -euo pipefail

# 設定
STATUS_DIR="${MULTI_CLAUDE_LOCAL}/session/runtime/agent_status"
LOG_FILE="${MULTI_CLAUDE_LOCAL}/session/logs/agent-status.log"
DEFAULT_TIMEOUT=300
CHECK_INTERVAL=2

# エージェント一覧
AGENTS=("boss1" "worker1" "architect" "worker2" "qa" "worker3" "president")

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} $*" >> "$LOG_FILE"
}

# 状態ファイル取得
get_status_file() {
    local agent="$1"
    echo "${STATUS_DIR}/${agent}.status"
}

# 状態読み取り
read_status() {
    local agent="$1"
    local status_file=$(get_status_file "$agent")
    
    if [[ -f "$status_file" ]]; then
        local status=$(grep '"status"' "$status_file" 2>/dev/null | cut -d'"' -f4 || echo "UNKNOWN")
        local timestamp=$(grep '"timestamp"' "$status_file" 2>/dev/null | cut -d'"' -f4 || echo "N/A")
        echo "${status}|${timestamp}"
    else
        echo "NOT_STARTED|N/A"
    fi
}

# 状態確認
check_agent() {
    local agent="$1"
    local status_info=$(read_status "$agent")
    local status="${status_info%|*}"
    local timestamp="${status_info#*|}"
    
    case "$status" in
        "ACTIVE"|"READY")
            echo -e "${GREEN}✅ ${agent}: ${status}${NC} (${timestamp})"
            return 0
            ;;
        "STARTING")
            echo -e "${YELLOW}⏳ ${agent}: ${status}${NC} (${timestamp})"
            return 1
            ;;
        "FAILED"|"TERMINATED")
            echo -e "${RED}❌ ${agent}: ${status}${NC} (${timestamp})"
            return 1
            ;;
        "LOGIN_REQUIRED")
            echo -e "${YELLOW}🔐 ${agent}: ${status}${NC} (${timestamp})"
            return 1
            ;;
        *)
            echo -e "${BLUE}❓ ${agent}: ${status}${NC} (${timestamp})"
            return 1
            ;;
    esac
}

# 全エージェント状態一覧
list_all() {
    echo -e "\n${BLUE}📊 エージェント状態一覧${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local all_ready=true
    for agent in "${AGENTS[@]}"; do
        if ! check_agent "$agent"; then
            all_ready=false
        fi
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if $all_ready; then
        echo -e "${GREEN}✅ 全エージェントが準備完了${NC}\n"
        return 0
    else
        echo -e "${YELLOW}⚠️  一部のエージェントが準備中${NC}\n"
        return 1
    fi
}

# エージェント待機
wait_for_agent() {
    local agent="$1"
    local timeout="${2:-$DEFAULT_TIMEOUT}"
    local start_time=$(date +%s)
    
    echo -e "${BLUE}⏳ ${agent} の準備完了を待機中...${NC}"
    log "Waiting for ${agent} (timeout: ${timeout}s)"
    
    while true; do
        local status_info=$(read_status "$agent")
        local status="${status_info%|*}"
        
        if [[ "$status" == "READY" ]] || [[ "$status" == "ACTIVE" ]]; then
            echo -e "${GREEN}✅ ${agent} が準備完了しました${NC}"
            log "${agent} is ready"
            return 0
        fi
        
        if [[ "$status" == "FAILED" ]] || [[ "$status" == "TERMINATED" ]]; then
            echo -e "${RED}❌ ${agent} の起動に失敗しました${NC}"
            log "${agent} failed to start"
            return 1
        fi
        
        local elapsed=$(($(date +%s) - start_time))
        if (( elapsed >= timeout )); then
            echo -e "${RED}❌ タイムアウト: ${agent} が準備完了しませんでした${NC}"
            log "Timeout waiting for ${agent}"
            return 1
        fi
        
        # 進捗表示
        if (( elapsed % 10 == 0 )) && (( elapsed > 0 )); then
            echo -e "${YELLOW}   待機中... (${elapsed}/${timeout}秒)${NC}"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# 全エージェント待機
wait_for_all() {
    local timeout="${1:-$DEFAULT_TIMEOUT}"
    local start_time=$(date +%s)
    
    echo -e "${BLUE}⏳ 全エージェントの準備完了を待機中...${NC}"
    log "Waiting for all agents (timeout: ${timeout}s)"
    
    while true; do
        local all_ready=true
        local not_ready=()
        
        for agent in "${AGENTS[@]}"; do
            local status_info=$(read_status "$agent")
            local status="${status_info%|*}"
            
            if [[ "$status" != "READY" ]] && [[ "$status" != "ACTIVE" ]]; then
                all_ready=false
                not_ready+=("$agent")
            fi
            
            if [[ "$status" == "FAILED" ]] || [[ "$status" == "TERMINATED" ]]; then
                echo -e "${RED}❌ ${agent} の起動に失敗しました${NC}"
                return 1
            fi
        done
        
        if $all_ready; then
            echo -e "${GREEN}✅ 全エージェントが準備完了しました${NC}"
            log "All agents are ready"
            list_all
            return 0
        fi
        
        local elapsed=$(($(date +%s) - start_time))
        if (( elapsed >= timeout )); then
            echo -e "${RED}❌ タイムアウト: 以下のエージェントが準備完了しませんでした:${NC}"
            for agent in "${not_ready[@]}"; do
                echo -e "${RED}   - ${agent}${NC}"
            done
            log "Timeout waiting for all agents"
            return 1
        fi
        
        # 進捗表示
        if (( elapsed % 10 == 0 )) && (( elapsed > 0 )); then
            echo -e "${YELLOW}   待機中... (${elapsed}/${timeout}秒) - 未準備: ${not_ready[*]}${NC}"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# 状態リセット
reset_agent() {
    local agent="$1"
    local status_file=$(get_status_file "$agent")
    
    if [[ -f "$status_file" ]]; then
        rm "$status_file"
        echo -e "${GREEN}✅ ${agent} の状態をリセットしました${NC}"
        log "Reset status for ${agent}"
    else
        echo -e "${YELLOW}⚠️  ${agent} の状態ファイルが存在しません${NC}"
    fi
}

# 全エージェント状態リセット
reset_all() {
    echo -e "${BLUE}🔄 全エージェントの状態をリセット中...${NC}"
    
    for agent in "${AGENTS[@]}"; do
        reset_agent "$agent"
    done
    
    echo -e "${GREEN}✅ 全エージェントの状態をリセットしました${NC}"
    log "Reset all agent statuses"
}

# 使用方法表示
usage() {
    cat << EOF
使用方法: $(basename "$0") [command] [options]

コマンド:
  check <agent>     特定エージェントの状態確認
  list              全エージェントの状態一覧
  wait <agent>      エージェントのREADY待機
  wait-all          全エージェントのREADY待機
  reset <agent>     特定エージェントの状態リセット
  reset-all         全エージェントの状態リセット
  help              このヘルプを表示

オプション:
  --timeout <秒>    待機タイムアウト (デフォルト: ${DEFAULT_TIMEOUT}秒)

例:
  $(basename "$0") check boss1
  $(basename "$0") list
  $(basename "$0") wait architect --timeout 60
  $(basename "$0") wait-all
  $(basename "$0") reset worker1
EOF
}

# メイン処理
main() {
    # ディレクトリ作成
    mkdir -p "$STATUS_DIR" "$(dirname "$LOG_FILE")"
    
    # コマンド解析
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        check)
            if [[ -z "${1:-}" ]]; then
                echo -e "${RED}エラー: エージェント名を指定してください${NC}"
                usage
                exit 1
            fi
            check_agent "$1"
            ;;
            
        list)
            list_all
            ;;
            
        wait)
            if [[ -z "${1:-}" ]]; then
                echo -e "${RED}エラー: エージェント名を指定してください${NC}"
                usage
                exit 1
            fi
            local agent="$1"
            shift
            local timeout="$DEFAULT_TIMEOUT"
            if [[ "${1:-}" == "--timeout" ]] && [[ -n "${2:-}" ]]; then
                timeout="$2"
            fi
            wait_for_agent "$agent" "$timeout"
            ;;
            
        wait-all)
            local timeout="$DEFAULT_TIMEOUT"
            if [[ "${1:-}" == "--timeout" ]] && [[ -n "${2:-}" ]]; then
                timeout="$2"
            fi
            wait_for_all "$timeout"
            ;;
            
        reset)
            if [[ -z "${1:-}" ]]; then
                echo -e "${RED}エラー: エージェント名を指定してください${NC}"
                usage
                exit 1
            fi
            reset_agent "$1"
            ;;
            
        reset-all)
            reset_all
            ;;
            
        help|--help|-h)
            usage
            exit 0
            ;;
            
        *)
            echo -e "${RED}エラー: 不明なコマンド '${command}'${NC}"
            usage
            exit 1
            ;;
    esac
}

# メイン処理実行
main "$@"