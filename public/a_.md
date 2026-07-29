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

PowerShellを管理者として実行し、以下のコードを入力して実行してください。
Get-WinEvent -FilterHashtable @{
    LogName      = 'System'
    ProviderName = 'Schannel'
    StartTime    = (Get-Date).AddMinutes(-10)
} |
Select-Object TimeCreated, Id, LevelDisplayName, Message |
Format-List

可以在邮件中追加下面这段“证书确认手顺”。我把整封邮件也一起整理好了：

---

北さんから送付いただいたイベントビューアーのログを確認したところ、主に以下の2件の証明書関連エラーが記録されていました。

証明書チェーンを、信頼されたルート証明機関まで構築できませんでした。
証明書チェーンは処理されましたが、信頼プロバイダーが信頼していないルート証明書で終了しました。

このため、今回のWebページのリンク遷移エラーは、証明書認証が正常に完了していないことに関連している可能性があります。

ただし、確認できたログが今回のWebアクセスによって発生したものかどうかは、現時点では完全には特定できていません。

北さんには、既存のイベントログを一度クリアしたうえで、再度リンクをクリックして事象を再現し、新しいエラーログが記録されるか確認いただくようメールで依頼しています。

現時点では、まだ北さんからの回答を受領していません。回答および再取得したログを確認後、改めてご報告いたします。

よろしくお願いいたします。

なお、証明書名が同じであっても、Thumbprintや有効期限が異なる場合は別の証明書となるため、証明書名だけではなく、Thumbprintもあわせてご確認ください。

お手数をおかけしますが、よろしくお願いいたします。
