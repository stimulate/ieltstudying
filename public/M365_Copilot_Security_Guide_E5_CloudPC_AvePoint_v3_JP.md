# Microsoft 365 Copilot 企業向けセキュリティ設定ガイド
## 【E5 + Windows 365 Cloud PC + AvePoint 環境版】

> **参考情報源：** Microsoft Learn 公式ドキュメント、Microsoft Security Blog (Ignite 2025)、wolkenman.nl・stealthpuppy・SoftwareOne・AvePoint 技術ブログ、MSEndpointMgr など  
> **最終更新：** 2026年5月  
> **対象読者：** IT管理者・セキュリティ担当者  

---

## 💰 コスト凡例（本書全体で使用）

> 本書では、コスト発生の有無を以下のアイコンで明示しています。

| アイコン | 意味 |
|---|---|
| ✅ **E5 付属** | Microsoft 365 E5 ライセンスに含まれるため追加費用なし |
| 💰 **有料アドオン** | E5 に含まれず、別途購入が必要な固定費 |
| 💸 **従量課金** | 使用量に応じて変動するコスト（Azure 従量課金など） |
| 🔶 **条件付き有料** | 特定の条件・プランでのみ追加コストが発生 |

---

## 本書について

### 本ガイドの前提となる環境

| 項目 | 内容 |
|---|---|
| **ライセンス** | Microsoft 365 E5 |
| **エンドポイント** | シンクライアント PC（Windows App でリモート接続） |
| **仮想デスクトップ** | Windows 365 Cloud PC（Windows 11） |
| **主要アプリ** | Word / Excel / PowerPoint / OneDrive / Power BI / Power Automate / Teams / Outlook |
| **バックアップ** | AvePoint Confidence Platform |

### E5 ライセンスで利用可能な主要機能（Copilot 関連）

| 機能 | コスト区分 | 補足 |
|---|---|---|
| Microsoft 365 Copilot | 💰 **有料アドオン** $30/user/月 | E5 に自動含まれない。最重要費用 |
| Security Copilot | ✅ **E5 付属**（2025年11月〜段階的ロールアウト） | 400 SCU/月 × 1,000ユーザー |
| Microsoft Entra ID P2 | ✅ **E5 付属** | PIM・リスクベース条件付きアクセス |
| Microsoft Purview（高度機能） | ✅ **E5 付属** | 監査Premium・eDiscovery Premium |
| Microsoft Defender XDR | ✅ **E5 付属** | Copilot 連携でインシデント調査 |
| Microsoft Intune Suite | ✅ **E5 付属** | Cloud PC の管理基盤 |
| Windows 365 Cloud PC | 💰 **別途購入** | E5 とは別にプラン別購入が必要 |

> **E5 の活用ポイント：** Security Copilot（2025年11月〜）が E5 に含まれるため、追加コストなしで Defender・Entra・Intune・Purview 全体を AI で管理できます。現時点（2026年5月）でロールアウト中のため、Microsoft からの通知（7〜30日前）を確認してください。

---

## 目次

1. [環境アーキテクチャと Copilot データフロー](#1-環境アーキテクチャと-copilot-データフロー)
2. [ライセンス設計と割り当て戦略](#2-ライセンス設計と割り当て戦略)
3. [Microsoft Entra ID P2 の設定（E5 フル活用）](#3-microsoft-entra-id-p2-の設定e5-フル活用)
4. [Windows 365 Cloud PC 専用の条件付きアクセス設定](#4-windows-365-cloud-pc-専用の条件付きアクセス設定)
5. [Copilot 専用の条件付きアクセスポリシー](#5-copilot-専用の条件付きアクセスポリシー)
6. [Microsoft Purview E5 による情報保護](#6-microsoft-purview-e5-による情報保護)
7. [SharePoint・OneDrive・Teams のアクセス権管理](#7-sharepointonedriveteams-のアクセス権管理)
8. [アプリ別 Copilot 設定（Power BI・Power Automate 含む）](#8-アプリ別-copilot-設定power-bipower-automate-含む)
9. [Microsoft 365 管理センターでの Copilot 設定](#9-microsoft-365-管理センターでの-copilot-設定)
10. [Security Copilot の有効化と活用（E5 付属）](#10-security-copilot-の有効化と活用e5-付属)
11. [Intune による Windows 365 Cloud PC の管理](#11-intune-による-windows-365-cloud-pc-の管理)
12. [AvePoint との連携とバックアップ戦略](#12-avepoint-との連携とバックアップ戦略)
13. [監査・監視・アラート設定](#13-監査監視アラート設定)
14. [ネットワーク要件（Cloud PC 環境）](#14-ネットワーク要件cloud-pc-環境)
15. [デプロイ前チェックリスト（E5 + Cloud PC 環境用）](#15-デプロイ前チェックリストe5--cloud-pc-環境用)
16. [よくあるリスクと対策](#16-よくあるリスクと対策)
17. [💰 コスト詳細・料金一覧と公式参照リンク](#17--コスト詳細料金一覧と公式参照リンク)

---

## 1. 環境アーキテクチャと Copilot データフロー

### 1.1 本環境の構成図（概念）

```
[シンクライアント]
      |
      | Windows App（RDP/RDP Shortpath）
      |
[Windows 365 Cloud PC]  ← Microsoft Azure 上の仮想マシン（Windows 11）
      |
      | Microsoft Graph / Microsoft 365 テナント境界内
      |
[Microsoft 365 Copilot]
      ├─ Word / Excel / PowerPoint
      ├─ Teams / Outlook
      ├─ OneDrive / SharePoint
      ├─ Power BI / Power Automate
      └─ Copilot Chat
```

### 1.2 本環境でのセキュリティ上の重要ポイント

1. **シンクライアント = 非管理デバイス** → Intune の管理対象は Cloud PC（仮想マシン）であり、シンクライアント本体ではない
2. **Cloud PC は Entra ID 参加済み** → 条件付きアクセスの「準拠デバイス」として扱われる
3. **データは Cloud PC と Microsoft 365 テナント境界内に留まる** → シンクライアントにデータを送信しない設計が基本
4. **AvePoint** はテナント内データのバックアップ・ガバナンスを担い、Copilot 展開前の過剰共有対策にも活用可能

---

## 2. ライセンス設計と割り当て戦略

### 2.1 必要なライセンス構成

```
全ユーザー共通:
  Microsoft 365 E5（基盤）✅ E5 付属
    ├─ Entra ID P2（PIM・リスクベース CA）
    ├─ Intune（Cloud PC 管理）
    ├─ Purview E5（高度な情報保護）
    ├─ Defender XDR（脅威保護）
    └─ Security Copilot（2025年11月〜 E5 付属）

Copilot 利用ユーザー（要アドオン）:
  💰 Microsoft 365 Copilot アドオン（$30/user/月）
    └─ E5 サブスクリプションへの追加購入が必要

仮想デスクトップ:
  💰 Windows 365 Enterprise または Business（E5 とは別途購入）
    └─ Cloud PC のサイズ・スペックに応じてプランを選択
```

### 2.2 グループベースのライセンス管理

```
管理センター → [グループ] → [ライセンスの割り当て]
  または
Entra 管理センター → [グループ] → 対象グループ → [ライセンス]
```

推奨グループ構成：

```yaml
グループ名: GRP-Copilot-Pilot（パイロット段階）
  ライセンス: M365 E5 + 💰 M365 Copilot アドオン
  メンバー: 先行ユーザー 30〜50名
  💡 コスト最適化: パイロット段階では最小限の人数に絞り、ROI を確認してから拡大する

グループ名: GRP-Copilot-全社（展開段階）
  ライセンス: M365 E5 + 💰 M365 Copilot アドオン
  メンバー: 全 Copilot 利用対象者

グループ名: GRP-E5-BaseOnly（Copilot 未割当）
  ライセンス: M365 E5 のみ（Copilot アドオンなし）
  メンバー: Copilot アドオン未付与のユーザー
  💡 Copilot Chat（Web グラウンディングのみ）は E5 ユーザーに無料で提供
```

---

## 3. Microsoft Entra ID P2 の設定（E5 フル活用）

> ✅ このセクションの機能はすべて **E5 付属**（Entra ID P2 を含む）のため、追加費用は発生しません。

### 3.1 多要素認証（MFA）の強制

```
Entra 管理センター（https://entra.microsoft.com）
→ [保護] → [条件付きアクセス] → [新しいポリシー]
```

```yaml
ポリシー名: CA001 - 全ユーザー MFA 強制
ユーザー: 全ユーザー（ブレークグラスアカウントは除外）
アプリ: すべてのクラウドアプリ
アクセス制御:
  許可: 多要素認証を要求 ✓
  認証の強度: フィッシング耐性のある MFA（推奨）
    └─ Windows Hello for Business または FIDO2 キー
状態: オン
```

### 3.2 PIM（特権 ID 管理）の設定（✅ Entra ID P2 機能）

```
Entra 管理センター → [ID ガバナンス] → [Privileged Identity Management]
→ [Microsoft Entra ロール]
```

JIT アクセスの設定（全管理者ロールに適用）：

```yaml
対象ロール（例）:
  - グローバル管理者
  - Exchange 管理者
  - SharePoint 管理者
  - Copilot 管理者（AI 管理者ロール）

設定:
  割り当てタイプ: 適格（Eligible）のみ
  アクティベーション要件:
    - MFA ✓
    - 承認要求（2名の承認者を設定）✓
    - 正当な理由の入力 ✓
  最大アクティベーション期間: 8時間
```

### 3.3 リスクベースの条件付きアクセス（✅ Entra ID P2 専用機能）

```yaml
ポリシー名: CA002 - 高リスクユーザーのアクセスブロック
ユーザー: 全ユーザー
アプリ: すべてのクラウドアプリ
条件:
  ユーザーリスク: 高
アクセス制御:
  ブロック ✓

---

ポリシー名: CA003 - サインインリスク時の MFA 再要求
ユーザー: 全ユーザー
アプリ: すべてのクラウドアプリ
条件:
  サインインリスク: 中・高
アクセス制御:
  許可: MFA を要求 + 準拠デバイスを要求 ✓
```

### 3.4 Security Copilot の CA 最適化エージェント（✅ E5 付属）

```
Entra 管理センター → [保護] → [条件付きアクセス]
→ [Optimization Agent] タブ → [エージェントを開始]
```

このエージェントでできること：
- MFA が適用されていないユーザーの自動検出と修正提案
- 古いポリシーや重複ポリシーの整理
- デバイスコンプライアンス要件の未適用ギャップの検出
- レガシー認証プロトコルのブロック推奨

---

## 4. Windows 365 Cloud PC 専用の条件付きアクセス設定

> ✅ このセクションの条件付きアクセス機能は **E5 付属**（Entra ID P2 を含む）のため、追加費用は発生しません。  
> 💰 Windows 365 Cloud PC 自体のライセンスは別途購入が必要です（→ 第17章 参照）。

### 4.1 Windows 365 関連アプリ ID の登録

| アプリ名 | アプリ ID | 用途 |
|---|---|---|
| Windows 365 | `0af06dc6-e4b5-4f28-818e-e78e62d137a5` | Cloud PC リソース一覧取得・操作 |
| Azure Virtual Desktop | `9cdead84-a844-4324-93f2-b2e6bb768d07` | Azure VD ゲートウェイ接続認証 |
| Windows Cloud Login | `270efc09-cd0d-444b-a71f-39af4910ec45` | SSO 有効時の Cloud PC 認証 |

> **注意：** 3つのアプリすべてに対して CA ポリシーを**一致**させることが推奨されます。

### 4.2 シンクライアントからの Cloud PC 専用アクセスポリシー

**目的：** Office 365 へのアクセスを Cloud PC 経由のみに限定する

```yaml
ポリシー名: CA010 - Office365 は Cloud PC のみ許可
対象ユーザー: GRP-CloudPC-Users（全 Cloud PC ユーザー）
対象アプリ:
  含める: Office 365
  除外する: Azure Virtual Desktop、Windows 365（Cloud PC 経由は除外）
デバイスフィルター（条件）:
  フィルター: 除外（exclude filtered devices）
  プロパティ: Model
  演算子: 次の値で始まる（Starts with）
  値: Cloud PC
アクセス制御: ブロック
状態: オン（事前に "What if" ツールで影響確認必須）
```

### 4.3 Cloud PC への強力な認証要求ポリシー

```yaml
ポリシー名: CA011 - Cloud PC への強力な MFA 要求
対象ユーザー: 全ユーザー（ブレークグラス除外）
対象アプリ（すべて選択）:
  - Windows 365
  - Azure Virtual Desktop
  - Windows Cloud Login
ネットワーク: 任意の場所（場所に関わらず強制）
アクセス制御:
  許可: フィッシング耐性 MFA を要求 ✓
セッションコントロール（高セキュリティ環境向け オプション）:
  トークン保護（Token Protection）: 有効 ✓
状態: オン
```

### 4.4 Cloud PC デバイスのコンプライアンスポリシー設定

```
Intune 管理センター → [デバイス] → [コンプライアンスポリシー] → [ポリシーの作成]
プラットフォーム: Windows 10 and later
```

```yaml
設定内容（推奨）:
  デバイスの正常性:
    - Secure Boot を有効にする ✓
    - コードの整合性 ✓
  システムセキュリティ:
    - デバイスにパスワードを要求する ✓
    - Windows Defender リアルタイム保護 ✓
  Microsoft Defender for Endpoint:
    - デバイスのリスクスコア: 「クリア」のみ許可（✅ E5 で利用可能）
```

---

## 5. Copilot 専用の条件付きアクセスポリシー

> ✅ 条件付きアクセス機能自体は **E5 付属**です。  
> 💰 ただし、このポリシーが保護する **M365 Copilot アドオン**は別途有料です。

### 5.1 Microsoft 365 Copilot を CA の対象として登録

```powershell
# PowerShell で Microsoft Graph に接続して登録
Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Microsoft 365 Copilot の Service Principal を作成
New-MgServicePrincipal -AppId "fb8d773d-7ef8-4ec0-a117-179f88add510"

# Security Copilot も同様に登録
New-MgServicePrincipal -AppId "bb5ffd56-39eb-458c-a53a-775ba21277da"
```

### 5.2 Copilot へのアクセスを Cloud PC 準拠デバイスのみに制限

```yaml
ポリシー名: CA108 - Copilot は準拠 Cloud PC のみ許可
対象ユーザー: GRP-Copilot-全社
対象アプリ:
  - Enterprise Copilot Platform（Microsoft 365 Copilot）
  - Security Copilot（✅ E5 付属）
アクセス制御:
  許可:
    - MFA を要求 ✓
    - 準拠デバイスを要求 ✓
状態: オン
```

---

## 6. Microsoft Purview E5 による情報保護

> ✅ このセクションの Purview 高度機能はすべて **E5 付属**のため、追加費用は発生しません。

### 6.1 E5 で利用可能な高度な Purview 機能

| 機能 | E3 | E5（✅ 付属） |
|---|---|---|
| 基本秘密度ラベル | ✓ | ✓ |
| 自動ラベル付け（クライアント側） | ✓ | ✓ |
| 自動ラベル付け（サービス側・大規模） | — | ✅ |
| 監査 Premium（1年保存） | — | ✅ |
| eDiscovery Premium | — | ✅ |
| Insider Risk Management | — | ✅ |
| Communication Compliance | — | ✅ |
| DSPM for AI | — | ✅ |
| Adaptive Protection | — | ✅ |

### 6.2 秘密度ラベルの作成（Power BI・Power Automate 対応版）

```
Purview ポータル（https://purview.microsoft.com）
→ [情報の保護] → [ラベル] → [ラベルの作成]
```

推奨ラベル体系：

```
公開（Public）
  └─ スコープ: ファイル・メール・Power BI レポート

内部限定（Internal Only）
  └─ スコープ: ファイル・メール・Teams・SharePoint サイト・Power BI

社外秘（Confidential）
  ├─ 暗号化: 組織内ユーザーのみアクセス可能
  └─ スコープ: ファイル・メール・会議・グループ・Power BI

極秘（Highly Confidential）
  ├─ 暗号化: 特定ユーザー/グループのみ（アクセス権を明示指定）
  └─ Copilot による参照: DLP ポリシーでブロック対象
```

**Power BI でのラベル有効化：**

```
Power BI 管理ポータル → [テナント設定]
→ [情報の保護] → [秘密度ラベルを適用] → 有効 ✓
```

### 6.3 サービス側自動ラベル付け（✅ E5 専用・大規模適用）

```
Purview ポータル → [情報の保護] → [自動ラベル付け]
→ [ポリシーの作成]

設定:
  ラベル: 社外秘（Confidential）
  検出対象:
    - 個人番号（マイナンバー）
    - 金融口座情報
    - 医療情報
    - パスポート番号
    - 人事情報（給与・評価）
  適用範囲:
    - Exchange Online（メール・送受信）
    - SharePoint Online（全サイト）
    - OneDrive for Business（全ユーザー）
  モード: 最初はシミュレーション実行 → 影響確認後に強制適用
```

### 6.4 DLP ポリシーの設定（Copilot・Teams・Power BI 対応）

> ✅ DLP ポリシー（Copilot 向け含む）は **E5 付属** Purview 機能のため追加費用なし。

```yaml
ポリシー名: DLP001 - Copilot 向け機密情報保護

場所（ロケーション）:
  - Exchange メール ✓
  - SharePoint サイト ✓
  - OneDrive アカウント ✓
  - Teams チャット・チャンネル ✓
  - Microsoft 365 Copilot ✓
  - Power BI ワークスペース ✓

ルール1: 極秘コンテンツの完全ブロック
  条件: 秘密度ラベル = 極秘（Highly Confidential）
  アクション: Copilot での応答をブロック
  管理者アラート: あり

ルール2: 社外秘コンテンツの警告
  条件: 秘密度ラベル = 社外秘（Confidential）
  アクション: ポリシーヒント（警告）を表示
  上書き許可: 正当な理由の入力で許可 ✓
```

### 6.5 Insider Risk Management の設定（✅ E5 専用）

```
Purview ポータル → [Insider Risk Management] → [ポリシー]
→ [ポリシーの作成]

テンプレート: データ漏洩（Data leaks）
  ├─ 機密コンテンツの大量ダウンロード
  ├─ 機密ファイルの外部共有
  └─ Cloud PC セッション終了前の大量コピー操作
```

---

## 7. SharePoint・OneDrive・Teams のアクセス権管理

> ✅ SharePoint Advanced Management（SAM）は **M365 Copilot ライセンスに付属**。  
> ✅ SharePoint/OneDrive/Teams の基本管理機能は **E5 付属**。  
> 💰 AvePoint は別途サードパーティ製品のコスト（→ 第17章 参照）。

### 7.1 AvePoint を活用した過剰共有の事前調査

```
AvePoint 管理ポータル → [Insights] → [アクセス権レポート]

確認項目:
  □ "全員"・"認証済みユーザー" への共有が存在するサイト一覧
  □ ゲストユーザーが多数存在するサイト
  □ 長期間アクセスのない外部共有リンク
  □ オーナー不在の孤立サイト（Inactive Sites）
  □ 部門をまたいだ過剰な権限設定
```

### 7.2 SharePoint 外部共有の制限設定

```
SharePoint 管理センター → [ポリシー] → [共有]

テナント全体の設定:
  外部共有: [既存のゲストのみ] または [特定のドメインのみ]
  ゲストアクセスの有効期限: 90日（自動失効）
  リンクの既定: [特定のユーザー]（"Anyone" リンク禁止）
```

### 7.3 制限付き SharePoint 検索（RSS）の暫定適用

```powershell
# SharePoint Online Management Shell
Set-SPOTenantSearchSettings -DisablePersonalListExternalSharing $true
```

```
SharePoint 管理センター → [設定] → [制限付き SharePoint 検索]
→ 有効化 → 許可するサイトリストを明示的に登録
```

### 7.4 Teams での Copilot 設定

```
Teams 管理センター（https://admin.teams.microsoft.com）
→ [Copilot の設定]

会議での Copilot:
  - 文字起こし中のみ Copilot を有効化（推奨）

Teams チャットでの Copilot:
  - DLP ポリシーと連動（上記 DLP001 ポリシーを適用）
```

---

## 8. アプリ別 Copilot 設定（Power BI・Power Automate 含む）

### 8.1 Microsoft 365 Apps（Word・Excel・PowerPoint・Outlook）

> ✅ M365 Apps 自体は **E5 付属**。  
> 💰 Copilot 機能の利用には **M365 Copilot アドオン**（$30/user/月）が必要。

**更新チャンネルの確認（Cloud PC に適用）：**

```
Intune 管理センター → [アプリ] → [Office アプリ展開]
→ 更新チャンネルを確認

Copilot 対応に必要なチャンネル:
  Current Channel（最新機能が最速で届く）← 推奨
  Monthly Enterprise Channel（毎月第2火曜に更新）
```

### 8.2 Power BI での Copilot 設定

> 🔶 **Power BI Copilot は追加ライセンスが必要な場合あり**

```
Power BI 管理ポータル（https://app.powerbi.com → [管理]）
→ [テナント設定]

[Copilot と Azure OpenAI Integration]:
  "Copilot とその他の Azure OpenAI Integration を有効にする"
  → 特定のグループのみ有効化（推奨）
```

| Power BI ライセンス | Copilot 機能 | コスト |
|---|---|---|
| Power BI Pro（✅ E5 付属） | Copilot **利用不可** | 追加費用なし |
| 🔶 Power BI Premium Per User（PPU） | Copilot **利用可能** | $20/user/月（追加） |
| 🔶 Microsoft Fabric 容量（F64以上） | Copilot **利用可能** | $5,068.80/月〜（追加） |

> **注意：** E5 に含まれる Power BI Pro では Power BI Copilot は利用できません。Copilot 機能を Power BI で使うには PPU または Fabric 容量が別途必要です。ROI に応じて要否を検討してください。

**Power BI の行レベルセキュリティ（RLS）の確認：**

```
Power BI Desktop → [モデリング] → [ロールの管理]
→ 機密データを含むレポートに RLS が設定されていることを確認
（人事データ、財務データ、経営情報など）
```

### 8.3 Power Automate での Copilot・AI 機能設定

> ✅ Power Automate の基本機能は **E5 付属**。  
> 🔶 **プレミアムコネクタ・AI Builder を使用する場合は別途課金あり**（→ 第17章 参照）。

```
Power Platform 管理センター（https://admin.powerplatform.microsoft.com）
→ [環境] → 対象環境を選択 → [設定]
```

**Power Automate の DLP ポリシー設定（重要・✅ 無料）：**

```yaml
ポリシー名: [Copilot] Power Automate コネクタ制限

ビジネスデータのみ許可コネクタ（許可リスト）:
  - SharePoint ✅ 標準コネクタ（無料）
  - Exchange（Outlook）✅ 標準コネクタ（無料）
  - Teams ✅ 標準コネクタ（無料）
  - OneDrive for Business ✅ 標準コネクタ（無料）
  - Power BI ✅ 標準コネクタ（無料）
  - Dataverse ✅ 標準コネクタ（無料）

ブロックコネクタ:
  - 個人用 OneDrive
  - Google サービス
  - 承認されていないサードパーティサービス

🔶 プレミアムコネクタ（SAP、Salesforce、ServiceNow 等）:
  → 使用する場合は Power Automate Premium ライセンスが別途必要
```

---

## 9. Microsoft 365 管理センターでの Copilot 設定

> ✅ 管理センターのコントロール設定自体は **E5 付属**。  
> 💰 Copilot アドオンを購入したユーザーに対してのみ各設定が適用される。

### 9.1 Copilot コントロールシステム

```
Microsoft 365 管理センター（https://admin.microsoft.com）
→ 左メニュー [Copilot] → [コントロールシステム]
```

主な管理項目：

```
データアクセスの管理:
  □ Web コンテンツ（Bing 接地）の有効/無効
  □ Microsoft Graph コネクタデータへのアクセス許可
  □ エージェントのデータアクセス範囲

Copilot アクションの管理:
  □ Copilot が実行できるアクション（ファイル作成・メール送信等）の制御
  □ 💸 Copilot Studio エージェントの公開承認フロー（エージェント使用量に応じた従量課金の可能性あり）

監視・レポート:
  □ テナント全体の Copilot 利用状況（✅ 無料）
  □ DLP 違反・ポリシー逸脱の検知状況
```

### 9.2 Copilot アプリのアクセス管理（グループ限定展開）

```
管理センター → [設定] → [統合アプリ]
→ [Microsoft 365 Copilot] → 展開設定

設定方法（段階的展開）:
  1. パイロット段階: GRP-Copilot-Pilot グループのみ（💰 Copilot ライセンス分のみ課金）
  2. 部門展開: 部門グループに順次追加
  3. 全社展開: 全ユーザーへ
```

---

## 10. Security Copilot の有効化と活用（E5 付属）

> ✅ **Security Copilot は E5 に自動付属**（2025年11月〜段階的ロールアウト）。  
> 基本割り当て：400 SCU/月 × 1,000 E5 ユーザー分が自動プロビジョニング。  
> 💸 割り当て SCU を超過する高負荷利用（大規模インシデント対応など）は別途従量課金の可能性あり。

### 10.1 テナントへの Security Copilot プロビジョニング確認

```
セキュリティ管理センター（https://security.microsoft.com）
→ [Security Copilot] を確認

E5 自動プロビジョニングの確認:
  - Microsoft から事前通知（7〜30日前）が届いているか確認
  - 通知後、追加設定不要で自動有効化される
  - 割り当て: 400 SCU/月 × 1,000 E5 ユーザー数（上限 10,000 SCU/月）
  - SCU は毎月リセット（翌月繰り越しなし）
```

### 10.2 Security Copilot の RBAC 設定

```
Security Copilot ポータル（https://securitycopilot.microsoft.com）
→ [設定] → [ロールの割り当て]

ロール割り当て:
  Security Copilot 所有者:
    → IT セキュリティ管理者のみ（プラグイン設定・ロール管理が可能）

  Security Copilot 共同作成者:
    → SOC アナリスト・Copilot 利用管理者
```

### 10.3 E5 で活用できる Security Copilot エージェント

| エージェント | 機能 | コスト |
|---|---|---|
| Phishing Triage Agent | フィッシングアラートの自動判定 | ✅ E5 付属 SCU 内 |
| Conditional Access Optimization Agent | CA ポリシーのギャップ自動検出 | ✅ E5 付属 SCU 内 |
| Threat Intelligence Briefing Agent | 脅威インテリジェンスのレポート自動生成 | ✅ E5 付属 SCU 内 |
| Data Security Triage Agent | DLP・Insider Risk アラートの優先順位付け | ✅ E5 付属 SCU 内 |
| Risky User Agent | リスクの高いユーザーの自動特定 | ✅ E5 付属 SCU 内 |

> ⚠️ SCU 消費量は Security Copilot ダッシュボードで月次監視し、E5 付属 SCU 上限（10,000 SCU/月）の超過に注意してください。超過分は別途従量課金（💸）となります。

---

## 11. Intune による Windows 365 Cloud PC の管理

> ✅ Intune の管理機能自体は **E5 付属**。  
> 💰 Windows 365 Cloud PC のライセンス（コンピュート・ストレージ）は別途購入が必要。

### 11.1 Cloud PC のプロビジョニングポリシー設定

```
Intune 管理センター → [デバイス] → [Windows 365]
→ [プロビジョニングポリシー] → [作成]

設定項目:
  ドメイン参加: Microsoft Entra ID 参加（推奨）
  ネットワーク: Microsoft ホスト型ネットワーク または オンプレミス接続
  イメージ: ギャラリーイメージ（Windows 11 Enterprise + M365 Apps）
  言語: 日本語（ja-JP）
  シングルサインオン（SSO）: 有効化 ✓
```

### 11.2 Cloud PC 向けの構成プロファイル（Copilot 最適化）

```yaml
プロファイル名: CloudPC-CopilotReady

Microsoft 365 Apps の設定:
  更新チャンネル: Current Channel
  
OneDrive:
  OneDrive の Known Folder Move: 有効（デスクトップ・ドキュメント・ピクチャを OneDrive に移動）

Microsoft Edge:
  サードパーティ Cookie: 特定ドメインのみ許可（*.cloud.microsoft, *.office.com）

Loop:
  Microsoft Loop ワークスペースを許可 ✓
```

### 11.3 Cloud PC の Copilot 利用状況モニタリング（✅ Security Copilot 連携）

```
Intune 管理センター → [トラブルシューティング + サポート]
→ [Security Copilot（プレビュー）]

活用例:
  - Cloud PC の接続品質の問題を自然言語で問い合わせ
  - ライセンス最適化の提案（未使用 Cloud PC の検出）
  - コンプライアンス非準拠デバイスの一括確認
```

---

## 12. AvePoint との連携とバックアップ戦略

> 💰 **AvePoint Confidence Platform はサードパーティ製品**のため、別途ライセンス費用が発生します。  
> ✅ Microsoft 365 ネイティブのバックアップ（Microsoft 365 Backup）は別サービスとして提供（→ 第17章 参照）。

### 12.1 AvePoint Cloud Backup と Copilot データの保護

| AvePoint 機能 | Copilot 展開での役割 | コスト区分 |
|---|---|---|
| Cloud Backup（M365） | SharePoint・OneDrive・Teams・Outlook のバックアップ | 💰 AvePoint 契約費用 |
| Cloud Backup（Copilot エージェントファイル） | Copilot Studio エージェントのファイル回復（2025年8月〜） | 💰 AvePoint 契約費用 |
| Insights（権限レポート） | 過剰共有の事前調査・権限棚卸し | 💰 AvePoint 契約費用 |
| Cloud Governance（EnPower） | Copilot Studio エージェントのガバナンス | 💰 AvePoint 契約費用 |
| tyGraph | Copilot 利用状況の可視化・Power BI 連携 | 💰 AvePoint 契約費用 |

### 12.2 Copilot 展開前の AvePoint 活用ステップ

```
ステップ1: 権限棚卸し（Insights）
  → 全 SharePoint サイト・Teams の過剰共有をスキャン
  → "Everyone" 共有・外部共有が多いサイトを特定

ステップ2: 問題のある権限の修正（Cloud Governance）
  → 孤立サイトのオーナー設定・ライフサイクル管理
  → 長期間未使用のサイトのアーカイブ・削除

ステップ3: バックアップの確認と拡張
  → Copilot データ（SharePoint・OneDrive・Teams）のバックアップが最新化されていることを確認
  → Copilot Studio エージェントファイルのバックアップを追加設定
  → バックアップポリシーの保持期間を確認（最低 1年、規制業種は 5〜7年）

ステップ4: 継続モニタリング（tyGraph + Insights）
  → Copilot 展開後の利用状況を tyGraph でモニタリング
```

### 12.3 コスト最適化：AvePoint と Microsoft ネイティブ機能の使い分け

```
Microsoft Purview（✅ E5 付属 → コスト無し）:
  - 秘密度ラベルの作成・管理
  - DLP ポリシーの設定
  - eDiscovery Premium・コンプライアンス調査
  - Insider Risk Management

SharePoint Advanced Management / SAM（✅ M365 Copilot ライセンスに付属）:
  - 過剰共有サイトの基本レポート
  - サイトレベルのアクセス制限
  - アクセスレビューの開始

💰 AvePoint（追加費用発生）← 上記だけでは対応しきれない場合に検討:
  - ファイルレベルの細粒度な権限可視化
  - 大規模環境での自動修復アクション
  - 複数サービス（Teams・OneDrive・SharePoint 等）の統合バックアップ
  - 継続的な権限モニタリングの自動化
```

---

## 13. 監査・監視・アラート設定

### 13.1 Purview 監査 Premium の設定（✅ E5 付属）

```
Purview ポータル → [監査] → [設定]

監査 Premium の有効化（✅ E5 では標準有効）:
  保存期間: 1年（Standard は 90日）
  → さらに延長が必要な場合は💰 監査保持ポリシーで有料拡張設定
```

### 13.2 Copilot インタラクションの監査検索（✅ E5 付属）

```
Purview ポータル → [監査] → [監査検索]

Copilot 専用クエリ例:
  アクティビティ: CopilotInteraction
  期間: 過去 30日

確認できる情報:
  - プロンプトのテキスト（内容の概要）
  - 参照されたファイル・メール
  - DLP ポリシーへの違反有無
```

### 13.3 Microsoft Sentinel との連携

> 💸 **Microsoft Sentinel は Azure 従量課金サービス**です。E5 に含まれません。  
> ✅ ただし E5 ユーザーは **5 MB/ユーザー/日の M365 データ無料インジェスト枠**が適用されます。

```
Azure Portal → [Microsoft Sentinel] → ワークスペースを選択
→ [データコネクタ] → [Microsoft 365 Copilot（プレビュー）]
→ [接続]

💡 コスト最適化:
  - E5 の 5 MB/user/日の無料枠を最大活用（M365 Defender コネクタ経由）
  - Analytics Tier（有料）は重要ログのみに絞る
  - Basic Logs Tier（安価）でアーカイブ用ログを管理
  - コミットメント層を選択することでペイアズユーゴーより最大 52% 節約
```

### 13.4 Microsoft Defender XDR での Copilot 活動監視（✅ E5 付属）

```
Defender ポータル（https://security.microsoft.com）
→ [調査と応答] → [インシデント]
→ Security Copilot で自動要約・優先順位付け

モニタリング対象:
  - Copilot 関連の DLP アラート
  - Cloud PC からの疑わしいファイル操作
  - 大量のプロンプト送信（スパム的な利用）
```

---

## 14. ネットワーク要件（Cloud PC 環境）

> ✅ ネットワーク設定自体は追加費用なし。  
> 💰 Cloud PC の RDP Shortpath 通信を最適化する場合、Azure ネットワーク帯域幅コストに注意。

### 14.1 Copilot に必要なネットワークエンドポイント

```
Copilot 必須エンドポイント:
  *.cloud.microsoft       ← Copilot 統合ドメイン
  *.office.com            ← Office 365 サービス
  *.microsoft.com         ← Microsoft サービス全般
  *.microsoftonline.com   ← 認証
  *.msftidentity.com      ← Entra ID 認証

WebSocket（WSS）の許可:
  ポート: 443（HTTPS/WSS）

Windows App（Windows 365 接続）:
  RDP Shortpath 用ポート: UDP 3478（推奨）
  フォールバック: TCP 443
```

### 14.2 Cloud PC のネットワーク最適化

```
Split Tunneling（推奨・コスト削減効果あり）:
  → Microsoft 365 トラフィックは VPN を迂回させて直接インターネットへ
  → Copilot の応答速度向上 + VPN 帯域節約

Microsoft 365 最適化カテゴリのエンドポイント:
  → プロキシ・ファイアウォールの迂回対象に追加
  → Copilot の *.cloud.microsoft は迂回対象に追加
```

---

## 15. デプロイ前チェックリスト（E5 + Cloud PC 環境用）

### フェーズ0: 前提確認（4〜8週間前）

```
[ ] E5 ライセンスの保有確認（✅ 既存）
[ ] 💰 Microsoft 365 Copilot アドオンの購入・グループ割り当て
[ ] 💰 Windows 365 Cloud PC ライセンスの確認
[ ] Microsoft 365 Copilot の段階的展開計画の策定（コスト管理）
[ ] Security Copilot の E5 自動プロビジョニング通知の受信確認（✅ 無料）
```

### フェーズ1: セキュリティ基盤整備（2〜4週間前）

```
[ ] MFA を全ユーザーに強制（CA001）✅ 無料
[ ] Cloud PC へのリスクベース認証を設定（CA002/CA003）✅ 無料
[ ] Office 365 アクセスを Cloud PC 経由のみに制限（CA010）✅ 無料
[ ] Cloud PC への強力な MFA ポリシー設定（CA011）✅ 無料
[ ] M365 Copilot を CA ポリシーの対象アプリとして登録（PowerShell）✅ 無料
[ ] Copilot 専用 CA ポリシー作成（CA108）✅ 無料
```

### フェーズ2: データガバナンス整備（2〜4週間）

```
[ ] 💰 AvePoint Insights で過剰共有調査・レポート作成
[ ] 💰 AvePoint Cloud Governance で過剰共有権限の修正
[ ] 秘密度ラベルの作成・公開（4段階）✅ 無料
[ ] SharePoint・OneDrive でのラベル有効化 ✅ 無料
[ ] Power BI でのラベル有効化 ✅ 無料
[ ] サービス側自動ラベル付けポリシーの作成・シミュレーション実行 ✅ 無料
[ ] DLP ポリシーの作成・シミュレーション実行（DLP001）✅ 無料
[ ] Power Platform DLP ポリシーの設定 ✅ 無料
[ ] 制限付き SharePoint 検索（RSS）の暫定適用 ✅ 無料
```

### フェーズ3: 監査・監視基盤の整備

```
[ ] Purview 監査 Premium の有効化 ✅ E5 付属
[ ] Copilot インタラクションイベントの記録設定確認 ✅ E5 付属
[ ] アラートポリシーの設定（DLP 違反・大量アクセス）✅ E5 付属
[ ] 💸 Microsoft Sentinel への Copilot ログ連携設定（オプション・従量課金）
[ ] Security Copilot エージェントの有効化 ✅ E5 付属 SCU 内
[ ] 💰 AvePoint tyGraph での Copilot 利用状況ダッシュボード設定
```

### フェーズ4: パイロット展開（1〜2週間）

```
[ ] GRP-Copilot-Pilot グループ（30〜50名）にライセンス割り当て（💰 Copilot アドオン課金開始）
[ ] Cloud PC の更新チャンネルを Current Channel に変更 ✅ 無料
[ ] OneDrive Known Folder Move の適用確認 ✅ 無料
[ ] Microsoft Loop・Teams Copilot 設定の確認 ✅ 無料
[ ] 🔶 Power BI Copilot 機能設定（PPU 追加が必要な場合）
[ ] ユーザー向け利用ガイドライン配布・研修実施 ✅ 社内対応
[ ] DLP ポリシーを本番有効化 ✅ 無料
[ ] 2週間後: フィードバック収集・設定調整
```

---

## 16. よくあるリスクと対策

### 16.1 Windows 365 環境特有のリスク

| リスク | 内容 | 対策 | コスト |
|---|---|---|---|
| シンクライアントからの直接アクセス | ユーザーがシンクライアントのブラウザで直接ログイン | CA010 ポリシーで Cloud PC 経由のみに制限 | ✅ 無料 |
| Cloud PC の共有利用 | 複数ユーザーが同一 Cloud PC を使用 | 1ユーザー 1 Cloud PC 構成にする | 💰 Cloud PC ライセンス費用 |
| セッション切れ後のデータ残留 | Cloud PC セッション終了後に一時データが残留 | Intune で一時ファイル自動消去ポリシーを適用 | ✅ 無料 |
| トークン盗難 | Windows App のセッショントークンが盗まれる | CA011 でトークン保護を有効化 | ✅ 無料 |

### 16.2 Power BI・Power Automate 特有のリスク

| リスク | 内容 | 対策 | コスト |
|---|---|---|---|
| Power BI の RLS 未設定 | Copilot がすべての行データを参照する | RLS を全機密レポートに設定 | ✅ 無料（設定作業のみ） |
| Power Automate の過剰な権限 | フローが機密データにアクセス | 最小権限・DLP でコネクタ制限 | ✅ 無料 |
| プレミアムコネクタの未管理利用 | 高コストのプレミアムコネクタが意図せず大量使用 | DLP ポリシーでプレミアムコネクタを制限 | ✅ 無料（制限設定のみ） |

### 16.3 EchoLeak（CVE-2025-32711）への対応

```
対応策（すべて ✅ 追加費用なし）:
  [ ] Intune で M365 Apps の更新を強制（Current Channel で最新版を維持）
  [ ] Cloud PC の Windows Update 管理ポリシーを確認・必要に応じて強制
  [ ] Security Copilot の Phishing Triage Agent でフィッシングメール自動検出
  [ ] 定期的な Microsoft Secure Score の確認と推奨事項の適用
```

---

## 17. 💰 コスト詳細・料金一覧と公式参照リンク

> **⚠️ 注意：** 以下の料金はすべて **米ドル（USD）の定価**です。日本円への換算レートや EA（エンタープライズ契約）割引・CSP 価格は Microsoft の担当営業またはパートナーにご確認ください。価格は予告なく変更される場合があります。

---

### 17.1 コスト発生ポイント一覧（本書全体のまとめ）

| # | 項目 | 種別 | 金額（USD） | 御社環境での必要性 |
|---|---|---|---|---|
| 1 | 💰 **Microsoft 365 Copilot アドオン** | 固定費（ユーザー数×月額） | $30/user/月 | **最重要・必須** |
| 2 | 💰 **Windows 365 Cloud PC** | 固定費（スペック×台数×月額） | プランにより異なる | **必須（既存）** |
| 3 | 🔶 **Power BI Premium Per User（PPU）** | 固定費（ユーザー数×月額） | $20/user/月 | Power BI Copilot を使う場合のみ |
| 4 | 🔶 **Microsoft Fabric 容量（F64以上）** | 固定費（容量×月額） | $5,068.80/月〜（F64） | 大規模 Power BI Copilot 利用時 |
| 5 | 💸 **Microsoft Sentinel** | 従量課金（データ量/GB） | $2.46〜$5.20/GB | オプション（高度監視時） |
| 6 | 💸 **Copilot Studio（社内向けエージェント超過分）** | 従量課金 | $200/月（25,000 クレジット）または $0.01/メッセージ | 標準利用は M365 Copilot に含まれる |
| 7 | 💸 **Security Copilot 超過 SCU** | 従量課金 | $4/SCU/時 | E5 付属 SCU（400 SCU/月/千人）超過時のみ |
| 8 | 🔶 **Power Automate プレミアムコネクタ** | ユーザー単位 | $15/user/月 | プレミアムコネクタ使用時のみ |
| 9 | 💰 **AvePoint Confidence Platform** | サードパーティ製品 | 要見積もり | 既存契約あり（確認を） |

---

### 17.2 各項目の詳細料金と公式ページ

---

#### 【1】Microsoft 365 Copilot アドオン 💰

| 項目 | 詳細 |
|---|---|
| **価格** | **$30/user/月**（年間コミット・エンタープライズ向け） |
| **前提ライセンス** | M365 E3 / E5 / Business Standard / Business Premium |
| **含まれるもの** | Word・Excel・PowerPoint・Outlook・Teams での Copilot、Copilot Chat（社内データ接続）、Copilot Studio（社内向けエージェント作成） |
| **含まれないもの** | Power BI Copilot（別途 PPU 等が必要）、外部向け Copilot Studio エージェント（別途クレジット購入） |
| **コスト試算例** | 100ユーザー → $3,000/月 = $36,000/年 |
| **割引** | EA（エンタープライズ契約）で 5〜15% の交渉余地あり |

> 📌 **公式料金ページ：**  
> [Microsoft 365 Copilot エンタープライズ料金 - Microsoft 公式](https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise)

---

#### 【2】Windows 365 Cloud PC 💰

| SKU | スペック | 価格/user/月 |
|---|---|---|
| Windows 365 Business 2 vCPU / 4 GB RAM / 128 GB | 軽作業向け | ~$28 |
| Windows 365 Enterprise 2 vCPU / 8 GB RAM / 128 GB | 一般業務向け | ~$41 |
| Windows 365 Enterprise 4 vCPU / 16 GB RAM / 128 GB | 高度な業務向け | ~$66 |
| Windows 365 Enterprise 8 vCPU / 32 GB RAM / 128 GB | 開発・設計向け | ~$113 |

> 📌 **公式料金ページ：**  
> [Windows 365 料金 - Microsoft 公式](https://www.microsoft.com/en-us/windows-365/enterprise/compare-plans-pricing)

> **💡 コスト最適化のポイント：**
> - 未使用時に Cloud PC を「休止」することで Azure コンピュートコストを削減できる場合がある（プランによる）
> - ユーザーの業務内容に合わせたスペック選定が重要（過剰スペックを避ける）
> - Intune でライセンス未使用 Cloud PC を Security Copilot が自動検出し最適化提案を行う

---

#### 【3】Power BI Premium Per User（PPU）🔶

| 項目 | 詳細 |
|---|---|
| **価格** | **$20/user/月** |
| **E5 付属の Power BI Pro との違い** | Pro は Copilot 機能なし。PPU は Copilot（AI 自然言語レポート生成）を含む |
| **必要な場合** | Power BI Copilot（「このデータについて教えて」等の AI 質問機能）を使いたい場合 |
| **不要な場合** | 通常の Power BI レポート作成・共有のみ → E5 付属の Power BI Pro で十分 |
| **コスト試算例** | Power BI Copilot 利用ユーザー 50名 → $1,000/月 |

> 📌 **公式料金ページ：**  
> [Power BI 料金 - Microsoft 公式](https://www.microsoft.com/en-us/power-platform/products/power-bi/pricing)

---

#### 【4】Microsoft Fabric 容量（大規模 Power BI Copilot）🔶

| SKU | vCore | 価格/月（Azure 予約1年） |
|---|---|---|
| F2 | 2 | $262.80 |
| F4 | 4 | $525.60 |
| F8 | 8 | $1,051.20 |
| F16 | 16 | $2,102.40 |
| F32 | 32 | $4,204.80 |
| **F64（Copilot 最小要件）** | 64 | **$5,068.80** |
| F128 | 128 | $10,137.60 |

> 📌 **公式料金ページ：**  
> [Microsoft Fabric 料金 - Microsoft 公式](https://azure.microsoft.com/en-us/pricing/details/microsoft-fabric/)

> **💡 コスト判断：** Power BI Copilot 機能は PPU（$20/user/月）でも利用可能です。F64（$5,068.80/月）は、ビューアーが大量（500名以上）かつ高頻度でレポートを参照する場合に経済的です。小〜中規模での Power BI Copilot は **PPU が現実的**です。

---

#### 【5】Microsoft Sentinel 💸（従量課金）

| 課金モデル | 価格 | 備考 |
|---|---|---|
| ペイアズユーゴー | $5.20/GB | 少量・評価時向け |
| コミットメント 100 GB/日 | $2.96/GB（約43%割引） | 中規模 SOC |
| コミットメント 200 GB/日 | $2.76/GB | 大規模 SOC |
| コミットメント 500 GB/日 | $2.60/GB | エンタープライズ |
| **E5 無料データ枠** | **5 MB/user/日** | M365 Defender コネクタ経由の M365 ログが無料 |

**E5 無料枠の活用例（コスト試算）：**

```
例: E5 ユーザー 1,000名の場合
  無料枠: 5 MB × 1,000名 = 5 GB/日（= $0/日）
  → M365 Defender・Teams・SharePoint・Exchange のログは無料で Sentinel に取り込み可能
  → ペイアズユーゴーで 5 GB/日相当: $26/日 = $780/月 の節約効果

超過分（それ以外のログを取り込む場合）:
  → 100 GB/日コミットメント: $296/日 = $8,880/月
```

> 📌 **公式料金ページ：**  
> [Microsoft Sentinel 料金 - Microsoft 公式](https://www.microsoft.com/en-us/security/pricing/microsoft-sentinel)  
> [Microsoft Sentinel コストの計画と理解 - Microsoft Learn](https://learn.microsoft.com/en-us/azure/sentinel/billing)

> **💡 コスト判断：** Sentinel は E5 の Security Copilot・Defender XDR で対応できない高度な相関分析や長期ログ保存が必要な場合に導入を検討してください。**E5 環境では Security Copilot と Defender XDR だけでも多くの監視ユースケースをカバーできます。**

---

#### 【6】Copilot Studio（社内向けエージェント） 💸

| 課金モデル | 価格 | 備考 |
|---|---|---|
| **M365 Copilot ライセンス内（社内向け）** | **$0（追加費用なし）** | M365 Copilot ライセンスユーザーが Teams/SharePoint/M365 内でエージェントを利用 |
| ペイアズユーゴーメーター | $0.01/メッセージ | Azure 請求、従量課金 |
| クレジットパック | $200/月（25,000 クレジット） | テナント全体、前払い |
| Pay-as-you-go（Azure） | $0.01/クレジット | 使用分のみ課金 |

> **💡 コスト判断：**  
> M365 Copilot ライセンスユーザー（$30/user/月 を購入済み）が、**Teams・SharePoint・Copilot Chat の範囲内**で社内向けエージェントを利用する場合は **追加費用なし**。  
> 外部向けエージェント（顧客向けチャットボット等）や、社外チャンネル経由の利用は別途クレジット購入が必要。御社の業務ユースケースを確認の上、利用範囲を明確にしてください。

> 📌 **公式料金ページ：**  
> [Copilot Studio 料金 - Microsoft 公式](https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/copilot-studio)  
> [Copilot Studio ライセンスガイド（PDF、2026年2月版） - Microsoft 公式](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/microsoft-365/1084694-Microsoft-Copilot-Studio-Licensing-Guide-February-2026-PUB.pdf)

---

#### 【7】Security Copilot 超過 SCU 💸

| 項目 | 詳細 |
|---|---|
| **E5 付属枠** | 400 SCU/月 × 1,000 E5 ユーザー（上限 10,000 SCU/月） |
| **超過分の単価** | $4/SCU/時（別途プロビジョニング費用） |
| **SCU リセット** | 毎月リセット（翌月繰り越しなし） |
| **超過が発生するケース** | 大規模インシデント対応、全エージェントの同時フル稼働など |

**E5 付属 SCU の試算例：**

```
例: E5 ユーザー 500名の場合
  付属 SCU: 400 SCU × (500/1000) = 200 SCU/月
  
例: E5 ユーザー 1,000名の場合
  付属 SCU: 400 SCU × 1 = 400 SCU/月
  
例: E5 ユーザー 5,000名の場合
  付属 SCU: 400 SCU × 5 = 2,000 SCU/月（上限 10,000 SCU）
```

> 📌 **公式ページ：**  
> [Security Copilot の Microsoft 365 E5 付属詳細 - Microsoft Learn](https://learn.microsoft.com/en-us/copilot/security/security-copilot-inclusion)

---

#### 【8】Power Automate プレミアムコネクタ 🔶

| ライセンス | 価格 | 含まれるもの |
|---|---|---|
| **Power Automate（E5 付属）** | **$0（追加費用なし）** | 標準コネクタのみ（SharePoint・Outlook・Teams・OneDrive・Power BI 等） |
| Power Automate Premium | $15/user/月 | プレミアムコネクタ（SAP・Salesforce・ServiceNow 等）+ RPA |
| Power Automate Process | $150/bot/月 | RPA・UI フロー用（非推奨ライセンス、2026年更新予定） |

> **💡 コスト判断：** 御社の Power Automate の用途が **SharePoint・Outlook・Teams・OneDrive の標準コネクタのみ**であれば、E5 付属のままで追加費用は発生しません。SAP や外部 SaaS との連携が必要な場合のみ Premium が必要です。

> 📌 **公式料金ページ：**  
> [Power Automate 料金 - Microsoft 公式](https://www.microsoft.com/en-us/power-platform/products/power-automate/pricing)

---

#### 【9】AvePoint Confidence Platform 💰

> AvePoint は Microsoft のサードパーティパートナー製品のため、Microsoft 公式価格ページには記載がありません。

| 提供モデル | 詳細 |
|---|---|
| **価格体系** | ユーザー数・保護するサービス数・機能に応じた見積もり制 |
| **主な製品** | Cloud Backup、Cloud Governance（EnPower）、Insights、tyGraph など |
| **購入方法** | AvePoint 正規代理店または AvePoint 直販で見積もりを取得 |

> 📌 **公式ページ：**  
> [AvePoint 製品ページ（英語）](https://www.avepoint.com/products)  
> [AvePoint 導入事例・価値実証](https://www.avepoint.com/ebooks/gartner-secure-and-govern-copilot-at-scale)

> **💡 コスト最適化：** AvePoint の機能の一部は、M365 E5 付属の Purview・SAM（SharePoint Advanced Management）で代替可能です。既存の AvePoint 契約が包括的であれば、機能重複を確認して追加費用を最小化してください。

---

### 17.3 御社環境のコスト試算モデル（参考）

以下は 500名のユーザーを想定した参考試算です。実際の価格は EA 割引・CSP 価格・AvePoint 契約内容によって異なります。

```
【必須費用】
  M365 E5 ライセンス（既存）:
    → 既存契約コスト（変更なし）

  Windows 365 Cloud PC（既存）:
    → 既存契約コスト（変更なし）

  💰 M365 Copilot アドオン（新規追加分）:
    → パイロット 50名: $30 × 50 = $1,500/月
    → 全社 500名: $30 × 500 = $15,000/月（$180,000/年）

【条件付き費用（用途に応じて検討）】
  🔶 Power BI PPU（Copilot 利用者分のみ）:
    → 対象者 30名想定: $20 × 30 = $600/月

  💸 Microsoft Sentinel（オプション）:
    → E5 無料枠（5 MB × 500名 = 2.5 GB/日）を活用
    → 超過分のみ課金（まず Defender XDR で代替できるか検討）

  💰 AvePoint（既存契約内で継続）:
    → 既存契約内容を確認し、Copilot 関連機能が含まれているか確認

【E5 付属で追加費用不要な項目】
  ✅ Security Copilot（E5 付属 SCU 内での利用）
  ✅ Microsoft Purview（DLP・秘密度ラベル・監査Premium・Insider Risk）
  ✅ Microsoft Defender XDR
  ✅ Microsoft Entra ID P2（PIM・リスクベース CA）
  ✅ Intune（Cloud PC 管理）
  ✅ Power Automate（標準コネクタのみ使用）
  ✅ Power BI Pro（Copilot 機能を除く通常利用）
  ✅ SharePoint Advanced Management（SAM）※M365 Copilot ライセンス付属
  ✅ 条件付きアクセスポリシー設定（全ポリシー）
  ✅ Teams での Copilot 管理設定
  ✅ Purview 監査ログ（1年保存）
```

---

### 17.4 公式料金・ライセンスページ一覧

| 製品・サービス | 公式 URL |
|---|---|
| Microsoft 365 Copilot エンタープライズ料金 | https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise |
| Microsoft 365 プラン比較 | https://www.microsoft.com/en-us/microsoft-365/enterprise/compare-office-365-plans |
| Windows 365 Cloud PC 料金 | https://www.microsoft.com/en-us/windows-365/enterprise/compare-plans-pricing |
| Power BI 料金 | https://www.microsoft.com/en-us/power-platform/products/power-bi/pricing |
| Microsoft Fabric 料金（Azure） | https://azure.microsoft.com/en-us/pricing/details/microsoft-fabric/ |
| Microsoft Sentinel 料金 | https://www.microsoft.com/en-us/security/pricing/microsoft-sentinel |
| Microsoft Sentinel コスト計画（Microsoft Learn） | https://learn.microsoft.com/en-us/azure/sentinel/billing |
| Copilot Studio 料金 | https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/copilot-studio |
| Copilot Studio ライセンスガイド（PDF・2026年2月版） | https://learn.microsoft.com/en-us/microsoft-copilot-studio/billing-licensing |
| Security Copilot E5 付属詳細（Microsoft Learn） | https://learn.microsoft.com/en-us/copilot/security/security-copilot-inclusion |
| Power Automate 料金 | https://www.microsoft.com/en-us/power-platform/products/power-automate/pricing |
| Microsoft 365 ライセンス比較ツール（M365Maps） | https://m365maps.com |
| Azure 料金計算ツール（Sentinel 等の試算） | https://azure.microsoft.com/en-us/pricing/calculator/ |

---

*本ドキュメントは 2026年5月時点の公開情報に基づいています。Microsoft のサービス仕様・ライセンス構成・価格は予告なく変更される場合があります。最新情報は必ず公式ドキュメントをご確認ください。特に価格については、Microsoft Enterprise Agreement（EA）や CSP パートナー経由の割引が適用される場合があります。*

*バージョン 3.0 — E5 + Windows 365 Cloud PC + AvePoint 環境向け・コスト表示改訂版*
