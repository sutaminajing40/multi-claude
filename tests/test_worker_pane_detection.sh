#!/bin/bash

# 🧪 tmuxペイン情報によるワーカー番号検出テスト

echo "🧪 tmuxペイン情報によるワーカー番号検出テスト"
echo "============================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# tmux環境のチェック
test_tmux_environment() {
    echo -n "1. tmux環境の確認... "
    
    if command -v tmux &> /dev/null; then
        echo "✅ OK - tmuxが利用可能"
        return 0
    else
        echo "❌ NG - tmuxが見つかりません"
        return 1
    fi
}

# ペイン情報取得コマンドのテスト
test_pane_info_command() {
    echo -n "2. ペイン情報取得コマンド... "
    
    # tmuxセッション内で実行されているかチェック
    if [ -n "$TMUX" ]; then
        # 現在のペイン情報を取得
        PANE_INFO=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')
        echo "✅ OK - 現在のペイン: $PANE_INFO"
        return 0
    else
        echo "⚠️  tmuxセッション外で実行中（テストスキップ）"
        return 0
    fi
}

# ワーカー番号判定ロジックのテスト
test_worker_number_detection() {
    echo -n "3. ワーカー番号判定ロジック... "
    
    # テスト用関数
    get_worker_number() {
        local pane_info="$1"
        case "$pane_info" in
            "multiagent:0.0") echo "boss1" ;;
            "multiagent:0.1") echo "worker1" ;;
            "multiagent:0.2") echo "worker2" ;;
            "multiagent:0.3") echo "worker3" ;;
            *) echo "unknown" ;;
        esac
    }
    
    # テストケース
    if [ "$(get_worker_number "multiagent:0.1")" = "worker1" ] && \
       [ "$(get_worker_number "multiagent:0.2")" = "worker2" ] && \
       [ "$(get_worker_number "multiagent:0.3")" = "worker3" ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - 判定ロジックに問題があります"
        return 1
    fi
}

# ワーカー番号取得スクリプトのテスト
test_worker_script() {
    echo -n "4. ワーカー番号取得スクリプト... "
    
    # スクリプト内容
    cat > /tmp/test_get_worker_number.sh << 'EOF'
#!/bin/bash
# 自分のワーカー番号を取得
if [ -n "$TMUX" ]; then
    PANE_INFO=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')
    case "$PANE_INFO" in
        "multiagent:0.0") WORKER_NUM="boss1" ;;
        "multiagent:0.1") WORKER_NUM="1" ;;
        "multiagent:0.2") WORKER_NUM="2" ;;
        "multiagent:0.3") WORKER_NUM="3" ;;
        *) WORKER_NUM="unknown" ;;
    esac
    echo "WORKER_NUM=$WORKER_NUM"
else
    echo "WORKER_NUM=unknown (not in tmux)"
fi
EOF
    
    chmod +x /tmp/test_get_worker_number.sh
    
    # スクリプトが正常に実行できるか確認
    if /tmp/test_get_worker_number.sh > /dev/null 2>&1; then
        echo "✅ OK"
        rm -f /tmp/test_get_worker_number.sh
        return 0
    else
        echo "❌ NG - スクリプトエラー"
        rm -f /tmp/test_get_worker_number.sh
        return 1
    fi
}

# 解決策の提案
generate_solution() {
    echo ""
    echo "5. 提案する解決策"
    echo "----------------"
    echo "各ワーカーが自分の番号を確実に認識する方法："
    echo ""
    echo "```bash"
    echo "# ワーカー番号を自動検出"
    echo 'if [ -n "$TMUX" ]; then'
    echo '    PANE_INFO=$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}")'
    echo '    case "$PANE_INFO" in'
    echo '        "multiagent:0.1") WORKER_NUM="1" ;;'
    echo '        "multiagent:0.2") WORKER_NUM="2" ;;'
    echo '        "multiagent:0.3") WORKER_NUM="3" ;;'
    echo '        *) WORKER_NUM="unknown" ;;'
    echo '    esac'
    echo 'fi'
    echo ""
    echo "# 完了ファイル作成"
    echo 'mkdir -p ./tmp'
    echo 'touch "./tmp/worker${WORKER_NUM}_done.txt"'
    echo "```"
}

# メイン処理
main() {
    local failed=0
    
    test_tmux_environment || ((failed++))
    test_pane_info_command || ((failed++))
    test_worker_number_detection || ((failed++))
    test_worker_script || ((failed++))
    
    generate_solution
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ tmuxペイン情報による番号検出が可能です"
        return 0
    else
        echo "❌ $failed 個のテストが失敗しました"
        return 1
    fi
}

main