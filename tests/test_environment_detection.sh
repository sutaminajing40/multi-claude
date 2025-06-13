#!/bin/bash

# 🧪 環境検出方法の包括的テスト

echo "🧪 環境検出方法の包括的テスト"
echo "=============================="
echo ""

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# 1. 環境変数の確認
test_environment_variables() {
    echo "1. 環境変数の確認"
    echo "-----------------"
    echo "  TMUX: '$TMUX'"
    echo "  TMUX_PANE: '$TMUX_PANE'"
    echo "  USER: '$USER'"
    echo "  PWD: '$PWD'"
    echo ""
    
    if [ -n "$TMUX" ]; then
        echo "  ✅ tmux環境内で実行されています"
        return 0
    else
        echo "  ❌ tmux環境変数が設定されていません"
        echo "  → Claude Code内では環境変数が利用できない可能性"
        return 1
    fi
}

# 2. tmuxコマンドの実行テスト
test_tmux_commands() {
    echo "2. tmuxコマンドの実行テスト"
    echo "---------------------------"
    
    # tmuxコマンドが使えるか確認
    echo -n "  tmux list-sessions... "
    if tmux list-sessions >/dev/null 2>&1; then
        echo "✅ 実行可能"
    else
        echo "❌ 実行不可"
    fi
    
    # 現在のペイン情報を取得できるか
    echo -n "  tmux display-message... "
    if tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' >/dev/null 2>&1; then
        PANE_INFO=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>&1)
        echo "✅ 実行可能 (結果: $PANE_INFO)"
    else
        echo "❌ 実行不可"
    fi
    echo ""
}

# 3. ファイルベースの番号伝達テスト
test_file_based_approach() {
    echo "3. ファイルベースの番号伝達方法"
    echo "--------------------------------"
    
    # テスト用ディレクトリ作成
    mkdir -p ./tmp/worker_ids
    
    # 各ワーカー用のIDファイルを作成
    echo "1" > ./tmp/worker_ids/multiagent_0.1.id
    echo "2" > ./tmp/worker_ids/multiagent_0.2.id
    echo "3" > ./tmp/worker_ids/multiagent_0.3.id
    
    echo "  作成したIDファイル:"
    ls -la ./tmp/worker_ids/*.id
    
    # 読み込みテスト
    echo ""
    echo "  読み込みテスト:"
    for pane in "0.1" "0.2" "0.3"; do
        if [ -f "./tmp/worker_ids/multiagent_${pane}.id" ]; then
            WORKER_NUM=$(cat "./tmp/worker_ids/multiagent_${pane}.id")
            echo "    multiagent:$pane → worker$WORKER_NUM ✅"
        fi
    done
    
    # クリーンアップ
    rm -rf ./tmp/worker_ids
    echo ""
}

# 4. プロセスIDベースの検出
test_process_based_approach() {
    echo "4. プロセスIDベースの検出"
    echo "-------------------------"
    
    # 現在のプロセス情報
    echo "  PID: $$"
    echo "  PPID: $PPID"
    
    # tmuxペインのプロセスツリーを確認
    echo ""
    echo "  tmuxペインのプロセス確認:"
    tmux list-panes -F '#{pane_id} #{pane_pid}' 2>/dev/null || echo "  ❌ tmuxペイン情報を取得できません"
    echo ""
}

# 5. 提案する解決策
propose_solution() {
    echo "5. 提案する解決策"
    echo "-----------------"
    echo ""
    echo "【問題】Claude Code内ではTMUX環境変数が利用できない"
    echo ""
    echo "【解決策1】起動時にワーカー番号をファイルに記録"
    echo "  multi-claude起動時に各ペインのIDファイルを作成:"
    echo "    ./tmp/worker_ids/worker1.id → \"1\""
    echo "    ./tmp/worker_ids/worker2.id → \"2\""
    echo "    ./tmp/worker_ids/worker3.id → \"3\""
    echo ""
    echo "【解決策2】BOSSからワーカー番号を含むファイルを作成"
    echo "  BOSSが各ワーカー用の設定ファイルを作成:"
    echo "    ./tmp/worker1.config → WORKER_NUM=1"
    echo "    ./tmp/worker2.config → WORKER_NUM=2"
    echo "    ./tmp/worker3.config → WORKER_NUM=3"
    echo ""
    echo "【解決策3】agent-send.shを改良"
    echo "  送信時にワーカー番号をファイルに記録:"
    echo "    ./agent-send.sh worker1 \"メッセージ\" → ./tmp/current_worker.txt に \"1\" を記録"
}

# メイン処理
main() {
    test_environment_variables
    test_tmux_commands
    test_file_based_approach
    test_process_based_approach
    propose_solution
    
    echo ""
    echo "================================"
    echo "結論: ファイルベースの番号伝達が最も確実"
    echo "================================"
}

main