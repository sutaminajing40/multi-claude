#!/bin/bash

# Terminal.app制御のテストスクリプト
# TDDアプローチ：まずエラーを再現し、その後修正を実装

set -e

echo "🧪 Terminal.app制御テスト"
echo "========================="

# テスト結果カウンタ
TESTS_PASSED=0
TESTS_FAILED=0

# 色付きログ関数
log_pass() {
    echo -e "\033[1;32m✓\033[0m $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "\033[1;31m✗\033[0m $1"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

# テスト1: 基本的なAppleScriptコマンドのテスト
test_basic_applescript() {
    log_info "テスト1: 基本的なAppleScriptコマンド"
    
    if osascript -e 'tell application "Terminal" to return name' &>/dev/null; then
        log_pass "Terminal.appとの通信が可能"
    else
        log_fail "Terminal.appとの通信に失敗"
    fi
}

# テスト2: 既存のコード（エラーが発生する）
test_original_code() {
    log_info "テスト2: 既存のタブ名設定コード（エラー期待）"
    
    # 現在のディレクトリ
    CURRENT_DIR=$(pwd)
    
    # エラーが発生するコード
    ERROR_OUTPUT=$(osascript << 'EOF' 2>&1 || true
tell application "Terminal"
    activate
    set president_window to do script "echo 'Test window'"
    set name of president_window to "Test: PRESIDENT"
end tell
EOF
)
    
    if [[ "$ERROR_OUTPUT" == *"execution error"* ]] || [[ "$ERROR_OUTPUT" == *"Can't set"* ]]; then
        log_pass "期待通りエラーが発生: タブ名設定に失敗"
        echo "  エラー内容: $(echo "$ERROR_OUTPUT" | head -1)"
    else
        log_fail "エラーが発生しませんでした"
    fi
}

# テスト3: 修正案1 - tabオブジェクトを使用
test_fixed_code_tab() {
    log_info "テスト3: 修正案1 - tabオブジェクトを使用"
    
    # tabオブジェクトとして扱う修正版
    OUTPUT=$(osascript << 'EOF' 2>&1
tell application "Terminal"
    activate
    set newTab to do script "echo 'Test with tab object'"
    tell newTab
        set custom title to "Test: TAB Object"
    end tell
    return "success"
end tell
EOF
)
    
    if [[ "$OUTPUT" == "success" ]]; then
        log_pass "tabオブジェクトでのタイトル設定成功"
    else
        log_fail "tabオブジェクトでのタイトル設定失敗: $OUTPUT"
    fi
}

# テスト4: 修正案2 - windowを介してタブを操作
test_fixed_code_window() {
    log_info "テスト4: 修正案2 - windowを介してタブを操作"
    
    OUTPUT=$(osascript << 'EOF' 2>&1
tell application "Terminal"
    activate
    do script "echo 'Test with window approach'"
    set currentWindow to front window
    set currentTab to selected tab of currentWindow
    tell currentTab
        set custom title to "Test: Window Approach"
    end tell
    return "success"
end tell
EOF
)
    
    if [[ "$OUTPUT" == "success" ]]; then
        log_pass "window経由でのタブタイトル設定成功"
    else
        log_fail "window経由でのタブタイトル設定失敗: $OUTPUT"
    fi
}

# テスト5: 最も安全なアプローチ - エラーハンドリング付き
test_safe_approach() {
    log_info "テスト5: 安全なアプローチ - エラーハンドリング付き"
    
    OUTPUT=$(osascript << 'EOF' 2>&1
tell application "Terminal"
    activate
    try
        do script "echo 'Safe approach test'"
        delay 0.5
        set currentWindow to front window
        set currentTab to selected tab of currentWindow
        tell currentTab
            set custom title to "Test: Safe"
        end tell
        return "success"
    on error errMsg
        return "error: " & errMsg
    end try
end tell
EOF
)
    
    if [[ "$OUTPUT" == "success" ]]; then
        log_pass "安全なアプローチでのタイトル設定成功"
    else
        if [[ "$OUTPUT" == error:* ]]; then
            log_fail "安全なアプローチでもエラー: ${OUTPUT#error: }"
        else
            log_fail "予期しない結果: $OUTPUT"
        fi
    fi
}

# テスト6: 複数ウィンドウのテスト
test_multiple_windows() {
    log_info "テスト6: 複数ウィンドウの作成とタイトル設定"
    
    OUTPUT=$(osascript << 'EOF' 2>&1
tell application "Terminal"
    activate
    
    -- 最初のウィンドウ
    do script "echo 'Window 1'"
    delay 0.5
    set window1 to front window
    set tab1 to selected tab of window1
    tell tab1
        set custom title to "Test: Window 1"
    end tell
    
    -- 2番目のウィンドウ
    do script "echo 'Window 2'"
    delay 0.5
    set window2 to front window
    set tab2 to selected tab of window2
    tell tab2
        set custom title to "Test: Window 2"
    end tell
    
    return "success"
end tell
EOF
)
    
    if [[ "$OUTPUT" == "success" ]]; then
        log_pass "複数ウィンドウの作成とタイトル設定成功"
    else
        log_fail "複数ウィンドウの処理に失敗: $OUTPUT"
    fi
}

# テスト実行
echo ""
test_basic_applescript
echo ""
test_original_code
echo ""
test_fixed_code_tab
echo ""
test_fixed_code_window
echo ""
test_safe_approach
echo ""
test_multiple_windows

# テスト結果サマリー
echo ""
echo "================================="
echo "テスト結果サマリー"
echo "================================="
echo "✅ 成功: $TESTS_PASSED"
echo "❌ 失敗: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 すべてのテストが成功しました！"
    exit 0
else
    echo "⚠️  一部のテストが失敗しました"
    exit 1
fi