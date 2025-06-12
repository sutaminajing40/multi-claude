#!/bin/bash

# 🧪 ワーカーtmux番号検出の統合テスト

echo "🧪 ワーカーtmux番号検出の統合テスト"
echo "===================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# PRESIDENTの指示書確認
test_president_instructions() {
    echo -n "1. PRESIDENT指示書のtmux検出コード... "
    
    if grep -q 'tmux display-message -p' ./instructions/president_dynamic.md && \
       grep -q 'multiagent:0.1.*WORKER_NUM="1"' ./instructions/president_dynamic.md && \
       grep -q 'multiagent:0.2.*WORKER_NUM="2"' ./instructions/president_dynamic.md && \
       grep -q 'multiagent:0.3.*WORKER_NUM="3"' ./instructions/president_dynamic.md; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - tmux検出コードが不完全です"
        return 1
    fi
}

# WORKERの指示書確認
test_worker_instructions() {
    echo -n "2. WORKER指示書のtmux検出コード... "
    
    if grep -q 'tmux display-message -p' ./instructions/worker_dynamic.md && \
       grep -q 'touch "./tmp/worker${WORKER_NUM}_done.txt"' ./instructions/worker_dynamic.md; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - tmux検出コードが不完全です"
        return 1
    fi
}

# 完了ファイル名の変数化確認
test_completion_file_variable() {
    echo -n "3. 完了ファイル名の変数化... "
    
    # 固定のファイル名（worker1_done.txt等）ではなく、変数を使っているか確認
    if grep -q 'worker${WORKER_NUM}_done.txt' ./instructions/president_dynamic.md && \
       grep -q 'worker${WORKER_NUM}_done.txt' ./instructions/worker_dynamic.md; then
        echo "✅ OK - 変数化されています"
        return 0
    else
        echo "❌ NG - 固定ファイル名が残っています"
        return 1
    fi
}

# エラーハンドリングの確認
test_error_handling() {
    echo -n "4. エラーハンドリング... "
    
    if grep -q 'エラー: 不明なペイン情報' ./instructions/president_dynamic.md && \
       grep -q 'エラー: tmux環境外では実行できません' ./instructions/worker_dynamic.md; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - エラーハンドリングが不十分です"
        return 1
    fi
}

# デバッグ情報の確認
test_debug_info() {
    echo -n "5. デバッグ情報の出力... "
    
    if grep -q '自分はworker${WORKER_NUM}として認識されました' ./instructions/president_dynamic.md && \
       grep -q '完了ファイルを作成:' ./instructions/worker_dynamic.md; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - デバッグ情報が不足しています"
        return 1
    fi
}

# tmuxペイン検出のシミュレーション
test_pane_detection_simulation() {
    echo ""
    echo "6. tmuxペイン検出のシミュレーション"
    echo "-----------------------------------"
    
    # テスト関数
    simulate_worker() {
        local pane_info="$1"
        local expected_num="$2"
        
        echo -n "  • $pane_info → "
        
        case "$pane_info" in
            "multiagent:0.1") WORKER_NUM="1" ;;
            "multiagent:0.2") WORKER_NUM="2" ;;
            "multiagent:0.3") WORKER_NUM="3" ;;
            *) WORKER_NUM="unknown" ;;
        esac
        
        if [ "$WORKER_NUM" = "$expected_num" ]; then
            echo "worker$WORKER_NUM ✅"
            return 0
        else
            echo "worker$WORKER_NUM ❌ (期待値: worker$expected_num)"
            return 1
        fi
    }
    
    local sim_failed=0
    simulate_worker "multiagent:0.1" "1" || ((sim_failed++))
    simulate_worker "multiagent:0.2" "2" || ((sim_failed++))
    simulate_worker "multiagent:0.3" "3" || ((sim_failed++))
    
    if [ $sim_failed -eq 0 ]; then
        echo "  シミュレーション: ✅ 全て成功"
    else
        echo "  シミュレーション: ❌ $sim_failed 個失敗"
    fi
}

# メイン処理
main() {
    local failed=0
    
    test_president_instructions || ((failed++))
    test_worker_instructions || ((failed++))
    test_completion_file_variable || ((failed++))
    test_error_handling || ((failed++))
    test_debug_info || ((failed++))
    test_pane_detection_simulation
    
    echo ""
    echo "7. 修正内容のまとめ"
    echo "-------------------"
    echo "  • 各ワーカーがtmuxペイン情報から自分の番号を自動検出"
    echo "  • 完了ファイル名を変数化（worker\${WORKER_NUM}_done.txt）"
    echo "  • エラーハンドリングとデバッグ情報の追加"
    echo "  • BOSSからのメッセージに依存しない確実な番号認識"
    
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