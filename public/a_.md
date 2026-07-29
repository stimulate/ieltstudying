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

**件名：CAPI2エラーログの再取得および証明書チェーン確認のお願い**

〇〇様

お疲れ様です。

先ほど確認したCAPI2のエラーログについてですが、今回アクセスできない `int.agt.millea.jp` のWebページによって発生したものではない可能性が高いと考えております。

確認できたログには、以下の情報が記録されていました。

* 証明書の対象：`checkin...dm.microsoft.com`
* 実行プロセス：Windowsのシステムプロセスである `lsass.exe`
* 実行アカウント：`SYSTEM`

今回のWebアクセスに直接関連するログであれば、`msedge.exe` や `iexplore.exe` などのブラウザー関連プロセスが記録される可能性が高いため、今回確認したログは、Intune／MDMのチェックインなど、別のWindowsシステム処理に関連するものと考えられます。

お手数ですが、以下の手順でもう一度エラーログを取得していただけますでしょうか。

### 1．CAPI2ログの再取得

1. イベントビューアーを開く
2. 以下の場所に移動する
   `アプリケーションとサービス ログ`
   → `Microsoft`
   → `Windows`
   → `CAPI2`
   → `Operational`
3. `Operational` を右クリックし、既存のログを一度クリアする
4. 対象メール内のリンクをクリックする
5. 証明書選択画面で対象の証明書を選択する
6. Webページが自動的に閉じるまで待つ
7. ログの反映に時間がかかる可能性があるため、さらに数十秒程度待つ
8. イベントビューアーのCAPI2ログを更新し、新しいエラーが発生しているか確認する

新しいエラーが記録された場合は、発生時刻に加えて、以下の項目もご確認ください。

* `Subject`：証明書の対象
* `Issuer`：証明書の発行者
* `ProcessName`：実行プロセス
* `Result`：エラーコード
* 証明書チェーンに関する詳細情報

### 2．現在のユーザー証明書の確認

1. `Windowsキー＋R` を押す
2. 以下を入力して実行する

```text
certmgr.msc
```

3. 以下の場所を確認する

```text
証明書 - 現在のユーザー
→ 個人
→ 証明書
```

4. Webサイトの証明書選択画面に表示された証明書を開く
5. 以下の項目を確認する

* 発行先
* 発行者
* 有効期限
* シリアル番号
* 拇印（Thumbprint）
* 証明書の用途

6. 「証明書のパス」タブを開き、証明書チェーン上に赤い×印や警告がないか確認する
7. 「全般」タブに、以下のような表示があるか確認する

```text
この証明書に対応する秘密キーを持っています
```

8. 「詳細」タブの「拡張キー使用法」に、以下が含まれているか確認する

```text
クライアント認証
```

### 3．コンピューター側のルート証明書・中間証明書の確認

1. `Windowsキー＋R` を押す
2. 以下を入力して実行する

```text
certlm.msc
```

3. 対象証明書のIssuerに対応する証明書が、以下の場所に存在するか確認する

ルート証明書：

```text
証明書 - ローカル コンピューター
→ 信頼されたルート証明機関
→ 証明書
```

中間証明書：

```text
証明書 - ローカル コンピューター
→ 中間証明機関
→ 証明書
```

4. 該当する証明書を開き、以下を確認する

* 有効期限が切れていないこと
* 「この証明書は問題ありません」と表示されていること
* 「証明書のパス」にエラーがないこと
* IssuerおよびSubjectが証明書チェーンと一致していること
* Thumbprintが正常端末と一致していること

可能であれば、正常にアクセスできるAD参加端末と、現在問題が発生している端末について、以下の証明書情報を比較していただけますと、原因を特定しやすくなります。

* 証明書の有無
* Subject
* Issuer
* Thumbprint
* 有効期限
* 証明書チェーンの状態
* 秘密キーの有無
* クライアント認証用途の有無

なお、証明書名が同じであっても、Thumbprintや有効期限が異なる場合は別の証明書となるため、証明書名だけではなく、Thumbprintもあわせてご確認ください。

お手数をおかけしますが、よろしくお願いいたします。
