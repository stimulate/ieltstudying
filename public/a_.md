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

