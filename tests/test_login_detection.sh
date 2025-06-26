#!/bin/bash
# ログイン検出機能のテストスクリプト

# login_detection.shを読み込み
# 新しいパス（bin/）を優先的にチェック
if [ -f "./bin/login_detection.sh" ]; then
    source "./bin/login_detection.sh"
elif [ -f "./login_detection.sh" ]; then
    source "./login_detection.sh"
else
    echo "エラー: login_detection.shが見つかりません"
    exit 1
fi

echo "=== Claude Code ログイン検出機能テスト ==="
echo ""

# テスト1: モックペイン作成してログイン完了パターンをテスト
test_login_complete() {
    echo "テスト1: ログイン完了パターンの検出"
    
    # テスト用の文字列パターン
    local test_patterns=(
        "⏵⏵ auto-accept edits on (shift+tab to cycle)"
        "Hello! I'm Claude ready to assist"
        "How can I help you today?"
    )
    
    for pattern in "${test_patterns[@]}"; do
        echo -n "  パターン: '$pattern' ... "
        if echo "$pattern" | grep -qi "ready\|claude\|help"; then
            echo "✅ 検出成功"
        else
            echo "❌ 検出失敗"
        fi
    done
}

# テスト2: ログイン要求パターンをテスト
test_login_required() {
    echo ""
    echo "テスト2: ログイン要求パターンの検出"
    
    local test_patterns=(
        "Please login to continue"
        "Sign in required"
        "Authentication needed"
    )
    
    for pattern in "${test_patterns[@]}"; do
        echo -n "  パターン: '$pattern' ... "
        if echo "$pattern" | grep -qi "login\|sign in\|authentication"; then
            echo "✅ 検出成功"
        else
            echo "❌ 検出失敗"
        fi
    done
}

# テスト3: 実際のtmuxペインでのテスト（もし存在すれば）
test_real_pane() {
    echo ""
    echo "テスト3: 実際のtmuxペインでのテスト"
    
    # multiagentセッションが存在するかチェック
    if tmux has-session -t multiagent 2>/dev/null; then
        echo "  multiagentセッション検出 ✅"
        
        # boss1ペインの内容を確認
        if tmux has-session -t multiagent:0.0 2>/dev/null; then
            echo "  boss1ペイン検出 ✅"
            echo "  boss1ペインの内容をチェック中..."
            
            # デバッグ出力（最初の5行のみ）
            echo "  === ペイン内容プレビュー ==="
            tmux capture-pane -t multiagent:0.0 -p -S -5 | head -5
            echo "  ==========================="
        else
            echo "  boss1ペインが見つかりません ❌"
        fi
    else
        echo "  multiagentセッションが見つかりません（通常のテスト環境）"
    fi
}

# メイン実行
main() {
    test_login_complete
    test_login_required
    test_real_pane
    
    echo ""
    echo "=== テスト完了 ==="
    echo ""
    echo "実装ファイル:"
    echo "  - login_detection.sh: ログイン検出ロジック（worker1作成）"
    echo ""
    echo "使用方法:"
    echo "  source login_detection.sh"
    echo "  status=\$(detect_login_status \"multiagent:0.0\" 30)"
    echo "  echo \"ステータス: \$status\""
}

# 実行
main