#!/bin/bash

# 修正したTerminal.app制御コードのテスト

echo "🧪 修正したTerminal.app制御のテスト"
echo "===================================="

CURRENT_DIR=$(pwd)
TERMINAL_APP="Terminal"

# テスト: 修正したコードが正しく動作するか確認
echo "✅ テスト実行中..."

osascript << EOF 2>&1
tell application "$TERMINAL_APP"
    activate
    do script "echo 'Test window for validation' && sleep 3 && exit"
    delay 0.5
    set currentWindow to front window
    set currentTab to selected tab of currentWindow
    tell currentTab
        set custom title to "Test: Fixed Code"
    end tell
    return "success"
end tell
EOF

RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "✅ 修正したコードは正常に動作しました！"
    echo "   Terminal.appのタブタイトルが正しく設定されます"
    exit 0
else
    echo "❌ エラーが発生しました"
    exit 1
fi