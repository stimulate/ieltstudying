〇〇株式会社　技術ご担当者様

お世話になっております。〇〇社の〇〇です。

DZPass をローカルの物理端末に正常にインストールできましたが、  
現在モバイルデバイスとの Bluetooth 接続ができない状態が続いております。

本日、Bluetooth 関連のログを調査したところ、以下のようなエラーが確認されました：

1. System Exception：デバイスがコマンドを認識できません（0x80070016）  
2. Services が取得できません（Status：Unreachable, ProtocolErrors）  
3. System Exception：属性を書き込めません  
　　System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)

また、下記のようなトラブルシューティングも実施しましたが、いずれも改善には至りませんでした：

- アプリと端末の再起動  
- Bluetooth の ON/OFF 切り替え  
- 再インストールおよびペアリング設定の確認  
- iOS／Android デバイスとの接続状況チェック　など

そこで質問なのですが、接続のためには API 通信先の URL をファイアウォールの  
Outbound 通信許可リストに追加する必要があるのでしょうか？

上記エラーの根本原因や、他に必要なネットワーク設定、または対処方法について  
ご教示いただけますと幸いです。



お忙しい中恐れ入りますが、何卒よろしくお願いいたします。


