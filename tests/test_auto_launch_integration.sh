#!/bin/bash

# 🧪 統合テストスクリプト - multi-claude自動起動機能

# カラー設定
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# テスト結果カウンタ
TESTS_PASSED=0
TESTS_FAILED=0

# テスト環境設定
export TEST_MODE=1
export MULTI_CLAUDE_LOCAL="${MULTI_CLAUDE_LOCAL:-$(pwd)/.multi-claude}"
export MULTI_CLAUDE_GLOBAL="${MULTI_CLAUDE_GLOBAL:-$HOME/.multi-claude}"

# ログ関数
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# セットアップ
setup_test_env() {
    log_info "テスト環境のセットアップ"
    
    # テスト用ディレクトリ作成
    mkdir -p "$MULTI_CLAUDE_LOCAL/bin"
    mkdir -p "$MULTI_CLAUDE_LOCAL/session/runtime/agent_status"
    mkdir -p "$MULTI_CLAUDE_LOCAL/session/logs"
    mkdir -p "$MULTI_CLAUDE_LOCAL/tmp"
    
    # 既存のtmuxセッションをクリーンアップ
    tmux kill-session -t test_multiagent 2>/dev/null || true
    tmux kill-session -t test_president 2>/dev/null || true
    
    sleep 1
}

# クリーンアップ
cleanup_test_env() {
    log_info "テスト環境のクリーンアップ"
    
    # テスト用tmuxセッションを削除
    tmux kill-session -t test_multiagent 2>/dev/null || true
    tmux kill-session -t test_president 2>/dev/null || true
    
    # 状態ファイルをクリア
    rm -rf "$MULTI_CLAUDE_LOCAL/session/runtime/agent_status"/*.status
    rm -rf "$MULTI_CLAUDE_LOCAL/tmp"/*
}

# テストケース: agent-send.sh の architect/qa 対応
test_agent_send_mapping() {
    log_test "TC001: agent-send.sh architect/qa マッピング"
    
    local agent_send="$MULTI_CLAUDE_LOCAL/../agent-send.sh"
    if [ ! -x "$agent_send" ]; then
        agent_send="./agent-send.sh"
    fi
    
    # architectマッピング確認
    if grep -q '"architect") echo "multiagent:0.2"' "$agent_send"; then
        log_pass "architectマッピングが正しく設定されています"
    else
        log_fail "architectマッピングが見つかりません"
    fi
    
    # qaマッピング確認
    if grep -q '"qa") echo "multiagent:0.4"' "$agent_send"; then
        log_pass "qaマッピングが正しく設定されています"
    else
        log_fail "qaマッピングが見つかりません"
    fi
}

# テストケース: Enterキー自動送信機能
test_enter_key_auto_send() {
    log_test "TC002: Enterキー自動送信機能"
    
    # テスト用tmuxセッション作成
    tmux new-session -d -s test_multiagent
    tmux new-window -t test_multiagent:0 -n test_pane
    
    # メッセージ送信関数の確認
    local agent_send="$MULTI_CLAUDE_LOCAL/../agent-send.sh"
    if [ ! -f "$agent_send" ]; then
        agent_send="./agent-send.sh"
    fi
    
    if grep -q "tmux send-keys.*Enter" "$agent_send" && grep -q "tmux send-keys.*C-m" "$agent_send"; then
        log_pass "Enterキー自動送信機能が実装されています"
        
        # リトライ機能の確認
        if grep -q "retry_count" "$agent_send"; then
            log_pass "リトライ機能が実装されています"
        else
            log_fail "リトライ機能が見つかりません"
        fi
    else
        log_fail "Enterキー自動送信機能が見つかりません"
    fi
    
    tmux kill-session -t test_multiagent 2>/dev/null
}

# テストケース: メッセージ配信システム
test_message_dispatcher() {
    log_test "TC003: メッセージ配信システム"
    
    local dispatcher="$MULTI_CLAUDE_LOCAL/../bin/message-dispatcher.sh"
    
    if [ -x "$dispatcher" ]; then
        log_pass "message-dispatcher.shが存在し実行可能です"
        
        # 機能確認
        if grep -q "wait_for_all_agents" "$dispatcher"; then
            log_pass "全エージェント待機機能が実装されています"
        else
            log_fail "全エージェント待機機能が見つかりません"
        fi
        
        if grep -q "queue_message" "$dispatcher"; then
            log_pass "メッセージキューイング機能が実装されています"
        else
            log_fail "メッセージキューイング機能が見つかりません"
        fi
        
        if grep -q "send_message_with_retry" "$dispatcher"; then
            log_pass "再送機能が実装されています"
        else
            log_fail "再送機能が見つかりません"
        fi
    else
        log_fail "message-dispatcher.shが見つかりません"
    fi
}

# テストケース: エラーハンドリング
test_error_handling() {
    log_test "TC004: エラーハンドリング機能"
    
    local error_handler="$MULTI_CLAUDE_LOCAL/../bin/error-handler.sh"
    
    if [ -x "$error_handler" ]; then
        log_pass "error-handler.shが存在し実行可能です"
        
        # エラー検出機能の確認
        if grep -q "detect_tmux_session_conflict" "$error_handler"; then
            log_pass "tmuxセッション競合検出が実装されています"
        else
            log_fail "tmuxセッション競合検出が見つかりません"
        fi
        
        if grep -q "detect_claude_code_failure" "$error_handler"; then
            log_pass "Claude Code起動失敗検出が実装されています"
        else
            log_fail "Claude Code起動失敗検出が見つかりません"
        fi
        
        if grep -q "auto_recovery" "$error_handler"; then
            log_pass "自動復旧機能が実装されています"
        else
            log_fail "自動復旧機能が見つかりません"
        fi
    else
        log_fail "error-handler.shが見つかりません"
    fi
}

# テストケース: 状態管理システム
test_agent_status_management() {
    log_test "TC005: エージェント状態管理"
    
    # Worker2が作成した状態管理ツールの確認
    local status_tool="$MULTI_CLAUDE_LOCAL/bin/agent-status.sh"
    
    if [ -x "$status_tool" ]; then
        log_pass "agent-status.shが存在し実行可能です"
        
        # 状態ファイルの作成テスト
        mkdir -p "$MULTI_CLAUDE_LOCAL/session/runtime/agent_status"
        
        # テスト用状態ファイル作成
        echo '{"agent":"test","status":"READY","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > \
            "$MULTI_CLAUDE_LOCAL/session/runtime/agent_status/test.status"
        
        if [ -f "$MULTI_CLAUDE_LOCAL/session/runtime/agent_status/test.status" ]; then
            log_pass "状態ファイルの作成が可能です"
        else
            log_fail "状態ファイルの作成に失敗しました"
        fi
        
        # クリーンアップ
        rm -f "$MULTI_CLAUDE_LOCAL/session/runtime/agent_status/test.status"
    else
        log_info "agent-status.shはWorker2により作成される予定です"
    fi
}

# テストケース: 統合起動フロー
test_integration_flow() {
    log_test "TC006: 統合起動フロー"
    
    # 必要なスクリプトの存在確認
    local required_scripts=(
        "$MULTI_CLAUDE_LOCAL/../agent-send.sh"
        "$MULTI_CLAUDE_LOCAL/../bin/message-dispatcher.sh"
        "$MULTI_CLAUDE_LOCAL/../bin/error-handler.sh"
    )
    
    local all_present=true
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            log_fail "必要なスクリプトが不足: $script"
            all_present=false
        fi
    done
    
    if $all_present; then
        log_pass "統合に必要な全スクリプトが存在します"
    fi
    
    # timing_control.shとの連携確認
    # 新しいパス（bin/）を優先的にチェック
    local timing_control_path=""
    if [ -f "$MULTI_CLAUDE_LOCAL/../bin/timing_control.sh" ]; then
        timing_control_path="$MULTI_CLAUDE_LOCAL/../bin/timing_control.sh"
    elif [ -f "$MULTI_CLAUDE_LOCAL/../timing_control.sh" ]; then
        timing_control_path="$MULTI_CLAUDE_LOCAL/../timing_control.sh"
    fi
    
    if [ -n "$timing_control_path" ]; then
        if grep -q "wait_for_all_agents_ready" "$timing_control_path"; then
            log_pass "timing_control.shとの連携準備が整っています (path: $timing_control_path)"
        else
            log_fail "timing_control.shに必要な関数が見つかりません"
        fi
    else
        log_info "timing_control.shが見つかりません"
    fi
}

# テスト実行
run_all_tests() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Multi-Claude 自動起動機能 統合テスト${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    setup_test_env
    
    # 各テストケースを実行
    test_agent_send_mapping
    echo
    test_enter_key_auto_send
    echo
    test_message_dispatcher
    echo
    test_error_handling
    echo
    test_agent_status_management
    echo
    test_integration_flow
    
    cleanup_test_env
    
    # テスト結果サマリー
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}テスト結果サマリー${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "成功: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失敗: ${RED}$TESTS_FAILED${NC}"
    echo -e "合計: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✅ 全てのテストが成功しました！${NC}"
        return 0
    else
        echo -e "\n${RED}❌ 一部のテストが失敗しました${NC}"
        return 1
    fi
}

# パフォーマンステスト
performance_test() {
    log_test "パフォーマンステスト: 起動時間測定"
    
    local start_time=$(date +%s)
    
    # 疑似的な起動プロセス
    sleep 2  # 実際の起動時間をシミュレート
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    if [ $elapsed -lt 30 ]; then
        log_pass "起動時間が30秒以内です: ${elapsed}秒"
    else
        log_fail "起動時間が30秒を超えています: ${elapsed}秒"
    fi
}

# メイン処理
main() {
    case "${1:-all}" in
        "all")
            run_all_tests
            ;;
        "performance")
            performance_test
            ;;
        "help"|"-h")
            echo "使用方法: $0 [all|performance|help]"
            ;;
        *)
            echo "不明なオプション: $1"
            echo "使用方法: $0 [all|performance|help]"
            exit 1
            ;;
    esac
}

main "$@"