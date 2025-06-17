#!/bin/bash

# 役割判定システム修正のテスト

echo "=== 役割判定システム修正テスト ==="

# テスト用の関数定義 (修正後のロジック)
detect_role_fixed() {
    local session_info=$(tmux list-panes -F "#{session_name}:#{pane_index} #{pane_id}" 2>/dev/null)
    local current_pane="$TMUX_PANE"
    
    # session_infoから現在のペインの情報を抽出
    local session_and_pane=$(echo "$session_info" | grep "$current_pane" | awk '{print $1}')
    
    case "$session_and_pane" in
        "president:0")
            echo "PRESIDENT"
            ;;
        "multiagent:0")
            echo "boss1"
            ;;
        "multiagent:1")
            echo "worker1"
            ;;
        "multiagent:2") 
            echo "worker2"
            ;;
        "multiagent:3")
            echo "worker3"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# テストケース1: president:0 → PRESIDENT
test_president() {
    echo "テスト1: president:0の判定"
    export TMUX_PANE="%0"
    
    # モックデータ
    mock_list_panes() {
        echo "president:0 %0"
    }
    
    # 一時的にtmuxコマンドを置き換え
    alias tmux_backup=$(which tmux)
    tmux() {
        if [[ "$1" == "list-panes" ]]; then
            mock_list_panes
        else
            tmux_backup "$@"
        fi
    }
    
    result=$(detect_role_fixed)
    if [[ "$result" == "PRESIDENT" ]]; then
        echo "✅ パス: president:0 → PRESIDENT"
    else
        echo "❌ 失敗: president:0 → $result (期待値: PRESIDENT)"
    fi
    
    unalias tmux 2>/dev/null || true
}

# テストケース2: multiagent:0 → boss1
test_boss1() {
    echo "テスト2: multiagent:0の判定"
    export TMUX_PANE="%0"
    
    # モックデータ
    mock_list_panes() {
        echo "multiagent:0 %0"
        echo "multiagent:1 %1"
        echo "multiagent:2 %2"
        echo "multiagent:3 %3"
    }
    
    # 一時的にtmuxコマンドを置き換え
    tmux() {
        if [[ "$1" == "list-panes" ]]; then
            mock_list_panes
        fi
    }
    
    result=$(detect_role_fixed)
    if [[ "$result" == "boss1" ]]; then
        echo "✅ パス: multiagent:0 → boss1"
    else
        echo "❌ 失敗: multiagent:0 → $result (期待値: boss1)"
    fi
    
    unset -f tmux
}

# テストケース3: multiagent:1 → worker1
test_worker1() {
    echo "テスト3: multiagent:1の判定"
    export TMUX_PANE="%1"
    
    # モックデータ
    mock_list_panes() {
        echo "multiagent:0 %0"
        echo "multiagent:1 %1"
        echo "multiagent:2 %2"
        echo "multiagent:3 %3"
    }
    
    # 一時的にtmuxコマンドを置き換え
    tmux() {
        if [[ "$1" == "list-panes" ]]; then
            mock_list_panes
        fi
    }
    
    result=$(detect_role_fixed)
    if [[ "$result" == "worker1" ]]; then
        echo "✅ パス: multiagent:1 → worker1"
    else
        echo "❌ 失敗: multiagent:1 → $result (期待値: worker1)"
    fi
    
    unset -f tmux
}

# すべてのテストを実行
test_president
test_boss1
test_worker1

echo "=== 役割判定システム修正テスト完了 ==="