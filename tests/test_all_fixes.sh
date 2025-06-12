#!/bin/bash

# 🧪 全修正の統合テスト

echo "🧪 全修正の統合テスト"
echo "====================="
echo ""

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# テスト結果を格納
declare -a TEST_RESULTS=()

# 個別テスト実行関数
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo "🔍 実行中: $test_name"
    if [ -f "$test_script" ] && [ -x "$test_script" ]; then
        if $test_script > /dev/null 2>&1; then
            echo "  ✅ 成功"
            TEST_RESULTS+=("✅ $test_name")
            return 0
        else
            echo "  ❌ 失敗"
            TEST_RESULTS+=("❌ $test_name")
            return 1
        fi
    else
        echo "  ⚠️  スクリプトが見つかりません: $test_script"
        TEST_RESULTS+=("⚠️  $test_name (スクリプトなし)")
        return 1
    fi
}

# 修正確認テスト
test_fixes() {
    echo "1. 修正内容の確認"
    echo "-----------------"
    
    # 問題1: ワーカー完了報告の修正確認
    echo -n "  • PRESIDENT指示書の完了確認セクション... "
    if grep -q "mkdir -p ./tmp" ./instructions/president_dynamic.md && \
       grep -q "touch ./tmp/worker.*_done.txt" ./instructions/president_dynamic.md && \
       grep -q "./agent-send.sh boss1" ./instructions/president_dynamic.md; then
        echo "✅ OK"
        TEST_RESULTS+=("✅ ワーカー完了報告の修正")
    else
        echo "❌ NG"
        TEST_RESULTS+=("❌ ワーカー完了報告の修正")
    fi
    
    # 問題2: --dangerously-skip-permissionsオプション
    echo -n "  • multi-claudeのオプション実装... "
    if grep -q 'SKIP_PERMISSIONS="--dangerously-skip-permissions"' ./multi-claude && \
       grep -q '\$CLAUDE_CMD \$SKIP_PERMISSIONS' ./multi-claude; then
        echo "✅ OK"
        TEST_RESULTS+=("✅ --dangerously-skip-permissionsオプション")
    else
        echo "❌ NG"
        TEST_RESULTS+=("❌ --dangerously-skip-permissionsオプション")
    fi
    
    echo ""
}

# メイン処理
main() {
    local failed=0
    
    # 修正内容確認
    test_fixes
    
    echo "2. 個別テストの実行"
    echo "-------------------"
    
    # 各テストスクリプトを実行
    run_test "Claude検出テスト" "./tests/test_claude_detection.sh" || ((failed++))
    run_test "ワーカー完了通知テスト" "./tests/test_worker_completion.sh" || ((failed++))
    run_test "権限スキップオプションテスト" "./tests/test_dangerously_skip_permissions_complete.sh" || ((failed++))
    run_test "ターミナル制御テスト" "./tests/test_terminal_control.sh" || ((failed++))
    
    echo ""
    echo "3. テスト結果サマリー"
    echo "-------------------"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    
    echo ""
    if [ $failed -eq 0 ] && [[ ! "${TEST_RESULTS[*]}" =~ "❌" ]]; then
        echo "🎉 全ての修正とテストが成功しました！"
        echo ""
        echo "次のステップ:"
        echo "  1. git add -A"
        echo "  2. git commit -m 'fix: ワーカー完了報告とdangerously-skip-permissionsオプションの修正'"
        echo "  3. git push origin main"
        echo "  4. git tag v1.0.14 -m 'Release: Worker completion and permissions option fixes'"
        echo "  5. git push origin v1.0.14"
        return 0
    else
        echo "❌ いくつかのテストが失敗しました"
        return 1
    fi
}

main