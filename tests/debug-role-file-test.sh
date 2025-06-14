#!/bin/bash

# デバッグ用テストスクリプト

# テスト用の一時ディレクトリ
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# .multi-claudeディレクトリ構造を作成
mkdir -p .multi-claude/{config,runtime/session-test,logs}

# role-mapping.jsonをコピー
cp "$OLDPWD/.multi-claude/config/role-mapping.json" .multi-claude/config/

# 役割判定関数のソース
source "$OLDPWD/.multi-claude/bin/role-detection.sh"

# 環境変数をクリア
unset MULTI_CLAUDE_ROLE

# セッションIDを明示的に設定
export MULTI_CLAUDE_SESSION_ID="session-test"

# 役割ファイルを作成
echo "boss1" > .multi-claude/runtime/session-test/my-role

echo "=== デバッグ情報 ==="
echo "Current directory: $(pwd)"
echo "Role file exists: $(ls -la .multi-claude/runtime/session-test/my-role)"
echo "Role file content: $(cat .multi-claude/runtime/session-test/my-role)"
echo "Session ID: $(get_session_id)"
echo "Role from file: $(read_role_file)"

# 役割判定を実行
echo -e "\n=== 役割判定実行 ==="
result=$(get_my_role)
status=$?

echo "Result: $result"
echo "Status: $status"

# クリーンアップ
cd "$OLDPWD"
rm -rf "$TEST_DIR"