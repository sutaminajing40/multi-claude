#!/bin/bash

# 🧪 ボス側完了管理システムのテスト

echo "🧪 ボス側完了管理システムのテスト"
echo "================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# テスト用ディレクトリ作成
setup_test_env() {
    mkdir -p .multi-claude/{completion,tmp,context}
    rm -f .multi-claude/completion/worker*_reported.txt
    rm -f .multi-claude/completion/boss_completion.log
}

# テスト1: 完了報告受信・記録システム
test_completion_report_system() {
    echo -n "1. 完了報告受信・記録システム... "
    
    setup_test_env
    
    # 模擬完了報告記録関数
    record_worker_completion() {
        local worker_id=$1
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        # 完了記録ファイル作成
        echo "$timestamp" > ".multi-claude/completion/worker${worker_id}_reported.txt"
        echo "[$timestamp] worker${worker_id} 完了報告受信" >> ".multi-claude/completion/boss_completion.log"
        
        return 0
    }
    
    # テスト実行
    record_worker_completion 1
    record_worker_completion 2
    
    # 検証
    if [ -f .multi-claude/completion/worker1_reported.txt ] && 
       [ -f .multi-claude/completion/worker2_reported.txt ] &&
       [ -f .multi-claude/completion/boss_completion.log ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - 完了報告記録システムが動作しません"
        return 1
    fi
}

# テスト2: 3人分完了確認ロジック
test_three_workers_completion_check() {
    echo -n "2. 3人分完了確認ロジック... "
    
    setup_test_env
    
    # 完了確認関数
    check_all_workers_completed() {
        local completed_count=0
        
        for i in 1 2 3; do
            if [ -f ".multi-claude/completion/worker${i}_reported.txt" ]; then
                ((completed_count++))
            fi
        done
        
        if [ $completed_count -eq 3 ]; then
            return 0  # 全員完了
        else
            return 1  # 未完了あり
        fi
    }
    
    # テストケース1: 1人のみ完了
    echo "$(date)" > ".multi-claude/completion/worker1_reported.txt"
    if check_all_workers_completed; then
        echo "❌ NG - 1人のみ完了で全員完了と判定されました"
        return 1
    fi
    
    # テストケース2: 2人完了
    echo "$(date)" > ".multi-claude/completion/worker2_reported.txt"
    if check_all_workers_completed; then
        echo "❌ NG - 2人完了で全員完了と判定されました"
        return 1
    fi
    
    # テストケース3: 3人全員完了
    echo "$(date)" > ".multi-claude/completion/worker3_reported.txt"
    if check_all_workers_completed; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - 3人全員完了なのに未完了と判定されました"
        return 1
    fi
}

# テスト3: プレジデントへの総合報告機能
test_president_report_function() {
    echo -n "3. プレジデントへの総合報告機能... "
    
    setup_test_env
    
    # 総合報告生成関数
    generate_completion_report() {
        local report_file=".multi-claude/completion/final_report.md"
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        cat > "$report_file" << EOF
# 全ワーカー作業完了報告

## 完了時刻
$timestamp

## 完了確認済みワーカー
EOF
        
        for i in 1 2 3; do
            if [ -f ".multi-claude/completion/worker${i}_reported.txt" ]; then
                local worker_time=$(cat ".multi-claude/completion/worker${i}_reported.txt")
                echo "- worker${i}: $worker_time" >> "$report_file"
            fi
        done
        
        echo "" >> "$report_file"
        echo "## ステータス: 全作業完了" >> "$report_file"
        
        return 0
    }
    
    # テスト実行
    for i in 1 2 3; do
        echo "$(date)" > ".multi-claude/completion/worker${i}_reported.txt"
    done
    
    generate_completion_report
    
    # 検証
    if [ -f .multi-claude/completion/final_report.md ]; then
        local report_content=$(cat .multi-claude/completion/final_report.md)
        if [[ "$report_content" == *"worker1"* ]] && 
           [[ "$report_content" == *"worker2"* ]] && 
           [[ "$report_content" == *"worker3"* ]] &&
           [[ "$report_content" == *"全作業完了"* ]]; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG - 報告内容が不完全です"
            return 1
        fi
    else
        echo "❌ NG - 報告ファイルが生成されません"
        return 1
    fi
}

# テスト4: 統合テスト（完全なフロー）
test_integrated_completion_flow() {
    echo -n "4. 統合テスト（完全なフロー）... "
    
    setup_test_env
    
    # 統合完了管理システム
    boss_completion_manager() {
        local worker_id=$1
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        
        # ステップ1: 完了報告記録
        echo "$timestamp" > ".multi-claude/completion/worker${worker_id}_reported.txt"
        echo "[$timestamp] worker${worker_id} 完了報告受信" >> ".multi-claude/completion/boss_completion.log"
        
        # ステップ2: 全員完了確認
        local completed_count=0
        for i in 1 2 3; do
            if [ -f ".multi-claude/completion/worker${i}_reported.txt" ]; then
                ((completed_count++))
            fi
        done
        
        # ステップ3: 全員完了時の処理
        if [ $completed_count -eq 3 ]; then
            echo "[$timestamp] 全ワーカー完了確認。PRESIDENT報告準備中..." >> ".multi-claude/completion/boss_completion.log"
            
            # 総合報告生成
            cat > ".multi-claude/completion/final_report.md" << EOF
# 全ワーカー作業完了報告
## 完了時刻: $timestamp
## 完了ワーカー: worker1, worker2, worker3
## ステータス: 全作業完了
EOF
            
            # PRESIDENT通知フラグ作成
            touch ".multi-claude/completion/ready_for_president_report.flag"
            
            return 0  # 全完了
        else
            echo "[$timestamp] 完了待機中 ($completed_count/3)" >> ".multi-claude/completion/boss_completion.log"
            return 1  # 待機中
        fi
    }
    
    # テスト実行: 順次完了報告
    boss_completion_manager 1
    if [ -f ".multi-claude/completion/ready_for_president_report.flag" ]; then
        echo "❌ NG - 1人完了でPRESIDENT報告準備されました"
        return 1
    fi
    
    boss_completion_manager 2
    if [ -f ".multi-claude/completion/ready_for_president_report.flag" ]; then
        echo "❌ NG - 2人完了でPRESIDENT報告準備されました"
        return 1
    fi
    
    boss_completion_manager 3
    if [ -f ".multi-claude/completion/ready_for_president_report.flag" ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - 3人完了でもPRESIDENT報告準備されませんでした"
        return 1
    fi
}

# クリーンアップ
cleanup_test_env() {
    rm -rf .multi-claude/completion
}

# メイン処理
main() {
    local failed=0
    
    test_completion_report_system || ((failed++))
    test_three_workers_completion_check || ((failed++))
    test_president_report_function || ((failed++))
    test_integrated_completion_flow || ((failed++))
    
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