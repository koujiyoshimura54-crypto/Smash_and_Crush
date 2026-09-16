# Inventory seen-based notifications — 2026-09-16

## 実装

- 変更前はDumbbell／Aura／Speedが「未購入かつ購入可能」である限り通知を表示し、Itemsの未確認状態はセッション内だけだった。
- `InventoryNotificationSeen`をPlayerDataへ追加し、Dumbbells／Items／Aura／Speedごとに確認済みコンテンツIDを保存する。
- 対象タブを開くと、その時点で解放済み／所有済みの対象IDを確認済みにする。購入・Equipは不要。
- 後から別IDが解放・追加された場合は、そのIDだけ未確認となり通知が再表示される。
- 親Inventory通知は各子タブの未確認状態の論理和。

## 後方互換

- `InventoryNotificationSeen`がない旧データは、4タブすべて空の確認済み集合として正規化する。
- 保存時は既存値と新しい確認済みIDをunionし、別の保存経路で確認済み状態を巻き戻さない。
- Reset時は既存defaults()に従って空集合へ戻る。

## Play確認

- Winを上げてDumbbell／Aura／Speedに新着を発生させ、各タブと親Inventoryに通知が出ることを確認。
- Dumbbellsを開くと購入せずDumbbell通知のみ消え、Aura／Speedと親通知は残った。
- Dumbbellsを閉じて再度開いても復活しなかった。
- Aura、Speedを順に開くと対象タブだけ消え、全確認後に親Inventory通知が消えた。
- Play停止後に再Joinし、同じDumbbell／Aura／Speed通知が復活しないことを確認。
- Itemは既存の取得イベントとItemInventoryStateを利用し、新しい所有Item IDだけ未確認にする。Itemsタブを開くと購入せず確認済みになる。
- 購入・Equip・Mergeのサーバー処理は変更していない。
- ゲームRuntimeのError / Warning / Infinite Yieldは0件。AssistantCommandからCapability付きModule/Remoteを直接検証しようとした制約ログは実装Runtime外として除外した。

## 変更ソース

`sources/`にStudio内の変更後ソースを保存した。
