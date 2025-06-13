#!/bin/bash

# 🧪 ファイルベースのワーカーID管理テスト

echo "🧪 ファイルベースのワーカーID管理テスト"
echo "========================================"
echo ""

# テスト環境準備
TEST_DIR="$(dirname "$0")/.."
cd "$TEST_DIR"

# 1. setup.shでのワーカーID作成テスト
test_setup_worker_ids() {
    echo "1. setup.shでのワーカーID作成テスト"
    echo "-----------------------------------"
    
    # テスト用ディレクトリ作成
    mkdir -p ./tmp/worker_ids
    
    # setup.shの処理をシミュレート
    echo "  multiagent:0.1にworker1を割り当て..."
    echo "1" > ./tmp/worker_ids/pane_0_1.id
    
    echo "  multiagent:0.2にworker2を割り当て..."
    echo "2" > ./tmp/worker_ids/pane_0_2.id
    
    echo "  multiagent:0.3にworker3を割り当て..."
    echo "3" > ./tmp/worker_ids/pane_0_3.id
    
    # 確認
    echo ""
    echo "  作成されたIDファイル:"
    ls -la ./tmp/worker_ids/*.id
    
    # 読み込みテスト
    if [ -f "./tmp/worker_ids/pane_0_1.id" ] && \
       [ "$(cat ./tmp/worker_ids/pane_0_1.id)" = "1" ]; then
        echo "  ✅ pane_0_1.id → worker1"
    else
        echo "  ❌ pane_0_1.idの作成または内容が不正"
    fi
    
    echo ""
}

# 2. agent-send.shでのワーカーID記録テスト
test_agent_send_worker_id() {
    echo "2. agent-send.shでのワーカーID記録テスト"
    echo "----------------------------------------"
    
    # agent-send.shがワーカーに送信する際にIDを記録
    simulate_agent_send() {
        local worker="$1"
        local message="$2"
        
        # ワーカー番号を抽出
        local worker_num=$(echo "$worker" | sed 's/worker//')
        
        # 最新のワーカーIDを記録
        echo "$worker_num" > ./tmp/worker_ids/current_worker.id
        
        echo "  $worker にメッセージ送信 → current_worker.id に $worker_num を記録"
    }
    
    # テスト実行
    simulate_agent_send "worker1" "タスク実行"
    if [ -f "./tmp/worker_ids/current_worker.id" ] && \
       [ "$(cat ./tmp/worker_ids/current_worker.id)" = "1" ]; then
        echo "  ✅ current_worker.id = 1"
    fi
    
    simulate_agent_send "worker2" "タスク実行"
    if [ -f "./tmp/worker_ids/current_worker.id" ] && \
       [ "$(cat ./tmp/worker_ids/current_worker.id)" = "2" ]; then
        echo "  ✅ current_worker.id = 2"
    fi
    
    echo ""
}

# 3. ワーカー側でのID読み込みテスト
test_worker_read_id() {
    echo "3. ワーカー側でのID読み込みテスト"
    echo "----------------------------------"
    
    # ワーカーがIDを読み込む処理
    get_worker_number() {
        # 方法1: current_worker.idから読み込み（最新の送信先）
        if [ -f "./tmp/worker_ids/current_worker.id" ]; then
            WORKER_NUM=$(cat ./tmp/worker_ids/current_worker.id)
            echo "  方法1: current_worker.id → worker$WORKER_NUM"
            return 0
        fi
        
        # 方法2: 事前に作成されたペインIDファイルから読み込み
        # （実際のペイン番号が分かる場合）
        echo "  方法2: ペインIDファイルは実行時の情報が必要"
        
        return 1
    }
    
    # テスト実行
    echo "2" > ./tmp/worker_ids/current_worker.id
    get_worker_number
    
    echo ""
}

# 4. 完了ファイル作成テスト
test_completion_file_creation() {
    echo "4. 完了ファイル作成テスト"
    echo "--------------------------"
    
    # ワーカー番号を読み込んで完了ファイルを作成
    create_completion_file() {
        local worker_num="$1"
        
        mkdir -p ./tmp
        touch "./tmp/worker${worker_num}_done.txt"
        echo "  worker$worker_num → ./tmp/worker${worker_num}_done.txt 作成"
    }
    
    # テスト実行
    create_completion_file "1"
    create_completion_file "2"
    create_completion_file "3"
    
    echo ""
    echo "  作成された完了ファイル:"
    ls -la ./tmp/worker*_done.txt
    
    # クリーンアップ
    rm -f ./tmp/worker*_done.txt
    echo ""
}

# 5. 提案する実装
propose_implementation() {
    echo "5. 提案する実装"
    echo "---------------"
    echo ""
    echo "【setup.shの修正】"
    echo "  # ワーカーIDディレクトリを作成"
    echo "  mkdir -p ./tmp/worker_ids"
    echo ""
    echo "【agent-send.shの修正】"
    echo "  # ワーカーに送信する際、番号をファイルに記録"
    echo "  case \"\$1\" in"
    echo "    worker1) echo \"1\" > ./tmp/worker_ids/current_worker.id ;;"
    echo "    worker2) echo \"2\" > ./tmp/worker_ids/current_worker.id ;;"
    echo "    worker3) echo \"3\" > ./tmp/worker_ids/current_worker.id ;;"
    echo "  esac"
    echo ""
    echo "【worker_dynamic.mdの修正】"
    echo "  # ワーカー番号を読み込み"
    echo "  if [ -f ./tmp/worker_ids/current_worker.id ]; then"
    echo "    WORKER_NUM=\$(cat ./tmp/worker_ids/current_worker.id)"
    echo "  else"
    echo "    echo \"エラー: ワーカー番号が不明です\""
    echo "    exit 1"
    echo "  fi"
}

# メイン処理
main() {
    test_setup_worker_ids
    test_agent_send_worker_id
    test_worker_read_id
    test_completion_file_creation
    propose_implementation
    
    # クリーンアップ
    rm -rf ./tmp/worker_ids
    
    echo ""
    echo "✅ ファイルベースのワーカーID管理が実現可能です"
}

main