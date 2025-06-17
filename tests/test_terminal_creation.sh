#!/bin/bash

# テスト: PRESIDENT用ターミナル作成の無効化テスト

set -e

# テスト設定
TEST_DIR="/tmp/multi-claude-terminal-test"
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

echo "🧪 Multi-Claude ターミナル作成テスト"
echo "====================================="

# テスト環境準備
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 必要なファイルをコピー
cp "$ORIGINAL_DIR/multi-claude" ./
cp -r "$ORIGINAL_DIR/.multi-claude" ./ 2>/dev/null || true
cp "$ORIGINAL_DIR/setup.sh" ./ 2>/dev/null || true

# 期待される動作をテスト
log_test "1. 現在の動作確認：2つのターミナルが作成されるか"

# multi-claudeスクリプトから、osascriptを使った部分を抽出
PRESIDENT_TERMINAL_COUNT=$(grep -A 20 "ウィンドウ1: PRESIDENT" multi-claude | grep -c "do script" || echo "0")
MULTIAGENT_TERMINAL_COUNT=$(grep -A 20 "ウィンドウ2: MULTIAGENT" multi-claude | grep -c "do script" || echo "0")

if [ "$PRESIDENT_TERMINAL_COUNT" -gt 0 ] && [ "$MULTIAGENT_TERMINAL_COUNT" -gt 0 ]; then
    log_pass "現在は2つのターミナルが作成される設定"
else
    log_fail "現在の設定が期待と異なります"
    exit 1
fi

log_test "2. PRESIDENT用ターミナル作成部分の特定"

# PRESIDENT用ターミナル作成のosascriptブロックを確認
PRESIDENT_OSASCRIPT_START=$(grep -n "ウィンドウ1: PRESIDENT" multi-claude | cut -d: -f1)
PRESIDENT_OSASCRIPT_END=$(grep -n "EOF" multi-claude | head -1 | cut -d: -f1)

if [ -n "$PRESIDENT_OSASCRIPT_START" ] && [ -n "$PRESIDENT_OSASCRIPT_END" ]; then
    log_pass "PRESIDENT用ターミナル作成部分を特定: ${PRESIDENT_OSASCRIPT_START}-${PRESIDENT_OSASCRIPT_END}行目"
else
    log_fail "PRESIDENT用ターミナル作成部分の特定に失敗"
    exit 1
fi

log_test "3. 修正対象の動作を確認"

# 現在のターミナルでmulti-claudeを実行した時に、PRESIDENTセッションにそのまま接続するかテスト
# これは実際の修正後の期待動作

# multi-claudeスクリプトの最後の部分（auto attach）を確認
AUTO_ATTACH_LINE=$(grep -n "tmux attach-session -t president" multi-claude | tail -1 | cut -d: -f1)

if [ -n "$AUTO_ATTACH_LINE" ]; then
    log_pass "現在のターミナルでPRESIDENTセッションに接続する処理が存在"
else
    log_fail "現在のターミナルでの接続処理が見つからない"
    exit 1
fi

echo ""
echo "🎯 テスト結果サマリー"
echo "===================="
echo "✅ 現在の動作：PRESIDENT用とMULTIAGENT用の2つのターミナルを作成"
echo "✅ 修正必要箇所：PRESIDENT用ターミナル作成処理（${PRESIDENT_OSASCRIPT_START}-${PRESIDENT_OSASCRIPT_END}行目）"
echo "✅ 期待動作：現在のターミナルをPRESIDENT用に使用、MULTIAGENT用のみ新規作成"

echo ""
echo "📋 修正計画："
echo "1. PRESIDENT用ターミナル作成処理を削除"
echo "2. 現在のターミナルで直接PRESIDENTセッションに接続"
echo "3. MULTIAGENT用ターミナルのみ作成"

log_pass "全テスト完了"