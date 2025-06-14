#!/bin/bash

# 🏥 Multi-Claude ヘルスチェックスクリプト
# エージェント間の定期的な状態確認を行う

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# ヘルスチェック実行
perform_health_check() {
    echo "🏥 Multi-Claude ヘルスチェック"
    echo "================================"
    echo "実行時刻: $(date)"
    echo ""
    
    # 1. tmuxセッション確認
    echo "📍 セッション状態:"
    if tmux has-session -t president 2>/dev/null; then
        echo "  ✅ president: 稼働中"
    else
        echo "  ❌ president: 停止"
    fi
    
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "  ✅ multiagent: 稼働中"
        # 各ペインの状態確認
        for i in {0..3}; do
            case $i in
                0) agent="boss1" ;;
                1) agent="worker1" ;;
                2) agent="worker2" ;;
                3) agent="worker3" ;;
            esac
            if tmux list-panes -t multiagent:0 -F "#{pane_index}" | grep -q "^$i$"; then
                echo "    ✅ $agent (pane $i): 稼働中"
            else
                echo "    ❌ $agent (pane $i): 停止"
            fi
        done
    else
        echo "  ❌ multiagent: 停止"
    fi
    echo ""
    
    # 2. 進捗ファイル確認
    echo "📊 進捗状況:"
    for i in 1 2 3; do
        if [ -f ".multi-claude/context/worker${i}_progress.md" ]; then
            last_update=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" ".multi-claude/context/worker${i}_progress.md" 2>/dev/null || stat -c "%y" ".multi-claude/context/worker${i}_progress.md" 2>/dev/null | cut -d. -f1)
            echo "  Worker$i: 最終更新 $last_update"
            
            # 10分以上更新がない場合は警告
            if [ $(($(date +%s) - $(date -j -f "%Y-%m-%d %H:%M:%S" "$last_update" +%s 2>/dev/null || date -d "$last_update" +%s))) -gt 600 ]; then
                log_warning "    ⚠️  10分以上更新なし"
            fi
        else
            echo "  Worker$i: 進捗ファイルなし"
        fi
    done
    echo ""
    
    # 3. タスクファイル確認
    echo "📋 タスク状況:"
    if [ -f ".multi-claude/tasks/current_task.md" ]; then
        echo "  ✅ 現在のタスク: あり"
        echo "  内容: $(head -1 .multi-claude/tasks/current_task.md | cut -c 1-50)..."
    else
        echo "  ℹ️  現在のタスク: なし"
    fi
    
    # 完了ファイル確認
    completed_count=$(ls -1 .multi-claude/tmp/worker*_done.txt 2>/dev/null | wc -l | tr -d ' ')
    if [ "$completed_count" -gt 0 ]; then
        echo "  完了済みワーカー: $completed_count/3"
    fi
    echo ""
    
    # 4. ログファイルサイズ確認
    echo "📝 ログ状況:"
    if [ -f ".multi-claude/logs/send_log.txt" ]; then
        log_size=$(du -h ".multi-claude/logs/send_log.txt" | cut -f1)
        echo "  送信ログサイズ: $log_size"
        
        # 100MB超えたら警告
        if [ $(du -k ".multi-claude/logs/send_log.txt" | cut -f1) -gt 102400 ]; then
            log_warning "  ⚠️  ログファイルが大きくなっています。クリーンアップを検討してください。"
        fi
    fi
    echo ""
    
    # 5. システム推奨事項
    echo "💡 推奨事項:"
    if [ "$completed_count" -eq 3 ]; then
        echo "  ℹ️  全ワーカーが完了しています。完了ファイルのクリアを検討してください:"
        echo "     rm -f .multi-claude/tmp/worker*_done.txt"
    fi
    
    # 古い進捗ファイルの検出
    old_files=$(find .multi-claude/context -name "*.md" -mtime +1 2>/dev/null | wc -l | tr -d ' ')
    if [ "$old_files" -gt 0 ]; then
        echo "  ℹ️  1日以上前の進捗ファイルが${old_files}個あります。クリーンアップを検討してください。"
    fi
}

# 定期実行モード
if [ "$1" = "--watch" ]; then
    log_info "定期ヘルスチェックモードで起動（5分間隔）"
    while true; do
        clear
        perform_health_check
        echo ""
        echo "次回チェック: 5分後（Ctrl+Cで終了）"
        sleep 300
    done
else
    perform_health_check
fi