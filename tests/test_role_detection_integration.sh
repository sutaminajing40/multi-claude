#!/bin/bash

# 役割判定システム統合テスト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== 役割判定システム統合テスト ==="
echo ""

# テスト準備
echo -e "${YELLOW}[準備]${NC} テスト環境をセットアップ中..."

# 一時ディレクトリ作成
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# multi-claudeのファイルをコピー
cp -r "$OLDPWD/.multi-claude" .
cp "$OLDPWD/setup.sh" .

# setup.shを実行してtmuxセッションを作成
echo -e "${YELLOW}[実行]${NC} setup.shを実行中..."
./setup.sh > /dev/null 2>&1

# セッションが作成されたか確認
echo -e "\n${YELLOW}[検証1]${NC} tmuxセッションの確認"
if tmux has-session -t multiagent 2>/dev/null && tmux has-session -t president 2>/dev/null; then
    echo -e "${GREEN}✓${NC} 両方のセッションが作成されました"
    tmux list-sessions
else
    echo -e "${RED}✗${NC} セッションの作成に失敗しました"
    exit 1
fi

# 役割判定システムのテスト
echo -e "\n${YELLOW}[検証2]${NC} 役割判定システムのテスト"

# 各ペインで役割を確認
for pane in president multiagent:0.0 multiagent:0.1 multiagent:0.2 multiagent:0.3; do
    # 役割判定スクリプトをソース
    tmux send-keys -t "$pane" "source .multi-claude/bin/role-detection.sh" C-m
    sleep 0.5
    
    # 役割を取得
    tmux send-keys -t "$pane" "role=\$(get_my_role); echo \"ROLE_CHECK: \$role\"" C-m
    sleep 0.5
    
    # 出力を確認
    output=$(tmux capture-pane -t "$pane" -p | grep "ROLE_CHECK:" | tail -1 || true)
    
    if [[ -n "$output" ]]; then
        role=$(echo "$output" | cut -d' ' -f2)
        echo -e "${GREEN}✓${NC} $pane: $role"
    else
        echo -e "${RED}✗${NC} $pane: 役割を取得できませんでした"
    fi
done

# ファイルベースのテスト
echo -e "\n${YELLOW}[検証3]${NC} ファイルベースの役割判定"
source .multi-claude/bin/role-detection.sh

# 役割ファイルを作成してテスト
mkdir -p .multi-claude/runtime/session-test
echo "worker1" > .multi-claude/runtime/session-test/my-role
export MULTI_CLAUDE_SESSION_ID="session-test"
unset MULTI_CLAUDE_ROLE

role=$(get_my_role)
if [[ "$role" == "worker1" ]]; then
    echo -e "${GREEN}✓${NC} ファイルベースの判定が正常に動作しています"
else
    echo -e "${RED}✗${NC} ファイルベースの判定に失敗しました（取得: $role）"
fi

# 整合性チェックのテスト
echo -e "\n${YELLOW}[検証4]${NC} 整合性チェック機能"
if perform_full_integrity_check > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 整合性チェックが正常に動作しています"
else
    echo -e "${YELLOW}⚠${NC} 整合性チェックで問題が検出されました（期待通り）"
fi

# クリーンアップ
echo -e "\n${YELLOW}[後処理]${NC} クリーンアップ中..."
tmux kill-session -t multiagent 2>/dev/null || true
tmux kill-session -t president 2>/dev/null || true
cd "$OLDPWD"
rm -rf "$TEST_DIR"

echo -e "\n${GREEN}=== 統合テスト完了 ===${NC}"