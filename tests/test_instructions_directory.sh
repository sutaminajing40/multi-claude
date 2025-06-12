#!/bin/bash

# 🧪 instructionsディレクトリの存在確認テスト

echo "🧪 instructionsディレクトリの存在確認テスト"
echo "================================="

# プロジェクトルートに移動
cd ..

# テスト1: instructionsディレクトリの存在確認
echo ""
echo "📝 テスト1: instructionsディレクトリの存在確認..."
if [ -d "instructions" ]; then
    echo "✅ instructionsディレクトリが存在します"
else
    echo "❌ instructionsディレクトリが見つかりません"
    exit 1
fi

# テスト2: 必要なファイルの存在確認
echo ""
echo "📝 テスト2: 必要なファイルの存在確認..."

REQUIRED_FILES=(
    "instructions/president_dynamic.md"
    "instructions/boss_dynamic.md"
    "instructions/worker_dynamic.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file が存在します"
    else
        echo "❌ $file が見つかりません"
        exit 1
    fi
done

# テスト3: shareディレクトリの存在確認
echo ""
echo "📝 テスト3: shareディレクトリの確認..."
if [ -d "share" ]; then
    echo "✅ shareディレクトリが存在します"
    if [ -f "share/CLAUDE_template.md" ]; then
        echo "✅ share/CLAUDE_template.md が存在します"
    else
        echo "❌ share/CLAUDE_template.md が見つかりません"
        exit 1
    fi
else
    echo "❌ shareディレクトリが見つかりません"
    exit 1
fi

# テスト4: Homebrewインストールシミュレーション
echo ""
echo "📝 テスト4: Homebrewインストールのシミュレーション..."

# 一時ディレクトリを作成
TEMP_INSTALL_DIR="./test_brew_install_$$"
mkdir -p "$TEMP_INSTALL_DIR/bin"
mkdir -p "$TEMP_INSTALL_DIR/share"

# ファイルをコピー（Homebrewのinstallセクションをシミュレート）
cp multi-claude setup.sh agent-send.sh "$TEMP_INSTALL_DIR/bin/" 2>/dev/null
cp -r instructions "$TEMP_INSTALL_DIR/share/" 2>/dev/null
cp share/CLAUDE_template.md "$TEMP_INSTALL_DIR/share/" 2>/dev/null

# コピー結果を確認
if [ -d "$TEMP_INSTALL_DIR/share/instructions" ]; then
    echo "✅ instructionsディレクトリが正しくコピーされました"
else
    echo "❌ instructionsディレクトリのコピーに失敗しました"
    rm -rf "$TEMP_INSTALL_DIR"
    exit 1
fi

# 後片付け
rm -rf "$TEMP_INSTALL_DIR"

echo ""
echo "✅ instructionsディレクトリの存在確認テスト完了"