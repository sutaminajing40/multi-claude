#!/bin/bash

# 簡易テストランナー（batsの代替）

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
    local test_file="$2"
    
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
    if eval "$test_file"; then
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

# TC001-1: 環境変数による役割判定
test_env_priority() {
    export MULTI_CLAUDE_ROLE="worker1"
    echo "boss1" > .multi-claude/runtime/session-test/my-role
    
    result=$(get_my_role)
    [[ "$result" == "worker1" ]]
}

# TC001-2: 役割ファイルによる判定
test_file_detection() {
    unset MULTI_CLAUDE_ROLE
    export MULTI_CLAUDE_SESSION_ID="session-test"
    echo "boss1" > .multi-claude/runtime/session-test/my-role
    
    result=$(get_my_role)
    [[ "$result" == "boss1" ]]
}

# TC001-3: ペインタイトルによる判定
test_pane_title() {
    unset MULTI_CLAUDE_ROLE
    export MOCK_TMUX_PANE_TITLE="worker2"
    
    result=$(get_my_role)
    [[ "$result" == "worker2" ]]
}

# メイン処理
echo "=== 役割判定システム ユニットテスト ==="
echo "期待される結果: すべて成功（実装後）"

run_test "環境変数による役割判定" test_env_priority
run_test "役割ファイルによる判定" test_file_detection
run_test "ペインタイトルによる判定" test_pane_title

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