#!/bin/bash

# Test: instructionsディレクトリが正しくコピーされることを確認

echo "=== instructionsディレクトリコピーテスト ==="

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

# テスト用のinstructionsディレクトリを作成
echo "テスト用のinstructionsディレクトリを作成中..."
mkdir -p instructions
echo "# Test President Instructions" > instructions/president_dynamic.md
echo "# Test Boss Instructions" > instructions/boss_dynamic.md
echo "# Test Worker Instructions" > instructions/worker_dynamic.md

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

# instructionsディレクトリの確認
echo -e "\n=== instructionsディレクトリの確認 ==="

# .multi-claude/instructionsディレクトリが存在することを確認
if [ -d "$TEST_DIR/.multi-claude/instructions" ]; then
    echo "✅ PASS: .multi-claude/instructionsディレクトリが存在します"
    
    # 各ファイルが存在することを確認
    FILES=("president_dynamic.md" "boss_dynamic.md" "worker_dynamic.md")
    ALL_FILES_EXIST=true
    
    for file in "${FILES[@]}"; do
        if [ -f "$TEST_DIR/.multi-claude/instructions/$file" ]; then
            echo "✅ PASS: $file が存在します"
            # ファイルの内容を確認（オプション）
            echo "  内容: $(head -n1 "$TEST_DIR/.multi-claude/instructions/$file")"
        else
            echo "❌ FAIL: $file が存在しません"
            ALL_FILES_EXIST=false
        fi
    done
    
    # ディレクトリの内容を表示
    echo -e "\n.multi-claude/instructionsの内容:"
    ls -la "$TEST_DIR/.multi-claude/instructions/"
else
    echo "❌ FAIL: .multi-claude/instructionsディレクトリが存在しません"
    ALL_FILES_EXIST=false
fi

# 元のinstructionsディレクトリはそのまま残っていることを確認
if [ -d "$TEST_DIR/instructions" ]; then
    echo -e "\n✅ PASS: 元のinstructionsディレクトリは残っています"
else
    echo -e "\n❌ FAIL: 元のinstructionsディレクトリが削除されています"
fi

# プロセスを終了
kill $MULTI_CLAUDE_PID 2>/dev/null
wait $MULTI_CLAUDE_PID 2>/dev/null

# tmuxセッションをクリーンアップ
tmux kill-session -t multiagent 2>/dev/null
tmux kill-session -t president 2>/dev/null

# テスト結果のサマリー
echo -e "\n=== テスト結果サマリー ==="
if [ "$ALL_FILES_EXIST" = true ]; then
    echo "✅ テスト成功: instructionsディレクトリが正しくコピーされています"
    RESULT=0
else
    echo "❌ テスト失敗: instructionsディレクトリのコピーに問題があります"
    RESULT=1
fi

# クリーンアップ
cd /
rm -rf "$TEST_DIR"

exit $RESULT