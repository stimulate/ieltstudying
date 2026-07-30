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

正常に画面が表示された後、同様に以下を実行してください。

    netsh trace stop
