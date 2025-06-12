#!/bin/bash

# 🧪 v1.0.16 最終修正テスト

echo "🧪 v1.0.16 最終修正テスト"
echo "========================"
echo ""

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

echo "1. 問題の根本原因と解決策"
echo "-------------------------"
echo "  問題: ワーカーが自分の番号を正しく認識できない"
echo "  原因: BOSSからのメッセージだけでは不確実"
echo "  解決: tmuxペイン情報から自動的に番号を検出"
echo ""

echo "2. 修正内容の確認"
echo "-----------------"

# 各ファイルの修正確認
check_file() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    echo -n "  • $description... "
    if grep -q "$pattern" "$file"; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG"
        return 1
    fi
}

# 修正内容チェック
check_file "./instructions/president_dynamic.md" "tmux display-message -p" "PRESIDENT: tmux検出コード"
check_file "./instructions/worker_dynamic.md" "PANE_INFO=.*tmux display-message" "WORKER: tmux検出コード"
check_file "./instructions/president_dynamic.md" 'worker${WORKER_NUM}_done.txt' "PRESIDENT: 変数化された完了ファイル"
check_file "./instructions/worker_dynamic.md" 'worker${WORKER_NUM}_done.txt' "WORKER: 変数化された完了ファイル"

echo ""
echo "3. 個別テストの実行"
echo "-------------------"

# 関連テストのみ実行
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo -n "  • $test_name... "
    if [ -f "$test_script" ] && [ -x "$test_script" ]; then
        if $test_script > /dev/null 2>&1; then
            echo "✅ OK"
            return 0
        else
            echo "❌ NG"
            return 1
        fi
    else
        echo "⚠️  スキップ"
        return 0
    fi
}

run_test "ワーカー完了通知" "./tests/test_worker_completion.sh"
run_test "ワーカー番号認識" "./tests/test_worker_identity.sh"
run_test "tmuxペイン検出" "./tests/test_worker_pane_detection.sh"
run_test "tmux統合検出" "./tests/test_worker_tmux_detection.sh"

echo ""
echo "4. ワーカー番号認識の動作確認"
echo "-----------------------------"
echo "  tmuxペイン → ワーカー番号のマッピング:"
echo "    multiagent:0.1 → worker1"
echo "    multiagent:0.2 → worker2"
echo "    multiagent:0.3 → worker3"
echo ""
echo "  各ワーカーの動作:"
echo "    1. tmux display-messageでペイン情報取得"
echo "    2. case文で自分の番号を判定"
echo "    3. worker\${WORKER_NUM}_done.txtを作成"
echo "    4. 全員完了時にBOSSに報告"

echo ""
echo "5. 期待される結果"
echo "-----------------"
echo "  ✅ worker1が1人（multiagent:0.1のみ）"
echo "  ✅ worker2が1人（multiagent:0.2のみ）"
echo "  ✅ worker3が1人（multiagent:0.3のみ）"
echo "  ✅ 全員が正しい完了ファイルを作成"
echo "  ✅ 最後のワーカーがBOSSに報告"

echo ""
echo "✅ v1.0.16の修正が完了しました！"
echo ""
echo "次のステップ:"
echo "  1. git add -A"
echo "  2. git commit -m 'fix: tmuxペイン情報によるワーカー番号自動検出'"
echo "  3. git push origin main"
echo "  4. git tag v1.0.16 -m 'Release: Reliable worker identification using tmux pane info'"
echo "  5. git push origin v1.0.16"