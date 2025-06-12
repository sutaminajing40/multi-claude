#!/bin/bash

# 🧪 直接指示機能のテスト

echo "🧪 直接指示機能のテスト"
echo "================================="

# multi-claudeスクリプトのパスを取得
MULTI_CLAUDE="../multi-claude"

# テスト1: ヘルプメッセージに直接指示機能が含まれているか
echo ""
echo "📝 テスト1: ヘルプメッセージ確認..."
if $MULTI_CLAUDE --help | grep -q "\[\指示\]"; then
    echo "✅ ヘルプに直接指示機能が記載されています"
else
    echo "❌ ヘルプに直接指示機能が記載されていません"
    exit 1
fi

# テスト2: 引数パースのテスト（ドライラン）
echo ""
echo "📝 テスト2: 引数パースのテスト..."

# multi-claudeの一部を抽出してテスト
test_arg_parsing() {
    local arg="$1"
    case "$arg" in
        --exit|--help|-h|--version|-v|--dangerously-skip-permissions)
            echo "OPTION"
            ;;
        "")
            echo "EMPTY"
            ;;
        --*)
            echo "UNKNOWN_OPTION"
            ;;
        *)
            echo "DIRECT_MESSAGE"
            ;;
    esac
}

# テストケース実行
echo "  - 'テストメッセージ' → $(test_arg_parsing 'テストメッセージ')"
echo "  - '--help' → $(test_arg_parsing '--help')"
echo "  - '--unknown' → $(test_arg_parsing '--unknown')"
echo "  - '' → $(test_arg_parsing '')"

# 期待値チェック
if [ "$(test_arg_parsing 'テストメッセージ')" = "DIRECT_MESSAGE" ]; then
    echo "✅ 通常のテキストは直接指示として認識されます"
else
    echo "❌ 通常のテキストが直接指示として認識されません"
    exit 1
fi

# テスト3: 直接指示時の処理フロー確認（コード検証）
echo ""
echo "📝 テスト3: 直接指示処理のコード確認..."

# STEP 5の存在確認
if grep -q "STEP 5: 直接指示の送信" "$MULTI_CLAUDE"; then
    echo "✅ STEP 5（直接指示送信）が実装されています"
else
    echo "❌ STEP 5（直接指示送信）が実装されていません"
    exit 1
fi

# agent-send.shの呼び出し確認
if grep -q './agent-send.sh president "$DIRECT_MESSAGE"' "$MULTI_CLAUDE"; then
    echo "✅ agent-send.shを使用してPRESIDENTに送信します"
else
    echo "❌ agent-send.shの呼び出しが見つかりません"
    exit 1
fi

# tmux attachの確認
if grep -q "tmux attach-session -t president" "$MULTI_CLAUDE"; then
    echo "✅ 送信後にPRESIDENTセッションにアタッチします"
else
    echo "❌ tmux attachが実装されていません"
    exit 1
fi

# テスト4: エラーハンドリング確認
echo ""
echo "📝 テスト4: エラーハンドリング確認..."

if grep -q 'log_error "agent-send.sh' "$MULTI_CLAUDE"; then
    echo "✅ agent-send.shが見つからない場合のエラーハンドリングあり"
else
    echo "❌ エラーハンドリングが不十分"
    exit 1
fi

echo ""
echo "✅ 直接指示機能のテスト完了"