# Microsoft 365 Copilot 企業向けセキュリティ設定ガイド

> **参考情報源：** Qiita（日本語技術ブログ）、Microsoft Learn 公式ドキュメント、EPC Group・CIAOPS・ShareGate などの英語技術ブログ（2025〜2026年版）  
> **最終更新：** 2026年5月  
> **対象読者：** IT管理者・セキュリティ担当者

---

## 目次

1. [概要・前提条件](#1-概要前提条件)
2. [ライセンスの確認と割り当て](#2-ライセンスの確認と割り当て)
3. [Microsoft Entra ID（旧 Azure AD）の設定](#3-microsoft-entra-id旧-azure-adの設定)
4. [条件付きアクセスポリシーの設定](#4-条件付きアクセスポリシーの設定)
5. [Microsoft Purview による情報保護](#5-microsoft-purview-による情報保護)
6. [SharePoint・OneDrive のアクセス権管理](#6-sharepointonedrive-のアクセス権管理)
7. [Microsoft 365 管理センターでの Copilot 設定](#7-microsoft-365-管理センターでの-copilot-設定)
8. [監査ログと監視の設定](#8-監査ログと監視の設定)
9. [Microsoft Intune によるデバイス管理](#9-microsoft-intune-によるデバイス管理)
10. [セキュリティチェックリスト（デプロイ前）](#10-セキュリティチェックリストデプロイ前)
11. [よくあるリスクと対策](#11-よくあるリスクと対策)
12. [参考リンク](#12-参考リンク)

---

## 1. 概要・前提条件

### 1.1 Microsoft 365 Copilot のセキュリティモデル

Microsoft 365 Copilot は、組織の **Microsoft 365 テナント境界内**でデータを処理します。主要なセキュリティ原則は以下のとおりです。

- プロンプトと応答は、Azure OpenAI Service（OpenAI の一般サービスではない）で処理され、LLM のトレーニングには使用されない
- ユーザーが既にアクセス権を持つデータのみ参照可能（既存のアクセス権を引き継ぐ）
- データの暗号化（転送中・保存中）
- GDPR、ISO 27001、HIPAA、ISO 42001 などのコンプライアンス認証に対応
- エンタープライズデータ保護（EDP）が自動適用（Microsoft Entra ID でサインインしたユーザー）

> **重要：** Copilot は既存のアクセス権設定を継承するため、**過剰共有（オーバーシェアリング）** が最大のリスクです。導入前にアクセス権の棚卸しが必須です。

### 1.2 前提ライセンス

| ライセンス | Copilot の種類 | 備考 |
|---|---|---|
| Microsoft 365 E3/E5、Business Premium 等 | Copilot Chat（無料付属） | 自動で含まれる |
| Microsoft 365 Copilot アドオン | Microsoft 365 Copilot（フル機能） | 有料アドオン |
| Microsoft 365 E5 / E7 | Security Copilot | 2025年11月〜自動プロビジョニング |

---

## 2. ライセンスの確認と割り当て

### 2.1 ライセンスの確認

```
Microsoft 365 管理センター → 課金 → ライセンス
```

確認ポイント：
- 組織が対象プラン（E3/E5/Business Premium 等）を保有しているか
- Microsoft 365 Copilot アドオンが購入済みか

### 2.2 ユーザーへのライセンス割り当て手順

```
1. https://admin.microsoft.com にサインイン（グローバル管理者または課金管理者）
2. 左メニュー → [ユーザー] → [アクティブなユーザー]
3. 対象ユーザーを選択 → [ライセンスとアプリ] タブ
4. [Microsoft 365 Copilot] にチェック → [変更の保存]
```

グループへの一括割り当て（推奨）：

```
1. 管理センター → [課金] → [ライセンス]
2. [Microsoft 365 Copilot] を選択 → [グループの割り当て]
3. 対象セキュリティグループを選択して割り当て
```

> **注意：** ライセンス割り当て後、各 Office アプリに Copilot が表示されるまで数時間かかる場合があります。ユーザーには再サインインを促してください。

### 2.3 フェーズ別ロールアウト（推奨）

```
フェーズ1: パイロット（〜50名）
  ├─ 早期採用者・IT部門・部門リーダーに限定
  └─ フィードバック収集・リスク評価

フェーズ2: 拡大展開（部門単位）
  ├─ パイロットの知見を反映
  └─ セキュリティ設定を確認してから展開

フェーズ3: 全社展開
  └─ 監査体制が整ってから実施
```

---

## 3. Microsoft Entra ID（旧 Azure AD）の設定

### 3.1 多要素認証（MFA）の強制

**前提：** Entra ID Premium P1 以上（Microsoft 365 E3/Business Premium に含まれる）

```
Microsoft Entra 管理センター（https://entra.microsoft.com）
→ [保護] → [条件付きアクセス] → [新しいポリシー]
```

設定内容：

```yaml
ポリシー名: [MFA強制] すべてのユーザー
割り当て:
  ユーザー: すべてのユーザー（管理者アカウントは別ポリシーで管理）
  クラウドアプリ: すべてのクラウドアプリ
アクセス制御:
  許可: アクセスを許可 → 多要素認証を要求 ✓
状態: オン
```

### 3.2 特権アクセス管理（PIM）の設定

Copilot 管理に必要な特権ロール（グローバル管理者など）は **JIT（Just-In-Time）アクセス** で管理します。

```
Entra 管理センター → [ID ガバナンス] → [Privileged Identity Management]
→ [Microsoft Entra ロール] → 対象ロールを選択 → [設定]
```

推奨設定：
- アクティブ割り当てを削除し、「適格」割り当てのみとする
- アクティベーション時に MFA と承認を要求
- アクティベーション最大期間：8時間以内

### 3.3 RBAC ロールの最小権限設定

Copilot 管理に必要なロール一覧：

| タスク | 必要な最小ロール |
|---|---|
| Copilot ライセンス管理 | ライセンス管理者 |
| Copilot アプリ設定 | Office Apps 管理者 |
| DLP ポリシー編集 | Purview Data Security AI Admin |
| 監査ログ閲覧 | コンプライアンス管理者 |
| Security Copilot 管理 | Security Copilot 所有者 |
| テナント全体の設定 | グローバル管理者（緊急時のみ使用） |

---

## 4. 条件付きアクセスポリシーの設定

### 4.1 Copilot 専用の条件付きアクセスポリシー

**目的：** 管理対象デバイスからのみ Copilot へのアクセスを許可する

```
Entra 管理センター → [保護] → [条件付きアクセス] → [新しいポリシー]
```

```yaml
ポリシー名: [Copilot] 管理対象デバイスのみ許可

割り当て:
  ユーザー: Copilot ライセンス保有グループ
  クラウドアプリ:
    - Microsoft 365 Copilot
    - Bing（Copilot Chat の Web 接地に使用）

条件:
  デバイスプラットフォーム: Windows, macOS, iOS, Android
  デバイスの状態: Intune 準拠デバイス または ハイブリッド Azure AD 参加済み

アクセス制御:
  許可: アクセスを許可
    ├─ 多要素認証を要求 ✓
    └─ デバイスは準拠としてマーク済みであることが必要 ✓
状態: オン
```

### 4.2 場所ベースのアクセス制限（オプション）

社外（特定 IP 以外）からのアクセスをブロックする場合：

```
Entra 管理センター → [保護] → [条件付きアクセス]
→ [ネームドロケーション] → [IP 範囲の場所] → 社内 IP を登録

ポリシーで条件に「場所」を追加:
  含める: 任意の場所
  除外: 社内IPアドレスの範囲（登録済み）

アクセス制御:
  ブロック ✓
```

---

## 5. Microsoft Purview による情報保護

### 5.1 秘密度ラベル（Sensitivity Labels）の作成と展開

**目的：** コンテンツを分類し、Copilot が参照・生成するデータを制限する

#### ステップ 1: ラベルの作成

```
Microsoft Purview ポータル（https://purview.microsoft.com）
→ [情報の保護] → [ラベル] → [ラベルの作成]
```

推奨ラベル体系：

```
公開（Public）
  └─ 社外公開可能なコンテンツ

内部限定（Internal）
  └─ 社内向け一般コンテンツ

社外秘（Confidential）
  ├─ アクセス制限あり
  └─ Copilot による要約・引用を制限可能

極秘（Highly Confidential）
  ├─ 強力な暗号化を適用
  └─ Copilot のアクセスを完全にブロック
```

#### ステップ 2: SharePoint・OneDrive でのラベル有効化（必須）

SharePoint/OneDrive 内の暗号化ファイルに Copilot がアクセスするには、この設定が必要です。

```powershell
# SharePoint Online 管理シェル or PowerShell で実行
Set-SPOTenant -EnableAIPIntegration $true
```

または：

```
SharePoint 管理センター → [設定] → [Microsoft Purview 情報保護]
→ [SharePoint と OneDrive でのラベル処理] → 有効化
```

#### ステップ 3: 自動ラベル付けポリシーの設定

```
Purview ポータル → [情報の保護] → [自動ラベル付け]
→ [ポリシーの作成]

設定例:
  名前: [自動] 個人情報の検出
  検出条件: 個人番号、マイナンバー、クレジットカード番号 等
  適用ラベル: 社外秘（Confidential）
  範囲: SharePoint Online サイト, OneDrive
```

### 5.2 データ損失防止（DLP）ポリシーの設定

**目的：** 機密情報が Copilot を通じて不適切に開示されることを防ぐ

> **2025年7月〜GA対応：** Microsoft Purview DLP の Copilot 向け機能が一般公開されました。秘密度ラベルを検出して Copilot のアクセスを制限できます。

#### DLP ポリシー作成手順

```
Purview ポータル → [データ損失防止] → [ポリシー] → [ポリシーの作成]
```

```yaml
ポリシー名: [Copilot DLP] 機密情報の保護

テンプレート: カスタム

場所（適用範囲）:
  - Exchange メール ✓
  - SharePoint サイト ✓
  - OneDrive アカウント ✓
  - Teams チャット・チャンネル ✓
  - Microsoft 365 Copilot ✓  ← 新設（2025年7月〜）

ルール:
  条件: コンテンツに次が含まれる
    - 秘密度ラベル: 極秘（Highly Confidential）
    OR
    - 機密情報の種類: マイナンバー、パスポート番号 等
  
  アクション:
    - Copilot での応答をブロック
    - ユーザーへの通知メッセージ表示
    - 管理者への警告アラート送信
  
  ポリシーのヒント: 有効 ✓
```

> **注意：** ポリシー作成には **Purview Data Security AI Admin** または **グローバル管理者** ロールが必要です。

#### DLP ポリシーのシミュレーション（テスト実行）

本番適用前に影響範囲を確認：

```
ポリシー作成の最後のステップで
→ [まずポリシーをテストする] を選択
→ Purview アクティビティエクスプローラーで影響を確認してから有効化
```

### 5.3 AI 向けデータセキュリティ態勢管理（DSPM for AI）

```
Purview ポータル → [AI ハブ] → [データセキュリティ態勢管理]
```

この機能でできること：
- Copilot のプロンプトと応答の監視
- 機密データのアクセス状況の可視化
- セキュリティ推奨事項の確認

---

## 6. SharePoint・OneDrive のアクセス権管理

### 6.1 過剰共有の調査と修正

**最重要事項：** Copilot はユーザーのアクセス権に基づいてデータを参照するため、過剰共有されたコンテンツはそのまま Copilot に参照されます。

#### SharePoint Advanced Management（SAM）の活用

```
SharePoint 管理センター（https://[テナント]-admin.sharepoint.com）
→ [レポート] → [データアクセスガバナンス]
```

確認事項：

```
- "全員" または "認証済みユーザー" への共有リンクが存在するサイト
- 外部共有が有効になっているサイト一覧
- 長期間アクセスのないゲストユーザー
- 過剰にアクセス権が付与されているサイト
```

アクセスレビューの実施：

```
SharePoint 管理センター → [ポリシー] → [アクセスレビュー]
→ 過剰共有サイトに対してアクセスレビューを開始
```

### 6.2 制限付き SharePoint 検索（RSS）の設定

**目的：** アクセス権の整備が完了していないサイトを一時的に Copilot の参照対象から除外する

```powershell
# SharePoint Online 管理シェルで実行
# 制限付き検索を有効化
Set-SPOTenantSearchSettings -DisablePersonalListExternalSharing $true

# または Purview でのポリシー設定経由
```

管理センター UI からの設定：

```
SharePoint 管理センター → [設定] → [制限付き SharePoint 検索]
→ 有効化 → 許可するサイトリストを登録
```

> **注意：** RSS は一時的な措置です。長期的にはアクセス権の適正化を進め、RSS を無効化することが推奨されます。

### 6.3 外部共有の制限設定

```
SharePoint 管理センター → [ポリシー] → [共有]

推奨設定（企業ポリシーに応じて選択）:
  組織レベル: [既存のゲストのみ] または [特定のドメインのみ]
  サイトレベル: 組織レベルと同じか、それより厳しい設定のみ可能

OneDrive の共有設定:
  → 組織の SharePoint 設定と同等またはそれ以下に設定
```

---

## 7. Microsoft 365 管理センターでの Copilot 設定

### 7.1 Copilot コントロールシステムへのアクセス

```
Microsoft 365 管理センター（https://admin.microsoft.com）
→ 左メニュー [Copilot] → [設定]
```

2025年7月より「Copilot コントロールシステム」が提供され、テナント全体の Copilot の利用状況・ポリシー・パフォーマンスを一元管理できます。

### 7.2 Copilot アプリのアクセス管理

特定のユーザー・グループのみに Copilot を限定する：

```
管理センター → [設定] → [統合アプリ]
→ [Microsoft 365 Copilot] アプリを選択
→ [組織全体に展開] または [特定のユーザー/グループ]
→ 対象グループを選択して [展開]
```

Copilot アプリを完全にブロックする（ライセンスなしユーザー向け）：

```
管理センター → [統合アプリ] → [Microsoft 365 Copilot]
→ [インストールできる組織] → [特定のユーザー/グループ]
→ Copilot ライセンスを持つユーザーのみのグループを選択
```

### 7.3 Web 検索（接地）の設定

Copilot が Bing を通じて Web 情報を参照する機能の管理：

```
管理センター → [Copilot] → [設定] → [データアクセス]
→ [Web コンテンツ] の有効/無効を切り替え
```

### 7.4 フィードバック設定の管理

ユーザーフィードバックの管理（LLM 訓練には使用されないが、組織ポリシーで管理可能）：

```
管理センター → [設定] → [組織設定] → [フィードバック]
→ フィードバックの許可・スクリーンショット送信の制御
```

---

## 8. 監査ログと監視の設定

### 8.1 Purview 監査ログの有効化

```
Purview ポータル → [監査] → [監査の開始]
（Microsoft 365 E3 以上ではデフォルト有効）
```

**Purview 監査 Premium** の有効化（E5 ライセンス推奨）：

```
保存期間: 標準 90日 → Premium で 1年間（拡張可能）
Copilot インタラクションイベントの記録
```

### 8.2 Copilot のインタラクションイベントの確認

```
Purview ポータル → [監査] → [監査検索]

フィルター設定:
  アクティビティ: "Copilot" または "AIInteraction" で検索
  期間: 任意
  ユーザー: 全ユーザー または 特定ユーザー

記録される情報:
  - プロンプトの内容（テキスト）
  - 参照されたファイル・メールの情報
  - 応答が生成された時刻・場所
  - DLP ポリシーへの違反
```

### 8.3 アラートポリシーの設定

異常なアクセスパターンを検知してアラートを発報：

```
Purview ポータル → [アラートポリシー] → [新しいアラートポリシー]

推奨アラート例:
  - 機密ラベル付きファイルへの大量アクセス
  - 同一ユーザーの大量プロンプト送信（一定時間内）
  - DLP ポリシー違反の発生
  - 管理者ロールの予期しない変更
```

### 8.4 Copilot 利用状況レポートの確認

```
管理センター → [レポート] → [使用状況]
→ [Microsoft 365 Copilot] を選択

確認できる情報:
  - アクティブユーザー数
  - アプリ別利用状況（Teams/Word/Excel 等）
  - 利用頻度トレンド
```

---

## 9. Microsoft Intune によるデバイス管理

### 9.1 コンプライアンスポリシーの作成

**目的：** Copilot へのアクセスを「準拠デバイス」のみに限定する

```
Intune 管理センター（https://intune.microsoft.com）
→ [デバイス] → [コンプライアンスポリシー] → [ポリシーの作成]

プラットフォーム別に設定（例：Windows 10/11）:
  ├─ BitLocker 有効 ✓
  ├─ セキュアブート有効 ✓
  ├─ Windows Defender リアルタイム保護 ✓
  ├─ 最小 OS バージョン: 指定
  └─ 簡単パスワードのブロック ✓
```

### 9.2 Copilot のエンドポイントポリシー設定

```
Intune 管理センター → [アプリ] → [アプリ構成ポリシー]

Copilot for Windows:
  - 承認済みプラグインのみ使用可能に制限
  - コンシューマー向けプラグインのブロック
  - エンタープライズログをクラウド Purview と統合
```

---

## 10. セキュリティチェックリスト（デプロイ前）

### 必須対応項目

```
[ ] 1. アクセス権の棚卸し（4〜8週間）
       └─ SharePoint・Teams・OneDrive・Exchange の過剰共有の解消

[ ] 2. 秘密度ラベルの展開
       └─ 全コンテンツへの自動ラベル付けポリシーの設定

[ ] 3. DLP ポリシーの設定
       └─ Exchange, SharePoint, Teams, Copilot の各ロケーションでの DLP 有効化

[ ] 4. 条件付きアクセスポリシーの設定
       └─ MFA 強制・管理対象デバイスのみ許可

[ ] 5. Purview 監査の有効化
       └─ Copilot インタラクションイベントのキャプチャ設定

[ ] 6. 制限付き SharePoint 検索（RSS）の暫定適用
       └─ アクセス権整備が完了するまでの過渡期措置

[ ] 7. Intune コンプライアンスポリシーの確認
       └─ デバイス準拠要件が Copilot アクセスに連動していること

[ ] 8. 管理者ロールの最小権限化
       └─ PIM（JIT アクセス）の設定
```

### 推奨対応項目

```
[ ] 9. SharePoint Advanced Management（SAM）の活用
       └─ アクセスレビュー・制限付きアクセス制御の設定

[ ] 10. eDiscovery の準備
        └─ Copilot のプロンプト・応答が調査対象となる場合の対応

[ ] 11. 情報バリア（Information Barriers）の設定
        └─ 規制業種向け：部門間の情報遮断

[ ] 12. DSPM for AI の有効化
        └─ AI に関するデータセキュリティ態勢の可視化

[ ] 13. Copilot Studio のデータポリシー設定
        └─ カスタムエージェントへのサードパーティ接続の制御
```

---

## 11. よくあるリスクと対策

### 11.1 過剰共有によるデータ漏洩

| リスク | 対策 |
|---|---|
| "Everyone" 共有ファイルが Copilot で参照される | SharePoint のアクセス権を見直し、RSS で一時制限 |
| 外部ゲストが組織内データを参照 | 条件付きアクセスでゲストアカウントを制限 |
| 機密ファイルがラベルなしで放置 | 自動ラベル付けポリシーで強制分類 |

### 11.2 プロンプトインジェクション攻撃

**概要：** 悪意のあるコンテンツ（メール・ドキュメント）がプロンプトに混入し、意図しない動作を引き起こす攻撃

**対策：**
- Copilot が参照するコンテンツのアクセス制御を徹底
- 外部メールの秘密度ラベルを適用
- Purview DLP で疑わしいコンテンツパターンをブロック

### 11.3 EchoLeak 脆弱性（CVE-2025-32711）への対応

2025年6月に報告されたゼロクリック脆弱性（Microsoft はパッチ適用済み）：

- Microsoft 365 Apps を最新バージョンに維持する
- セキュリティ更新プログラムの適用を Intune で強制する
- Microsoft Secure Score を定期的に確認し推奨事項を適用する

### 11.4 Shadow AI（シャドー AI）の利用

**リスク：** 未承認の AI ツールをユーザーが個人的に利用し、業務データを外部 AI へ入力する

**対策：**
- Microsoft Defender for Cloud Apps で未承認 SaaS の利用を検知・ブロック
- ユーザー教育とポリシーの明文化
- Intune App Protection Policy（MAM）でモバイルからの業務データコピーを制限

---

## 12. 参考リンク

### 日本語リソース

- [Copilotはセキュアなのか〜管理者・ユーザー目線でまとめてみた (Qiita)](https://qiita.com/sadabon444/items/9a2e5c163b46d81e1f62)
- [Microsoft Security Copilot とは？ (Qiita)](https://qiita.com/aktsmm/items/f13c9034e6e560e08b7c)
- [Microsoft 365 Copilot のデータ、プライバシー、セキュリティ (Microsoft Learn)](https://learn.microsoft.com/ja-jp/microsoft-365/copilot/microsoft-365-copilot-privacy)
- [Microsoft 365 Copilot の使用を開始 (Microsoft Learn)](https://learn.microsoft.com/ja-jp/copilot/microsoft-365/microsoft-365-copilot-setup)
- [Copilot シナリオの管理 (Microsoft Learn)](https://learn.microsoft.com/ja-jp/copilot/microsoft-365/microsoft-365-copilot-page)

### 英語リソース

- [Security for Microsoft 365 Copilot (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/security-microsoft-365-copilot)
- [Secure & Governed Data Foundation for Copilot (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/secure-govern-copilot-foundational-deployment-guidance)
- [Microsoft 365 Copilot Admin Guide for E3 + SAM (Microsoft Learn)](https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-e3-guide)
- [Learn about DLP to protect Copilot interactions (Microsoft Learn)](https://learn.microsoft.com/en-us/purview/dlp-microsoft365-copilot-location-learn-about)
- [Copilot Security – Risks, Controls & Best Practices (Opsin Security)](https://www.opsinsecurity.com/learn/copilot-security)
- [Microsoft 365 Copilot Security Guide (ShareGate)](https://sharegate.com/blog/copilot-security)
- [Microsoft 365 Copilot Enterprise Security in 2025 (DataStudios)](https://www.datastudios.org/post/microsoft-copilot-enterprise-security-configurations-and-best-practices-in-2025)

---

*本ドキュメントは 2026年5月時点の公開情報に基づいています。Microsoft のサービス仕様は予告なく変更される場合があります。最新情報は必ず公式ドキュメントをご確認ください。*
