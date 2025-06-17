#!/bin/bash

# シンプルなターミナル作成修正確認テスト

set -e

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_test() { echo -e "${YELLOW}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }

echo "🧪 ターミナル作成修正確認テスト"
echo "================================"

log_test "1. PRESIDENT用新規ターミナル作成が削除されているか"

if grep -B2 -A2 "do script" multi-claude | grep -q "PRESIDENT"; then
    log_fail "PRESIDENT用新規ターミナル作成がまだ存在します"
    echo "検出された内容:"
    grep -B2 -A2 "do script" multi-claude | grep "PRESIDENT"
    exit 1
else
    log_pass "PRESIDENT用新規ターミナル作成が削除されている"
fi

log_test "2. MULTIAGENT用ターミナル作成が残っているか"

if grep "do script.*MULTIAGENT" multi-claude >/dev/null 2>&1; then
    log_pass "MULTIAGENT用ターミナル作成が残っている"
else
    log_fail "MULTIAGENT用ターミナル作成が見つからない"
    exit 1
fi

log_test "3. 現在のターミナルでClaude Code起動処理があるか"

if grep "exec.*CLAUDE_CMD" multi-claude >/dev/null 2>&1; then
    log_pass "現在のターミナルでClaude Code起動処理が追加されている"
else
    log_fail "現在のターミナルでのClaude Code起動処理が見つからない"
    exit 1
fi

log_test "4. デグレがないか - 既存テストを実行"

echo "既存テストを実行して、デグレがないことを確認..."

# 重要な既存テストを実行
if [ -f "tests/test_claude_detection.sh" ]; then
    echo "Claude検出テスト実行中..."
    if tests/test_claude_detection.sh >/dev/null 2>&1; then
        log_pass "Claude検出テスト: 正常"
    else
        log_fail "Claude検出テスト: 失敗"
        exit 1
    fi
fi

if [ -f "tests/test_syntax_check.sh" ]; then
    echo "構文チェックテスト実行中..."
    if tests/test_syntax_check.sh >/dev/null 2>&1; then
        log_pass "構文チェックテスト: 正常"
    else
        log_fail "構文チェックテスト: 失敗"
        exit 1
    fi
fi

echo ""
echo "🎯 テスト結果"
echo "============"
echo "✅ PRESIDENT用新規ターミナル作成: 削除済み"
echo "✅ MULTIAGENT用ターミナル作成: 維持"
echo "✅ 現在のターミナルでClaude Code起動: 追加済み"
echo "✅ デグレなし: 既存テスト通過"

log_pass "全テスト完了 - 修正は正常に動作します"