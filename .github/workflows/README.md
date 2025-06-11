# GitHub Actions 設定手順

## Homebrew自動更新のセットアップ

このワークフローは、新しいタグがプッシュされたときに自動的にHomebrewのFormulaを更新します。

### 必要な設定

1. **Personal Access Token (PAT) の作成**
   - GitHubの Settings > Developer settings > Personal access tokens > Tokens (classic)
   - 「Generate new token」をクリック
   - 必要な権限:
     - `repo` (Full control of private repositories)
   - トークンをコピー

2. **リポジトリシークレットの設定**
   - Claude-Code-Communicationリポジトリの Settings > Secrets and variables > Actions
   - 「New repository secret」をクリック
   - Name: `HOMEBREW_GITHUB_TOKEN`
   - Value: 上記でコピーしたトークン

### 使い方

タグをプッシュすると自動的に実行されます：

```bash
git tag v1.0.6 -m "New release"
git push origin v1.0.6
```

### ワークフローの動作

1. 新しいタグ（v*）がプッシュされる
2. GitHub Actionsが起動
3. tarballのSHA256を計算
4. homebrew-multi-claudeリポジトリをチェックアウト
5. Formula/multi-claude.rbを更新
6. 変更をコミット・プッシュ

これで手動でのFormula更新が不要になります！