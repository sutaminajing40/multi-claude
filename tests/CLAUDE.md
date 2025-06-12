# 🤖 Multi-Claude システム設定

## Agent Communication System

### エージェント構成

- **PRESIDENT** (別セッション): 統括責任者 + 動的指示書生成
- **boss1** (multiagent:0.0): チームリーダー + 指示書読み込み
- **worker1,2,3** (multiagent:0.1-3): 実行担当 + 指示書実行

### あなたの役割（動的版）

- **PRESIDENT**: @instructions/president_dynamic.md
- **boss1**: @instructions/boss_dynamic.md
- **worker1,2,3**: @instructions/worker_dynamic.md

### メッセージ送信

```bash
./agent-send.sh [相手] "[メッセージ]"
```

### 新しい基本フロー

ユーザー → PRESIDENT（指示書生成） → boss1（指示書読み込み） → workers（指示書実行） → boss1 → PRESIDENT

### 動的指示書システム

- ユーザーの要求に応じて PRESIDENT が指示書を自動生成
- BOSS と WORKER は生成された指示書を読み込んで実行
- 柔軟でスケーラブルなタスク管理が可能

## 🚀 CI/CDシステム

### 自動リリースパイプライン

#### リリースフロー
```
1. git tag v1.0.X -m "Release message"
2. git push origin v1.0.X
3. GitHub Actions 自動実行
4. Homebrew Formula 自動更新
```

#### GitHub Actions ワークフロー

##### 1. update-homebrew.yml (自動実行)
- **トリガー**: タグプッシュ (v*)
- **処理**:
  1. tarball URL生成
  2. SHA256計算
  3. homebrew-multi-claude リポジトリへ自動更新
  4. 約15-18秒で完了

##### 2. update-homebrew-manual.yml (手動実行)
- **用途**: 特定バージョンの再配布
- **実行**: GitHub Actions画面から手動トリガー

### CI/CD設定要件

#### 必要なシークレット
- `HOMEBREW_GITHUB_TOKEN`: homebrew-multi-claudeリポジトリへのアクセス権限
  - 設定場所: Settings > Secrets and variables > Actions
  - 必要権限: `repo` (Full control)

### リポジトリ構成

```
Claude-Code-Communication/    # 開発リポジトリ
├── .github/workflows/       # CI/CD設定
├── multi-claude            # 実行ファイル
├── instructions/           # 動的指示書
└── CLAUDE.md              # プロジェクト設定

homebrew-multi-claude/      # 配布リポジトリ
├── Formula/               # Homebrew Formula
└── README.md             # インストール手順
```

### 開発ワークフロー

1. **機能開発**: feature/* ブランチで開発
2. **テスト**: ローカルで動作確認
3. **マージ**: mainブランチへマージ
4. **リリース**: タグ付けで自動配布

### バージョニング規則

- **v1.0.X**: パッチリリース（バグ修正）
- **v1.X.0**: マイナーリリース（機能追加）
- **vX.0.0**: メジャーリリース（破壊的変更）
