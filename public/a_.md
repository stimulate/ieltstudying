情報セキュリティ通知

このシステムはツーサンのコンピューターシステムです。
本コンピュータシステムおよび関係する全ての設備、ネットワーク、ネ
ットワーク機器（特にインターネットにアクセス可能なもの）は、当社
の行動倫理憲章及び情報取扱要領等に基づき、許可された使用のために
のみ提供されるものです。
本システムの使用状況は、当該使用が許可されたものであることの確保
、システムの管理、不正アクセス防止の促進、並びにセキュリティ手順
、サバイバビリティ（生存性）及び、運用セキュリティの検証を行う目
的により、合法的に監視される場合があります。
本システムの使用者は、本システムを使用することにより、本システム
が監視されることを、承諾し、かつ、許可された使用のためにのみ本シ
ステムを使用することに同意したものと、みなされます。
本システムを不正に利用した場合、懲戒処分等の対象となる可能性があ
ります。

https://int.agt.millea.jp/tokiomarine-nichido/dfw/SETCK2/redirect.html?Alias=SP*2Fweb*2Fuj_startFromTNetGet.html*3FcalculationType*3D01*26item*3D02*26pol_Num*3D1CHAVGK3vZhYPPCeej*252FMxg*253D*253D*26pol_classification_no*3D*26gamen_seigyo_modern*3D1&Session=U2FsdGVkX18yhfR6JsugmbzDI4yRpPqUFVSLAcFqARI5Ic5LTKLaboOh5mAIb3E*2FSjhaHujGYCKvtYn*2BVguMDUTvel59RFMydTXA7LDhnNCJ7Yn*2BglK6Km0M9GpD1384CL&TS=U2FsdGVkX1*2Bw*2FKdAX6YgCh*2BrigjtUYG4*2BgjHRwXYOluQ*3D&WN=_blank&WA=width*3D1014*2Cheight*3D705*2Ctop*3D0*2Cleft*3D0*2Ctoolbar*3Dno*2Cmenubar*3Dno*2Cstatus*3Dno*2Clocation*3Dno*2Cscrollbars*3Dyes*2Cresizable*3Dyes

Windows標準のnetsh traceを取得いただけますと、元のTLS／クライアント証明書認証を変更せずに比較できます。

管理者権限でPowerShellまたはコマンドプロンプトを起動し、以下を実行してください。

保存先フォルダーの作成
    mkdir C:\Temp\IETrace

Entra ID参加端末では、以下を実行します。

    netsh trace start scenario=InternetClient capture=yes report=yes persistent=no overwrite=yes maxSize=512 traceFile="C:\Temp\IETrace\entra-fail.etl"

その後、以下の操作を行ってください。

対象サイトのリンクをクリックする
証明書を選択する
画面が閉じるまで待つ
さらに20～30秒程度待つ
以下のコマンドでトレースを停止する
    netsh trace stop

正常にアクセスできるAD参加端末でも同様に取得する場合は、以下のファイル名で開始してください。

    netsh trace start scenario=InternetClient capture=yes report=yes persistent=no overwrite=yes maxSize=512 traceFile="C:\Temp\IETrace\ad-success.etl"

{"pattern":"https://int.agt.millea.jp","filter":{}}
正常に画面が表示された後、同様に以下を実行してください。

    netsh trace stop


echo WScript.Echo("CSCRIPT_OK") > "%TEMP%\sqltraining_test.js"
cscript.exe //nologo "%TEMP%\sqltraining_test.js"
del "%TEMP%\sqltraining_test.js"


把两份 ETL 分别转换为文本：

netsh trace convert input="C:\Temp\IETrace\entra-fail.etl" output="C:\Temp\IETrace\entra-fail.txt" dump=TXT report=yes overwrite=yes
netsh trace convert input="C:\Temp\IETrace\ad-success.etl" output="C:\Temp\IETrace\ad-success.txt" dump=TXT report=yes overwrite=yes

netsh trace convert 支持将 ETL 转换为 TXT、CSV、XML 或 EVTX，也可以同时生成 HTML 报告。

お疲れ様です。

旧端末でMicrosoft Authenticatorを利用できる場合は、以下の手順で新端末への登録をお願いいたします。

新端末に「Microsoft Authenticator」アプリをインストールします。
PCのブラウザから、以下のページへアクセスします。
https://mysignins.microsoft.com/security-info
会社アカウントでサインインし、旧端末のMicrosoft Authenticatorで認証します。
「サインイン方法の追加」をクリックし、「Microsoft Authenticator」を選択します。
新端末でMicrosoft Authenticatorを開き、以下を選択します。
「＋」→「職場または学校アカウント」→「QRコードをスキャン」
PC画面に表示されたQRコードを新端末で読み取り、画面の案内に従って登録を完了します。
新端末で認証通知を受信し、正常に承認できることを確認します。
新端末での認証確認後、同じ「セキュリティ情報」画面から旧端末のMicrosoft Authenticatorを削除します。

新端末での認証確認が完了するまでは、旧端末の登録を削除しないようお願いいたします。

操作中にエラーが発生した場合は、表示されたエラーメッセージのスクリーンショットをお送りください。

よろしくお願いいたします。

お疲れ様です。

AWSの月額費用について、試算結果をExcelにまとめましたので、添付いたします。

今回、以下の2パターンで試算しております。

① 最小構成での試算
　1か月間の最小構成を前提として、各サービスの必要最低限の設定・利用量で算出しています。
② 想定利用量ベースでの試算
　プロジェクトのシステム構成図のうち、今回対象としているAWS 5サービスについて、想定される利用量を設定し、やや保守的に算出しています。
　現時点では実績値がない項目もあるため、一部の利用量については構成図をもとに仮定値を設定しています。

今回の試算対象は、以下の5サービスです。

Amazon CloudFront
AWS Amplify
Amazon S3
Amazon Route 53
AWS Certificate Manager（ACM）

なお、ACMについては、CloudFrontと連携して使用する非エクスポート型のパブリック証明書は追加料金が発生しないため、Excelの費用明細には記載しておりません。

試算値については、東京リージョンおよび共通IDアカウントでの利用を前提とし、AWS Pricing Calculatorに各想定値を入力したうえで、出力した結果をもとに作成しております。

また、2つ目の試算については、実際のアクセス数、データ転送量、キャッシュヒット率、SSRの処理時間等によって費用が変動するため、現時点での概算値となります。

ご確認のほど、よろしくお願いいたします。

なお、Lambda@EdgeについてはCloudFrontの処理と直接関連するため、2つ目の試算では追加で設定値を含めています。

お世話になっております。

スクリーンショットをご共有いただき、ありがとうございます。

確認したところ、スクリーンセーバーを有効化する構成ポリシー、およびSharePointから端末側へ画像を同期する修復処理については正常に適用されており、LT49端末内にも対象の画像ファイルが存在していることを確認しました。

一方で、Photo Screensaverが参照する画像フォルダの設定については、Intune上ではPowerShell Platform Scriptが「成功」と表示されていますが、実際の端末では対象の設定値が期待どおり反映されていないことを確認しました。

現時点では、Platform Scriptの実行タイミングや端末側の状態などにより、設定が正常に反映されなかった可能性があると考えておりますが、他の要因の可能性もあるため、引き続き確認を行っています。

IntuneのPowerShell Platform Scriptは、一度「成功」と判定されると、スクリプトまたはポリシーに変更がない限り、基本的には再実行されません。なお、実行結果が「失敗」と判定された場合は、その後3回のIntune Management Extensionのチェックイン時に再試行されます。

Microsoft公式ドキュメント：
https://learn.microsoft.com/ja-jp/intune/device-management/tools/run-powershell-scripts-windows

今回、より確実に設定状態を確認・修正できるよう、対象の設定値を定期的に検出し、正しく設定されていない場合に再設定する修復スクリプトを新たに作成しました。

修復スクリプトをLT49端末に適用して動作確認を行いたいため、恐れ入りますが、本日LT49端末の電源を入れ、ネットワークに接続した状態でしばらく保持していただくことは可能でしょうか。

お手数をおかけしますが、よろしくお願いいたします。

お疲れ様です。
本日午後から、既存のAWS Organization配下にアカウントを作成し、必要なユーザー／権限設定、Budgetアラート、S3バケット等の初期設定を進めようと思っていますが、問題ないでしょうか。

あわせて、今回の構築はTerraformで実施する想定でしょうか。それとも、まずはコンソールから手動で作成する形でしょうか。
方針をご確認いただけますと助かります。

昨日は、Route 53のHosted Zoneの作成、S3バケットの作成、Budgetのアラート設定を行いました。
あわせて、Terraformの設定確認と修正も進めました。

本日は、残っているAWSリソースの構築と動作確認を進め、プロジェクト全体を一通り構築完了させる予定です。

| 区分                | 構築・設定内容                                     | Reviewポイント                                       |
| ----------------- | ------------------------------------------- | ------------------------------------------------ |
| AWS Account       | `eol-dev` アカウント作成                           | Organization配下、対象OU/アカウント情報                      |
| AWS Access        | `OrganizationAccountAccessRole` を利用した管理アクセス | 管理アカウントからAssumeRole可能か                           |
| AWS CLI           | `eol-dev` Profile設定                         | 対象Account ID、Regionが正しいか                         |
| Terraform         | Terraform DEV環境の基本構成                        | Provider / Backend / State管理                     |
| Terraform Backend | Terraform State保存用S3 Bucket                 | Versioning、Encryption、Public Access Block        |
| Terraform State   | DEV環境を統一Stateで管理                            | `eol/dev/terraform.tfstate`                      |
| Budget            | 月額Budgetおよび通知設定                             | 金額、通知先、閾値                                        |
| Route 53          | DEV用Public Hosted Zone                      | Domain名、NS Record                                |
| DNS Delegation    | 親ドメインからDEV Hosted ZoneへのNS委譲                | 4つのNSが正しく登録されているか                                |
| ACM               | CloudFront用Public Certificate               | `us-east-1`、DNS Validation、Issued状態              |
| S3                | Static用Bucket                               | Naming、Encryption、Versioning、Public Access Block |
| S3                | Upload用Bucket                               | Naming、Private設定、Encryption                      |
| Amplify           | GitHub Repository連携                         | Repo、Branch、GitHub App接続                         |
| Amplify           | Amplify App作成                               | `WEB_COMPUTE` / Next.js SSR                      |
| Amplify           | DEV Branch設定                                | `DEVELOPMENT`、Auto Build                         |
| Amplify IAM       | Amplify Service Role                        | Trust Policy、CloudWatch Logs権限                   |
| CloudFront        | Distribution作成                              | Origin、Alias、ACM証明書                              |
| CloudFront Origin | Amplify Origin                              | Amplify App/Branchへの接続                           |
| CloudFront Origin | S3 Origin                                   | OAC / Bucket Policy                              |
| Route 53 Alias    | DEV Domain → CloudFront                     | A / AAAA Alias                                   |
| IAM Group         | `BillViewer`                                | Billing ReadOnly                                 |
| IAM Group         | `Administrator`                             | `AdministratorAccess`、ユーザー未割当                    |
| IAM Group         | `Developer`                                 | 開発者向け権限                                          |
| IAM Group         | `InfraEngineer`                             | 5サービス管理権限                                        |
| IAM User          | 指定3名のIAM User作成                             | 所属Group、Console Login                            |
| IAM Security      | Terraform State Bucket保護                    | InfraEngineerでもtfstate Bucket操作不可                |
| Billing Access    | Billing参照権限                                 | `AWSBillingReadOnlyAccess`                       |
| GitHub            | Demo用Next.jsコードUpload                       | Repository / Branch / Build成功                    |
| GitHub            | TerraformコードUpload                          | Secret / tfstate / tfvarsがCommitされていないか          |
| Demo Test         | Amplify Build / Deploy                      | 成功しているか                                          |
| Demo Test         | Amplify URL疎通                               | Homepage / `/api/health`                         |
| HTTPS Test        | Custom Domain                               | ACM証明書でHTTPS接続可能か                                |
| Final Check       | Terraform `plan`                            | 不要なdestroy / replaceがないか                         |
Chromebook検証に必要なCEUライセンスについて



---
name: sharepoint-knowledge-search
description: Search only the specified SharePoint folder and its subfolders to answer questions based on internal documents. Do not use web search or external sources.
---

# SharePoint限定ナレッジ検索

## Goal
指定されたSharePointフォルダー内の文書だけを根拠として、ユーザーの質問に回答する。

## Allowed Sources
- 設定済みのSharePointフォルダー
- そのフォルダー配下のサブフォルダーに含まれるファイル

## Prohibited Sources
- Web検索、公開Webサイト、インターネット上の情報
- 指定フォルダー以外のSharePointサイトやファイル
- メール、Teams、OneDriveなど、別途指定されていない情報源
- 資料に根拠がない一般知識や推測による補完

## Workflow
1. 質問のキーワードと同義語を整理する。
2. 許可されたSharePointフォルダー内の関連文書を検索する。
3. 該当箇所を確認し、回答の根拠を特定する。
4. 複数文書がある場合は、記載内容と日付を比較する。
5. 根拠に基づき、日本語で回答する。
6. 可能な場合はファイル名、該当箇所、文書リンクを示す。

## Grounding Rules
- 回答は検索で確認できた資料の内容に基づく。
- 資料にない情報を事実として追加しない。
- 情報不足や文書間の矛盾を明示する。
- 検索できなかった場合、検索したと偽ってはいけない。
- 根拠が見つからない場合は、回答を推測で補完しない。

## Fallback Response
指定されたSharePointフォルダー内の資料からは、
質問に対する明確な根拠を確認できませんでした。
検索キーワードを変更するか、関連資料の追加をお願いします。

## Response Format
### 回答
資料に基づく回答。

### 根拠
- ファイル名
- 該当箇所
- 該当箇所の要約

### 参照先
可能な場合はSharePointファイルへのリンク。

### 確認できない事項
資料から確認できない事項がある場合のみ記載する。

お疲れ様です。

Cloud PCのディスク容量について、これまでの調査結果、現在の状況、および今後の対応案についてご報告いたします。

### 1. 現状

現在、一部のCloud PCにおいて、Windows 365のライセンス上で設定されているディスク容量に対し、Windows上で認識されている実際の容量が約半分になっている問題が発生しています。

先週、同様の問題が発生している端末を4台確認し、手動でディスクの拡張作業を実施した結果、すべて正常に拡張できました。

現在、同様の問題が残っている端末は以下の3台です。

- （PC名①）
- （PC名②）
- （PC名③）

なお、3台のうち1台については、ユーザーから現時点では容量不足による業務への影響がないとの申告があったため、当面は拡張作業を実施せず、様子を見る予定です。

### 2. 業務への影響

ディスクの空き容量が不足すると、以下のような問題が発生する可能性があります。

- 仮想メモリ（Pagefile）の使用領域不足
- 一時ファイルやシステムキャッシュの保存領域不足
- Windows Updateに必要な空き容量の不足
- アプリケーションのインストール・実行時の容量不足

その結果、アプリケーションの動作が遅くなったり、システム全体のパフォーマンスが低下したりするなど、日常業務に影響が出る可能性があります。

### 3. 原因分析

私が使用しているCloud PCでの調査結果から、原因はWindowsのディスクパーティション構成にあると考えています。

具体的には、Windows RE（Windows回復環境）のパーティションがCドライブと未割り当て領域の間に配置されているため、Cドライブを直接拡張しようとしても、Windows REのパーティションが障害となり、拡張処理が失敗します。

### 4. 対応方法

対応方法として、以下の2つを考えています。

**案①：未割り当て領域にDドライブを新規作成する**

未割り当て領域を利用してDドライブを作成し、ユーザーがダウンロードしたファイルや個人で保存するデータなどをDドライブに移動・保存する方法です。

これにより、Cドライブの使用量を抑え、システム領域の空き容量を確保できます。

**案②：Windows REのパーティションを再構成し、Cドライブを拡張する**

以下の手順でパーティションを再構成する方法です。

1. Windows REを一時的に無効化する
2. Windows REのパーティションを削除する
3. 未割り当て領域を利用してCドライブを拡張する
4. 新たにWindows RE用のパーティションを作成する
5. Windows REを再度有効化する

この方法であれば、ライセンス上の設定容量に合わせてCドライブ自体を拡張できます。

### 5. Intuneによる対応案

今後の対応については、PowerShellスクリプトを作成し、Intune経由で対象のCloud PCに配布・実行する方法を検討しています。

スクリプトによって、Windows REの無効化、パーティションの再構成、Cドライブの拡張、およびWindows REの再有効化を自動化する想定です。

独立したテスト環境がないため、まずは対象端末のうち1台で実施し、正常に拡張できることを確認したうえで、もう1台に対しても順次適用したいと考えています。

なお、現時点でユーザーから業務への影響がないと申告されている1台については、当面は対応を保留する予定です。

### 6. 作業リスクと安全対策

今回の作業では、Windows REのパーティションを削除・再作成するため、パーティション構成を変更するリスクがあります。

一方、Cloud PCには自動的に作成されるシステム復元ポイント（Restore Point）があるため、作業中にWindowsの動作に問題が発生した場合、復元ポイントを利用して以前の正常なシステム状態に戻せる可能性があります。

ただし、システム復元ポイントはパーティション構成そのもののバックアップではないため、これだけで完全に復旧できるとは限りません。

そのため、作業前にディスク構成やWindows REの状態を確認し、各処理の実行結果を検証しながら進める予定です。また、異常が検出された場合は後続処理を停止するよう、スクリプトにも安全対策を組み込む想定です。

### 7. 今後の進め方

現時点では、Cドライブ自体の容量不足を根本的に解消できる案②が望ましいと考えています。

まずはPowerShellスクリプトを作成し、対象端末1台で実施・検証したうえで、問題がないことを確認してから、もう1台に順次適用したいと考えています。

ご確認のほど、よろしくお願いいたします。

鈴木さん、お疲れ様です。

Appのインストール状況について、現時点での確認結果をご報告します。

**■ 確認時の状況**
月曜日の朝、Appのインストール状況を確認しようとしたところ、すでに鈴木さんが対象端末にログインしてテストを実施されており、ユーザーのパスワードも変更されていたため、テストに影響しないよう、端末にログインしての確認はいったん控えました。

**■ 各Appのインストール状況**

**1. Python**
- Intune上ではインストール完了となっています。
- ただし、Pythonのインストールのみ実施しており、環境変数（PATH）の設定は行っていません。
- コマンドラインから直接Pythonを実行する場合、ユーザー側でPATHの設定が必要になる可能性があります。

**2. WSL**
- 現在もIntune上では「保留中（Pending）」の状態が続いています。
- 以前、Finjuさんの端末に旧バージョンのWSLを正常にインストールした際も、同じ設定を使用していました。
- WSLのインストールファイル自体のサイズが大きいため、ダウンロードやインストールに時間がかかっている可能性もあります。

**3. Visual Studio Code**
- 旧バージョンと同じインストールコマンドを使用しています。
- Intuneからはインストール処理が正常に実行されたという結果が返っていますが、設定した検出パスで実行ファイルが確認できず、インストール状態が失敗と判定されています。
- 実際には別のフォルダにインストールされており、検出ルールと実際のインストール先が一致していない可能性があるため、引き続き確認が必要です。

**■ 今後の対応**
- 対象ユーザーには、Teamsで個別にDMを送信済みです。
- 自分のPCもテスト対象として追加し、インストール状況を確認できるようにしました。
- 引き続き、Intune上のインストール状態と実際のアプリの動作を確認していきます。

進展があり次第、改めてご報告します。

