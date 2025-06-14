#!/usr/bin/env bats

# TC001-3: tmuxペインタイトルによる判定
# 期待値: 役割ファイルがない場合、ペインタイトルを参照

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

@test "ペインタイトルから役割を判定できる" {
    # 役割ファイルなし（存在しない）
    
    # tmuxペインタイトルを設定（モック）
    export MOCK_TMUX_PANE_TITLE="worker2"
    
    # 役割判定を実行
    run get_my_role
    
    # ペインタイトルの値が返されることを確認
    [ "$status" -eq 0 ]
    [ "$output" = "worker2" ]
}

@test "ペインタイトルが有効な役割名でない場合は次の判定方法へ" {
    # tmuxペインタイトルを設定（無効な値）
    export MOCK_TMUX_PANE_TITLE="invalid_title"
    
    # tmuxセッション情報を設定（モック）
    export MOCK_TMUX_SESSION="multiagent"
    export MOCK_TMUX_PANE_INDEX="1"
    
    # 役割判定を実行
    run get_my_role
    
    # セッションとペインインデックスから判定された値が返される
    [ "$status" -eq 0 ]
    [ "$output" = "worker1" ]
}

@test "すべての判定方法が失敗した場合はエラー" {
    # tmuxペインタイトルも無効
    export MOCK_TMUX_PANE_TITLE=""
    
    # tmuxセッション情報も無効
    export MOCK_TMUX_SESSION=""
    export MOCK_TMUX_PANE_INDEX=""
    
    # 役割判定を実行
    run get_my_role
    
    # エラーが返されることを確認
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot determine role" ]]
}