#!/bin/bash

# =============================================================================
# Claude Code ログイン状態確認・タイミング制御システム
# worker2 実装分担: 動的待機ロジック、エラーハンドリング機能
# =============================================================================

set -e

# ログ関数
log_timing() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TIMING] $1" >&2
}

log_error_timing() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

# =============================================================================
# 動的待機ロジック実装
# =============================================================================

# Claude Codeのログイン状態を確認する関数
check_claude_login_status() {
    local pane_id="$1"
    local max_wait_seconds="${2:-60}"
    local check_interval="${3:-2}"
    
    log_timing "Claude Codeのログイン状態確認を開始 (ペイン: $pane_id)"
    log_timing "最大待機時間: ${max_wait_seconds}秒, チェック間隔: ${check_interval}秒"
    
    local elapsed=0
    local login_detected=false
    local ready_detected=false
    
    while [ $elapsed -lt $max_wait_seconds ]; do
        # tmux pane-captureでペインの内容を取得
        local pane_content
        if ! pane_content=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null); then
            log_error_timing "ペイン $pane_id の内容取得に失敗"
            return 1
        fi
        
        # ログインプロンプトの検出パターン
        if echo "$pane_content" | grep -q -E "(login|sign in|authenticate|Enter your email)" && [ "$login_detected" = false ]; then
            log_timing "ログインプロンプトを検出しました"
            login_detected=true
        fi
        
        # Claude Codeの準備完了を示すパターン
        if echo "$pane_content" | grep -q -E "(Welcome|Ready|claude>|\$ |# |>)" && [ "$login_detected" = true ]; then
            log_timing "Claude Codeの準備完了を検出しました"
            ready_detected=true
            break
        fi
        
        # ログインなしで直接準備完了している場合
        if echo "$pane_content" | grep -q -E "(claude>|\$ |# |>)" && [ "$login_detected" = false ]; then
            log_timing "Claude Codeは既にログイン済みまたはログイン不要状態です"
            ready_detected=true
            break
        fi
        
        # エラー状態の検出
        if echo "$pane_content" | grep -q -E "(Error|Failed|Connection failed|Authentication failed)"; then
            log_error_timing "Claude Codeでエラーが検出されました"
            echo "$pane_content" | tail -5 >&2
            return 2
        fi
        
        log_timing "待機中... (経過時間: ${elapsed}秒)"
        sleep "$check_interval"
        elapsed=$((elapsed + check_interval))
    done
    
    if [ "$ready_detected" = true ]; then
        log_timing "Claude Codeの準備完了を確認しました (所要時間: ${elapsed}秒)"
        return 0
    else
        log_error_timing "タイムアウト: Claude Codeの準備完了を確認できませんでした (${elapsed}秒経過)"
        return 3
    fi
}

# =============================================================================
# エラーハンドリング機能実装
# =============================================================================

# リトライ機能付きの待機関数
wait_for_claude_with_retry() {
    local pane_id="$1"
    local max_retries="${2:-3}"
    local retry_interval="${3:-10}"
    
    log_timing "リトライ機能付き待機を開始 (最大リトライ: $max_retries 回)"
    
    for ((i=1; i<=max_retries; i++)); do
        log_timing "試行 $i/$max_retries"
        
        if check_claude_login_status "$pane_id" 300 2; then
            log_timing "Claude Codeの準備完了を確認しました"
            return 0
        else
            local exit_code=$?
            case $exit_code in
                1)
                    log_error_timing "ペイン取得エラー (試行 $i/$max_retries)"
                    ;;
                2)
                    log_error_timing "Claude Codeでエラー発生 (試行 $i/$max_retries)"
                    ;;
                3)
                    log_error_timing "タイムアウト (試行 $i/$max_retries)"
                    ;;
            esac
            
            if [ $i -lt $max_retries ]; then
                log_timing "リトライまで ${retry_interval}秒待機します"
                sleep "$retry_interval"
                
                # Claude Codeの再起動を試行
                log_timing "Claude Codeの再起動を試行します"
                tmux send-keys -t "$pane_id" C-c
                sleep 2
                tmux send-keys -t "$pane_id" "claude" C-m
                sleep 3
            fi
        fi
    done
    
    log_error_timing "全てのリトライが失敗しました"
    return 1
}

# =============================================================================
# システム統合用の包括的制御関数
# =============================================================================

# multi-claudeスクリプトから呼び出される統合関数
wait_for_all_agents_ready() {
    local agents=("0.0" "0.1" "0.2" "0.3" "0.4" "0.5")
    local agent_names=("boss1" "worker1" "architect" "worker2" "qa" "worker3")
    local failed_agents=()
    
    log_timing "全エージェントの準備完了を待機します"
    
    for i in "${!agents[@]}"; do
        local pane_id="multiagent:${agents[$i]}"
        local agent_name="${agent_names[$i]}"
        
        log_timing "エージェント $agent_name (ペイン: $pane_id) の準備を確認中..."
        
        if ! wait_for_claude_with_retry "$pane_id" 2 5; then
            log_error_timing "エージェント $agent_name の準備に失敗しました"
            failed_agents+=("$agent_name")
        else
            log_timing "エージェント $agent_name の準備完了"
        fi
    done
    
    if [ ${#failed_agents[@]} -eq 0 ]; then
        log_timing "全エージェントの準備が完了しました"
        return 0
    else
        log_error_timing "準備に失敗したエージェント: ${failed_agents[*]}"
        return 1
    fi
}

# =============================================================================
# デバッグ・診断関数
# =============================================================================

# ペイン状態の診断情報を出力
diagnose_pane_status() {
    local pane_id="$1"
    
    log_timing "ペイン $pane_id の診断情報:"
    
    # ペインの存在確認
    if ! tmux list-panes -t "$pane_id" >/dev/null 2>&1; then
        log_error_timing "ペイン $pane_id が存在しません"
        return 1
    fi
    
    # ペインの基本情報
    tmux list-panes -t "$pane_id" -F "#{pane_id}: #{pane_width}x#{pane_height} #{pane_current_command}" 2>/dev/null || true
    
    # ペインの最新内容
    log_timing "ペインの最新内容 (最後の10行):"
    tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -10 || true
}

# =============================================================================
# メイン実行部分 (テスト用)
# =============================================================================

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # スクリプトが直接実行された場合のテスト実行
    
    if [ $# -eq 0 ]; then
        echo "使用方法:"
        echo "  $0 check <pane_id>           # 単一ペインの状態確認"
        echo "  $0 wait <pane_id>            # 単一ペインの準備完了待機"
        echo "  $0 wait-all                  # 全エージェントの準備完了待機"
        echo "  $0 diagnose <pane_id>        # ペイン状態の診断"
        exit 1
    fi
    
    case "$1" in
        "check")
            if [ -z "$2" ]; then
                echo "エラー: ペインIDを指定してください"
                exit 1
            fi
            check_claude_login_status "$2"
            ;;
        "wait")
            if [ -z "$2" ]; then
                echo "エラー: ペインIDを指定してください"
                exit 1
            fi
            wait_for_claude_with_retry "$2"
            ;;
        "wait-all")
            wait_for_all_agents_ready
            ;;
        "diagnose")
            if [ -z "$2" ]; then
                echo "エラー: ペインIDを指定してください"
                exit 1
            fi
            diagnose_pane_status "$2"
            ;;
        *)
            echo "エラー: 不明なコマンド '$1'"
            exit 1
            ;;
    esac
fi