#!/bin/bash

# 🧪 CLAUDE.md追記機能のテスト

echo "🧪 CLAUDE.md追記機能のテスト"
echo "================================="

# テスト用ディレクトリ作成
TEST_DIR="./test_claude_md_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 元のCLAUDE.mdを作成
cat > CLAUDE.md << 'EOF'
# 既存のプロジェクト

## 概要
これは既存のプロジェクトのCLAUDE.mdです。

## 開発ガイドライン
- テスト駆動開発
- 細かいコミット
EOF

# share/CLAUDE_template.mdを作成
mkdir -p share
cat > share/CLAUDE_template.md << 'EOF'
## 🤖 Multi-Claude システム設定

### Agent Communication System

### エージェント構成

- **PRESIDENT** (別セッション): 統括責任者
- **boss1** (multiagent:0.0): チームリーダー
EOF

# setup_first_time関数の一部をテスト
echo "📝 既存のCLAUDE.mdがある場合のテスト..."

# システム設定が既に追加されているかチェック
if ! grep -q "## 🤖 Multi-Claude システム設定" "./CLAUDE.md"; then
    # 既存の内容を一時保存
    cp "./CLAUDE.md" "./CLAUDE.md.original"
    
    # Multi-Claudeシステム設定を先頭に追加
    cp "share/CLAUDE_template.md" "./CLAUDE.md.tmp"
    echo "" >> "./CLAUDE.md.tmp"
    echo "---" >> "./CLAUDE.md.tmp"
    echo "" >> "./CLAUDE.md.tmp"
    echo "# 元のCLAUDE.md内容" >> "./CLAUDE.md.tmp"
    echo "" >> "./CLAUDE.md.tmp"
    cat "./CLAUDE.md.original" >> "./CLAUDE.md.tmp"
    
    # 新しいCLAUDE.mdとして保存
    mv "./CLAUDE.md.tmp" "./CLAUDE.md"
    rm "./CLAUDE.md.original"
fi

# 結果確認
echo ""
echo "✅ 結果確認:"
echo "----------"

# Multi-Claude設定が追加されているか
if grep -q "## 🤖 Multi-Claude システム設定" "./CLAUDE.md"; then
    echo "✅ Multi-Claude設定が追加されました"
else
    echo "❌ Multi-Claude設定の追加に失敗"
    exit 1
fi

# 元の内容が保持されているか
if grep -q "これは既存のプロジェクトのCLAUDE.mdです" "./CLAUDE.md"; then
    echo "✅ 元の内容が保持されています"
else
    echo "❌ 元の内容が失われました"
    exit 1
fi

# 区切り線が追加されているか
if grep -q -- "---" "./CLAUDE.md"; then
    echo "✅ 区切り線が追加されています"
else
    echo "❌ 区切り線が追加されていません"
    exit 1
fi

echo ""
echo "📄 最終的なCLAUDE.md:"
echo "==================="
cat CLAUDE.md

# 後片付け
cd ..
rm -rf "$TEST_DIR"

echo ""
echo "✅ CLAUDE.md追記機能のテスト完了"