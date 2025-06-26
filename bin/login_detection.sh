#!/bin/bash
# Claude Code ログイン状態検出機能
# worker1担当部分: ログイン検出ロジック

# ログイン完了を示すパターン
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

# ログインが必要なことを示すパターン
LOGIN_REQUIRED_PATTERNS=(
    "login"
    "sign in"
    "authenticate"
    "Please log in"
    "Authentication required"
    "Enter your credentials"
)

# tmuxペインのキャプチャからログイン状態を検出
detect_login_status() {
    local pane_id="$1"
    local timeout="${2:-60}"
    local start_time=$(date +%s)
    
    while true; do
        # ペインの内容をキャプチャ（最新20行）
        local pane_content=$(tmux capture-pane -t "$pane_id" -p -S -20)
        
        # ログイン完了パターンをチェック
        for pattern in "${LOGIN_COMPLETE_PATTERNS[@]}"; do
            if echo "$pane_content" | grep -qi "$pattern"; then
                echo "LOGIN_COMPLETE"
                return 0
            fi
        done
        
        # ログイン要求パターンをチェック
        for pattern in "${LOGIN_REQUIRED_PATTERNS[@]}"; do
            if echo "$pane_content" | grep -qi "$pattern"; then
                echo "LOGIN_REQUIRED"
                return 1
            fi
        done
        
        # タイムアウトチェック
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        if [ $elapsed -ge $timeout ]; then
            echo "TIMEOUT"
            return 2
        fi
        
        # 1秒待機して再チェック
        sleep 1
    done
}

# デバッグ用: ペイン内容を表示
debug_pane_content() {
    local pane_id="$1"
    echo "=== Pane Content Debug ==="
    tmux capture-pane -t "$pane_id" -p -S -30
    echo "========================="
}

# エクスポートして他のスクリプトから使用可能に
export -f detect_login_status
export -f debug_pane_content

# テスト実行（このスクリプトが直接実行された場合）
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "Claude Code ログイン検出機能テスト"
    
    if [ -z "$1" ]; then
        echo "使用方法: $0 <tmux_pane_id>"
        echo "例: $0 multiagent:0.0"
        exit 1
    fi
    
    echo "検出中... (pane: $1)"
    status=$(detect_login_status "$1" 30)
    echo "検出結果: $status"
    
    if [ "$2" == "--debug" ]; then
        debug_pane_content "$1"
    fi
fi