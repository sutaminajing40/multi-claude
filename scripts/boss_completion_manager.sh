#!/bin/bash

# 🎯 ボス側完了管理システム
# 中央集権型完了管理 - 各ワーカーからの個別報告を受信・管理

# 設定
COMPLETION_DIR=".multi-claude/completion"
LOG_FILE="$COMPLETION_DIR/boss_completion.log"
VALIDATION_DIR=".multi-claude/validation"
FINAL_REPORT="$COMPLETION_DIR/final_report.md"

# ディレクトリ初期化
initialize_completion_system() {
    mkdir -p "$COMPLETION_DIR" "$VALIDATION_DIR"
    
    # 既存の完了記録をクリア
    rm -f "$COMPLETION_DIR"/worker*_reported.txt
    rm -f "$FINAL_REPORT"
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] 完了管理システム初期化完了" >> "$LOG_FILE"
}

# ワーカーからの完了報告を受信・記録
receive_worker_completion() {
    local worker_id=$1
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local report_file="$COMPLETION_DIR/worker${worker_id}_reported.txt"
    
    # 入力検証
    if [[ ! "$worker_id" =~ ^[1-3]$ ]]; then
        echo "[$timestamp] エラー: 無効なworker_id ($worker_id)" >> "$LOG_FILE"
        return 1
    fi
    
    # 重複報告チェック
    if [ -f "$report_file" ]; then
        echo "[$timestamp] 重複報告検出: worker${worker_id} (無視)" >> "$LOG_FILE"
        return 2  # 重複
    fi
    
    # 報告記録
    echo "$timestamp" > "$report_file"
    echo "[$timestamp] worker${worker_id} 完了報告受信" >> "$LOG_FILE"
    
    # リアルタイム状況更新
    update_completion_status
    
    return 0
}

# 完了状況をリアルタイム更新
update_completion_status() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local status_file="$VALIDATION_DIR/current_status.json"
    local completed_workers=()
    local pending_workers=()
    
    # 各ワーカーの状況確認
    for i in 1 2 3; do
        if [ -f "$COMPLETION_DIR/worker${i}_reported.txt" ]; then
            completed_workers+=("worker${i}")
        else
            pending_workers+=("worker${i}")
        fi
    done
    
    # JSON形式で状況記録
    cat > "$status_file" << EOF
{
  "timestamp": "$timestamp",
  "completed_count": ${#completed_workers[@]},
  "total_workers": 3,
  "completed_workers": [$(printf '"%s",' "${completed_workers[@]}" | sed 's/,$//')]$([ ${#completed_workers[@]} -eq 0 ] && echo ''),
  "pending_workers": [$(printf '"%s",' "${pending_workers[@]}" | sed 's/,$//')]$([ ${#pending_workers[@]} -eq 0 ] && echo ''),
  "all_completed": $([ ${#completed_workers[@]} -eq 3 ] && echo 'true' || echo 'false')
}
EOF
    
    echo "[$timestamp] 状況更新: ${#completed_workers[@]}/3 完了" >> "$LOG_FILE"
    
    # 全員完了時の処理
    if [ ${#completed_workers[@]} -eq 3 ]; then
        trigger_president_report
    fi
}

# 全員完了時のプレジデント報告処理
trigger_president_report() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local completion_times=()
    
    echo "[$timestamp] 全ワーカー完了確認。PRESIDENT報告準備中..." >> "$LOG_FILE"
    
    # 各ワーカーの完了時刻収集
    for i in 1 2 3; do
        local report_file="$COMPLETION_DIR/worker${i}_reported.txt"
        if [ -f "$report_file" ]; then
            local worker_time=$(cat "$report_file")
            completion_times+=("worker${i}: $worker_time")
        fi
    done
    
    # 最終報告書生成
    cat > "$FINAL_REPORT" << EOF
# 全ワーカー作業完了報告

## 完了確認時刻
$timestamp

## 各ワーカー完了時刻
$(printf '%s\n' "${completion_times[@]}")

## 完了順序
$(ls -t "$COMPLETION_DIR"/worker*_reported.txt | sed 's/.*worker\([0-9]\)_reported.txt/worker\1/' | nl -w2 -s'. ')

## ステータス
✅ 全作業完了 - PRESIDENT報告準備完了

## 統計
- 総ワーカー数: 3
- 完了ワーカー数: 3
- 完了率: 100%
EOF
    
    # PRESIDENT報告準備フラグ作成
    touch "$COMPLETION_DIR/ready_for_president_report.flag"
    
    echo "[$timestamp] PRESIDENT報告準備完了" >> "$LOG_FILE"
    
    # agent-send.shを使ってPRESIDENTに報告
    if command -v ./agent-send.sh >/dev/null 2>&1; then
        ./agent-send.sh president "全ワーカーの作業が完了しました。詳細: $FINAL_REPORT"
        echo "[$timestamp] PRESIDENT への報告送信完了" >> "$LOG_FILE"
    else
        echo "[$timestamp] 警告: agent-send.shが見つかりません。手動でPRESIDENTに報告してください" >> "$LOG_FILE"
    fi
    
    # 完了後のクリーンアップ準備
    schedule_cleanup
}

# クリーンアップのスケジュール（次回タスクのため）
schedule_cleanup() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # クリーンアップスクリプト作成
    cat > "$COMPLETION_DIR/cleanup.sh" << 'EOF'
#!/bin/bash
# 自動生成されたクリーンアップスクリプト

echo "完了記録をクリーンアップ中..."
rm -f .multi-claude/completion/worker*_reported.txt
rm -f .multi-claude/completion/ready_for_president_report.flag
rm -f .multi-claude/completion/cleanup.sh

echo "クリーンアップ完了"
EOF
    
    chmod +x "$COMPLETION_DIR/cleanup.sh"
    echo "[$timestamp] クリーンアップスクリプト準備完了" >> "$LOG_FILE"
}

# 完了状況確認（外部からの問い合わせ用）
check_completion_status() {
    local status_file="$VALIDATION_DIR/current_status.json"
    
    if [ -f "$status_file" ]; then
        echo "=== 現在の完了状況 ==="
        cat "$status_file" | jq '.' 2>/dev/null || cat "$status_file"
        echo ""
    else
        echo "完了状況データが見つかりません"
        return 1
    fi
    
    if [ -f "$LOG_FILE" ]; then
        echo "=== 最新のログ（最後5行） ==="
        tail -n 5 "$LOG_FILE"
    fi
}

# エラー時のリカバリー処理
recover_from_errors() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] エラーリカバリー開始" >> "$LOG_FILE"
    
    # 破損ファイルの検出と修復
    for i in 1 2 3; do
        local report_file="$COMPLETION_DIR/worker${i}_reported.txt"
        if [ -f "$report_file" ] && [ ! -s "$report_file" ]; then
            echo "$timestamp - recovered" > "$report_file"
            echo "[$timestamp] 修復: worker${i}_reported.txt" >> "$LOG_FILE"
        fi
    done
    
    # 状況の再計算
    update_completion_status
    
    echo "[$timestamp] エラーリカバリー完了" >> "$LOG_FILE"
}

# メイン処理関数
main() {
    local action=$1
    local worker_id=$2
    
    case "$action" in
        "init")
            initialize_completion_system
            echo "完了管理システムを初期化しました"
            ;;
        "report")
            if [ -z "$worker_id" ]; then
                echo "使用法: $0 report <worker_id(1-3)>"
                exit 1
            fi
            
            receive_worker_completion "$worker_id"
            case $? in
                0) echo "worker${worker_id}の完了報告を受信しました" ;;
                1) echo "エラー: 無効なworker_id" ;;
                2) echo "警告: worker${worker_id}の重複報告" ;;
            esac
            ;;
        "status")
            check_completion_status
            ;;
        "recover")
            recover_from_errors
            echo "エラーリカバリーを実行しました"
            ;;
        "cleanup")
            if [ -f "$COMPLETION_DIR/cleanup.sh" ]; then
                "$COMPLETION_DIR/cleanup.sh"
            else
                echo "クリーンアップスクリプトが見つかりません"
            fi
            ;;
        *)
            echo "ボス側完了管理システム"
            echo ""
            echo "使用法: $0 <action> [options]"
            echo ""
            echo "Actions:"
            echo "  init                 - システム初期化"
            echo "  report <worker_id>   - ワーカー完了報告受信 (1-3)"
            echo "  status               - 現在の完了状況確認"
            echo "  recover              - エラーリカバリー実行"
            echo "  cleanup              - 完了記録クリーンアップ"
            echo ""
            echo "例:"
            echo "  $0 init"
            echo "  $0 report 1"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"