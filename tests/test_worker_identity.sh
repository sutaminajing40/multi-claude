#!/bin/bash

# 🧪 ワーカー番号認識テスト

echo "🧪 ワーカー番号認識テスト"
echo "========================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# CLAUDE.mdでの役割定義確認
test_claude_md_roles() {
    echo -n "1. CLAUDE.mdでの役割定義... "
    
    if grep -q "## あなたの役割" ./CLAUDE.md; then
        echo "✅ OK - 役割セクションあり"
        return 0
    else
        echo "❌ NG - 役割定義がありません"
        return 1
    fi
}

# BOSSからのメッセージでワーカー番号を含める仕組みの確認
test_boss_message_with_identity() {
    echo -n "2. BOSSの指示書でワーカー番号伝達... "
    
    # boss_dynamic.mdを確認
    if grep -q "worker1.*worker_task.md" ./instructions/boss_dynamic.md; then
        echo "✅ OK - ワーカー番号を含むメッセージ送信"
        return 0
    else
        echo "❌ NG - ワーカー番号の伝達方法が不明"
        return 1
    fi
}

# PRESIDENTの指示書生成でワーカー番号を考慮
test_president_task_generation() {
    echo -n "3. PRESIDENT指示書でのワーカー番号考慮... "
    
    # president_dynamic.mdを確認
    if grep -q "worker1_done.txt.*worker1" ./instructions/president_dynamic.md; then
        echo "✅ OK - ワーカー番号別の完了ファイル"
        return 0
    else
        echo "❌ NG - ワーカー番号の考慮不足"
        return 1
    fi
}

# 実装提案の生成
generate_solution() {
    echo ""
    echo "4. 解決策の提案"
    echo "---------------"
    echo "  方法1: BOSSからのメッセージにワーカー番号を含める"
    echo "    例: ./agent-send.sh worker1 \"あなたはworker1です。instructions/worker_task.mdを確認して作業開始\""
    echo ""
    echo "  方法2: CLAUDE.mdに各エージェントの役割を明記"
    echo "    multiagent:0.0 → boss1"
    echo "    multiagent:0.1 → worker1"
    echo "    multiagent:0.2 → worker2"
    echo "    multiagent:0.3 → worker3"
    echo ""
    echo "  方法3: 環境変数やファイルでワーカー番号を設定"
    echo "    各ワーカー起動時に番号を記録"
}

# メイン処理
main() {
    local failed=0
    
    test_claude_md_roles || ((failed++))
    test_boss_message_with_identity || ((failed++))
    test_president_task_generation || ((failed++))
    
    generate_solution
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ 基本的な仕組みは整っています"
        return 0
    else
        echo "❌ $failed 個の問題があります"
        echo ""
        echo "推奨される修正:"
        echo "1. CLAUDE.mdに役割マッピングを追加"
        echo "2. BOSSからワーカー番号を含むメッセージを送信"
        echo "3. ワーカーがメッセージから自分の番号を認識する仕組み"
        return 1
    fi
}

main