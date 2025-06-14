#!/bin/bash
# 修正版のテスト - multi-claudeが正しく動作するか確認

echo "🧪 Testing Fixed Multi-Claude Implementation"
echo "==========================================="
echo ""

# テスト1: 最小限の環境でも動作することを確認
echo "TEST 1: Minimal environment test"
echo "Running multi-claude with minimal env..."
echo ""

env -i HOME="$HOME" PATH="/usr/local/bin:/usr/bin:/bin" bash -c '
cd /Users/iguchihiroto/dev/multi-claude
echo "Current PATH: $PATH"
echo ""

# multi-claudeスクリプトの該当部分を直接実行
export PATH="$HOME/.claude/local:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

# 修正版の検出ロジックをテスト
CLAUDE_CMD=""

# 1. 直接パスを最優先で確認
if [ -x "$HOME/.claude/local/claude" ]; then
    CLAUDE_CMD="$HOME/.claude/local/claude"
    echo "✅ Found claude at: $CLAUDE_CMD"
elif which claude >/dev/null 2>&1; then
    CLAUDE_CMD=$(which claude 2>/dev/null)
    echo "✅ Found claude via which: $CLAUDE_CMD"
elif command -v claude >/dev/null 2>&1; then
    CLAUDE_CMD="claude"
    echo "✅ Found claude via command -v"
else
    echo "❌ Claude not found"
    exit 1
fi

if [ -n "$CLAUDE_CMD" ]; then
    echo ""
    echo "🎉 SUCCESS: Claude command detected!"
    echo "   Location: $CLAUDE_CMD"
    echo "   Executable: $([ -x "$CLAUDE_CMD" ] && echo "Yes" || echo "No")"
else
    echo ""
    echo "❌ FAILED: Claude command not detected"
    exit 1
fi
'

echo ""
echo "==========================================="
echo "TEST 2: Actual multi-claude script test"
echo ""

# 実際のmulti-claudeスクリプトが動作するかチェック（ヘルプ表示のみ）
if /Users/iguchihiroto/dev/multi-claude/multi-claude --help >/dev/null 2>&1; then
    echo "✅ multi-claude --help executes successfully"
else
    echo "❌ multi-claude --help failed"
fi

echo ""
echo "==========================================="
echo "Test completed!"