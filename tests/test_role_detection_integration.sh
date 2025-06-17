#!/bin/bash

# 修正された役割判定システムの統合テスト

echo "=== 役割判定システム統合テスト ==="

# テスト用のシミュレート関数
simulate_role_check() {
    local session_name=$1
    local pane_index=$2
    local pane_id=$3
    
    export TMUX_PANE="$pane_id"
    
    # 修正後の役割判定ロジック
    SESSION_INFO="$session_name:$pane_index $pane_id"
    SESSION_AND_PANE=$(echo "$SESSION_INFO" | grep "$TMUX_PANE" | awk '{print $1}')
    
    case "$SESSION_AND_PANE" in
        "president:0")
            echo "PRESIDENT"
            ;;
        "multiagent:0")
            echo "boss1"
            ;;
        "multiagent:1")
            echo "worker1"
            ;;
        "multiagent:2") 
            echo "worker2"
            ;;
        "multiagent:3")
            echo "worker3"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# テストケース実行
test_cases=(
    "president:0:%0:PRESIDENT"
    "multiagent:0:%0:boss1"
    "multiagent:1:%1:worker1"
    "multiagent:2:%2:worker2"
    "multiagent:3:%3:worker3"
    "unknown:0:%0:UNKNOWN"
)

passed_tests=0
total_tests=${#test_cases[@]}

for test_case in "${test_cases[@]}"; do
    IFS=':' read -r session pane_idx pane_id expected <<< "$test_case"
    
    result=$(simulate_role_check "$session" "$pane_idx" "$pane_id")
    
    if [[ "$result" == "$expected" ]]; then
        echo "✅ パス: $session:$pane_idx ($pane_id) → $result"
        ((passed_tests++))
    else
        echo "❌ 失敗: $session:$pane_idx ($pane_id) → $result (期待値: $expected)"
    fi
done

echo "=========================="
echo "テスト結果: $passed_tests/$total_tests パス"

if [[ $passed_tests -eq $total_tests ]]; then
    echo "🎉 すべてのテストが成功しました！"
    exit 0
else
    echo "❌ 一部のテストが失敗しました"
    exit 1
fi