#!/usr/bin/env bats

# TC001-1: 環境変数による役割判定
# 期待値: 環境変数が最優先される

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
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "環境変数が設定されている場合、それが最優先される" {
    # 環境変数を設定
    export MULTI_CLAUDE_ROLE="worker1"
    
    # 役割ファイルを作成（異なる役割）
    echo "boss1" > .multi-claude/runtime/session-test/my-role
    
    # tmuxペインタイトルも異なる設定（モック）
    export MOCK_TMUX_PANE_TITLE="worker2"
    
    # 役割判定を実行
    run get_my_role
    
    # 環境変数の値が返されることを確認
    [ "$status" -eq 0 ]
    [ "$output" = "worker1" ]
}

@test "環境変数が空の場合は無視される" {
    # 空の環境変数
    export MULTI_CLAUDE_ROLE=""
    
    # 役割ファイルを作成
    echo "boss1" > .multi-claude/runtime/session-test/my-role
    
    # 役割判定を実行
    run get_my_role
    
    # 役割ファイルの値が返されることを確認
    [ "$status" -eq 0 ]
    [ "$output" = "boss1" ]
}

@test "環境変数が無効な役割の場合はエラー" {
    # 無効な役割を設定
    export MULTI_CLAUDE_ROLE="invalid_role"
    
    # 役割判定を実行
    run get_my_role
    
    # エラーが返されることを確認
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid role" ]]
}