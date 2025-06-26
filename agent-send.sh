#!/bin/bash

# 🚀 Agent間メッセージ送信スクリプト

# エージェント→tmuxターゲット マッピング
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

show_usage() {
    cat << EOF
🤖 Agent間メッセージ送信

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list

利用可能エージェント:
  president - プロジェクト統括責任者
  boss1     - チームリーダー  
  worker1   - 実装担当者1
  architect - 設計・アーキテクチャ担当
  worker2   - 実装担当者2
  qa        - 品質保証・テスト担当
  worker3   - 実装担当者3（統合・デバッグ）

使用例:
  $0 president "指示書に従って"
  $0 boss1 "Hello World プロジェクト開始指示"
  $0 worker1 "作業完了しました"
EOF
}

# エージェント一覧表示
show_agents() {
    echo "📋 利用可能なエージェント:"
    echo "=========================="
    echo "  president → president:0     (プロジェクト統括責任者)"
    echo "  boss1     → multiagent:0.0  (チームリーダー)"
    echo "  worker1   → multiagent:0.1  (実装担当者1)"
    echo "  architect → multiagent:0.2  (設計・アーキテクチャ担当)"
    echo "  worker2   → multiagent:0.3  (実装担当者2)" 
    echo "  qa        → multiagent:0.4  (品質保証・テスト担当)"
    echo "  worker3   → multiagent:0.5  (実装担当者3・統合)"
}

# ログ記録
log_send() {
    local agent="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$MULTI_CLAUDE_LOCAL/session/logs"
    echo "[$timestamp] $agent: SENT - \"$message\"" >> "$MULTI_CLAUDE_LOCAL/session/logs/send_log.txt"
}

# メッセージ送信（改良版：確実なEnterキー送信）
send_message() {
    local target="$1"
    local message="$2"
    local retry_count=0
    local max_retries=3
    
    echo "📤 送信中: $target ← '$message'"
    
    # Claude Codeのプロンプトを一度クリア
    tmux send-keys -t "$target" C-c
    sleep 0.3
    
    # メッセージ送信
    tmux send-keys -t "$target" "$message"
    sleep 0.2
    
    # Enterキー送信（リトライ機能付き）
    while [ $retry_count -lt $max_retries ]; do
        # 複数の方法でEnterキーを送信
        tmux send-keys -t "$target" Enter
        sleep 0.1
        tmux send-keys -t "$target" C-m
        sleep 0.5
        
        # メッセージが処理されたか簡易確認
        if [ $retry_count -eq 0 ]; then
            # 初回は確実に送信
            break
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "⚠️  Enterキー送信をリトライ中... ($retry_count/$max_retries)"
            sleep 1
        fi
    done
    
    if [ $retry_count -eq $max_retries ]; then
        echo "⚠️  警告: Enterキー送信が不完全な可能性があります"
        log_send "system" "Enter key send may have failed for $target"
    fi
}

# ワーカーID記録
record_worker_id() {
    local agent_name="$1"
    
    # ワーカーIDディレクトリ作成
    mkdir -p "$MULTI_CLAUDE_LOCAL/tmp/worker_ids"
    
    # ワーカーに送信する際、番号をファイルに記録
    case "$agent_name" in
        "worker1") 
            echo "1" > "$MULTI_CLAUDE_LOCAL/tmp/worker_ids/current_worker.id"
            log_send "system" "worker1のIDを記録: 1"
            ;;
        "worker2") 
            echo "2" > "$MULTI_CLAUDE_LOCAL/tmp/worker_ids/current_worker.id"
            log_send "system" "worker2のIDを記録: 2"
            ;;
        "worker3") 
            echo "3" > "$MULTI_CLAUDE_LOCAL/tmp/worker_ids/current_worker.id"
            log_send "system" "worker3のIDを記録: 3"
            ;;
    esac
}

# ターゲット存在確認
check_target() {
    local target="$1"
    local session_name="${target%%:*}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "❌ セッション '$session_name' が見つかりません"
        return 1
    fi
    
    return 0
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    # --listオプション
    if [[ "$1" == "--list" ]]; then
        show_agents
        exit 0
    fi
    
    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi
    
    local agent_name="$1"
    local message="$2"
    
    # エージェントターゲット取得
    local target
    target=$(get_agent_target "$agent_name")
    
    if [[ -z "$target" ]]; then
        echo "❌ エラー: 不明なエージェント '$agent_name'"
        echo "利用可能エージェント: $0 --list"
        exit 1
    fi
    
    # ターゲット確認
    if ! check_target "$target"; then
        exit 1
    fi
    
    # ワーカーID記録（worker1,2,3の場合）
    record_worker_id "$agent_name"
    
    # メッセージ送信
    send_message "$target" "$message"
    
    # ログ記録
    log_send "$agent_name" "$message"
    
    echo "✅ 送信完了: $agent_name に '$message'"
    
    return 0
}

main "$@" 