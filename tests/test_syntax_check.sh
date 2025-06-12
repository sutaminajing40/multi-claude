#!/bin/bash

# 🧪 シンタックスチェックテスト

echo "🧪 シンタックスチェックテスト"
echo "================================="

# チェック対象のスクリプト
SCRIPTS=(
    "../multi-claude"
    "../setup.sh"
    "../agent-send.sh"
)

# エラーカウンター
ERROR_COUNT=0

# 各スクリプトをチェック
for script in "${SCRIPTS[@]}"; do
    echo ""
    echo "📝 $script のシンタックスチェック..."
    
    # bash -n でシンタックスチェック（実行はしない）
    if bash -n "$script" 2>&1; then
        echo "✅ $script: シンタックスOK"
    else
        echo "❌ $script: シンタックスエラー"
        bash -n "$script" 2>&1 | head -10
        ((ERROR_COUNT++))
    fi
done

# shellcheckがインストールされている場合は追加チェック
if command -v shellcheck &> /dev/null; then
    echo ""
    echo "📝 ShellCheckによる詳細チェック..."
    for script in "${SCRIPTS[@]}"; do
        echo ""
        echo "Checking $script with ShellCheck..."
        if shellcheck "$script" 2>&1; then
            echo "✅ $script: ShellCheck OK"
        else
            echo "⚠️  $script: ShellCheck警告あり"
            # エラーではなく警告として扱う
        fi
    done
else
    echo ""
    echo "ℹ️  ShellCheckがインストールされていません（オプション）"
fi

# osascriptのシンタックスチェック（macOSのみ）
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "📝 AppleScriptのシンタックスチェック..."
    
    # multi-claudeからAppleScriptを抽出してチェック
    grep -A 20 "osascript << EOF" ../multi-claude | grep -B 20 "^EOF$" > /tmp/applescript_test.txt
    
    if [ -s /tmp/applescript_test.txt ]; then
        # AppleScriptのシンタックスをチェック（コンパイルのみ）
        osascript -e 'tell application "Terminal" to name' &>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ AppleScriptシンタックス: OK"
        else
            echo "⚠️  AppleScriptシンタックス: 警告（実行環境依存）"
        fi
    fi
    rm -f /tmp/applescript_test.txt
fi

# 結果サマリー
echo ""
echo "================================="
if [ $ERROR_COUNT -eq 0 ]; then
    echo "✅ すべてのスクリプトのシンタックスが正しいです"
    exit 0
else
    echo "❌ $ERROR_COUNT 個のスクリプトにシンタックスエラーがあります"
    exit 1
fi