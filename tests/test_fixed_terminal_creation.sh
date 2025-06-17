#!/bin/bash

# テスト: PRESIDENT用ターミナル作成無効化後のテスト

set -e

# テスト設定
TEST_DIR="/tmp/multi-claude-fixed-terminal-test"
ORIGINAL_DIR=$(pwd)

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ヘルパー関数
log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# クリーンアップ関数
cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR" 2>/dev/null || true
    # tmuxセッションクリーンアップ
    tmux kill-server 2>/dev/null || true
}

# シグナルハンドラー設定
trap cleanup EXIT

echo "🧪 Multi-Claude 修正後ターミナル作成テスト"
echo "============================================"

# テスト環境準備
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 必要なファイルをコピー
cp "$ORIGINAL_DIR/multi-claude" ./

log_test "1. PRESIDENT用ターミナル作成処理が削除されているか"

# PRESIDENT用新規ターミナル作成処理が削除されているかチェック
# "do script"と"PRESIDENT"が同時に含まれる行がないことを確認
PRESIDENT_TERMINAL_COUNT=$(grep -B2 -A2 "do script" multi-claude | grep -c "PRESIDENT" 2>/dev/null || echo "0")

if [ "$PRESIDENT_TERMINAL_COUNT" -eq 0 ]; then
    log_pass "PRESIDENT用新規ターミナル作成処理が削除されている"
else
    log_fail "PRESIDENT用新規ターミナル作成処理がまだ存在する"
    echo "残存している処理:"
    grep -B2 -A2 "do script" multi-claude | grep "PRESIDENT" || true
    exit 1
fi

log_test "2. MULTIAGENT用ターミナル作成処理が残っているか"

# MULTIAGENT用ターミナル作成のosascriptブロックが残っているかチェック
MULTIAGENT_TERMINAL_COUNT=$(grep -c "👥 MULTIAGENT ウィンドウ" multi-claude 2>/dev/null || echo "0")

if [ "$MULTIAGENT_TERMINAL_COUNT" -gt 0 ]; then
    log_pass "MULTIAGENT用ターミナル作成処理が残っている"
else
    log_fail "MULTIAGENT用ターミナル作成処理が見つからない"
    exit 1
fi

log_test "3. 現在のターミナルでClaude Code起動処理が追加されているか"

# 現在のターミナルでClaude Codeを起動する処理があるかチェック
CURRENT_TERMINAL_EXEC=$(grep -c "exec.*CLAUDE_CMD" multi-claude 2>/dev/null || echo "0")

if [ "$CURRENT_TERMINAL_EXEC" -gt 0 ]; then
    log_pass "現在のターミナルでClaude Code起動処理が追加されている"
else
    log_fail "現在のターミナルでのClaude Code起動処理が見つからない"
    exit 1
fi

log_test "4. ログメッセージが修正されているか"

# ログメッセージが修正されているかチェック
MULTIAGENT_LOG=$(grep -c "MULTIAGENTターミナルウィンドウ起動" multi-claude 2>/dev/null || echo "0")
CURRENT_TERMINAL_MESSAGE=$(grep -c "現在のターミナル: PRESIDENT" multi-claude 2>/dev/null || echo "0")

if [ "$MULTIAGENT_LOG" -gt 0 ] && [ "$CURRENT_TERMINAL_MESSAGE" -gt 0 ]; then
    log_pass "ログメッセージが適切に修正されている"
else
    log_fail "ログメッセージの修正が不十分"
    exit 1
fi

log_test "5. Linux環境での修正も適切か"

# Linux環境でのPRESIDENT用ターミナル作成が削除されているかチェック
LINUX_PRESIDENT_COUNT=$(grep -A 10 "linux-gnu" multi-claude | grep -c "PRESIDENT" 2>/dev/null || echo "0")

if [ "$LINUX_PRESIDENT_COUNT" -eq 0 ]; then
    log_pass "Linux環境でもPRESIDENT用ターミナル作成が削除されている"
else
    log_fail "Linux環境でPRESIDENT用ターミナル作成が残っている"
    exit 1
fi

echo ""
echo "🎯 修正後テスト結果サマリー"
echo "=========================="
echo "✅ PRESIDENT用ターミナル作成処理：削除済み"
echo "✅ MULTIAGENT用ターミナル作成処理：維持"
echo "✅ 現在のターミナルでClaude Code起動：追加済み"
echo "✅ ログメッセージ：適切に修正"
echo "✅ Linux環境対応：修正済み"

echo ""
echo "📋 期待される動作："
echo "1. multi-claude実行時、MULTIAGENTウィンドウのみ新規作成"
echo "2. 現在のターミナルでPRESIDENT用Claude Codeが起動"
echo "3. ユーザーは実行したターミナルでそのままPRESIDENTと対話可能"

log_pass "全テスト完了 - 修正が正常に適用されました"