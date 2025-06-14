#!/bin/bash

# 役割判定システム - コア機能
# 設計書: docs/role-detection-system-design.md
# テスト仕様書: docs/role-detection-test-specification.md

# 定数定義
VALID_ROLES=("president" "boss1" "worker1" "worker2" "worker3")

# 役割が有効かチェック
is_valid_role() {
    local role="$1"
    for valid_role in "${VALID_ROLES[@]}"; do
        if [[ "$role" == "$valid_role" ]]; then
            return 0
        fi
    done
    return 1
}

# セッションIDを取得
get_session_id() {
    if [[ -n "$MULTI_CLAUDE_SESSION_ID" ]]; then
        echo "$MULTI_CLAUDE_SESSION_ID"
    else
        # tmuxセッションからIDを生成
        local session_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")
        if [[ -n "$session_name" ]]; then
            echo "session-${session_name}-$$"
        else
            echo "session-test"
        fi
    fi
}

# 役割ファイルから読み取り
read_role_file() {
    local session_id=$(get_session_id)
    local role_file=".multi-claude/runtime/${session_id}/my-role"
    
    if [[ -f "$role_file" ]] && [[ -s "$role_file" ]]; then
        cat "$role_file" | tr -d '\n'
    else
        echo ""
    fi
}

# tmuxペインタイトルを取得（モック対応）
get_tmux_pane_title() {
    if [[ -n "$MOCK_TMUX_PANE_TITLE" ]]; then
        echo "$MOCK_TMUX_PANE_TITLE"
    else
        tmux display-message -p '#{pane_title}' 2>/dev/null || echo ""
    fi
}

# tmuxセッション情報から役割を判定
get_role_from_session() {
    local session pane_index
    
    if [[ -n "$MOCK_TMUX_SESSION" ]]; then
        session="$MOCK_TMUX_SESSION"
        pane_index="$MOCK_TMUX_PANE_INDEX"
    else
        session=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")
        pane_index=$(tmux display-message -p '#{pane_index}' 2>/dev/null || echo "")
    fi
    
    # role-mapping.jsonから判定
    if [[ -f ".multi-claude/config/role-mapping.json" ]]; then
        # jqがあれば使用、なければ簡易パース
        if command -v jq &> /dev/null; then
            jq -r --arg session "$session" --arg index "$pane_index" '
                .mappings | to_entries[] | 
                select(.value.session == $session and (.value.pane_index | tostring) == $index) | 
                .key
            ' .multi-claude/config/role-mapping.json 2>/dev/null || echo ""
        else
            # 簡易パース（presidentセッションの場合）
            if [[ "$session" == "president" ]] && [[ "$pane_index" == "0" ]]; then
                echo "president"
            elif [[ "$session" == "multiagent" ]]; then
                case "$pane_index" in
                    "0") echo "boss1" ;;
                    "1") echo "worker1" ;;
                    "2") echo "worker2" ;;
                    "3") echo "worker3" ;;
                    *) echo "" ;;
                esac
            else
                echo ""
            fi
        fi
    else
        echo ""
    fi
}

# メインの役割判定関数
get_my_role() {
    local role=""
    
    # 優先順位1: 環境変数
    if [[ -n "$MULTI_CLAUDE_ROLE" ]]; then
        role="$MULTI_CLAUDE_ROLE"
        if is_valid_role "$role"; then
            echo "$role"
            return 0
        else
            echo "Invalid role: $role" >&2
            return 1
        fi
    fi
    
    # 優先順位2: 役割ファイル
    role=$(read_role_file)
    if [[ -n "$role" ]] && is_valid_role "$role"; then
        echo "$role"
        return 0
    fi
    
    # 優先順位3: tmuxペインタイトル
    role=$(get_tmux_pane_title)
    if [[ -n "$role" ]] && is_valid_role "$role"; then
        echo "$role"
        return 0
    fi
    
    # 優先順位4: tmuxセッション情報
    role=$(get_role_from_session)
    if [[ -n "$role" ]] && is_valid_role "$role"; then
        echo "$role"
        return 0
    fi
    
    # すべて失敗
    echo "Cannot determine role" >&2
    return 1
}

# ログ出力関数
log_message() {
    local level="$1"
    local message="$2"
    local log_file=".multi-claude/logs/integrity-check.log"
    
    # ログディレクトリが存在しない場合は作成
    mkdir -p "$(dirname "$log_file")"
    
    # タイムスタンプ付きでログ出力
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] [$level] $message" >> "$log_file"
}

# 整合性チェック関数
check_role_integrity() {
    local my_role_file role_from_file role_from_title
    
    # 現在の役割を各方法で取得
    role_from_file=$(read_role_file)
    role_from_title=$(get_tmux_pane_title)
    
    # 両方が有効な値を持っている場合のみチェック
    if [[ -n "$role_from_file" ]] && [[ -n "$role_from_title" ]] && \
       is_valid_role "$role_from_file" && is_valid_role "$role_from_title"; then
        
        if [[ "$role_from_file" != "$role_from_title" ]]; then
            log_message "WARN" "Role mismatch detected: file=$role_from_file, title=$role_from_title"
            return 1
        fi
    fi
    
    log_message "INFO" "Role integrity check passed"
    return 0
}

# 役割重複チェック関数
check_role_duplication() {
    local session_id=$(get_session_id)
    local runtime_dir=".multi-claude/runtime/${session_id}"
    local role timestamp
    local found_roles=""
    
    # runtime ディレクトリが存在しない場合はスキップ
    if [[ ! -d "$runtime_dir" ]]; then
        return 0
    fi
    
    # すべてのペインの役割ファイルをチェック
    for role_file in "$runtime_dir"/pane*-role; do
        if [[ -f "$role_file" ]]; then
            # 役割とタイムスタンプを読み取り
            IFS='|' read -r role timestamp < "$role_file"
            
            if is_valid_role "$role"; then
                # すでに見つかった役割かチェック
                if [[ "$found_roles" == *"|$role|"* ]]; then
                    log_message "ERROR" "Duplicate role detected: $role assigned to multiple panes"
                    return 1
                fi
                
                # 役割を記録
                found_roles="${found_roles}|${role}|"
            fi
        fi
    done
    
    log_message "INFO" "No role duplication detected"
    return 0
}

# 包括的な整合性チェック
perform_full_integrity_check() {
    local has_error=0
    
    echo "=== 役割判定システム整合性チェック ==="
    
    # 1. 役割の不一致チェック
    if ! check_role_integrity; then
        echo "⚠️  役割の不一致が検出されました"
        has_error=1
    fi
    
    # 2. 役割の重複チェック
    if ! check_role_duplication; then
        echo "⚠️  役割の重複が検出されました"
        has_error=1
    fi
    
    # 3. セッション構造チェック
    if ! tmux has-session -t multiagent 2>/dev/null && ! tmux has-session -t president 2>/dev/null; then
        echo "⚠️  必要なtmuxセッションが見つかりません"
        log_message "ERROR" "Required tmux sessions not found"
        has_error=1
    fi
    
    if [[ $has_error -eq 0 ]]; then
        echo "✅ すべての整合性チェックに合格しました"
        return 0
    else
        echo "❌ 整合性チェックで問題が検出されました"
        return 1
    fi
}