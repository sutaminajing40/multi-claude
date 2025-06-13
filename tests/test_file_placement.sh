#!/bin/bash

# Test: ファイルが正しい場所に作成されることを確認

echo "=== Test: File Placement ==="

# テスト用の一時ディレクトリ
TEST_DIR="/tmp/test_multi_claude_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# multi-claudeスクリプトをコピー
cp "$HOME/dev/Claude-Code-Communication/multi-claude" .

# setup.shとagent-send.shもコピー（現在の状態を再現）
cp "$HOME/dev/Claude-Code-Communication/setup.sh" .
cp "$HOME/dev/Claude-Code-Communication/agent-send.sh" .

# テスト1: 初回実行時に.multi-claude/bin/ディレクトリが作成される
echo -n "Test 1: .multi-claude/bin/ directory creation... "
# 一時的にclaudeコマンドを作成（モック）
cat > claude << 'EOF'
#!/bin/bash
echo "Mock claude command"
EOF
chmod +x claude
export PATH="$TEST_DIR:$PATH"

# multi-claudeを実行（初回セットアップが走るはず）
# バックグラウンドで実行して、3秒後にkill
(./multi-claude 2>&1 > /dev/null) &
PID=$!
sleep 3
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

if [ -d ".multi-claude/bin" ]; then
    echo "PASS"
else
    echo "FAIL: .multi-claude/bin/ directory not created"
    # デバッグ情報
    echo "Contents of current directory:"
    ls -la
    exit 1
fi

# テスト2: setup.shが.multi-claude/bin/に配置される
echo -n "Test 2: setup.sh placement in .multi-claude/bin/... "
if [ -f ".multi-claude/bin/setup.sh" ]; then
    echo "PASS"
else
    echo "FAIL: setup.sh not found in .multi-claude/bin/"
    exit 1
fi

# テスト3: agent-send.shが.multi-claude/bin/に配置される
echo -n "Test 3: agent-send.sh placement in .multi-claude/bin/... "
if [ -f ".multi-claude/bin/agent-send.sh" ]; then
    echo "PASS"
else
    echo "FAIL: agent-send.sh not found in .multi-claude/bin/"
    exit 1
fi

# テスト4: ルートディレクトリのagent-send.shはシンボリックリンク
echo -n "Test 4: Root agent-send.sh is symlink... "
if [ -L "./agent-send.sh" ]; then
    LINK_TARGET=$(readlink ./agent-send.sh)
    if [ "$LINK_TARGET" = ".multi-claude/bin/agent-send.sh" ] || [ "$LINK_TARGET" = "./.multi-claude/bin/agent-send.sh" ]; then
        echo "PASS"
    else
        echo "FAIL: symlink target is '$LINK_TARGET', expected '.multi-claude/bin/agent-send.sh'"
        exit 1
    fi
else
    echo "FAIL: ./agent-send.sh is not a symlink"
    ls -la ./agent-send.sh
    exit 1
fi

# テスト5: ルートディレクトリのsetup.shは存在しない（不要）
echo -n "Test 5: Root setup.sh should not exist... "
if [ ! -e "./setup.sh" ]; then
    echo "PASS"
else
    echo "FAIL: ./setup.sh should not exist in root"
    exit 1
fi

# テスト6: 実行権限の確認
echo -n "Test 6: Executable permissions... "
if [ -x ".multi-claude/bin/setup.sh" ] && [ -x ".multi-claude/bin/agent-send.sh" ]; then
    echo "PASS"
else
    echo "FAIL: Scripts do not have executable permissions"
    exit 1
fi

# クリーンアップ
cd /
rm -rf "$TEST_DIR"

echo "=== All tests passed! ==="