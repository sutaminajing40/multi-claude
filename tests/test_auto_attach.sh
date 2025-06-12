#!/bin/bash

# 🧪 自動アタッチ機能のテスト

echo "🧪 PRESIDENT自動アタッチ機能のテスト"
echo "================================="

# multi-claudeスクリプトのパスを取得
MULTI_CLAUDE="../multi-claude"

# テスト1: 起動完了メッセージの後に自動接続メッセージが表示されるか
echo ""
echo "📝 テスト1: 自動接続メッセージの確認..."

# multi-claudeスクリプトの該当部分を確認
if grep -q "PRESIDENTセッションに自動接続中..." "$MULTI_CLAUDE"; then
    echo "✅ 自動接続メッセージが実装されています"
else
    echo "❌ 自動接続メッセージが見つかりません"
    exit 1
fi

# テスト2: tmux attach-sessionコマンドが実行されるか
echo ""
echo "📝 テスト2: tmux attachコマンドの確認..."

# 最後の部分でtmux attach-sessionが実行されるか確認
if tail -n 20 "$MULTI_CLAUDE" | grep -q "tmux attach-session -t president"; then
    echo "✅ 最後にPRESIDENTセッションへのアタッチが実行されます"
else
    echo "❌ PRESIDENTセッションへのアタッチが見つかりません"
    exit 1
fi

# テスト3: セッション操作の説明が表示されるか
echo ""
echo "📝 テスト3: 操作説明の確認..."

if grep -q "Ctrl+B → D" "$MULTI_CLAUDE"; then
    echo "✅ セッションを抜ける方法が説明されています"
else
    echo "❌ セッション操作の説明が不足しています"
    exit 1
fi

if grep -q "tmux attach-session -t multiagent" "$MULTI_CLAUDE"; then
    echo "✅ MULTIAGENTウィンドウの確認方法が説明されています"
else
    echo "❌ MULTIAGENTウィンドウの確認方法が説明されていません"
    exit 1
fi

# テスト4: 直接指示モードと通常モードの分岐確認
echo ""
echo "📝 テスト4: モード分岐の確認..."

# DIRECT_MESSAGEがある場合とない場合で異なる処理になっているか
if grep -A 50 'if \[ -n "$DIRECT_MESSAGE" \]' "$MULTI_CLAUDE" | grep -q "else"; then
    echo "✅ 直接指示モードと通常モードが適切に分岐されています"
else
    echo "❌ モード分岐が正しく実装されていません"
    exit 1
fi

# テスト5: 通常モードで最後にアタッチされるか
echo ""
echo "📝 テスト5: 通常モードでの自動アタッチ確認..."

# elseブロック内で最後にtmux attachが実行されるか
if grep -A 100 'else' "$MULTI_CLAUDE" | grep -B 5 '^fi$' | grep -q "tmux attach-session -t president"; then
    echo "✅ 通常モードでも最後にPRESIDENTにアタッチされます"
else
    echo "❌ 通常モードでの自動アタッチが実装されていません"
    exit 1
fi

echo ""
echo "✅ PRESIDENT自動アタッチ機能のテスト完了"