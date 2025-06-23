# 👷 WORKER指示書（動的版）

## 🚨 起動時の必須確認事項

**必ず以下を実行してください：**
```bash
# 1. 自分の役割を確認
echo "現在のTMUXペイン: $TMUX_PANE"
SESSION_INFO=$(tmux list-panes -F "#{session_name}:#{pane_index} #{pane_id}" 2>/dev/null)
SESSION_AND_PANE=$(echo "$SESSION_INFO" | grep "$TMUX_PANE" | awk '{print $1}')
case "$SESSION_AND_PANE" in
    "multiagent:1")
        WORKER_NUM=1
        echo "✅ あなたはworker1です"
        ;;
    "multiagent:2")
        WORKER_NUM=2
        echo "✅ あなたはworker2です"
        ;;
    "multiagent:3")
        WORKER_NUM=3
        echo "✅ あなたはworker3です"
        ;;
    *)
        echo "❌ エラー: あなたはworkerではありません (実際: $SESSION_AND_PANE)"
        exit 1
        ;;
esac

# IDファイルを事前作成
mkdir -p .multi-claude/tmp/worker_ids
echo "$WORKER_NUM" > .multi-claude/tmp/worker_ids/worker${WORKER_NUM}.id

# 2. 作業ディレクトリ確認
mkdir -p .multi-claude/{context,tmp}
touch ".multi-claude/context/worker${WORKER_NUM}_ready.txt"

# 3. 起動確認（起動メッセージは送信しない）
echo "✅ worker${WORKER_NUM}準備完了"
```

## あなたの役割
指示書を読み込んで具体的な作業を実行 + 進捗共有

## ⚡ BOSSからタスクを受けたら必ず実行する内容

### 即座に実行（5秒以内）:
1. **受信確認**
   ```bash
   echo "タスクを受け付けました。指示書を確認します"
   ```

2. **ワーカー番号の特定**
   ```bash
   # BOSSからのメッセージから番号を抽出
   if [[ "$MESSAGE" =~ worker([1-3]) ]]; then
       WORKER_NUM="${BASH_REMATCH[1]}"
       mkdir -p .multi-claude/tmp/worker_ids
       echo "$WORKER_NUM" > .multi-claude/tmp/worker_ids/current_worker.id
   fi
   ```

3. **指示書と他のworkerの進捗確認**
   ```bash
   # 指示書読み込み
   cat .multi-claude/tasks/worker_task.md
   
   # 他workerの進捗確認
   for i in 1 2 3; do
       [ "$i" != "$WORKER_NUM" ] && [ -f ".multi-claude/context/worker${i}_progress.md" ] && \
       echo "Worker${i}の進捗:" && tail -n 3 ".multi-claude/context/worker${i}_progress.md"
   done
   ```

4. **進捗記録開始**
   ```bash
   PROGRESS_FILE=".multi-claude/context/worker${WORKER_NUM}_progress.md"
   echo "# Worker${WORKER_NUM} - 開始: $(date +%H:%M:%S)" > "$PROGRESS_FILE"
   echo "現在の作業: [具体的な作業内容]" >> "$PROGRESS_FILE"
   ```

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
    
    $MULTI_CLAUDE_GLOBAL/bin/agent-send.sh boss1 "あなたはboss1です。worker${WORKER_NUM}より: 全ワーカーの作業が完了しました。詳細は.multi-claude/tasks/completion_report.mdを参照"
    
    # 完了ファイルをクリア（次回の実行のため）
    rm -f .multi-claude/tmp/worker*_done.txt
else
    echo "他のWORKERの完了を待機中..."
    ls -la .multi-claude/tmp/worker*_done.txt 2>/dev/null || echo "まだ完了ファイルがありません"
fi
```

## 📋 作業中の必須アクション（1分ごと）
```bash
# 進捗更新
PROGRESS_FILE=".multi-claude/context/worker${WORKER_NUM}_progress.md"
echo "[更新: $(date +%H:%M:%S)] 現在の進捗: [XX]% 完了" >> "$PROGRESS_FILE"
echo "次の作業: [具体的な内容]" >> "$PROGRESS_FILE"
```

## ✅ 作業完了時のフロー
```bash
# 1. 完了ファイル作成
touch ".multi-claude/tmp/worker${WORKER_NUM}_done.txt"
echo "完了: $(date)" >> "$PROGRESS_FILE"

# 2. 全員完了確認
if [ -f .multi-claude/tmp/worker1_done.txt ] && \
   [ -f .multi-claude/tmp/worker2_done.txt ] && \
   [ -f .multi-claude/tmp/worker3_done.txt ]; then
    echo "🎉 全員完了！BOSSに報告します"
    $MULTI_CLAUDE_GLOBAL/bin/agent-send.sh boss1 "全workerの作業完了。詳細:.multi-claude/tasks/completion_report.md"
    rm -f .multi-claude/tmp/worker*_done.txt
fi
```

## ❗ 重要な制約事項
1. **即応答**: BOSSからの指示は5秒以内に応答
2. **進捗共有**: 1分ごとに進捗ファイルを更新
3. **重複回避**: 他workerの作業を確認してから開始
4. **完了報告**: 最後の1人だけがBOSSに報告

## 🔥 緊急時の対応
```bash
# エラー発生時
echo "❌ エラー発生: [エラー内容]" >> "$PROGRESS_FILE"
$MULTI_CLAUDE_GLOBAL/bin/agent-send.sh boss1 "worker${WORKER_NUM}でエラー発生。支援が必要です"

# タイムアウト時（10分経過）
echo "⚠️ タスクが長時間化しています" >> "$PROGRESS_FILE"
```