#!/bin/bash

# 🚀 Multi-Claude システム グローバルインストール

set -e

# Claude Codeのパス検出
CLAUDE_PATH=""
# 一般的なClaude Codeインストールパス
COMMON_CLAUDE_PATHS=(
    "$HOME/.claude/local/claude"
    "/usr/local/bin/claude"
    "/opt/homebrew/bin/claude"
)

for path in "${COMMON_CLAUDE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        CLAUDE_PATH="$path"
        break
    fi
done

# パスが見つからなければ、コマンドとして確認
if [ -z "$CLAUDE_PATH" ] && command -v claude &> /dev/null; then
    CLAUDE_PATH="claude"
fi

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

echo "🤖 Multi-Claude システム グローバルインストール"
echo "============================================="
echo ""

# インストール先ディレクトリ
INSTALL_DIR="$HOME/.multi-claude"
BIN_DIR="$HOME/bin"

# STEP 1: 環境チェック
log_info "🔍 環境チェック中..."

# tmuxの存在確認
if ! command -v tmux &> /dev/null; then
    log_error "tmuxがインストールされていません"
    echo "インストール: brew install tmux"
    exit 1
fi

# claudeの存在確認
if [ -z "$CLAUDE_PATH" ]; then
    log_error "claude commandが見つかりません"
    echo "Claude Codeがインストールされていることを確認してください"
    echo "一般的なパス: ~/.claude/local/claude"
    exit 1
fi

log_info "Claude Code検出: $CLAUDE_PATH"

log_success "✅ 環境チェック完了"

# STEP 2: インストールディレクトリ作成
log_info "📁 インストールディレクトリ作成中..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/instructions"
mkdir -p "$INSTALL_DIR/share"

log_success "✅ ディレクトリ作成完了: $INSTALL_DIR"

# STEP 3: ファイルコピー
log_info "📋 ファイルコピー中..."

# 実行ファイルをbinディレクトリにコピー
cp setup.sh "$INSTALL_DIR/bin/"
cp agent-send.sh "$INSTALL_DIR/bin/"
cp health-check.sh "$INSTALL_DIR/bin/" 2>/dev/null || true

# multi-claudeは直接配置（シンボリックリンク用）
cp multi-claude "$INSTALL_DIR/"

# 指示書ファイルをコピー
cp instructions/*_dynamic.md "$INSTALL_DIR/instructions/"

# shareディレクトリのファイルをコピー（存在する場合）
if [ -d "share" ] && [ -f "share/CLAUDE_template.md" ]; then
    cp share/CLAUDE_template.md "$INSTALL_DIR/share/"
else
    # CLAUDE.mdテンプレート作成（shareディレクトリがない場合）
cat > "$INSTALL_DIR/share/CLAUDE_template.md" << 'EOF'
# 🤖 Multi-Claude システム設定

## システム概要

Multi-Claudeは、複数のClaude Codeインスタンスが協調して動作するマルチエージェント開発システムです。

### プロジェクト情報
- **起動日時**: [STARTUP_TIME]
- **プロジェクトパス**: [PROJECT_PATH]
- **環境変数**:
  - `MULTI_CLAUDE_GLOBAL`: [GLOBAL_PATH]
  - `MULTI_CLAUDE_LOCAL`: [LOCAL_PATH]

## Agent Communication System

### エージェント構成
- **PRESIDENT** (別セッション): 統括責任者 + タスク概要伝達
- **boss1** (multiagent:0.0): チームリーダー + 要件整理・指示書生成
- **worker1,2,3** (multiagent:0.1-3): 実行担当 + 進捗共有

### あなたの役割（動的版）

- **PRESIDENT**: @.multi-claude/instructions/president_dynamic.md
- **boss1**: @.multi-claude/instructions/boss_dynamic.md
- **worker1,2,3**: @.multi-claude/instructions/worker_dynamic.md

## メッセージ送信
```bash
$MULTI_CLAUDE_GLOBAL/bin/agent-send.sh [相手] "[メッセージ]"
# 注: MULTI_CLAUDE_GLOBAL は multi-claude 起動時に自動設定されます
```

## 新しい基本フロー
ユーザー → PRESIDENT（指示書生成） → boss1（指示書読み込み） → workers（指示書実行） → boss1 → PRESIDENT

## 動的指示書システム
- ユーザーの要求に応じてPRESIDENTが指示書を自動生成
- BOSSとWORKERは生成された指示書を読み込んで実行
- 柔軟でスケーラブルなタスク管理が可能
EOF
fi

log_success "✅ ファイルコピー完了"

# STEP 4: グローバルコマンド作成
log_info "🌐 グローバルコマンド作成中..."

# multi-claudeスクリプトに実行権限を付与
chmod +x "$INSTALL_DIR/multi-claude"

# STEP 5: ローカルbinディレクトリにリンク作成
log_info "🔗 ローカルコマンドリンク作成中..."

# ~/binディレクトリ作成
mkdir -p "$BIN_DIR"

# 既存のリンクを削除（存在する場合）
rm -f "$BIN_DIR/multi-claude"

# 新しいシンボリックリンクを作成
ln -s "$INSTALL_DIR/multi-claude" "$BIN_DIR/multi-claude"

log_success "✅ グローバルコマンド作成完了"

echo ""
echo "🎉 Multi-Claude システム ローカルインストール完了！"
echo "=============================================="
echo ""
echo "⚠️  環境設定の追加:"
echo ""
echo "1️⃣  PATH設定（必須）:"
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "   $BIN_DIR がPATHに含まれていません。"
    echo "   以下を ~/.zshrc または ~/.bashrc に追加してください："
    echo ""
    echo "   export PATH=\"\$HOME/bin:\$PATH\""
else
    echo "   ✅ PATH設定OK"
fi
echo ""
echo "2️⃣  便利な環境変数（オプション）:"
echo "   multi-claudeをより便利に使うため、以下も追加できます："
echo ""
echo "   # Multi-Claude 環境変数"
echo "   export MULTI_CLAUDE_GLOBAL=\"\$HOME/.multi-claude\""
echo ""
echo "3️⃣  エイリアス設定（オプション）:"
echo "   よく使うコマンドのエイリアスも設定できます："
echo ""
echo "   # Multi-Claude エイリアス"
echo "   alias mc='multi-claude'"
echo "   alias mc-exit='multi-claude --exit'"
echo "   alias mc-send='\$MULTI_CLAUDE_GLOBAL/bin/agent-send.sh'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "設定後は、ターミナルを再起動するか以下を実行してください："
echo "   source ~/.zshrc  # zshの場合"
echo "   source ~/.bashrc # bashの場合"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 使用方法:"
echo "  任意のディレクトリで以下を実行："
echo "    multi-claude                # 通常起動"
echo "    multi-claude --help         # ヘルプ表示"
echo "    multi-claude \"タスク内容\"    # 直接指示"
echo ""
echo "🔧 システム情報:"
echo "  インストール先: $INSTALL_DIR"
echo "  コマンドパス: $BIN_DIR/multi-claude"
echo ""
echo "🗑️  アンインストール:"
echo "  rm $BIN_DIR/multi-claude"
echo "  rm -rf $INSTALL_DIR"