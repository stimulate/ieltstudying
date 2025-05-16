# ✅ AWSで新しいリソースを作成する際のベストプラクティス（CloudFormation 編）

AWS において新しいリソースを作成する際、特に **CloudFormation** のような Infrastructure as Code（IaC）ツールを使用する場合には、**保守性・追跡性・安全性・コスト管理**を確保するためのベストプラクティスがあります。以下は CloudFormation を中心とした、CDK や Terraform でも活用可能な推奨事項です。

---

## 1. Change Set を強制的に確認する（No Execute ChangeSet）

- **目的**：リソース削除・再作成などの意図しない破壊的変更を未然に防止。
- **実践方法**：
  - `--no-execute-changeset` フラグで Change Set を作成。
  - 内容を確認してから `execute-change-set` を手動で実行。
- **ツール連携例**：
  - GitHub Actions + AWS CLI + Slack 通知などの CI/CD パイプラインに組み込む。

---

## 2. スタックとリソース命名規則の徹底

- スタック名・リソース名には以下を含める：
  - プロジェクト名（例：`myproj`）
  - 環境名（例：`dev`, `stg`, `prod`）
  - サービス用途（例：`api`, `db`, `vpc`）
  - 例：`myproj-prod-vpc-stack`
- CloudFormation テンプレート内にもタグ（`Tags`）として明示する。

---

## 3. リソース破壊を防ぐ保護設定

- `DeletionPolicy: Retain` の設定：
  - S3 バケット、RDS、EBS など重要リソースに設定し、スタック削除時にもリソースを保持。
- `StackTerminationProtection` の有効化：
  - スタック自体の誤削除を防止。

---

## 4. パラメータとマッピングを活用して再利用性を高める

- 再利用可能なテンプレート構築：
  - `Parameters` で環境ごとの違いを吸収。
  - `Mappings` でリージョンごとの AMI ID や値を分離。
- CDK 利用時は `context` や `env` による制御が効果的。

---

## 5. テンプレートのバージョン管理とレビュー体制

- CloudFormation テンプレート（YAML/JSON）を Git 管理。
- Pull Request ベースでレビュー。
- `cfn-lint`, `cfn-nag` などの静的解析を CI に組み込む。

---

## 6. CloudFormation Drift Detection を定期実行

- テンプレートとの差異（ドリフト）を検出。
- 手動変更や予期しない状態変化を可視化。
- 定期実行または EventBridge で自動トリガー。

---

## 7. コストを意識した設計

- 不要なリソースを最初から作らない設計に。
- テスト環境の EC2 や DB に停止スケジュールを設定（Lambda や Instance Scheduler）。
- S3 は Intelligent-Tiering をテンプレートに事前設定。

---

## 8. 例外処理・エラーハンドリング設計

- Lambda や Step Functions 使用時：
  - `Catch`, `Retry` を使って障害耐性を向上。
- `DependsOn` の乱用は避ける：並列処理性が落ちるため注意。

---

## 9. CloudFormation StackSet を活用して複数アカウント／リージョン展開

- AWS Organizations + StackSet を使い、組織全体への一括適用が可能。
- 手動ミス・設定のばらつきを回避。

---

## 10. 開発段階ではスタック名やテンプレートにバージョンや日付を含める

- 例：`myproj-dev-vpc-20240516`
- テンプレートの誤再利用を防止し、変更履歴も把握しやすくなる。
