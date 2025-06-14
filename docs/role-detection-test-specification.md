# Multi-Claude 役割判定システム テスト仕様書

## 概要
役割判定システムの堅牢性を確保するためのテスト仕様。TDD（テスト駆動開発）アプローチに従い、実装前にテストケースを定義。

## テスト戦略

### 1. テストレベル
- **ユニットテスト**: 個別の関数・モジュール
- **統合テスト**: 複数コンポーネントの連携
- **システムテスト**: エンドツーエンドの動作
- **回帰テスト**: 既存機能への影響確認

### 2. テストカテゴリ
- **正常系**: 期待される使用方法
- **異常系**: エラーケース
- **境界値**: 限界値での動作
- **ストレス**: 高負荷・長時間稼働

## テストケース一覧

### TC001: 基本的な役割判定

#### TC001-1: 環境変数による役割判定
```bash
# テストファイル: test_role_detection_env.sh
# 期待値: 環境変数が最優先される

# 入力
export MULTI_CLAUDE_ROLE="worker1"
# tmuxは boss1 のペインを示している

# 期待される出力
get_my_role() # => "worker1"
```

#### TC001-2: 役割ファイルによる判定
```bash
# テストファイル: test_role_detection_file.sh
# 期待値: 環境変数がない場合、役割ファイルを参照

# 前提条件
unset MULTI_CLAUDE_ROLE
echo "boss1" > .multi-claude/runtime/session-123/my-role

# 期待される出力
get_my_role() # => "boss1"
```

#### TC001-3: tmuxペインタイトルによる判定
```bash
# テストファイル: test_role_detection_title.sh
# 期待値: 役割ファイルがない場合、ペインタイトルを参照

# 前提条件
unset MULTI_CLAUDE_ROLE
rm -f .multi-claude/runtime/*/my-role
tmux select-pane -T "worker2"

# 期待される出力
get_my_role() # => "worker2"
```

### TC002: 整合性チェック

#### TC002-1: ペインタイトルと役割ファイルの不一致検出
```bash
# テストファイル: test_integrity_check_mismatch.sh
# 期待値: 不一致を検出し、WARNログを出力

# 設定
echo "worker1" > .multi-claude/runtime/session-123/my-role
tmux select-pane -T "worker2"

# 期待される動作
check_role_integrity() # => false
# ログ: "[WARN] Role mismatch detected: file=worker1, title=worker2"
```

#### TC002-2: 役割の重複検出
```bash
# テストファイル: test_integrity_check_duplicate.sh
# 期待値: 同じ役割を持つ複数のエージェントを検出

# 設定
# 2つのペインが同じ役割ファイルを持つ
echo "boss1" > .multi-claude/runtime/session-123/pane0-role
echo "boss1" > .multi-claude/runtime/session-123/pane1-role

# 期待される動作
check_role_duplication() # => true
# ログ: "[ERROR] Duplicate role detected: boss1 assigned to multiple panes"
```

### TC003: 自動修復機能

#### TC003-1: ペインタイトルの自動修正
```bash
# テストファイル: test_auto_repair_title.sh
# 期待値: 役割ファイルに合わせてペインタイトルを更新

# 初期状態
echo "worker3" > .multi-claude/runtime/session-123/my-role
tmux select-pane -T "worker1"  # 不一致

# 実行
auto_repair_role()

# 期待される結果
tmux display-message -p '#{pane_title}' # => "worker3"
# ログ: "[INFO] Pane title updated: worker1 -> worker3"
```

#### TC003-2: 役割重複の自動解決
```bash
# テストファイル: test_auto_repair_duplicate.sh
# 期待値: 新しい方を優先し、古い方を再割り当て

# 初期状態（タイムスタンプ付き）
echo "boss1|2024-01-01T10:00:00" > pane0-role
echo "boss1|2024-01-01T10:00:05" > pane1-role  # より新しい

# 実行
resolve_role_conflict()

# 期待される結果
cat pane0-role # => "worker1|2024-01-01T10:00:10"  # 再割り当て
cat pane1-role # => "boss1|2024-01-01T10:00:05"    # 維持
```

### TC004: エラーケース

#### TC004-1: tmuxセッションが存在しない
```bash
# テストファイル: test_error_no_session.sh
# 期待値: 適切なエラーメッセージとフォールバック

# 前提条件
tmux kill-server 2>/dev/null

# 実行
get_my_role()

# 期待される結果
# 戻り値: 1 (エラー)
# 出力: "[ERROR] No tmux session found. Cannot determine role."
```

#### TC004-2: 役割ファイルの破損
```bash
# テストファイル: test_error_corrupt_file.sh
# 期待値: 破損を検出し、再作成を試みる

# 設定（不正なJSON）
echo "{invalid json" > .multi-claude/runtime/session-123/role-assignments.json

# 実行
load_role_assignments()

# 期待される結果
# ログ: "[WARN] Corrupted role file detected. Attempting recovery..."
# 新しい有効なファイルが作成される
```

### TC005: 境界値テスト

#### TC005-1: 最大ペイン数での動作
```bash
# テストファイル: test_boundary_max_panes.sh
# 期待値: 10個のワーカーでも正常動作

# 設定
for i in {1..10}; do
    tmux split-window
    setup_worker_role "worker$i"
done

# 検証
all_roles_unique() # => true
all_roles_assigned() # => true
```

#### TC005-2: 長時間稼働後の動作
```bash
# テストファイル: test_boundary_long_running.sh
# 期待値: 24時間後も役割判定が正確

# シミュレーション
# - 5分ごとの定期チェックを288回実行
# - ランダムなタイミングでペイン再起動
# - 役割の一貫性を検証
```

### TC006: パフォーマンステスト

#### TC006-1: 役割判定の応答時間
```bash
# テストファイル: test_performance_response_time.sh
# 期待値: 100ms以内に役割を返す

# 測定
time_start=$(date +%s%N)
role=$(get_my_role)
time_end=$(date +%s%N)
duration=$((($time_end - $time_start) / 1000000))

# 検証
[[ $duration -lt 100 ]] # => true
```

#### TC006-2: 同時アクセス時の動作
```bash
# テストファイル: test_performance_concurrent.sh
# 期待値: 4つのエージェントが同時に役割判定してもデッドロックしない

# 並列実行
for i in {0..3}; do
    (check_and_update_role) &
done
wait

# 検証
# すべてのプロセスが正常終了
# ファイルロックが適切に機能
```

## テスト実行環境

### 必要なツール
```bash
# テストランナー
bats          # Bash Automated Testing System
jq            # JSON処理
timeout       # タイムアウト制御

# モック・スタブ
tmux_mock.sh  # tmuxコマンドのモック
```

### ディレクトリ構成
```
tests/
├── role-detection/
│   ├── unit/           # ユニットテスト
│   ├── integration/    # 統合テスト
│   └── system/         # システムテスト
├── fixtures/           # テストデータ
├── mocks/             # モック実装
└── run-all-tests.sh   # 全テスト実行スクリプト
```

## テスト実行方法

### 個別テスト実行
```bash
cd tests/role-detection/unit
bats test_role_detection_env.sh
```

### カテゴリ別実行
```bash
# ユニットテストのみ
./run-all-tests.sh --unit

# 統合テストのみ
./run-all-tests.sh --integration
```

### 全テスト実行
```bash
./run-all-tests.sh --all
```

## 期待される結果

### カバレッジ目標
- ユニットテスト: 90%以上
- 統合テスト: 80%以上
- システムテスト: 主要シナリオ100%

### 品質基準
- すべてのテストがグリーン
- パフォーマンステストが基準値以内
- エラーケースで適切なメッセージ表示

## CI/CD統合

### GitHub Actions設定
```yaml
name: Role Detection Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: |
          sudo apt-get install tmux bats jq
      - name: Run tests
        run: ./tests/run-all-tests.sh --all
      - name: Upload coverage
        uses: codecov/codecov-action@v1
```

## まとめ

このテスト仕様に基づいて実装を進めることで：
1. **実装前に期待動作が明確**になる
2. **エッジケースを事前に洗い出せる**
3. **リファクタリング時の安全性**が確保される
4. **新機能追加時の既存機能への影響**を検出できる

テストファースト開発により、堅牢で保守性の高い役割判定システムを構築します。