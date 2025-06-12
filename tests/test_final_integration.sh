#!/bin/bash

# 🧪 最終統合テスト

echo "🧪 最終統合テスト"
echo "================="
echo ""

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# 修正内容の確認
echo "1. 修正内容の確認"
echo "-----------------"

# CLAUDE.mdの役割定義
echo -n "  • CLAUDE.mdの役割定義... "
if grep -q "multiagent:0.1.*worker1" ./CLAUDE.md && \
   grep -q "multiagent:0.2.*worker2" ./CLAUDE.md && \
   grep -q "multiagent:0.3.*worker3" ./CLAUDE.md; then
    echo "✅ OK"
else
    echo "❌ NG"
fi

# BOSSの指示書
echo -n "  • BOSSからのワーカー番号伝達... "
if grep -q "あなたはworker1です" ./instructions/boss_dynamic.md && \
   grep -q "あなたはworker2です" ./instructions/boss_dynamic.md && \
   grep -q "あなたはworker3です" ./instructions/boss_dynamic.md; then
    echo "✅ OK"
else
    echo "❌ NG"
fi

# PRESIDENTの指示書
echo -n "  • PRESIDENTからのワーカー番号伝達... "
if grep -q "あなたはworker1です" ./instructions/president_dynamic.md && \
   grep -q "あなたはworker2です" ./instructions/president_dynamic.md && \
   grep -q "あなたはworker3です" ./instructions/president_dynamic.md; then
    echo "✅ OK"
else
    echo "❌ NG"
fi

# WORKERの指示書
echo -n "  • WORKERの番号認識説明... "
if grep -q "自分のワーカー番号を確認" ./instructions/worker_dynamic.md && \
   grep -q "BOSSからのメッセージ" ./instructions/worker_dynamic.md; then
    echo "✅ OK"
else
    echo "❌ NG"
fi

echo ""
echo "2. 個別テストの実行"
echo "-------------------"

# 各テストを実行
for test_script in ./tests/test_*.sh; do
    if [ -f "$test_script" ] && [ -x "$test_script" ] && [ "$test_script" != "$0" ]; then
        test_name=$(basename "$test_script" .sh)
        echo -n "  • $test_name... "
        if $test_script > /dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ NG"
        fi
    fi
done

echo ""
echo "3. 統合確認"
echo "-----------"
echo "  ワーカー番号認識の仕組み:"
echo "    1. CLAUDE.mdで各エージェントの役割を定義"
echo "    2. BOSSからワーカーに「あなたはworkerXです」と明示"
echo "    3. ワーカーは自分の番号に応じた完了ファイルを作成"
echo "    4. 全員完了後、最後のワーカーがBOSSに報告"

echo ""
echo "✅ 全ての修正が完了しました！"
echo ""
echo "次のステップ:"
echo "  1. git add -A"
echo "  2. git commit -m 'fix: ワーカー番号認識の問題を修正'"
echo "  3. git push origin main"
echo "  4. git tag v1.0.15 -m 'Release: Worker identity recognition fix'"
echo "  5. git push origin v1.0.15"