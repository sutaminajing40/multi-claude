# 👷 WORKER指示書（動的生成）

## 今回のタスク
multi-claudeコマンドに`--dangerously-skip-permissions`オプションを追加

## Worker1（テスト担当）の作業
1. `tests/test_dangerously_skip_permissions.sh`を作成
2. 以下のテストケースを実装：
   - `multi-claude --dangerously-skip-permissions`が正常に起動すること
   - claudeコマンドに`--dangerously-skip-permissions`が渡されること
   - ヘルプに新オプションが表示されること
3. テストを実行して失敗を確認

## Worker2（実装担当）の作業
1. multi-claudeスクリプトを編集
2. コマンドライン引数処理に`--dangerously-skip-permissions`を追加
3. claudeコマンド起動時にオプションを渡す処理を実装

## Worker3（補助担当）の作業
1. ヘルプメッセージに新オプションの説明を追加
2. バージョン番号を1.0.9に更新
3. 実装の補助・レビュー

## 完了確認
テストが全て通過したらBOSSに報告
EOF < /dev/null