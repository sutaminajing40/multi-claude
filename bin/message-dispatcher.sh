#!/bin/bash

# 🚀 初期メッセージ配信システム
# 全エージェントのREADY確認と初期メッセージの確実な配信を管理

# 設定
MULTI_CLAUDE_LOCAL="${MULTI_CLAUDE_LOCAL:-$HOME/.multi-claude}"
STATUS_DIR="$MULTI_CLAUDE_LOCAL/session/runtime/agent_status"
QUEUE_DIR="$MULTI_CLAUDE_LOCAL/session/runtime/message_queue"
LOG_FILE="$MULTI_CLAUDE_LOCAL/session/logs/dispatcher.log"
TIMEOUT=300  # 5分のタイムアウト

# ログ関数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# ディレクトリ初期化
init_directories() {
    mkdir -p "$STATUS_DIR" "$QUEUE_DIR" "$(dirname "$LOG_FILE")"
    log "INFO" "ディレクトリを初期化しました"
}

# エージェントのステータスを更新
update_agent_status() {
    local agent_name="$1"
    local status="$2"  # STARTING, READY, ACTIVE
    local status_file="$STATUS_DIR/${agent_name}.status"
    
    echo "$status" > "$status_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_DIR/${agent_name}.timestamp"
    log "INFO" "$agent_name のステータスを $status に更新"
}

# エージェントのステータスを確認
check_agent_status() {
    local agent_name="$1"
    local status_file="$STATUS_DIR/${agent_name}.status"
    
    if [ -f "$status_file" ]; then
        cat "$status_file"
    else
        echo "UNKNOWN"
    fi
}

# 全エージェントのREADY確認
wait_for_all_agents_ready() {
    local agents=("president" "boss1" "worker1" "architect" "worker2" "qa" "worker3")
    local start_time=$(date +%s)
    local all_ready=false
    
    log "INFO" "全エージェントのREADY待機を開始"
    
    while [ "$all_ready" != "true" ]; do
        all_ready=true
        local ready_count=0
        
        for agent in "${agents[@]}"; do
            local status=$(check_agent_status "$agent")
            
            if [ "$status" == "READY" ] || [ "$status" == "ACTIVE" ]; then
                ((ready_count++))
            else
                all_ready=false
            fi
        done
        
        # 進捗表示
        echo -ne "\r⏳ エージェント準備状況: $ready_count/${#agents[@]}"
        
        # 全員準備完了
        if [ "$all_ready" == "true" ]; then
            echo ""
            log "INFO" "全エージェントの準備が完了しました"
            return 0
        fi
        
        # タイムアウトチェック
        local current_time=$(date +%s)
        if (( current_time - start_time > TIMEOUT )); then
            echo ""
            log "ERROR" "タイムアウト: 全エージェントの準備が完了しませんでした"
            return 1
        fi
        
        sleep 2
    done
}

# メッセージをキューに追加
queue_message() {
    local agent="$1"
    local message="$2"
    local priority="${3:-normal}"  # high, normal, low
    
    local queue_file="$QUEUE_DIR/${agent}_$(date +%s%N).msg"
    
    cat > "$queue_file" << EOF
AGENT=$agent
MESSAGE=$message
PRIORITY=$priority
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
STATUS=pending
EOF
    
    log "INFO" "$agent へのメッセージをキューに追加: $message"
}

# キューからメッセージを配信
process_message_queue() {
    local processed=0
    local failed=0
    
    # 優先度順にメッセージを処理
    for priority in "high" "normal" "low"; do
        for queue_file in $(ls -t "$QUEUE_DIR"/*.msg 2>/dev/null | xargs grep -l "PRIORITY=$priority" 2>/dev/null); do
            if [ ! -f "$queue_file" ]; then
                continue
            fi
            
            # メッセージ情報を読み込み
            source "$queue_file"
            
            if [ "$STATUS" == "delivered" ]; then
                continue
            fi
            
            # エージェントの準備確認
            local agent_status=$(check_agent_status "$AGENT")
            if [ "$agent_status" != "READY" ] && [ "$agent_status" != "ACTIVE" ]; then
                log "WARN" "$AGENT はまだ準備できていません (status: $agent_status)"
                continue
            fi
            
            # メッセージ送信
            log "INFO" "$AGENT にメッセージを送信中: $MESSAGE"
            
            # agent-send.shの場所を確認
            local agent_send_script
            if [ -f "$MULTI_CLAUDE_LOCAL/bin/agent-send.sh" ]; then
                agent_send_script="$MULTI_CLAUDE_LOCAL/bin/agent-send.sh"
            elif [ -f "./agent-send.sh" ]; then
                agent_send_script="./agent-send.sh"
            else
                agent_send_script="agent-send.sh"
            fi
            
            if "$agent_send_script" "$AGENT" "$MESSAGE"; then
                # 配信成功
                sed -i '' "s/STATUS=pending/STATUS=delivered/" "$queue_file" 2>/dev/null || \
                sed -i "s/STATUS=pending/STATUS=delivered/" "$queue_file"
                ((processed++))
                log "INFO" "$AGENT へのメッセージ配信成功"
                
                # エージェントステータスをACTIVEに更新
                update_agent_status "$AGENT" "ACTIVE"
            else
                # 配信失敗
                ((failed++))
                log "ERROR" "$AGENT へのメッセージ配信失敗"
            fi
            
            sleep 1
        done
    done
    
    log "INFO" "メッセージキュー処理完了: 成功=$processed, 失敗=$failed"
    return $([ $failed -eq 0 ] && echo 0 || echo 1)
}

# 初期メッセージの準備
prepare_initial_messages() {
    log "INFO" "初期メッセージを準備中"
    
    # PRESIDENTへのメッセージ
    queue_message "president" "あなたはPRESIDENTです。CLAUDE.mdと\$MULTI_CLAUDE_LOCAL/instructions/president_dynamic.mdを読み込んで、指示に従って行動してください。" "high"
    
    # BOSS1へのメッセージ
    queue_message "boss1" "あなたはboss1です。CLAUDE.mdと\$MULTI_CLAUDE_LOCAL/instructions/boss_dynamic.mdを読み込んで、指示に従って行動してください。" "high"
    
    # 各WORKERへのメッセージ
    for i in 1 2 3; do
        queue_message "worker$i" "あなたはworker${i}です。CLAUDE.mdと\$MULTI_CLAUDE_LOCAL/instructions/worker_dynamic.mdを読み込んで、指示に従って行動してください。" "normal"
    done
    
    # ARCHITECTへのメッセージ
    queue_message "architect" "あなたはarchitectです。CLAUDE.mdと\$MULTI_CLAUDE_LOCAL/instructions/architect_dynamic.mdを読み込んで、指示に従って行動してください。" "normal"
    
    # QAへのメッセージ
    queue_message "qa" "あなたはqaです。CLAUDE.mdと\$MULTI_CLAUDE_LOCAL/instructions/qa_dynamic.mdを読み込んで、指示に従って行動してください。" "normal"
}

# メイン処理
main() {
    local mode="${1:-dispatch}"  # dispatch, wait, status
    
    case "$mode" in
        "dispatch")
            log "INFO" "メッセージ配信システムを開始"
            init_directories
            
            # 全エージェントの準備を待機
            if wait_for_all_agents_ready; then
                # 初期メッセージを準備
                prepare_initial_messages
                
                # メッセージキューを処理
                process_message_queue
                
                log "INFO" "メッセージ配信システム完了"
                return 0
            else
                log "ERROR" "エージェントの準備待機でタイムアウト"
                return 1
            fi
            ;;
            
        "wait")
            # 全エージェントの準備を待機するだけ
            init_directories
            wait_for_all_agents_ready
            ;;
            
        "status")
            # 現在のステータスを表示
            echo "📊 エージェントステータス:"
            echo "=========================="
            for agent in president boss1 worker1 architect worker2 qa worker3; do
                local status=$(check_agent_status "$agent")
                printf "%-12s: %s\n" "$agent" "$status"
            done
            ;;
            
        *)
            echo "使用方法: $0 [dispatch|wait|status]"
            exit 1
            ;;
    esac
}

# スクリプト実行
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi