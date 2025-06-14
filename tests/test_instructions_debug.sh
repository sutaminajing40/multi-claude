#!/bin/bash

# instructionsディレクトリのコピー問題をデバッグ

echo "=== instructionsディレクトリデバッグテスト ==="

# テスト用の一時ディレクトリを作成
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
echo "テストディレクトリ: $TEST_DIR"

# テスト用のinstructionsディレクトリを作成
echo "テスト用のinstructionsディレクトリを作成中..."
mkdir -p instructions
echo "# Test President Instructions" > instructions/president_dynamic.md
echo "# Test Boss Instructions" > instructions/boss_dynamic.md
echo "# Test Worker Instructions" > instructions/worker_dynamic.md

# Homebrewの環境変数を確認
echo -e "\n=== Homebrew環境の確認 ==="
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo '/usr/local')"
echo "BREW_PREFIX: $BREW_PREFIX"

if [ -d "${BREW_PREFIX}/Cellar/multi-claude" ]; then
    MULTI_CLAUDE_VERSION=$(ls -1 "${BREW_PREFIX}/Cellar/multi-claude" | sort -V | tail -1)
    MULTI_CLAUDE_BASE="${BREW_PREFIX}/Cellar/multi-claude/${MULTI_CLAUDE_VERSION}"
    MULTI_CLAUDE_BIN="${MULTI_CLAUDE_BASE}/bin"
    MULTI_CLAUDE_SHARE="${MULTI_CLAUDE_BASE}/share"
    
    echo "MULTI_CLAUDE_VERSION: $MULTI_CLAUDE_VERSION"
    echo "MULTI_CLAUDE_BASE: $MULTI_CLAUDE_BASE"
    echo "MULTI_CLAUDE_BIN: $MULTI_CLAUDE_BIN"
    echo "MULTI_CLAUDE_SHARE: $MULTI_CLAUDE_SHARE"
    
    # shareディレクトリの内容を確認
    echo -e "\nshareディレクトリの内容:"
    ls -la "$MULTI_CLAUDE_SHARE"
    
    if [ -d "$MULTI_CLAUDE_SHARE/instructions" ]; then
        echo -e "\nshare/instructionsの内容:"
        ls -la "$MULTI_CLAUDE_SHARE/instructions"
    else
        echo "❌ ERROR: $MULTI_CLAUDE_SHARE/instructionsが存在しません"
    fi
fi

# multi-claudeスクリプトの該当部分を確認
echo -e "\n=== multi-claudeスクリプトの確認 ==="
if [ -n "$MULTI_CLAUDE_CMD" ]; then
    SCRIPT_PATH="$MULTI_CLAUDE_CMD"
else
    SCRIPT_PATH="/usr/local/bin/multi-claude"
fi

echo "スクリプトパス: $SCRIPT_PATH"
echo -e "\nsetup_first_time関数のinstructions部分:"
grep -A10 -B5 "instructionsディレクトリがなければコピー" "$SCRIPT_PATH" || echo "該当部分が見つかりません"

# .multi-claudeディレクトリを作成
mkdir -p .multi-claude

# コピー処理をシミュレート
echo -e "\n=== コピー処理のシミュレーション ==="

# ローカルディレクトリのテスト
if [ -d "./instructions" ]; then
    echo "✅ ローカルのinstructionsディレクトリが存在"
    echo "cp -r ./instructions ./.multi-claude/ を実行"
    cp -r ./instructions ./.multi-claude/
    COPY_RESULT=$?
    echo "コピー結果: $COPY_RESULT"
fi

# コピー後の確認
if [ -d "./.multi-claude/instructions" ]; then
    echo -e "\n✅ .multi-claude/instructionsが作成されました"
    echo "内容:"
    ls -la ./.multi-claude/instructions/
else
    echo -e "\n❌ .multi-claude/instructionsが作成されませんでした"
fi

# クリーンアップ
cd /
rm -rf "$TEST_DIR"

echo -e "\n=== デバッグ完了 ==="