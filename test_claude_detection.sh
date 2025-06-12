#!/bin/bash
# claudeコマンド検出のテストケース

echo "🧪 Claude Command Detection Tests"
echo "================================="
echo ""

# テスト結果カウンター
PASSED=0
FAILED=0

# テスト1: 直接パスの存在確認
test_direct_path() {
    echo -n "TEST1: Direct path check... "
    if [ -x "$HOME/.claude/local/claude" ]; then
        echo "✅ PASS: Direct path exists"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL: Direct path not found"
        ((FAILED++))
        return 1
    fi
}

# テスト2: 様々なPATH配置での検出
test_various_paths() {
    echo -n "TEST2: Various path detection... "
    local found=0
    local found_cmd=""
    
    # claude, claude-code, claude.codeなどのバリエーション
    for cmd in claude claude-code claude.code; do
        if which $cmd 2>/dev/null; then
            found=1
            found_cmd=$cmd
            break
        elif [ -x "$HOME/.claude/local/$cmd" ]; then
            found=1
            found_cmd="$HOME/.claude/local/$cmd"
            break
        fi
    done
    
    if [ $found -eq 1 ]; then
        echo "✅ PASS: Found as '$found_cmd'"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL: No claude variants found"
        ((FAILED++))
        return 1
    fi
}

# テスト3: 実行可能性の確認
test_executable() {
    echo -n "TEST3: Executable check... "
    local claude_cmd=""
    
    if [ -x "$HOME/.claude/local/claude" ]; then
        claude_cmd="$HOME/.claude/local/claude"
    elif which claude 2>/dev/null; then
        claude_cmd=$(which claude 2>/dev/null)
    fi
    
    if [ -n "$claude_cmd" ] && [ -x "$claude_cmd" ]; then
        echo "✅ PASS: Claude is executable at $claude_cmd"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL: Claude not executable"
        ((FAILED++))
        return 1
    fi
}

# テスト4: 現在のmulti-claude実装でのテスト
test_current_implementation() {
    echo -n "TEST4: Current multi-claude logic... "
    
    # multi-claudeの現在の検出ロジックを再現
    export PATH="$HOME/.claude/local:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"
    CLAUDE_DIRECT_PATH="$HOME/.claude/local/claude"
    
    if ! command -v claude &> /dev/null && [ ! -x "$CLAUDE_DIRECT_PATH" ]; then
        echo "❌ FAIL: Current logic fails to detect claude"
        ((FAILED++))
        return 1
    else
        echo "✅ PASS: Current logic detects claude"
        ((PASSED++))
        return 0
    fi
}

# テスト5: 修正版の検出ロジック
test_improved_detection() {
    echo -n "TEST5: Improved detection logic... "
    
    local CLAUDE_CMD=""
    
    # 1. 直接パスを最優先で確認
    if [ -x "$HOME/.claude/local/claude" ]; then
        CLAUDE_CMD="$HOME/.claude/local/claude"
    # 2. whichコマンドで検索
    elif which claude 2>/dev/null; then
        CLAUDE_CMD=$(which claude 2>/dev/null)
    # 3. claude-codeやclaude.codeなどのバリエーションも確認
    else
        for cmd in claude-code claude.code; do
            if which $cmd 2>/dev/null; then
                CLAUDE_CMD=$(which $cmd 2>/dev/null)
                break
            fi
        done
    fi
    
    if [ -n "$CLAUDE_CMD" ]; then
        echo "✅ PASS: Improved logic found claude at $CLAUDE_CMD"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL: Improved logic failed"
        ((FAILED++))
        return 1
    fi
}

# 全テスト実行
echo "Running all tests..."
echo ""

test_direct_path
test_various_paths
test_executable
test_current_implementation
test_improved_detection

echo ""
echo "================================="
echo "Test Results:"
echo "  ✅ PASSED: $PASSED"
echo "  ❌ FAILED: $FAILED"
echo "================================="

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed!"
    exit 1
fi