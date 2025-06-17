#!/bin/bash

# 👷 ワーカー側簡素化報告システム
# 個別完了報告のみ（他のワーカー状況確認不要・ファイル作成依存削除）

# 設定
CONTEXT_DIR=".multi-claude/context"
PROGRESS_FILE_PREFIX="$CONTEXT_DIR/worker"
LOG_FILE="$CONTEXT_DIR/worker_reporter.log"

# ワーカー番号の自動判定
detect_worker_id() {
    local worker_id=""
    
    # 方法1: TMUXペインから判定
    if [ -n "$TMUX_PANE" ]; then
        local session_info=$(tmux list-panes -F "#{session_name}:#{pane_index} #{pane_id}" 2>/dev/null || echo "")
        local session_and_pane=$(echo "$session_info" | grep "$TMUX_PANE" | awk '{print $1}' || echo "")
        
        case "$session_and_pane" in
            "multiagent:1") worker_id=1 ;;
            "multiagent:2") worker_id=2 ;;
            "multiagent:3") worker_id=3 ;;
        esac
    fi
    
    # 方法2: IDファイルから読み込み
    if [ -z "$worker_id" ] && [ -f .multi-claude/tmp/worker_ids/current_worker.id ]; then
        worker_id=$(cat .multi-claude/tmp/worker_ids/current_worker.id 2>/dev/null)
    fi
    
    # 方法3: 環境変数
    if [ -z "$worker_id" ] && [ -n "$WORKER_ID" ]; then
        worker_id="$WORKER_ID"
    fi
    
    echo "$worker_id"
}

# 進捗記録システム
record_progress() {
    local worker_id=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local progress_file="${PROGRESS_FILE_PREFIX}${worker_id}_progress.md"
    
    mkdir -p "$CONTEXT_DIR"
    
    # 進捗記録
    if [ ! -f "$progress_file" ]; then
        cat > "$progress_file" << EOF
# Worker${worker_id} 進捗レポート

## 開始時刻
$timestamp

## 作業履歴
EOF
    fi
    
    echo "- [$timestamp] $message" >> "$progress_file"
    echo "[$timestamp] worker${worker_id}: $message" >> "$LOG_FILE"
}

# 作業開始の記録
start_work() {
    local worker_id=$1
    local task_description=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    record_progress "$worker_id" "作業開始: $task_description"
    
    # 作業開始をボスに通知
    if command -v ./agent-send.sh >/dev/null 2>&1; then
        ./agent-send.sh boss1 "worker${worker_id}: 作業を開始しました - $task_description"
    fi
    
    echo "worker${worker_id}: 作業開始を記録しました"
}

# 進捗更新
update_progress() {
    local worker_id=$1
    local progress_message=$2
    
    record_progress "$worker_id" "進捗更新: $progress_message"
    echo "worker${worker_id}: 進捗を更新しました"
}

# 作業完了報告（新システム）
report_completion() {
    local worker_id=$1
    local completion_message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # 最終進捗記録
    record_progress "$worker_id" "作業完了: $completion_message"
    
    # 完了時刻を進捗ファイルに記録
    local progress_file="${PROGRESS_FILE_PREFIX}${worker_id}_progress.md"
    cat >> "$progress_file" << EOF

## 完了時刻
$timestamp

## 完了報告
$completion_message

## ステータス
✅ 作業完了
EOF
    
    # ボスの完了管理システムに直接報告
    if [ -f "./scripts/boss_completion_manager.sh" ]; then
        ./scripts/boss_completion_manager.sh report "$worker_id"
        local boss_result=$?
        
        case $boss_result in
            0) 
                echo "✅ worker${worker_id}: 完了報告をボスに送信しました"
                record_progress "$worker_id" "ボスへの完了報告送信完了"
                ;;
            1) 
                echo "❌ worker${worker_id}: ボスへの報告でエラーが発生しました"
                record_progress "$worker_id" "ボスへの報告エラー"
                ;;
            2) 
                echo "⚠️ worker${worker_id}: 重複報告（既に報告済み）"
                record_progress "$worker_id" "重複報告検出"
                ;;
        esac
    else
        # フォールバック: 従来のagent-send.sh
        if command -v ./agent-send.sh >/dev/null 2>&1; then
            ./agent-send.sh boss1 "worker${worker_id}: 作業が完了しました - $completion_message"
            echo "✅ worker${worker_id}: 完了報告をボスに送信しました（従来方式）"
            record_progress "$worker_id" "ボスへの完了報告送信完了（従来方式）"
        else
            echo "❌ worker${worker_id}: 報告システムが見つかりません"
            record_progress "$worker_id" "報告システム不明エラー"
        fi
    fi
}

# エラー報告
report_error() {
    local worker_id=$1
    local error_message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    record_progress "$worker_id" "❌ エラー発生: $error_message"
    
    # ボスに緊急報告
    if command -v ./agent-send.sh >/dev/null 2>&1; then
        ./agent-send.sh boss1 "🚨 worker${worker_id}: エラーが発生しました - $error_message"
    fi
    
    echo "❌ worker${worker_id}: エラーを報告しました"
}

# 現在の進捗確認
check_progress() {
    local worker_id=$1
    local progress_file="${PROGRESS_FILE_PREFIX}${worker_id}_progress.md"
    
    if [ -f "$progress_file" ]; then
        echo "=== Worker${worker_id} 進捗状況 ==="
        cat "$progress_file"
        echo ""
    else
        echo "worker${worker_id}: 進捗記録が見つかりません"
        return 1
    fi
}

# クリーンアップ（次回タスク準備）
cleanup_worker_data() {
    local worker_id=$1
    
    # 古い進捗ファイルをアーカイブ
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local progress_file="${PROGRESS_FILE_PREFIX}${worker_id}_progress.md"
    local archive_file="${PROGRESS_FILE_PREFIX}${worker_id}_progress_${timestamp}.md"
    
    if [ -f "$progress_file" ]; then
        mv "$progress_file" "$archive_file"
        echo "worker${worker_id}: 進捗ファイルをアーカイブしました ($archive_file)"
    fi
    
    # 一時ファイルクリーンアップ
    rm -f ".multi-claude/tmp/worker${worker_id}_*" 2>/dev/null
    
    echo "worker${worker_id}: クリーンアップ完了"
}

# 使用方法表示
show_usage() {
    echo "ワーカー側簡素化報告システム"
    echo ""
    echo "使用法: $0 <action> [worker_id] [message]"
    echo ""
    echo "Actions:"
    echo "  auto <action> [message]     - 自動でworker_idを判定して実行"
    echo "  start <worker_id> <task>    - 作業開始記録"
    echo "  progress <worker_id> <msg>  - 進捗更新"
    echo "  complete <worker_id> <msg>  - 作業完了報告"
    echo "  error <worker_id> <msg>     - エラー報告"
    echo "  status <worker_id>          - 進捗確認"
    echo "  cleanup <worker_id>         - データクリーンアップ"
    echo ""
    echo "自動判定の例:"
    echo "  $0 auto start \"新機能の実装\""
    echo "  $0 auto progress \"50%完了\""
    echo "  $0 auto complete \"実装とテスト完了\""
    echo "  $0 auto error \"ビルドエラーが発生\""
    echo ""
    echo "手動指定の例:"
    echo "  $0 start 1 \"ログイン機能の実装\""
    echo "  $0 progress 2 \"API設計完了\""
    echo "  $0 complete 3 \"テスト実装完了\""
}

# メイン処理
main() {
    local action=$1
    local worker_or_id=$2
    local message="$3"
    
    # ディレクトリ初期化
    mkdir -p "$CONTEXT_DIR" .multi-claude/tmp
    
    case "$action" in
        "auto")
            local auto_action="$worker_or_id"
            local auto_message="$message"
            local detected_id=$(detect_worker_id)
            
            if [ -z "$detected_id" ]; then
                echo "❌ worker_idを自動判定できませんでした"
                echo "手動で指定してください: $0 $auto_action <worker_id> \"$auto_message\""
                exit 1
            fi
            
            echo "🔍 自動判定: worker${detected_id}"
            
            case "$auto_action" in
                "start") start_work "$detected_id" "$auto_message" ;;
                "progress") update_progress "$detected_id" "$auto_message" ;;
                "complete") report_completion "$detected_id" "$auto_message" ;;
                "error") report_error "$detected_id" "$auto_message" ;;
                "status") check_progress "$detected_id" ;;
                "cleanup") cleanup_worker_data "$detected_id" ;;
                *) 
                    echo "❌ 無効な自動アクション: $auto_action"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        "start")
            if [ -z "$worker_or_id" ] || [ -z "$message" ]; then
                echo "使用法: $0 start <worker_id> <task_description>"
                exit 1
            fi
            start_work "$worker_or_id" "$message"
            ;;
        "progress")
            if [ -z "$worker_or_id" ] || [ -z "$message" ]; then
                echo "使用法: $0 progress <worker_id> <progress_message>"
                exit 1
            fi
            update_progress "$worker_or_id" "$message"
            ;;
        "complete")
            if [ -z "$worker_or_id" ] || [ -z "$message" ]; then
                echo "使用法: $0 complete <worker_id> <completion_message>"
                exit 1
            fi
            report_completion "$worker_or_id" "$message"
            ;;
        "error")
            if [ -z "$worker_or_id" ] || [ -z "$message" ]; then
                echo "使用法: $0 error <worker_id> <error_message>"
                exit 1
            fi
            report_error "$worker_or_id" "$message"
            ;;
        "status")
            if [ -z "$worker_or_id" ]; then
                echo "使用法: $0 status <worker_id>"
                exit 1
            fi
            check_progress "$worker_or_id"
            ;;
        "cleanup")
            if [ -z "$worker_or_id" ]; then
                echo "使用法: $0 cleanup <worker_id>"
                exit 1
            fi
            cleanup_worker_data "$worker_or_id"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"