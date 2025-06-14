#!/bin/bash

# メッセージフォーマットテスト

set -e

echo "=== メッセージフォーマット変更テスト ==="
echo ""

# テスト用ディレクトリ
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# multi-claudeファイルをコピー
cp -r "$OLDPWD/instructions" .
cp -r "$OLDPWD/.multi-claude" .

echo "1. 起動メッセージが削除されたか確認"
echo "----------------------------------------"

# PRESIDENTの起動メッセージ確認
if grep -q "PRESIDENTが起動しました" instructions/president_dynamic.md; then
    echo "❌ PRESIDENTの起動メッセージが残っています"
    exit 1
else
    echo "✅ PRESIDENTの起動メッセージが削除されました"
fi

# BOSSの起動メッセージ確認
if grep -q "BOSSシステム初期化完了" instructions/boss_dynamic.md; then
    echo "❌ BOSSの起動メッセージが残っています"
    exit 1
else
    echo "✅ BOSSの起動メッセージが削除されました"
fi

# WORKERの起動メッセージ確認
if grep -q "起動しました。指示待機中です" instructions/worker_dynamic.md; then
    echo "❌ WORKERの起動メッセージが残っています"
    exit 1
else
    echo "✅ WORKERの起動メッセージが削除されました"
fi

echo ""
echo "2. 役割確認付きメッセージフォーマット確認"
echo "----------------------------------------"

# PRESIDENTからBOSSへのメッセージ
if grep -q "あなたはboss1です" instructions/president_dynamic.md; then
    echo "✅ PRESIDENT→BOSSの役割確認付きメッセージ形式に変更済み"
else
    echo "❌ PRESIDENT→BOSSのメッセージ形式が変更されていません"
    exit 1
fi

# BOSSからWORKERへのメッセージ
if grep -q "あなたはworker1です" instructions/boss_dynamic.md; then
    echo "✅ BOSS→WORKERの役割確認付きメッセージ形式に変更済み"
else
    echo "❌ BOSS→WORKERのメッセージ形式が変更されていません"
    exit 1
fi

# WORKERからBOSSへのメッセージ
if grep -q "あなたはboss1です.*worker.*より" instructions/worker_dynamic.md; then
    echo "✅ WORKER→BOSSの役割確認付きメッセージ形式に変更済み"
else
    echo "❌ WORKER→BOSSのメッセージ形式が変更されていません"
    exit 1
fi

# クリーンアップ
cd "$OLDPWD"
rm -rf "$TEST_DIR"

echo ""
echo "✅ すべてのテストが成功しました！"
echo "メッセージ上書き問題の対策が正しく実装されています。"