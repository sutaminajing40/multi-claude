#!/bin/bash

# 🧪 3人分報告確認ロジックのテスト

echo "🧪 3人分報告確認ロジックのテスト"
echo "================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# テスト用ディレクトリ作成
setup_test_env() {
    mkdir -p .multi-claude/{completion,validation,tmp}
    rm -f .multi-claude/completion/worker*_reported.txt
    rm -f .multi-claude/validation/*
}

# テスト1: 順次報告受信の確認
test_sequential_report_validation() {
    echo -n "1. 順次報告受信の確認... "
    
    setup_test_env
    
    # 報告確認関数
    validate_worker_reports() {
        local validation_file=".multi-claude/validation/current_status.txt"
        local completed_workers=()
        
        for i in 1 2 3; do
            if [ -f ".multi-claude/completion/worker${i}_reported.txt" ]; then
                completed_workers+=("worker${i}")
            fi
        done
        
        echo "完了済み: ${#completed_workers[@]}/3" > "$validation_file"
        echo "完了ワーカー: ${completed_workers[*]}" >> "$validation_file"
        
        # 3人全員の報告が揃った場合
        if [ ${#completed_workers[@]} -eq 3 ]; then
            echo "ステータス: 全完了" >> "$validation_file"
            return 0
        else
            echo "ステータス: 待機中" >> "$validation_file"
            return 1
        fi
    }
    
    # テストケース1: worker1のみ報告
    echo "$(date)" > ".multi-claude/completion/worker1_reported.txt"
    validate_worker_reports
    status1=$?
    
    # テストケース2: worker1,2が報告
    echo "$(date)" > ".multi-claude/completion/worker2_reported.txt"
    validate_worker_reports
    status2=$?
    
    # テストケース3: 全員報告
    echo "$(date)" > ".multi-claude/completion/worker3_reported.txt"
    validate_worker_reports
    status3=$?
    
    # 検証
    if [ $status1 -eq 1 ] && [ $status2 -eq 1 ] && [ $status3 -eq 0 ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - 順次報告確認ロジックに問題があります"
        echo "  worker1のみ: $status1 (期待: 1)"
        echo "  worker1,2: $status2 (期待: 1)"
        echo "  全員: $status3 (期待: 0)"
        return 1
    fi
}

# テスト2: タイムスタンプ付き報告記録
test_timestamped_report_recording() {
    echo -n "2. タイムスタンプ付き報告記録... "
    
    setup_test_env
    
    # タイムスタンプ付き記録関数
    record_timestamped_report() {
        local worker_id=$1
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local report_file=".multi-claude/completion/worker${worker_id}_reported.txt"
        local log_file=".multi-claude/validation/reports.log"
        
        # 報告記録
        echo "$timestamp" > "$report_file"
        echo "[$timestamp] worker${worker_id}: 作業完了報告" >> "$log_file"
        
        return 0
    }
    
    # テスト実行
    record_timestamped_report 1
    sleep 1
    record_timestamped_report 2
    sleep 1
    record_timestamped_report 3
    
    # 検証
    if [ -f .multi-claude/completion/worker1_reported.txt ] &&
       [ -f .multi-claude/completion/worker2_reported.txt ] &&
       [ -f .multi-claude/completion/worker3_reported.txt ] &&
       [ -f .multi-claude/validation/reports.log ]; then
        
        local log_lines=$(wc -l < .multi-claude/validation/reports.log)
        if [ $log_lines -eq 3 ]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - ログ行数が不正です (実際: $log_lines, 期待: 3)"
            return 1
        fi
    else
        echo "❌ NG - 必要なファイルが作成されていません"
        return 1
    fi
}

# テスト3: 部分的完了状態の処理
test_partial_completion_handling() {
    echo -n "3. 部分的完了状態の処理... "
    
    setup_test_env
    
    # 部分完了確認関数
    check_partial_completion() {
        local completion_status=".multi-claude/validation/partial_status.json"
        local completed=0
        local pending=()
        
        for i in 1 2 3; do
            if [ -f ".multi-claude/completion/worker${i}_reported.txt" ]; then
                ((completed++))
            else
                pending+=("worker${i}")
            fi
        done
        
        # JSON形式で状態を記録
        cat > "$completion_status" << EOF
{
  "completed_count": $completed,
  "total_workers": 3,
  "pending_workers": [$(printf '"%s",' "${pending[@]}" | sed 's/,$//')]
}
EOF
        
        return $completed
    }
    
    # テストケース1: worker1,3が完了、worker2が未完了
    echo "$(date)" > ".multi-claude/completion/worker1_reported.txt"
    echo "$(date)" > ".multi-claude/completion/worker3_reported.txt"
    
    check_partial_completion
    partial_count=$?
    
    # 検証
    if [ $partial_count -eq 2 ] && [ -f .multi-claude/validation/partial_status.json ]; then
        local json_content=$(cat .multi-claude/validation/partial_status.json)
        if [[ "$json_content" == *'"completed_count": 2'* ]] &&
           [[ "$json_content" == *'"worker2"'* ]]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - JSON内容が不正です"
            return 1
        fi
    else
        echo "❌ NG - 部分完了処理に問題があります (完了数: $partial_count)"
        return 1
    fi
}

# テスト4: 完了順序の記録と検証
test_completion_order_tracking() {
    echo -n "4. 完了順序の記録と検証... "
    
    setup_test_env
    
    # 完了順序記録関数
    track_completion_order() {
        local worker_id=$1
        local order_file=".multi-claude/validation/completion_order.txt"
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
        
        # 完了記録
        echo "$timestamp" > ".multi-claude/completion/worker${worker_id}_reported.txt"
        echo "[$timestamp] worker${worker_id}" >> "$order_file"
        
        return 0
    }
    
    # テスト実行（意図的に順序を変更）
    track_completion_order 2
    sleep 0.1
    track_completion_order 1
    sleep 0.1
    track_completion_order 3
    
    # 検証
    if [ -f .multi-claude/validation/completion_order.txt ]; then
        local order_content=$(cat .multi-claude/validation/completion_order.txt)
        local first_worker=$(echo "$order_content" | head -n1 | grep -o 'worker[0-9]')
        local last_worker=$(echo "$order_content" | tail -n1 | grep -o 'worker[0-9]')
        
        if [ "$first_worker" = "worker2" ] && [ "$last_worker" = "worker3" ]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - 完了順序が正しく記録されていません"
            echo "  最初: $first_worker (期待: worker2)"
            echo "  最後: $last_worker (期待: worker3)"
            return 1
        fi
    else
        echo "❌ NG - 完了順序記録ファイルが作成されていません"
        return 1
    fi
}

# テスト5: 統合報告確認ロジック
test_integrated_report_validation() {
    echo -n "5. 統合報告確認ロジック... "
    
    setup_test_env
    
    # 統合報告確認システム
    integrated_report_validator() {
        local validation_result=".multi-claude/validation/final_validation.md"
        local all_completed=true
        local completion_times=()
        
        # 各ワーカーの完了確認
        for i in 1 2 3; do
            local report_file=".multi-claude/completion/worker${i}_reported.txt"
            if [ -f "$report_file" ]; then
                local timestamp=$(cat "$report_file")
                completion_times+=("worker${i}: $timestamp")
            else
                all_completed=false
                break
            fi
        done
        
        # 統合報告生成
        if [ "$all_completed" = true ]; then
            cat > "$validation_result" << EOF
# 3人分報告確認完了

## 検証結果
- ✅ 全ワーカー報告受信済み
- ✅ 完了時刻記録済み
- ✅ PRESIDENT報告準備完了

## 完了詳細
$(printf '%s\n' "${completion_times[@]}")

## ステータス: 検証完了
EOF
            return 0
        else
            cat > "$validation_result" << EOF
# 3人分報告確認未完了

## 検証結果
- ❌ 未完了ワーカーあり
- ⏳ 完了待機中

## ステータス: 検証待機
EOF
            return 1
        fi
    }
    
    # テスト実行
    for i in 1 2 3; do
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Test completion" > ".multi-claude/completion/worker${i}_reported.txt"
    done
    
    integrated_report_validator
    validation_status=$?
    
    # 検証
    if [ $validation_status -eq 0 ] && [ -f .multi-claude/validation/final_validation.md ]; then
        local validation_content=$(cat .multi-claude/validation/final_validation.md)
        if [[ "$validation_content" == *"検証完了"* ]] &&
           [[ "$validation_content" == *"worker1:"* ]] &&
           [[ "$validation_content" == *"worker2:"* ]] &&
           [[ "$validation_content" == *"worker3:"* ]]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - 統合報告内容が不完全です"
            return 1
        fi
    else
        echo "❌ NG - 統合報告確認に失敗しました"
        return 1
    fi
}

# クリーンアップ
cleanup_test_env() {
    rm -rf .multi-claude/completion .multi-claude/validation
}

# メイン処理
main() {
    local failed=0
    
    test_sequential_report_validation || ((failed++))
    test_timestamped_report_recording || ((failed++))
    test_partial_completion_handling || ((failed++))
    test_completion_order_tracking || ((failed++))
    test_integrated_report_validation || ((failed++))
    
    cleanup_test_env
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ 全てのテストが成功しました"
        return 0
    else
        echo "❌ $failed 個のテストが失敗しました"
        return 1
    fi
}

main