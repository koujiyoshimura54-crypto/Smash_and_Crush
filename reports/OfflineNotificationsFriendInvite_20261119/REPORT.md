# オフライン報酬通知・カスタム招待（UI入口は後日接続）

2026-11-19、Y01 / DESKTOP-CNFVEH2。既存副本 PlaceId **126576845524886**、UniverseId **10765181857**、Editで実装。開始時HEAD/mainは `ff9ed2b897bfde4ef60cfd1d970826912480e5f3`。作業フォルダーは `C:\Users\kouji\Smash_and_Crush\AnalyticsSpawnItems`。

途中の確定指示「UIは追加しない」「指示したらボタンなどで実装できる状態」に従い、**ボタン・バナー・GUI・自動表示を追加していない**。招待／通知許可は後から指定された操作へ接続する呼出しModuleまで実装。まだプレイヤーがゲーム内からこの新しい呼出しを行う入口はない。

オフライン通知の永続予約・保存成功連携・処理担当は実装済み。両文面IDは既存Sourceにも見つからず空欄を保持し、現状は予約／送信・招待呼出しが無効。仮IDの登録、Secretの再登録・値の取得は行っていない。

## 変更Full Path

| Full Path | 変更 |
|---|---|
| `ReplicatedStorage.Config.EngagementConfig` | 両機能の設定・文字列ID検査。新規 |
| `ReplicatedStorage.Modules.EngagementPrompts` | 明示操作用の資格確認・多重表示防止・終了時解除。新規 |
| `ReplicatedStorage.Modules.EngagementClient` | `Invite()` / `NotifyMe()` / `Destroy()`。呼出しがあるまで接続も登録しない。新規 |
| `ServerScriptService.Services.OfflineNotificationState` | 副作用なしの通知状態・退出世代・結果分類。新規 |
| `ServerScriptService.Services.OfflineNotificationWorker` | 時計・保存先・HTTPを差し替えられる処理本体。新規 |
| `ServerScriptService.Services.OfflineNotificationService` | 本番用のDataStore／HTTPアダプター、上限付き担当処理。新規 |
| `ServerScriptService.Services.PlayerDataOwnership` | 新しい所有権取得と同一UpdateAsyncで前回退出通知を取消 |
| `ServerScriptService.Services.PlayerDataService` | 成功した参加の復旧候補登録、退出保存内の通知記録、成功応答後のキュー登録 |
| `ServerScriptService.Systems.Controllers.PlayerDataController` | 通知サービスを一度だけ起動 |
| `HttpService.HttpEnabled` | false → true。Allow HTTP Requestsのみ。Studio Access to API Services等は変更していない |

9 Sourceの構文・Source／Editor一致、ローカルとの内容照合を実施。[SHA256一覧](source_manifest.json)、[変更前Source](before.json)、[検証結果](verification.json)。新規6 Moduleと既存3 Sourceへの追加だけで、既存スクリプトを一括同期していない。

## 設定・後からの接続

設定は `ReplicatedStorage.Config.EngagementConfig`。

```lua
Offline = {
    Enabled = true,
    OfflineRewardMessageId = "",
    SecretName = "OfflineRewardNotificationKey",
    DelaySeconds = 86400,
},
Invite = {
    Enabled = true,
    FriendInviteMessageId = "",
},
```

文面IDは引用符付きの文字列。UUIDと数値形式の文字列を受け付け、数値化しない。空欄・プレースホルダー・不正形式は無効。SecretNameは登録済みSecretの**名前**であってキー文字列ではない。

`Offline.Enabled=false`で新規予約／処理を停止、`Invite.Enabled=false`で招待を停止。各機能のID空欄も当該呼出しを停止する。Module設定はサーバー／クライアントの起動時に読むため、編集は次のPlay／デプロイ後に起動するサーバー・クライアントへ反映される。既に稼働しているサーバーを即時に遠隔停止する仕組みは追加していない。

後日、承認された既存ボタン等のLocalScriptの明示操作コールバックから接続する例（**今回、この接続は追加していない**）：

```lua
local Engagement = require(game.ReplicatedStorage.Modules.EngagementClient)
-- 招待ボタンのユーザー操作時:
Engagement.Invite()
-- 通知許可ボタンのユーザー操作時:
Engagement.NotifyMe()
-- 接続を所有するUIの終了時（必要な場合）:
Engagement.Destroy()
```

Inviteは`CanSendGameInviteAsync(player)`をpcallし、`ExperienceInviteOptions.InviteMessageId`を渡す。送信相手の選択はRoblox標準画面。APIキー・通知許可・通知の年齢条件を招待の独自ゲートにしていない。文面の表示名／ゲーム名はRoblox側の置換に任せる。

NotifyMeは`CanPromptOptInAsync()`がtrueの場合だけ`PromptOptIn()`。閉じたイベントやfalseを「許可済み」と解釈せず、許可フラグもRemoteも作らない。両処理とも確認中／表示中の連打を抑止し、失敗・取消後は再操作可能。標準画面が開いている間は時間切れだけでロックを解除しない。

旧 `StarterPlayer.StarterPlayerScripts.Services.BoostClient` に標準招待処理が残っていたが、入口の `StarterGui.ScreenGui` はEnabled=false、`ActiveBoost.Friends` はVisible=false、旧MainもDisabled=trueだった。今回そのUI・起動経路は変更していない。

## 永続予約・処理・保存との分離

1. 正常な新規プロフィール取得後、成功した参加だけを対象に、ユーザーID＋セッション世代の**復旧候補**を期限索引へ登録する。Onlineの候補は送信資格ではない。導入前の全Player走査はしない。
2. 既存の退出保存UpdateAsyncが成功したときだけ、同じプロフィール内に `OfflineNotificationExit` が残る。退出Strength／Presenceと同一トランザクション。普通の保存では新規作成しない。保存失敗・古い所有権からの書込みで資格を作らない。
3. 保存成功応答後に期限索引へ登録する。索引操作は非同期・最大3試行で、失敗が本来のプロフィール保存を失敗にしない。退出後にサーバーが停止しても、参加時の復旧候補があればコミット済み通知記録を発見できる。
4. 初回処理で `DataStoreKeyInfo.UpdatedTime` を使い保存の確定時刻を確認してから、通知開始時刻を固定する。UpdateAsyncコールバック実行時刻が保存確定より早くても、DelaySecondsを早く開始しない。退出後に同じプロフィールへの別の保存があれば、その最新確定時刻を採る保守的な遅延となる。
5. 再参加の所有権取得と同じUpdateAsyncで前退出の記録を消す。別サーバー参加も同じフェンスを通る。再退出は新世代・新退出時刻。死亡だけでは世代を変更しない。
6. 実際の送信直前に、最新保存の世代・Offline Presence・通知状態・処理権・既存報酬計算の正の結果を再確認する。再参加時に初めて報酬レコードが生成される仕様を維持し、レコード未作成を「報酬なし」としない。

保存先は既存 `PlayerData_v1 / Player_<UserId>` の通知専用フィールドと、追加の `OfflineNotifyDue_v1`（OrderedDataStore）、`OfflineNotifyWorker_v1`（担当リース）。通知側のUpdateAsyncは、**現在値を複製して通知フィールドだけ**を変更し、UserIds／Metadataを保持する。古いプロフィールをゲーム状態へ戻さない。報酬付与・受取済み変更・所有権変更は通知側で行わない。

通常受取、2倍購入、唯一のReceipt処理、退出Strengthの毎時4％・上限86400秒の計算Sourceは変更なし。通知DelaySecondsと報酬蓄積上限は別設定。

## 負荷・復旧の限界

- 担当確認は60秒間隔、担当リース120秒。1回の期限取得は最大5件。個別予約にも120秒の処理権があり、複数サーバーの同時送信を防ぐ。単一ループ・単一起動。
- DataStoreの読込／Update予算40以上、Sorted取得予算・更新予算を確認して処理。予算不足は後回し。既存の90秒定期保存などの周期は変更なし。
- Online復旧候補は1時間後へ繰延べ、退出証明のない候補は7日で整理。通知期限から7日を超えたものも期限切れ扱い。掃除も最大5件の枠内。プロフィール全件走査、毎秒照会、毎フレーム処理はない。
- 全サーバー停止中は実行できず、次の稼働サーバーが期限索引を再確認する。確定時計の初回確認、担当間隔、件数上限、予算・バックオフにより遅延する。**24時間ちょうどの配信を保証しない**。
- プロフィールとOrderedDataStoreの間に分散トランザクションはない。参加時候補と退出後索引登録の両方が、全再試行を含めて失敗した場合、その退出の通知は自動発見できず欠落し得る。次回参加では旧退出を取消し、次の退出から再登録する。これを全Player走査で補う処理は追加していない。
- 応答消失後も、退出保存自体がコミット済みなら復旧候補経由で確認できる。コミットされていないOnlineデータや異常終了から退出を推測しない。
- 処理失敗項目は1時間繰延べ、先頭の少数エラーが索引処理を占有し続けないようにする。

## API・重複と結果不明の扱い

`POST https://apis.roblox.com/cloud/v2/users/{UserId}/notifications`。`source.universe="universes/10765181857"`、`payload.message_id`、`payload.type="MOMENT"`を使用。

本番アダプターは `HttpService:GetSecret("OfflineRewardNotificationKey")` のSecretオブジェクトをそのまま `x-api-key` ヘッダーへ渡す。キー文字列の取得・保存・ログ出力なし。本文やヘッダー、プロフィールをログへ出さない。今回、実Secretを取得していない。

Studioでは最初の条件で終了し、通知用DataStore・Secret・HTTPを呼ばない。ID未設定・OFFでも同様。StudioのクラウドSecret利用可否を登録漏れの根拠にしていない。

HTTPの直前に`Sending`を永続化する。これが成功したと確認できない場合は送らない。送信後の結果保存失敗やサーバー停止でも`Sending`を回収して自動再送せず、リース失効後は`Uncertain`として終了。送信されなかった通知が欠落する可能性と引き換えに、曖昧な再送を避ける。

| 結果 | 扱い |
|---|---|
| 2xx | API受付成功 `Accepted`。端末表示・受信確認ではない |
| 401／403 | `AuthError`、その退出は終了。担当は15分停止。403だけで年齢や許可の状態を推測しない |
| 400／404 | `InvalidRequest`、再試行なし |
| 412 | 前提条件拒否 `Ineligible`。具体的な年齢・許可状態は保存しない |
| 429 | `RateLimited`。300秒から指数バックオフ、最大3600秒、最大3試行で`LimitReached` |
| Secret取得不可／HTTP無効 | HTTP送信前に停止。1時間間隔・最大3試行 |
| 通信例外／タイムアウト／408／5xx等、成否を確定できない応答 | `Uncertain`、自動再送なし |
| 新世代／取消／報酬0／期限超過 | 送信せず取消／対象外として索引を整理 |

直近の送信試行時刻もプロフィールに保持し、別退出世代では24時間内に次の試行を行わない。Roblox側の日次制限・許可・13歳以上等の対象条件はRobloxに最終判断を任せる。今回、実APIの各拒否本文は取得しておらず、より詳細な配信不能理由や実際の権限は未確認。

再参加は未送信予約を無効化するが、最終チェック後・HTTP実行中の再参加は送信を完全には取り消せない。**必ず一度届く／完全取消／exactly onceは保証しない**。

## 検証区分

すべて実SourceをLuauでコンパイルして実行した**Edit内の隔離模擬**。保存・時計・HTTP・標準画面を偽物へ差し替え、実データへアクセスしていない。

| suite | 確認数 | 主な内容 |
|---|---:|---|
| EngagementNotifications | 155 | 期限直前／一致／直後、再参加・別サーバー世代、複数担当、リース終了、長時間停止、報酬0、未設定／OFF、Secret／HTTP障害、401／403／429、タイムアウト、送信後保存失敗、取消競合、標準画面の取消・連打・終了処理 |
| EngagementAdapter | 176 | 本番アダプターを偽サービスで実行。Studio／未設定時の外部呼出し0、Secretを文字列化しないヘッダー、RESTフィールド、保存の確定時計が5秒遅れる例、索引復旧、予算、担当競合、呼出しModuleの標準招待・許可連携 |
| EngagementSaveHook | 63 | 実PlayerDataService.Save関数を抽出しメモリ保存で実行。正常退出、保存前失敗、コミット後応答消失、キュー失敗、普通の保存、OFF。本来のStrength／LV／進捗／Win／所有品維持。無関係な正規化関数はスタブ |
| 既存StrengthRewards／StrengthRewardOwnership | 60＋11 | 通常受取、2倍の固定額、遅延・重複Receipt、保存応答消失、同時加算、所有権フェンスの既存回帰 |

合計465 assertion。件数は実配信・実購入・実プロフィール保存の成功証拠ではない。再実行用：[生成runner](../../tests/EngagementOffline.py)でcore／adapter／save／rewardsを選び、生成コードを既存StudioのEdit実行環境で実行する。Playを起動するrunnerではない。

最終静的確認：9 Sourceをコンパイル、Source／Editor一致。他の既存541 Sourceのうち変更は指定3件のみ、新規6件。StarterGui配下13,490 Instanceの階層・確認対象GUI値の指紋は前後一致（位置・サイズ・表示・文字・Font・画像等）。GUI追加・表示変更・端末エミュレータ変更なし。

**実Playは未実施。** 現行の `_Studio` 保存名は実DataStoreであり、保存しない隔離の証明にならない。今回の場所以外を作る方法や無関係なサービス一括改造も使っていない。実Playerの退出／再参加、実際のDataStore障害・予算、公開API受付、実Secret、実招待・OptIn標準画面、実端末・PC／スマホの標準画面表示は未確認。UI入口を追加しない今回の確定範囲では、その操作感やレイアウトを確認済みとはしない。

## 保全・公開前の残作業

- Premium Treadmillイベントは対象外。現在Studio内の `2026-11-28 / 03:00` と開始日時から24時間の実装を保持。Gitの旧設定で上書きしていない。
- 別worktree、stash、既存未追跡`crashes/`は操作・stage対象外。検証コードをStudio Instanceとして配置していない。一時物の残置なし。
- ユーザーが入口を指定した後、その明示操作へ呼出しModuleを接続する。ボタン追加は別指示待ち。
- その際に既存の通知文面ID2件をConfigへ文字列で入力する。Secret登録作業のやり直しは不要。
- ユーザーのSave／Publish後、同意のあるテスト利用者だけで標準画面の取消／許可／招待と、正常退出後のAPI受付・再参加取消を確認する。実際に受信したかはAPI受付と別に確認する。現在は両ID空欄で外部呼出し無効。

Studioは既存編集を保持した**未保存Editで開いたまま**。エージェントによるPlay／Stop・Save／Publish、公開サーバー再起動、実通知・実招待・購入は未実施。

## 参照した公式資料

- [User notifications](https://create.roblox.com/docs/cloud/guides/experience-notifications)：RESTのmessage_id、MOMENT、日次制限。
- [In-game HTTP requests](https://create.roblox.com/docs/cloud-services/http-service)：HTTP設定とSecretヘッダー。
- [ExperienceNotificationService](https://create.roblox.com/docs/reference/engine/classes/ExperienceNotificationService)：許可画面のメソッドと閉じたイベント。
- [Player invite prompts](https://create.roblox.com/docs/production/promotion/invite-prompts)：InviteMessageId、UUID例、Robloxの文面置換。
- [DataStoreKeyInfo](https://create.roblox.com/docs/reference/engine/classes/DataStoreKeyInfo)：UpdatedTimeのミリ秒単位の確定時刻。
