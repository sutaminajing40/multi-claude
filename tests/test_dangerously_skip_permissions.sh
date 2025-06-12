#!/bin/bash

# テスト: --dangerously-skip-permissions オプションの動作確認

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# テスト結果カウンター
PASSED=0
FAILED=0

# テスト開始
echo "=== Testing --dangerously-skip-permissions option ==="
echo

# テスト関数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command"; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}PASSED${NC}"
            ((PASSED++))
        else
            echo -e "${RED}FAILED${NC} (expected to fail but passed)"
            ((FAILED++))
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}PASSED${NC} (correctly failed)"
            ((PASSED++))
        else
            echo -e "${RED}FAILED${NC}"
            ((FAILED++))
        fi
    fi
}

# Test 1: ヘルプメッセージに --dangerously-skip-permissions が含まれているか
test_help_message() {
    ../multi-claude --help 2>&1 | grep -q "dangerously-skip-permissions"
}
run_test "Help message contains --dangerously-skip-permissions" "test_help_message" "pass"

# Test 2: --dangerously-skip-permissions オプションが認識されるか
test_option_recognized() {
    # オプションが認識されない場合はエラーで終了するはず
    # ここではドライランモードでテスト
    ../multi-claude --dangerously-skip-permissions --dry-run 2>&1 | grep -q "unrecognized option"
    # grepがマッチしなければ成功（オプションが認識された）
    [ $? -ne 0 ]
}
run_test "Option --dangerously-skip-permissions is recognized" "test_option_recognized" "pass"

# Test 3: claudeコマンドに --dangerously-skip-permissions が渡されるか
test_option_passed_to_claude() {
    # ドライランモードで実行し、claudeコマンドに渡される引数を確認
    ../multi-claude --dangerously-skip-permissions --dry-run 2>&1 | grep -q "claude.*--dangerously-skip-permissions"
}
run_test "Option is passed to claude command" "test_option_passed_to_claude" "pass"

# Test 4: 複数のオプションと組み合わせて使えるか
test_combined_options() {
    ../multi-claude --dangerously-skip-permissions --exit --dry-run 2>&1 | grep -q "error"
    # エラーがなければ成功
    [ $? -ne 0 ]
}
run_test "Can combine with other options" "test_combined_options" "pass"

# Test 5: 実際の起動テスト（ドライランモード）
test_actual_launch() {
    # ドライランモードで起動テスト
    OUTPUT=$(../multi-claude --dangerously-skip-permissions --dry-run 2>&1)
    echo "$OUTPUT" | grep -q "Would execute:" && echo "$OUTPUT" | grep -q "dangerously-skip-permissions"
}
run_test "Dry run with --dangerously-skip-permissions" "test_actual_launch" "pass"

# テスト結果サマリー
echo
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

# 終了コード
if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed.${NC}"
    exit 1
fi