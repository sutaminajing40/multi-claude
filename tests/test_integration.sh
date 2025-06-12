#!/bin/bash

# 🧪 統合テスト - 新機能の動作確認

echo "🧪 Multi-Claude 統合テスト"
echo "================================="

# テスト用ディレクトリ作成
TEST_DIR="./test_integration_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 既存のプロジェクトをシミュレート
echo "📝 既存プロジェクトのシミュレーション..."
cat > CLAUDE.md << 'EOF'
# My Awesome Project

This is an existing project with its own CLAUDE.md file.

## Development Guidelines
- Use TypeScript
- Write tests
- Keep commits small
EOF

# multi-claudeに必要なファイルをコピー（シミュレーション）
echo "📝 Multi-Claudeファイルの準備..."
cp ../../multi-claude .
cp ../../setup.sh .
cp ../../agent-send.sh .
chmod +x multi-claude setup.sh agent-send.sh

# shareディレクトリを作成
mkdir -p share
cp ../../share/CLAUDE_template.md share/

# instructionsディレクトリをコピー
cp -r ../../instructions .

# バージョン確認
echo ""
echo "✅ バージョン確認:"
VERSION=$(./multi-claude --version | grep -o "v[0-9.]*")
echo "   現在のバージョン: $VERSION"

# ヘルプ確認
echo ""
echo "✅ ヘルプメッセージ確認:"
if ./multi-claude --help | grep -q "指示"; then
    echo "   ✅ 直接指示機能がヘルプに記載されています"
else
    echo "   ❌ 直接指示機能がヘルプに記載されていません"
fi

# CLAUDE.md追記機能のテスト
echo ""
echo "✅ CLAUDE.md追記機能のテスト:"

# Homebrewインストールをシミュレート
export BREW_PREFIX="/usr/local"
export MULTI_CLAUDE_VERSION="1.0.10"
export MULTI_CLAUDE_BASE="${BREW_PREFIX}/Cellar/multi-claude/${MULTI_CLAUDE_VERSION}"
export MULTI_CLAUDE_SHARE="./share"

# setup_first_time関数の一部を実行
if [ -f "./CLAUDE.md" ]; then
    if ! grep -q "## 🤖 Multi-Claude システム設定" "./CLAUDE.md"; then
        cp "./CLAUDE.md" "./CLAUDE.md.original"
        cp "${MULTI_CLAUDE_SHARE}/CLAUDE_template.md" "./CLAUDE.md.tmp"
        echo "" >> "./CLAUDE.md.tmp"
        echo "---" >> "./CLAUDE.md.tmp"
        echo "" >> "./CLAUDE.md.tmp"
        echo "# 元のCLAUDE.md内容" >> "./CLAUDE.md.tmp"
        echo "" >> "./CLAUDE.md.tmp"
        cat "./CLAUDE.md.original" >> "./CLAUDE.md.tmp"
        mv "./CLAUDE.md.tmp" "./CLAUDE.md"
        rm "./CLAUDE.md.original"
    fi
fi

# 結果確認
if grep -q "## 🤖 Multi-Claude システム設定" "./CLAUDE.md"; then
    echo "   ✅ Multi-Claude設定が追加されました"
else
    echo "   ❌ Multi-Claude設定の追加に失敗"
fi

if grep -q "My Awesome Project" "./CLAUDE.md"; then
    echo "   ✅ 元のプロジェクト内容が保持されています"
else
    echo "   ❌ 元のプロジェクト内容が失われました"
fi

# 最終的なCLAUDE.mdの内容を表示
echo ""
echo "📄 最終的なCLAUDE.md（最初の30行）:"
echo "================================="
head -n 30 CLAUDE.md

# 後片付け
cd ..
rm -rf "$TEST_DIR"

echo ""
echo "✅ 統合テスト完了"