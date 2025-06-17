#!/bin/bash

# 🧪 エッジケース（重複報告等）のテスト

echo "🧪 エッジケース（重複報告等）のテスト"
echo "===================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# テスト用ディレクトリ作成
setup_test_env() {
    mkdir -p .multi-claude/{completion,edge_test,tmp}
    rm -f .multi-claude/completion/worker*_reported.txt
    rm -f .multi-claude/edge_test/*
}

# テスト1: 重複報告の防止
test_duplicate_report_prevention() {
    echo -n "1. 重複報告の防止... "
    
    setup_test_env
    
    # 重複防止付き報告受信関数
    receive_worker_report() {
        local worker_id=$1
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local report_file=".multi-claude/completion/worker${worker_id}_reported.txt"
        local log_file=".multi-claude/edge_test/duplicate_log.txt"
        
        # 既に報告済みかチェック
        if [ -f "$report_file" ]; then
            echo "[$timestamp] 重複報告検出: worker${worker_id} (無視)" >> "$log_file"
            return 1  # 重複のため処理しない
        else
            echo "$timestamp" > "$report_file"
            echo "[$timestamp] 新規報告受信: worker${worker_id}" >> "$log_file"
            return 0  # 新規報告として処理
        fi
    }
    
    # テスト実行
    receive_worker_report 1  # 初回報告
    result1=$?
    receive_worker_report 1  # 重複報告
    result2=$?
    receive_worker_report 2  # 別ワーカーの初回報告
    result3=$?
    receive_worker_report 2  # 別ワーカーの重複報告
    result4=$?
    
    # 検証
    if [ $result1 -eq 0 ] && [ $result2 -eq 1 ] && [ $result3 -eq 0 ] && [ $result4 -eq 1 ]; then
        local log_content=$(cat .multi-claude/edge_test/duplicate_log.txt)
        local duplicate_count=$(echo "$log_content" | grep -c "重複報告検出")
        if [ $duplicate_count -eq 2 ]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - 重複検出数が不正です (実際: $duplicate_count, 期待: 2)"
            return 1
        fi
    else
        echo "❌ NG - 重複報告防止ロジックに問題があります"
        echo "  初回1: $result1, 重複1: $result2, 初回2: $result3, 重複2: $result4"
        return 1
    fi
}

# テスト2: 異常時のリカバリー機能
test_error_recovery_function() {
    echo -n "2. 異常時のリカバリー機能... "
    
    setup_test_env
    
    # リカバリー機能付き完了管理
    completion_manager_with_recovery() {
        local action=$1  # "report" or "recover"
        local worker_id=$2
        local recovery_log=".multi-claude/edge_test/recovery.log"
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        case "$action" in
            "report")
                # 通常の報告処理
                if [ -n "$worker_id" ] && [[ "$worker_id" =~ ^[1-3]$ ]]; then
                    echo "$timestamp" > ".multi-claude/completion/worker${worker_id}_reported.txt"
                    echo "[$timestamp] 正常報告: worker${worker_id}" >> "$recovery_log"
                    return 0
                else
                    echo "[$timestamp] エラー: 無効なworker_id ($worker_id)" >> "$recovery_log"
                    return 1
                fi
                ;;
            "recover")
                # リカバリー処理
                echo "[$timestamp] リカバリー開始" >> "$recovery_log"
                
                # 破損ファイルの検出と修復
                for i in 1 2 3; do
                    local report_file=".multi-claude/completion/worker${i}_reported.txt"
                    if [ -f "$report_file" ] && [ ! -s "$report_file" ]; then
                        # 空ファイルを修復
                        echo "$timestamp - recovered" > "$report_file"
                        echo "[$timestamp] 修復: worker${i}_reported.txt" >> "$recovery_log"
                    fi
                done
                
                echo "[$timestamp] リカバリー完了" >> "$recovery_log"
                return 0
                ;;
        esac
    }
    
    # テスト実行
    completion_manager_with_recovery "report" 1
    completion_manager_with_recovery "report" ""     # 無効なID
    completion_manager_with_recovery "report" "invalid"  # 無効なID
    
    # 異常ファイル作成（空ファイル）
    touch .multi-claude/completion/worker2_reported.txt
    touch .multi-claude/completion/worker3_reported.txt
    
    # リカバリー実行
    completion_manager_with_recovery "recover"
    
    # 検証
    if [ -f .multi-claude/edge_test/recovery.log ]; then
        local log_content=$(cat .multi-claude/edge_test/recovery.log)
        local error_count=$(echo "$log_content" | grep -c "エラー:")
        local recovery_count=$(echo "$log_content" | grep -c "修復:")
        
        if [ $error_count -eq 2 ] && [ $recovery_count -eq 2 ]; then
            # 修復されたファイルの確認
            if [ -s .multi-claude/completion/worker2_reported.txt ] && 
               [ -s .multi-claude/completion/worker3_reported.txt ]; then
                echo "✅ OK"
                return 0
            else
                echo "❌ NG - ファイル修復が不完全です"
                return 1
            fi
        else
            echo "❌ NG - エラー処理・リカバリー数が不正です"
            echo "  エラー数: $error_count (期待: 2), 修復数: $recovery_count (期待: 2)"
            return 1
        fi
    else
        echo "❌ NG - リカバリーログが作成されていません"
        return 1
    fi
}

# テスト3: タイムアウト処理
test_timeout_handling() {
    echo -n "3. タイムアウト処理... "
    
    setup_test_env
    
    # タイムアウト付き完了確認
    completion_checker_with_timeout() {
        local timeout_seconds=$1
        local start_time=$(date +%s)
        local timeout_log=".multi-claude/edge_test/timeout.log"
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        echo "[$timestamp] 完了確認開始 (タイムアウト: ${timeout_seconds}秒)" >> "$timeout_log"
        
        while true; do
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            
            # 完了確認
            local completed_count=0
            for i in 1 2 3; do
                if [ -f ".multi-claude/completion/worker${i}_reported.txt" ]; then
                    ((completed_count++))
                fi
            done
            
            if [ $completed_count -eq 3 ]; then
                echo "[$timestamp] 全員完了確認 (${elapsed}秒)" >> "$timeout_log"
                return 0
            fi
            
            # タイムアウトチェック
            if [ $elapsed -ge $timeout_seconds ]; then
                echo "[$timestamp] タイムアウト (${elapsed}秒) - 未完了: $((3 - completed_count))人" >> "$timeout_log"
                return 1
            fi
            
            sleep 1
        done
    }
    
    # テスト実行（短時間でタイムアウトさせる）
    # worker1,2のみ報告してタイムアウトを発生させる
    echo "$(date)" > .multi-claude/completion/worker1_reported.txt
    echo "$(date)" > .multi-claude/completion/worker2_reported.txt
    
    # 3秒でタイムアウト
    completion_checker_with_timeout 3
    timeout_result=$?
    
    # 検証
    if [ $timeout_result -eq 1 ] && [ -f .multi-claude/edge_test/timeout.log ]; then
        local log_content=$(cat .multi-claude/edge_test/timeout.log)
        if [[ "$log_content" == *"タイムアウト"* ]] && [[ "$log_content" == *"未完了: 1人"* ]]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - タイムアウトログの内容が不正です"
            return 1
        fi
    else
        echo "❌ NG - タイムアウト処理に失敗しました"
        return 1
    fi
}

# テスト4: ファイルシステム障害時の処理
test_filesystem_error_handling() {
    echo -n "4. ファイルシステム障害時の処理... "
    
    setup_test_env
    
    # ファイルシステム障害対応付き報告システム
    robust_report_system() {
        local worker_id=$1
        local error_log=".multi-claude/edge_test/filesystem_error.log"
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local report_file=".multi-claude/completion/worker${worker_id}_reported.txt"
        local backup_file=".multi-claude/edge_test/worker${worker_id}_backup.txt"
        
        # 通常の報告ファイル作成を試行
        if echo "$timestamp" > "$report_file" 2>/dev/null; then
            echo "[$timestamp] 正常報告: worker${worker_id}" >> "$error_log"
            # バックアップも作成
            cp "$report_file" "$backup_file" 2>/dev/null
            return 0
        else
            echo "[$timestamp] 報告ファイル作成失敗: worker${worker_id}" >> "$error_log"
            
            # バックアップファイルで代替
            if echo "$timestamp - backup" > "$backup_file" 2>/dev/null; then
                echo "[$timestamp] バックアップファイル作成: worker${worker_id}" >> "$error_log"
                return 2  # バックアップモード
            else
                echo "[$timestamp] バックアップファイル作成も失敗: worker${worker_id}" >> "$error_log"
                return 1  # 完全失敗
            fi
        fi
    }
    
    # ディレクトリの権限を制限してエラーを発生させる
    chmod 444 .multi-claude/completion 2>/dev/null
    
    # テスト実行
    robust_report_system 1
    result1=$?
    robust_report_system 2
    result2=$?
    
    # 権限を戻す
    chmod 755 .multi-claude/completion 2>/dev/null
    
    # 正常なケースもテスト
    robust_report_system 3
    result3=$?
    
    # 検証
    if [ $result1 -eq 2 ] && [ $result2 -eq 2 ] && [ $result3 -eq 0 ]; then
        if [ -f .multi-claude/edge_test/worker1_backup.txt ] && 
           [ -f .multi-claude/edge_test/worker2_backup.txt ] &&
           [ -f .multi-claude/completion/worker3_reported.txt ]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - バックアップファイルまたは通常ファイルが不正です"
            return 1
        fi
    else
        echo "❌ NG - ファイルシステム障害処理に問題があります"
        echo "  worker1: $result1 (期待: 2), worker2: $result2 (期待: 2), worker3: $result3 (期待: 0)"
        return 1
    fi
}

# テスト5: 同時アクセス競合状態の処理
test_concurrent_access_handling() {
    echo -n "5. 同時アクセス競合状態の処理... "
    
    setup_test_env
    
    # ロック機能付き報告システム
    locked_report_system() {
        local worker_id=$1
        local lock_file=".multi-claude/edge_test/report.lock"
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
        local concurrent_log=".multi-claude/edge_test/concurrent.log"
        local max_wait=5
        local wait_count=0
        
        # ロック取得試行
        while [ -f "$lock_file" ] && [ $wait_count -lt $max_wait ]; do
            echo "[$timestamp] ロック待機: worker${worker_id} (${wait_count}/${max_wait})" >> "$concurrent_log"
            sleep 1
            ((wait_count++))
            timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
        done
        
        if [ $wait_count -ge $max_wait ]; then
            echo "[$timestamp] ロック取得タイムアウト: worker${worker_id}" >> "$concurrent_log"
            return 1
        fi
        
        # ロック作成
        echo "worker${worker_id}" > "$lock_file"
        echo "[$timestamp] ロック取得: worker${worker_id}" >> "$concurrent_log"
        
        # 報告処理（意図的に遅延）
        sleep 1
        echo "$timestamp" > ".multi-claude/completion/worker${worker_id}_reported.txt"
        
        # ロック解除
        rm -f "$lock_file"
        echo "[$timestamp] ロック解除: worker${worker_id}" >> "$concurrent_log"
        
        return 0
    }
    
    # 同時実行シミュレーション
    locked_report_system 1 &
    pid1=$!
    sleep 0.1  # 少し遅らせて競合状態を作る
    locked_report_system 2 &
    pid2=$!
    sleep 0.1
    locked_report_system 3 &
    pid3=$!
    
    # 全プロセスの完了待機
    wait $pid1
    result1=$?
    wait $pid2
    result2=$?
    wait $pid3
    result3=$?
    
    # 検証
    if [ $result1 -eq 0 ] && [ $result2 -eq 0 ] && [ $result3 -eq 0 ]; then
        if [ -f .multi-claude/edge_test/concurrent.log ]; then
            local log_content=$(cat .multi-claude/edge_test/concurrent.log)
            local lock_acquired=$(echo "$log_content" | grep -c "ロック取得:")
            local lock_released=$(echo "$log_content" | grep -c "ロック解除:")
            
            if [ $lock_acquired -eq 3 ] && [ $lock_released -eq 3 ] &&
               [ -f .multi-claude/completion/worker1_reported.txt ] &&
               [ -f .multi-claude/completion/worker2_reported.txt ] &&
               [ -f .multi-claude/completion/worker3_reported.txt ]; then
                echo "✅ OK"
                return 0
            else
                echo "❌ NG - ロック処理またはファイル作成に問題があります"
                echo "  ロック取得: $lock_acquired, ロック解除: $lock_released"
                return 1
            fi
        else
            echo "❌ NG - 同時アクセスログが作成されていません"
            return 1
        fi
    else
        echo "❌ NG - 同時アクセス処理に失敗しました"
        echo "  worker1: $result1, worker2: $result2, worker3: $result3"
        return 1
    fi
}

# クリーンアップ
cleanup_test_env() {
    rm -rf .multi-claude/completion .multi-claude/edge_test
    chmod 755 .multi-claude 2>/dev/null
}

# メイン処理
main() {
    local failed=0
    
    test_duplicate_report_prevention || ((failed++))
    test_error_recovery_function || ((failed++))
    test_timeout_handling || ((failed++))
    test_filesystem_error_handling || ((failed++))
    test_concurrent_access_handling || ((failed++))
    
    cleanup_test_env
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ 全てのエッジケーステストが成功しました"
        return 0
    else
        echo "❌ $failed 個のエッジケーステストが失敗しました"
        return 1
    fi
}

main