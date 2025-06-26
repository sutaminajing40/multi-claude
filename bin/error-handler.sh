#!/bin/bash

# 🚨 エラーハンドリング・復旧システム
# multi-claude起動時のエラー検出と自動復旧

# カラー設定
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ関数
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$MULTI_CLAUDE_LOCAL/session/logs/error.log"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$MULTI_CLAUDE_LOCAL/session/logs/error.log"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$MULTI_CLAUDE_LOCAL/session/logs/error.log"
}

# エラー情報の記録
record_error() {
    local error_type="$1"
    local error_msg="$2"
    local agent="${3:-system}"
    
    local error_file="$MULTI_CLAUDE_LOCAL/session/runtime/errors/${agent}_errors.json"
    mkdir -p "$MULTI_CLAUDE_LOCAL/session/runtime/errors"
    
    jq -n \
        --arg type "$error_type" \
        --arg msg "$error_msg" \
        --arg agent "$agent" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            type: $type,
            message: $msg,
            agent: $agent,
            timestamp: $ts,
            resolved: false
        }' >> "$error_file"
}

# エラータイプの定義
ERROR_TMUX_SESSION_EXISTS="TMUX_SESSION_EXISTS"
ERROR_CLAUDE_CODE_LAUNCH="CLAUDE_CODE_LAUNCH"
ERROR_AGENT_TIMEOUT="AGENT_TIMEOUT"
ERROR_MESSAGE_DELIVERY="MESSAGE_DELIVERY"
ERROR_LOGIN_REQUIRED="LOGIN_REQUIRED"
ERROR_PERMISSION_DENIED="PERMISSION_DENIED"
ERROR_DEPENDENCY_MISSING="DEPENDENCY_MISSING"

# エラー検出関数
detect_tmux_session_conflict() {
    if tmux has-session -t multiagent 2>/dev/null || tmux has-session -t president 2>/dev/null; then
        return 0  # 競合あり
    fi
    return 1  # 競合なし
}

detect_claude_code_failure() {
    local agent="$1"
    local pane_content=$(tmux capture-pane -t "$agent" -p 2>/dev/null)
    
    # エラーパターンの検出
    if echo "$pane_content" | grep -q "command not found"; then
        return 0
    fi
    
    if echo "$pane_content" | grep -q "Permission denied"; then
        return 0
    fi
    
    return 1
}

detect_login_required() {
    local agent="$1"
    local pane_content=$(tmux capture-pane -t "$agent" -p 2>/dev/null)
    
    if echo "$pane_content" | grep -q "Please log in"; then
        return 0
    fi
    
    return 1
}

# 復旧アクション
recover_tmux_session_conflict() {
    log_warning "既存のtmuxセッションを検出しました"
    
    echo -e "${YELLOW}既存のmulti-claudeセッションが見つかりました。${NC}"
    echo "次のオプションから選択してください:"
    echo "1) 既存のセッションに接続"
    echo "2) 既存のセッションを終了して新規作成"
    echo "3) キャンセル"
    
    read -r -p "選択 [1-3]: " choice
    
    case $choice in
        1)
            log_info "既存セッションへの接続を選択"
            tmux attach-session -t multiagent
            exit 0
            ;;
        2)
            log_info "既存セッションの終了を選択"
            tmux kill-session -t multiagent 2>/dev/null
            tmux kill-session -t president 2>/dev/null
            sleep 1
            return 0
            ;;
        3)
            log_info "キャンセルを選択"
            exit 0
            ;;
        *)
            log_error "無効な選択"
            exit 1
            ;;
    esac
}

recover_claude_code_failure() {
    local agent="$1"
    
    log_warning "Claude Code起動エラーを検出: $agent"
    record_error "$ERROR_CLAUDE_CODE_LAUNCH" "Claude Code launch failed" "$agent"
    
    # claude-codeコマンドの存在確認
    if ! command -v claude-code &> /dev/null; then
        log_error "claude-codeコマンドが見つかりません"
        echo -e "${RED}claude-codeがインストールされていません。${NC}"
        echo "インストール方法: https://claude.ai/code"
        return 1
    fi
    
    # 再起動を試行
    log_info "Claude Code再起動を試行: $agent"
    tmux send-keys -t "$agent" C-c
    sleep 1
    tmux send-keys -t "$agent" "claude-code -m sonnet" Enter
    
    return 0
}

recover_login_required() {
    local agent="$1"
    
    log_warning "ログインが必要です: $agent"
    record_error "$ERROR_LOGIN_REQUIRED" "Login required" "$agent"
    
    echo -e "${YELLOW}Claude Codeへのログインが必要です。${NC}"
    echo "ブラウザでログイン処理を完了してください。"
    
    # ログイン検知待機
    if [ -x "$MULTI_CLAUDE_LOCAL/../timing_control.sh" ]; then
        "$MULTI_CLAUDE_LOCAL/../timing_control.sh" wait_for_login "$agent"
    fi
    
    return 0
}

# システム全体のヘルスチェック
system_health_check() {
    local agents=("president" "boss1" "worker1" "architect" "worker2" "qa" "worker3")
    local unhealthy_agents=()
    local recovery_needed=false
    
    log_info "システムヘルスチェックを開始"
    
    # 各エージェントのチェック
    for agent in "${agents[@]}"; do
        local target=$(get_agent_target "$agent")
        
        if [ -z "$target" ]; then
            continue
        fi
        
        # Claude Code起動失敗チェック
        if detect_claude_code_failure "$target"; then
            unhealthy_agents+=("$agent")
            recovery_needed=true
            recover_claude_code_failure "$target"
        fi
        
        # ログイン必要チェック
        if detect_login_required "$target"; then
            unhealthy_agents+=("$agent")
            recovery_needed=true
            recover_login_required "$target"
        fi
    done
    
    if [ ${#unhealthy_agents[@]} -gt 0 ]; then
        log_warning "問題のあるエージェント: ${unhealthy_agents[*]}"
        return 1
    fi
    
    log_info "✅ システムヘルスチェック完了 - 全て正常"
    return 0
}

# エージェントマッピング
get_agent_target() {
    case "$1" in
        "president") echo "president" ;;
        "boss1") echo "multiagent:0.0" ;;
        "worker1") echo "multiagent:0.1" ;;
        "architect") echo "multiagent:0.2" ;;
        "worker2") echo "multiagent:0.3" ;;
        "qa") echo "multiagent:0.4" ;;
        "worker3") echo "multiagent:0.5" ;;
        *) echo "" ;;
    esac
}

# 自動復旧プロセス
auto_recovery() {
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        log_info "自動復旧試行 $((retry_count + 1))/$max_retries"
        
        if system_health_check; then
            log_info "✅ システムが正常に復旧しました"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            log_info "30秒後に再試行します..."
            sleep 30
        fi
    done
    
    log_error "自動復旧に失敗しました"
    return 1
}

# エラーレポート生成
generate_error_report() {
    local report_file="$MULTI_CLAUDE_LOCAL/session/logs/error_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# エラーレポート

生成日時: $(date)

## サマリー

### エラー統計
EOF
    
    # エラー集計
    local error_count=0
    for error_file in "$MULTI_CLAUDE_LOCAL/session/runtime/errors"/*.json; do
        if [ -f "$error_file" ]; then
            local count=$(jq -s 'length' "$error_file" 2>/dev/null || echo 0)
            error_count=$((error_count + count))
            
            local agent=$(basename "$error_file" | sed 's/_errors.json//')
            echo "- $agent: $count件" >> "$report_file"
        fi
    done
    
    echo -e "\n合計エラー数: $error_count件\n" >> "$report_file"
    
    # エラー詳細
    echo "## エラー詳細" >> "$report_file"
    
    for error_file in "$MULTI_CLAUDE_LOCAL/session/runtime/errors"/*.json; do
        if [ -f "$error_file" ]; then
            echo -e "\n### $(basename "$error_file" | sed 's/_errors.json//')" >> "$report_file"
            jq -r '.[] | "- [\(.timestamp)] \(.type): \(.message)"' "$error_file" >> "$report_file" 2>/dev/null
        fi
    done
    
    echo -e "\n---\n*このレポートは自動生成されました*" >> "$report_file"
    
    log_info "エラーレポートを生成しました: $report_file"
    echo "$report_file"
}

# 使用法表示
show_usage() {
    cat << EOF
🚨 エラーハンドリング・復旧システム

使用方法:
  $0 [コマンド]

コマンド:
  check           システムヘルスチェックを実行
  recover         自動復旧プロセスを開始
  report          エラーレポートを生成
  clear           エラーログをクリア
  help            このヘルプを表示

例:
  $0 check
  $0 recover
  $0 report
EOF
}

# エラーログクリア
clear_error_logs() {
    log_info "エラーログをクリアします"
    
    rm -f "$MULTI_CLAUDE_LOCAL/session/runtime/errors"/*.json
    > "$MULTI_CLAUDE_LOCAL/session/logs/error.log"
    
    log_info "✅ エラーログをクリアしました"
}

# メイン処理
main() {
    # 環境確認
    if [ -z "$MULTI_CLAUDE_LOCAL" ]; then
        echo "エラー: MULTI_CLAUDE_LOCAL環境変数が設定されていません" >&2
        exit 1
    fi
    
    mkdir -p "$MULTI_CLAUDE_LOCAL/session/logs"
    mkdir -p "$MULTI_CLAUDE_LOCAL/session/runtime/errors"
    
    case "${1:-check}" in
        "check")
            system_health_check
            ;;
        "recover")
            auto_recovery
            ;;
        "report")
            generate_error_report
            ;;
        "clear")
            clear_error_logs
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            echo "不明なコマンド: $1" >&2
            show_usage
            exit 1
            ;;
    esac
}

# エラートラップ設定
trap 'log_error "スクリプトが異常終了しました: $?"' ERR

main "$@"