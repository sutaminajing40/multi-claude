#!/bin/bash

# Test: agent-send.shが正しい場所に配置されることを確認

echo "=== agent-send.sh配置場所テスト ==="

# テスト用の一時ディレクトリを作成
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# multi-claudeコマンドの場所を取得
if [ -n "$MULTI_CLAUDE_CMD" ]; then
    # 環境変数から指定されたコマンドを使用
    echo "指定されたmulti-claudeコマンドを使用: $MULTI_CLAUDE_CMD"
else
    MULTI_CLAUDE_CMD=$(which multi-claude)
    if [ -z "$MULTI_CLAUDE_CMD" ]; then
        echo "Error: multi-claudeコマンドが見つかりません"
        exit 1
    fi
fi

# テスト環境をセットアップ
mkdir -p .multi-claude/bin
echo "claude" > .multi-claude/bin/claude_path.txt

# multi-claudeを実行（権限確認をスキップ）
echo "multi-claudeを実行中..."
export HOME="$TEST_DIR"
"$MULTI_CLAUDE_CMD" --dangerously-skip-permissions &
MULTI_CLAUDE_PID=$!

# 少し待機
sleep 3

# agent-send.shの配置場所を確認
echo -e "\n=== agent-send.shの配置場所確認 ==="

# ルートディレクトリにagent-send.shが存在しないことを確認
if [ -f "$TEST_DIR/agent-send.sh" ]; then
    echo "❌ FAIL: agent-send.shがルートディレクトリに存在します"
    ls -la "$TEST_DIR/agent-send.sh"
else
    echo "✅ PASS: agent-send.shがルートディレクトリに存在しません"
fi

# .multi-claude/bin/にagent-send.shが存在することを確認
if [ -f "$TEST_DIR/.multi-claude/bin/agent-send.sh" ]; then
    echo "✅ PASS: agent-send.shが.multi-claude/bin/に存在します"
    ls -la "$TEST_DIR/.multi-claude/bin/agent-send.sh"
    
    # 実行権限があることを確認
    if [ -x "$TEST_DIR/.multi-claude/bin/agent-send.sh" ]; then
        echo "✅ PASS: agent-send.shに実行権限があります"
    else
        echo "❌ FAIL: agent-send.shに実行権限がありません"
    fi
else
    echo "❌ FAIL: agent-send.shが.multi-claude/bin/に存在しません"
fi

# プロセスを終了
kill $MULTI_CLAUDE_PID 2>/dev/null
wait $MULTI_CLAUDE_PID 2>/dev/null

# tmuxセッションをクリーンアップ
tmux kill-session -t multiagent 2>/dev/null
tmux kill-session -t president 2>/dev/null

# テスト結果のサマリー
echo -e "\n=== テスト結果サマリー ==="
if [ -f "$TEST_DIR/agent-send.sh" ]; then
    echo "❌ テスト失敗: agent-send.shがルートディレクトリに存在します"
    RESULT=1
elif [ ! -f "$TEST_DIR/.multi-claude/bin/agent-send.sh" ]; then
    echo "❌ テスト失敗: agent-send.shが.multi-claude/bin/に存在しません"
    RESULT=1
else
    echo "✅ テスト成功: agent-send.shが正しい場所に配置されています"
    RESULT=0
fi

# クリーンアップ
cd /
rm -rf "$TEST_DIR"

exit $RESULT