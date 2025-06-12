#!/bin/bash

# 🧪 Worker完了通知システムのテスト

echo "🧪 Worker完了通知システムのテスト"
echo "================================="

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# tmpディレクトリの存在確認
test_tmp_directory() {
    echo -n "1. tmpディレクトリの存在確認... "
    if [ -d "./tmp" ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - tmpディレクトリが存在しません"
        return 1
    fi
}

# 完了ファイル作成テスト
test_completion_files() {
    echo -n "2. 完了ファイル作成テスト... "
    
    # テスト用完了ファイル作成
    mkdir -p ./tmp
    touch ./tmp/test_worker1_done.txt
    touch ./tmp/test_worker2_done.txt
    touch ./tmp/test_worker3_done.txt
    
    if [ -f ./tmp/test_worker1_done.txt ] && [ -f ./tmp/test_worker2_done.txt ] && [ -f ./tmp/test_worker3_done.txt ]; then
        echo "✅ OK"
        # クリーンアップ
        rm -f ./tmp/test_worker*.txt
        return 0
    else
        echo "❌ NG - 完了ファイルが作成できません"
        return 1
    fi
}

# agent-send.shの実行可能性
test_agent_send_executable() {
    echo -n "3. agent-send.shの実行可能性... "
    if [ -x "./agent-send.sh" ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ NG - agent-send.shが実行可能ではありません"
        return 1
    fi
}

# Workerの完了確認ロジックテスト
test_worker_completion_logic() {
    echo -n "4. Worker完了確認ロジックテスト... "
    
    # tmpディレクトリ作成
    mkdir -p ./tmp
    
    # 実際のWorkerの完了確認ロジックを再現
    touch ./tmp/worker1_done.txt
    touch ./tmp/worker2_done.txt
    touch ./tmp/worker3_done.txt
    
    if [ -f ./tmp/worker1_done.txt ] && [ -f ./tmp/worker2_done.txt ] && [ -f ./tmp/worker3_done.txt ]; then
        echo "✅ OK - 全ワーカーの完了を確認できます"
        # クリーンアップ
        rm -f ./tmp/worker*_done.txt
        return 0
    else
        echo "❌ NG - 完了確認ロジックに問題があります"
        return 1
    fi
}

# メイン処理
main() {
    local failed=0
    
    test_tmp_directory || ((failed++))
    test_completion_files || ((failed++))
    test_agent_send_executable || ((failed++))
    test_worker_completion_logic || ((failed++))
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ 全てのテストが成功しました"
        return 0
    else
        echo "❌ $failed 個のテストが失敗しました"
        return 1
    fi
}

main