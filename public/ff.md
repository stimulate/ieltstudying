# AWS Well-Architected Framework を活用した低コスト構築ベストプラクティス

コストをできるだけ抑えながら、AWS Well-Architected Framework の6つの柱に沿った実践的なベストプラクティスを紹介します。特に Shield Advanced などの高額サービスを避けつつも、セキュリティや運用性を担保する方法を含みます。

---

## 🧱 命名規則とタグ管理（全体共通）

- **命名規則の統一**  
  例：`myapp-prod-tokyo-ec2-web` のように、プロジェクト名・環境・リージョン・用途を含めた統一的な命名ルールを適用。

- **タグの活用**  
  `Project`, `Environment`, `Owner` などのタグで分類・コスト集計を明確に。

---

## 🔐 セキュリティ（Security）

- **AWS Shield Standard の利用**  
  無料で DDoS 保護が可能。高額な Shield Advanced の代替手段。

- **セキュリティグループの最小化**  
  必要最小限のポートと IP 範囲のみ許可。

- **IAM の最小権限設定**  
  各ユーザーやサービスに必要最低限のポリシーだけを付与。

---

## ⚙️ 運用効率（Operational Excellence）

- **AWS Instance Scheduler の導入**  
  開発環境などの EC2/RDS を営業時間外に自動停止。コスト削減に有効。

- **AWS Config の活用**  
  リソース構成変更を監視し、自動的に是正。

---

## 💰 コスト最適化（Cost Optimization）

- **Savings Plans / RI の活用**  
  長期稼働リソースに予約型課金を適用し、最大72%コスト削減。

- **Cost Explorer の利用**  
  使用率の低いリソースの把握と停止・サイズ変更。

- **S3 Intelligent-Tiering の導入**  
  アクセス頻度に応じて自動でストレージクラスを変更し、最大40%節約。

---

## ⚡ パフォーマンス効率（Performance Efficiency）

- **最適なインスタンスタイプの選定**  
  ワークロードに合わせた選定でコスパ最大化。

- **Auto Scaling の活用**  
  リソースを動的に増減し、無駄なリソースを排除。

---

## 🔄 信頼性（Reliability）

- **マルチAZ構成**  
  複数 AZ に配置して障害に強い設計を実現。

- **定期的なバックアップとリカバリーテスト**  
  バックアップの実施と復元手順の検証は必須。

---

## 🌿 サステナビリティ（Sustainability）

- **リソースの最適化**  
  無駄のない構成でエネルギー効率とコストを両立。

- **サーバーレスの活用**  
  AWS Lambda や Fargate により、スケーラブルかつ効率的なシステムを構築。

---

## 参考リンク

- [AWS Well-Architected Framework ホワイトペーパー（日本語）](https://docs.aws.amazon.com/ja_jp/wellarchitected/latest/framework/wellarchitected-framework.pdf)
- [AWSコスト最適化ガイド](https://aws.amazon.com/jp/blogs/news/9ways-to-optimize-aws-cost/)
- [AWS公式 Cost Optimization ホワイトペーパー](https://docs.aws.amazon.com/ja_jp/whitepapers/latest/how-aws-pricing-works/aws-cost-optimization.html)
