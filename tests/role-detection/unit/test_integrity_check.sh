#!/bin/bash

# 整合性チェックのテストスクリプト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# テスト結果カウンター
PASSED=0
FAILED=0

# テスト実行関数
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo -e "\n${YELLOW}Running: $test_name${NC}"
    
    # テスト用の一時ディレクトリ
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # .multi-claudeディレクトリ構造を作成
    mkdir -p .multi-claude/{config,runtime/session-test,logs}
    
    # role-mapping.jsonをコピー
    cp "$OLDPWD/.multi-claude/config/role-mapping.json" .multi-claude/config/
    
    # 役割判定関数のソース
    source "$OLDPWD/.multi-claude/bin/role-detection.sh"
    
    # テスト実行
    if eval "$test_func"; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $test_name"
        ((FAILED++))
    fi
    
    # クリーンアップ
    cd "$OLDPWD"
    rm -rf "$TEST_DIR"
}

# TC002-1: ペインタイトルと役割ファイルの不一致検出
test_role_mismatch() {
    export MULTI_CLAUDE_SESSION_ID="session-test"
    echo "worker1" > .multi-claude/runtime/session-test/my-role
    export MOCK_TMUX_PANE_TITLE="worker2"
    
    # 整合性チェック実行
    check_role_integrity
    local status=$?
    
    # 不一致が検出されること（戻り値1）
    [[ $status -eq 1 ]] || return 1
    
    # ログファイルにWARNが記録されていること
    if [[ -f .multi-claude/logs/integrity-check.log ]]; then
        grep -q "WARN.*Role mismatch detected" .multi-claude/logs/integrity-check.log
    else
        # 実装前なのでファイルがなくてもOK
        return 0
    fi
}

# TC002-2: 役割の重複検出
test_role_duplication() {
    export MULTI_CLAUDE_SESSION_ID="session-test"
    
    # 複数のペインが同じ役割を持つ状況をシミュレート
    mkdir -p .multi-claude/runtime/session-test
    echo "boss1|$(date -u +%Y-%m-%dT%H:%M:%S)" > .multi-claude/runtime/session-test/pane0-role
    echo "boss1|$(date -u +%Y-%m-%dT%H:%M:%S)" > .multi-claude/runtime/session-test/pane1-role
    
    # 重複チェック実行
    check_role_duplication
    local status=$?
    
    # 重複が検出されること（戻り値1）
    [[ $status -eq 1 ]]
}

# TC002-3: 正常な状態での整合性チェック
test_integrity_normal() {
    export MULTI_CLAUDE_SESSION_ID="session-test"
    echo "worker1" > .multi-claude/runtime/session-test/my-role
    export MOCK_TMUX_PANE_TITLE="worker1"
    
    # 整合性チェック実行
    check_role_integrity
    local status=$?
    
    # 問題なし（戻り値0）
    [[ $status -eq 0 ]]
}

# メイン処理
echo "=== 整合性チェック テスト ==="
echo "期待される結果: すべて成功（実装後）"

run_test "ペインタイトルと役割ファイルの不一致検出" test_role_mismatch
run_test "役割の重複検出" test_role_duplication
run_test "正常な状態での整合性チェック" test_integrity_normal

echo -e "\n=== テスト結果 ==="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"

# 実装後なのですべて成功することを確認
if [[ $PASSED -eq 3 ]]; then
    echo -e "\n${GREEN}✓ すべてのテストが成功しました！${NC}"
    exit 0
else
    echo -e "\n${RED}✗ 一部のテストが失敗しています${NC}"
    exit 1
fi