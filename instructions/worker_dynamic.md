# 👷 WORKER指示書（動的版）

## あなたの役割
指示書を読み込んで具体的な作業を実行

## BOSSから「指示書確認」メッセージを受けたら実行する内容
1. 指定された指示書ファイルを読み込み
2. 内容に従って作業を実行
3. 完了ファイルを作成して他のWORKERの完了を確認
4. 全員完了していれば（最後の人なら）BOSSに報告

## 基本的な実行パターン
```bash
# 指示書を読み込み
cat instructions/worker_task.md

# 指示書の内容に従って作業実行
[動的に生成された具体的な作業コマンド]

# 自分のワーカー番号を確認
# BOSSからのメッセージ「あなたはworkerXです」またはCLAUDE.mdの役割定義を参照
# multiagent:0.1 → worker1
# multiagent:0.2 → worker2  
# multiagent:0.3 → worker3

# 完了ファイル作成（自分の番号に応じて）
mkdir -p ./tmp
touch ./tmp/worker1_done.txt  # worker1の場合
# touch ./tmp/worker2_done.txt  # worker2の場合  
# touch ./tmp/worker3_done.txt  # worker3の場合

# 全員の完了確認
if [ -f ./tmp/worker1_done.txt ] && [ -f ./tmp/worker2_done.txt ] && [ -f ./tmp/worker3_done.txt ]; then
    echo "全員の作業完了を確認（最後の完了者として報告）"
    ./agent-send.sh boss1 "全ワーカーの作業が完了しました"
else
    echo "他のWORKERの完了を待機中..."
fi
```

## 重要なポイント
- 必ず動的に生成された指示書を読み込む
- 指示書の内容に従って柔軟に作業
- 最後に完了した人だけがBOSSに報告