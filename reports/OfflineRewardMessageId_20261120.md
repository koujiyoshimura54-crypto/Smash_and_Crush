# オフライン報酬通知の文面ID設定

2026-11-20 JST。ユーザー指定の `4905299160793744045` を、既存副本Studio（PlaceId 126576845524886 / UniverseId 10765181857）の `ReplicatedStorage.Config.EngagementConfig.Offline.OfflineRewardMessageId` へ **文字列** として設定。変更前は空欄。開始HEAD/mainは `e0c94fbfdf363783138e72a976cad3c88eea87bb`。

```lua
Offline = {
    Enabled = true,
    OfflineRewardMessageId = "4905299160793744045",
    SecretName = "OfflineRewardNotificationKey",
    DelaySeconds = 86400,
}
```

実装Sourceの変更はこのID一箇所だけ。桁落ちを避けるため数値化していない。Studio Sourceとエディター、ローカル設定を照合。既存のEnabled=true、退出保存確定から24時間のDelaySeconds、処理上限、Secret名、報酬・UI・友達招待・Premiumイベントを保持。友達招待IDは空欄のまま。

Configの形式判定 `OfflineConfigured()` はtrue。**これは通知文字列アセットの実在・用途・対象Universeの利用権限を確認した意味ではない**。このIDはユーザー指定値として登録したもので、Robloxの通知APIでの受付・実配信は未確認。今回実APIやSecretへアクセスしていない。

既存テストの「IDなし」fixtureをデプロイ設定から独立させ、設定済みfixtureでは今回のIDをそのまま模擬HTTPへ渡すようにした。隔離した既存core 155＋adapter 176、合計331 assertionsを再実行し通過。JSONの`payload.message_id`が文字列のまま一致すること、StudioでDataStore/Secret/HTTP呼出しが0、未設定/OFF・再参加取消・期限・競合・再試行・結果不明時の挙動を確認。新たな実通知送信は行っていない。

設定は起動時に読むため、ユーザーがSave/Publishした後に起動する公開サーバーで既存条件に従って有効になる。StudioではID設定後も実通知用保存・送信を禁止。停止は `Offline.Enabled=false`。全サーバー停止中は処理できず、通知時刻の厳密保証はしない。[予約・配信の制約](OfflineNotificationsFriendInvite_20261119/REPORT.md)、[UIと未確認事項](OfflineRewardMenuUI_20261119/REPORT.md)。

既存Studioを未保存Editで開いたまま保持。Play/Stop・Save/Publish・実通知・購入・招待・Creator Hub操作なし。既存未保存編集、別worktree、stash、crashes/は保持。
