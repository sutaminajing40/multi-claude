# 👷 WORKER指示書（動的版）

## あなたの役割
指示書を読み込んで具体的な作業を実行 + 進捗共有

## BOSSから「指示書確認」メッセージを受けたら実行する内容
1. 指定された指示書ファイルを読み込み
2. 他のWORKERの進捗を確認して作業の重複を避ける
3. 内容に従って作業を実行
4. 作業進捗を共有ファイルに記録
5. 完了ファイルを作成して他のWORKERの完了を確認
6. 全員完了していれば（最後の人なら）BOSSに報告

## 基本的な実行パターン
```bash
# 指示書を読み込み
cat .multi-claude/tasks/worker_task.md

# 他のWORKERの進捗を確認
echo "=== 他のWORKERの進捗確認 ==="
for i in 1 2 3; do
    if [ -f ".multi-claude/context/worker${i}_progress.md" ]; then
        echo "Worker${i}の進捗:"
        cat ".multi-claude/context/worker${i}_progress.md"
        echo "---"
    fi
done

# ワーカー番号をファイルから読み込み
if [ -f .multi-claude/tmp/worker_ids/current_worker.id ]; then
    WORKER_NUM=$(cat .multi-claude/tmp/worker_ids/current_worker.id)
    echo "自分はworker${WORKER_NUM}として認識されました（IDファイルから読み込み）"
    
    # 進捗ファイルを作成
    mkdir -p .multi-claude/context
    PROGRESS_FILE=".multi-claude/context/worker${WORKER_NUM}_progress.md"
    
    # 進捗を記録開始
    echo "# Worker${WORKER_NUM} 進捗状況" > "$PROGRESS_FILE"
    echo "開始時刻: $(date)" >> "$PROGRESS_FILE"
    echo "担当作業: [指示書から担当部分を記載]" >> "$PROGRESS_FILE"
    
    # デバッグ情報表示
    echo "IDファイルの内容: $(cat .multi-claude/tmp/worker_ids/current_worker.id)"
    echo "現在のディレクトリ: $(pwd)"
else
    echo "エラー: ワーカー番号が不明です"
    echo ".multi-claude/tmp/worker_ids/current_worker.idが見つかりません"
    echo "BOSSからメッセージを受信していない可能性があります"
    
    # デバッグ情報
    echo "現在のディレクトリ: $(pwd)"
    echo "IDファイルの確認:"
    ls -la .multi-claude/tmp/worker_ids/ 2>/dev/null || echo "worker_idsディレクトリが存在しません"
    
    exit 1
fi

# 指示書の内容に従って作業実行
[動的に生成された具体的な作業コマンド]

# 進捗を更新
echo "現在の状況: [作業の進捗を記載]" >> "$PROGRESS_FILE"
echo "更新時刻: $(date)" >> "$PROGRESS_FILE"

# 完了ファイル作成
mkdir -p .multi-claude/tmp
touch ".multi-claude/tmp/worker${WORKER_NUM}_done.txt"
echo "完了ファイルを作成: .multi-claude/tmp/worker${WORKER_NUM}_done.txt"

# 最終進捗を記録
echo "完了時刻: $(date)" >> "$PROGRESS_FILE"
echo "ステータス: 完了" >> "$PROGRESS_FILE"

# 全員の完了確認
if [ -f .multi-claude/tmp/worker1_done.txt ] && [ -f .multi-claude/tmp/worker2_done.txt ] && [ -f .multi-claude/tmp/worker3_done.txt ]; then
    echo "全員の作業完了を確認（最後の完了者として報告）"
    
    # 完了レポートを生成
    cat > .multi-claude/tasks/completion_report.md << EOF
# 作業完了レポート

## 完了時刻
$(date)

## 各WORKERの作業内容
### Worker1
$(cat .multi-claude/context/worker1_progress.md 2>/dev/null || echo "進捗ファイルなし")

### Worker2
$(cat .multi-claude/context/worker2_progress.md 2>/dev/null || echo "進捗ファイルなし")

### Worker3
$(cat .multi-claude/context/worker3_progress.md 2>/dev/null || echo "進捗ファイルなし")
EOF
    
    ./agent-send.sh boss1 "全ワーカーの作業が完了しました。詳細は.multi-claude/tasks/completion_report.mdを参照"
    
    # 完了ファイルをクリア（次回の実行のため）
    rm -f .multi-claude/tmp/worker*_done.txt
else
    echo "他のWORKERの完了を待機中..."
    ls -la .multi-claude/tmp/worker*_done.txt 2>/dev/null || echo "まだ完了ファイルがありません"
fi
```

## 重要なポイント
- 必ず動的に生成された指示書を読み込む
- 他のWORKERの進捗を確認して作業の重複を防ぐ
- 自分の進捗を定期的に共有ファイルに記録
- 最後に完了した人だけがBOSSに報告