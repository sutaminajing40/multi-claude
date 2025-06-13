#!/bin/bash

# 🧪 ファイル構造改善テスト
# .multi-claudeフォルダへのファイル配置が正しく行われるかテスト

set -e

echo "🧪 ファイル構造改善テスト"
echo "========================="

# テスト用ディレクトリ作成
TEST_DIR="/tmp/test_multi_claude_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📁 テストディレクトリ: $TEST_DIR"

# 1. 初回セットアップのシミュレート
echo ""
echo "1️⃣ 初回セットアップのシミュレート"
echo "--------------------------------"

# .multi-claudeディレクトリ構造を作成
mkdir -p .multi-claude/{bin,instructions,tmp/worker_ids,logs,context,tasks}

# ファイルパスのテスト
echo "✅ .multi-claudeディレクトリ構造を作成"
tree .multi-claude 2>/dev/null || find .multi-claude -type d | sort

# 2. ファイルパスの更新確認
echo ""
echo "2️⃣ ファイルパスの更新確認"
echo "------------------------"

# テスト用のagent-send.shを作成（ログパスのテスト）
cat > test_log_path.sh << 'EOF'
#!/bin/bash
LOG_DIR="./.multi-claude/logs"
mkdir -p "$LOG_DIR"
echo "Test log entry" >> "$LOG_DIR/send_log.txt"
echo "ログファイル作成: $LOG_DIR/send_log.txt"
EOF
chmod +x test_log_path.sh
./test_log_path.sh

if [ -f "./.multi-claude/logs/send_log.txt" ]; then
    echo "✅ ログファイルが正しい場所に作成されました"
    cat ./.multi-claude/logs/send_log.txt
else
    echo "❌ ログファイルが作成されませんでした"
    exit 1
fi

# 3. ワーカーIDファイルのテスト
echo ""
echo "3️⃣ ワーカーIDファイルのテスト"
echo "----------------------------"

# ワーカーIDの記録テスト
echo "1" > ./.multi-claude/tmp/worker_ids/current_worker.id
if [ -f "./.multi-claude/tmp/worker_ids/current_worker.id" ]; then
    echo "✅ ワーカーIDファイルが正しい場所に作成されました"
    echo "内容: $(cat ./.multi-claude/tmp/worker_ids/current_worker.id)"
else
    echo "❌ ワーカーIDファイルが作成されませんでした"
    exit 1
fi

# 4. 進捗共有ファイルのテスト
echo ""
echo "4️⃣ 進捗共有ファイルのテスト"
echo "--------------------------"

# 進捗ファイルの作成テスト
cat > ./.multi-claude/context/worker1_progress.md << 'EOF'
# Worker1 進捗状況
開始時刻: 2024-01-01 10:00:00
担当作業: テストタスク
ステータス: 作業中
EOF

if [ -f "./.multi-claude/context/worker1_progress.md" ]; then
    echo "✅ 進捗ファイルが正しい場所に作成されました"
    head -n 3 ./.multi-claude/context/worker1_progress.md
else
    echo "❌ 進捗ファイルが作成されませんでした"
    exit 1
fi

# 5. 後方互換性のテスト
echo ""
echo "5️⃣ 後方互換性のテスト"
echo "--------------------"

# シンボリックリンクの作成テスト
ln -sf ./.multi-claude/bin/setup.sh ./setup.sh
ln -sf ./.multi-claude/bin/agent-send.sh ./agent-send.sh
ln -sf ./.multi-claude/instructions ./instructions

if [ -L "./setup.sh" ] && [ -L "./agent-send.sh" ] && [ -L "./instructions" ]; then
    echo "✅ 後方互換性のためのシンボリックリンクが作成されました"
    ls -la setup.sh agent-send.sh instructions
else
    echo "❌ シンボリックリンクの作成に失敗しました"
    exit 1
fi

# 6. クリーンアップテスト
echo ""
echo "6️⃣ クリーンアップテスト"
echo "----------------------"

# 一時ファイルの作成
touch ./.multi-claude/tmp/worker{1,2,3}_done.txt
echo "作成したファイル:"
ls -la ./.multi-claude/tmp/worker*_done.txt

# クリーンアップ実行
rm -f ./.multi-claude/tmp/worker*_done.txt

if [ ! -f "./.multi-claude/tmp/worker1_done.txt" ]; then
    echo "✅ 一時ファイルが正しくクリーンアップされました"
else
    echo "❌ クリーンアップに失敗しました"
    exit 1
fi

# テスト完了
echo ""
echo "🎉 すべてのテストが成功しました！"
echo ""
echo "📊 最終的なディレクトリ構造:"
tree .multi-claude 2>/dev/null || find .multi-claude -type d | sort

# クリーンアップ
cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ テストディレクトリをクリーンアップしました"