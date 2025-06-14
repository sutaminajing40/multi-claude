#!/usr/bin/env bats

# TC001-2: 役割ファイルによる判定
# 期待値: 環境変数がない場合、役割ファイルを参照

setup() {
    # テスト用の一時ディレクトリ
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # .multi-claudeディレクトリ構造を作成
    mkdir -p .multi-claude/{config,runtime/session-test,logs}
    
    # role-mapping.jsonをコピー
    cp "$BATS_TEST_DIRNAME/../../../.multi-claude/config/role-mapping.json" .multi-claude/config/
    
    # 役割判定関数のソース
    source "$BATS_TEST_DIRNAME/../../../.multi-claude/bin/role-detection.sh"
    
    # 環境変数をクリア
    unset MULTI_CLAUDE_ROLE
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "役割ファイルが存在する場合、その内容が返される" {
    # 役割ファイルを作成
    echo "boss1" > .multi-claude/runtime/session-test/my-role
    
    # 役割判定を実行
    run get_my_role
    
    # 役割ファイルの値が返されることを確認
    [ "$status" -eq 0 ]
    [ "$output" = "boss1" ]
}

@test "複数のセッションディレクトリがある場合、現在のセッションIDのファイルを読む" {
    # 複数のセッションディレクトリを作成
    mkdir -p .multi-claude/runtime/session-old
    echo "worker1" > .multi-claude/runtime/session-old/my-role
    
    # 現在のセッションIDを設定
    export MULTI_CLAUDE_SESSION_ID="session-test"
    echo "worker2" > .multi-claude/runtime/session-test/my-role
    
    # 役割判定を実行
    run get_my_role
    
    # 現在のセッションの役割が返されることを確認
    [ "$status" -eq 0 ]
    [ "$output" = "worker2" ]
}

@test "役割ファイルが空の場合は次の判定方法にフォールバック" {
    # 空の役割ファイルを作成
    touch .multi-claude/runtime/session-test/my-role
    
    # tmuxペインタイトルを設定（モック）
    export MOCK_TMUX_PANE_TITLE="worker3"
    
    # 役割判定を実行
    run get_my_role
    
    # ペインタイトルの値が返されることを確認
    [ "$status" -eq 0 ]
    [ "$output" = "worker3" ]
}