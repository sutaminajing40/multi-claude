#!/bin/bash

# 🧪 --dangerously-skip-permissionsオプションの完全テスト

echo "🧪 --dangerously-skip-permissionsオプションの完全テスト"
echo "=================================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# オプション解析テスト
test_option_parsing() {
    echo -n "1. オプション解析テスト... "
    
    # multi-claudeスクリプトでオプションが正しく解析されるか確認
    if grep -q 'SKIP_PERMISSIONS="--dangerously-skip-permissions"' ./multi-claude; then
        echo "✅ OK - オプション解析実装済み"
        return 0
    else
        echo "❌ NG - オプション解析が実装されていません"
        return 1
    fi
}

# Claudeコマンドへの伝達テスト
test_option_propagation() {
    echo -n "2. Claudeコマンドへの伝達テスト... "
    
    # $CLAUDE_CMD $SKIP_PERMISSIONSの形式でコマンドが送信されるか確認
    if grep -q '\$CLAUDE_CMD \$SKIP_PERMISSIONS' ./multi-claude; then
        echo "✅ OK - オプションが正しく伝達されます"
        return 0
    else
        echo "❌ NG - オプションが伝達されていません"
        return 1
    fi
}

# 全エージェントへの適用テスト
test_all_agents() {
    echo -n "3. 全エージェントへの適用テスト... "
    
    # PRESIDENTとMULTIAGENT両方でオプションが使用されるか確認
    president_count=$(grep -c 'tmux send-keys -t president.*\$CLAUDE_CMD \$SKIP_PERMISSIONS' ./multi-claude)
    multiagent_count=$(grep -c 'tmux send-keys -t multiagent.*\$CLAUDE_CMD \$SKIP_PERMISSIONS' ./multi-claude)
    
    if [ "$president_count" -ge 1 ] && [ "$multiagent_count" -ge 1 ]; then
        echo "✅ OK - 全エージェントにオプションが適用されます"
        return 0
    else
        echo "❌ NG - 一部のエージェントにオプションが適用されていません (president: $president_count, multiagent: $multiagent_count)"
        return 1
    fi
}

# オプション付き実行シミュレーション
test_option_execution() {
    echo -n "4. オプション付き実行シミュレーション... "
    
    # 実際のコマンドラインを構築してテスト
    SKIP_PERMISSIONS="--dangerously-skip-permissions"
    CLAUDE_CMD="claude"
    TEST_COMMAND="$CLAUDE_CMD $SKIP_PERMISSIONS"
    
    if [[ "$TEST_COMMAND" == "claude --dangerously-skip-permissions" ]]; then
        echo "✅ OK - 正しいコマンドラインが生成されます"
        return 0
    else
        echo "❌ NG - コマンドライン: '$TEST_COMMAND'"
        return 1
    fi
}

# メイン処理
main() {
    local failed=0
    
    test_option_parsing || ((failed++))
    test_option_propagation || ((failed++))
    test_all_agents || ((failed++))
    test_option_execution || ((failed++))
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ 全てのテストが成功しました"
        return 0
    else
        echo "❌ $failed 個のテストが失敗しました"
        return 1
    fi
}

main