# GamePass Phase 1 — 2026-11-17

副本の現在の未保存編集を基準に、Strengthパスと有料Treadmill倍率だけを反映。イベント用ボードは読み取り調査のみ。新しい購入UI、報酬UIの移動、イベント、ダンベル文字の色・フォント変更は行っていない。

## 対象・根拠

- 実接続：PlaceId `126576845524886` / UniverseId `10765181857`、Studio `c5f24ec8-6d16-4db3-a02c-1a1c61572814`、Edit。
- Repository：`koujiyoshimura54-crypto/Smash_and_Crush`、作業開始HEAD `20808b8e1ce55e1f49a67edc008d1d3d6faf295d`。既存の未追跡 `crashes/` は変更・commit対象外。
- 指定ファイル `C:\Users\kouji\Downloads\Roblox_GamePass_Phases_20261117.md` を全文読了。SHA256 `9c7faff42dea3e02046e89ef6ef641c7430fb87ff220e7e167eac6de5387bea4`。
- [13件の最新Pass一覧](../../docs/GAMEPASS_CATALOG.md)へ価格・管理された価格設定・未確認範囲を反映。Passの作成、購入、販売価格変更はなし。

## 変更Full Pathと設定

| Full Path | 変更 |
|---|---|
| `ReplicatedStorage.Config.WorldPassConfig` | `StrengthPass.GamePassId=2089895831`、`AdditiveMultiplier=1`。販売価格の固定値は入れない |
| `ReplicatedStorage.Config.TreadmillConfig` | `Types.Premium.Multiplier` 20→7。World1の他Tier 1/2/3を維持 |
| `ReplicatedStorage.Config.World2GameplayConfig` | `Treadmills[4].Multiplier` 35→15。他Tier 5/7/12、Pass ID、BasePrice等を維持 |
| `ServerScriptService.Services.GamePassService` | server所有確認、セッションcache、参加／購入後の再確認、既存Studio/製作者ゲート、退出cleanup |
| `ServerScriptService.Systems.Controllers.GamePassController` | 参加済みPlayer・PlayerAddedからStrength所有確認を起動 |
| `ServerScriptService.Services.StrengthManager` | 歩行またはTreadmillのsource倍率へ所有時＋1。一度のみ適用 |
| `ServerScriptService.Services.AutoTapService` | server側でWalking/Manualを区別して渡す。手動タップは今回の対象経路外として既存計算を維持 |
| `Workspace.Treadmills.Diamond01.BillboardGui.Multiplier.Text` | `×20 Strength` → `×7 Strength` |
| `Workspace.World2Map.TrainingArea.TreadmillDisplays.07.StationBillboard.Multiplier.Text` | `×35 Strength` → `×15 Strength` |

7 Sourceと既存Text 2個のみをStudioへ反映。Sourceと開いているエディタbufferが調査時と一致することを先に確認し、差分適用。全527 Source中、対象外520 Sourceの一致を確認。GamePassController／TrainingControllerは有効のまま。テキストは新Configから生成した値。レイアウト、画像、購入カードは変更しない。実行時も既存 `TreadmillUIClient` / `LeftMenuClient` が共通Configを参照する。[最終Edit照合](STUDIO_VERIFICATION.json)。

手動調整は上記Config内で行い、次のPlay／新サーバー開始から反映する（ModuleScriptはセッション内cache）。`AdditiveMultiplier=1` は無単位の倍率加算であり、Strength固定値＋1や最終獲得量×2ではない。既存Editの看板Textは静的プロパティなので、Configを今後変更した際のEdit表示更新は別途必要。実行中は既存Config表示処理が適用する。

`StudioDebugConfig.GamePassEffectsEnabled=false` と `ProductionCreatorGamePassEffectsEnabled=false` は維持。副本Studioで所有していても、このゲートがfalseなら効果は0。一般の本番Playerへの通常効果とは区別する。

## 最終計算式

正の獲得量について、既存 `StrengthCalculation.Gain` は変更していない。

```
B = amount + (Lobby内Dumbbell + Aura + Protein) × ticks
歩行のsource = 1 + StrengthPassBonus
Treadmillのsource = 設備倍率 + Belt + TrainingPotionBonus + StrengthPassBonus
gain = B × Rebirth × source × StrengthPotion × VIP × Pet
```

通常1tickは `amount=1 / ticks=1`。Dumbbellの有効範囲は既存server Lobby判定のまま。TrainingManagerが既存Belt・TrainingPotionを足し、StrengthManagerが検証済みパスの1を一度だけ追加する。最終gainを `PlayerDataService.AddStrengthGain → LevelProgression.ApplyGain` へ渡し、Strength、Level、LevelProgress、獲得累計へ反映。小数は切り捨てず既存どおり保持する。clientの表示にはcommit済み増分を送る。

手動タップ、`AddRewardStrength`、`GetNormalTrainingGain`、固定報酬、Offline専用経路へStrengthパスを追加していない。所持Strengthの一括倍増、戦闘ダメージ直接倍率、新しい保存fieldはなし。`StrengthReference` 自体は変更せずパス＋1を含めない。ただし従来から共通Treadmill Configを使う最大rate参照では、今回承認された設備20→7／35→15の変更が参照値にも反映される。既に確定したOffline報酬の書き換えや保存はしていない。

所有権は `UserOwnsGamePassAsync` の成功結果だけをcacheし、Attributeは表示用mirror。未所有・初回確認失敗では＋0。成功確認後の一時失敗は、そのセッションで検証済みの権利だけを保持。購入完了通知では再確認し、通知だけで権利を与えない。1 Playerにつき再確認workerは1個。失敗時は1/2/3/4秒後、以降15秒間隔で回復を待ち、退出時に終了する。毎tickでMarketplaceへ問い合わせない。再参加は新たに確認し、死亡復帰は同じ所有cacheを使うため倍率が積み上がらない。

API根拠：[Roblox MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService) の所有確認・購入完了仕様。今回のMarketplace応答検証は下記の模擬応答であり、実購入は行っていない。

## 今回の検証

### Edit内の隔離模擬実行 — 181 assertion

[試験コード](../../tests/GamePassPhase1.spec.luau)、[生の増分結果](SIMULATION_RESULTS.json)。現在Sourceを `loadstring` し、requireを明示したSource／stubだけへ解決。game、Players、Marketplace、task時計、所有応答、装備値、占有入力を隔離。実Player・DataStore・外部送信・課金・通常Scriptの起動は0。Studioの実Config、修正Source、未変更TrainingManager／Calculation／LevelProgressionを利用した。

`PlayerDataService.AddStrengthGain` と `RecordStrengthGain` は現物Sourceから関数本体をそのまま切り出し、メモリsessionへ実行。呼出し回数だけでなくStrength、属性、累計と通知増分の一致を確認。PlayerDataService全体はrequireせず、保存workerも起動しない。これは**実Play、実移動速度測定、実購入検証ではない**。

| 条件・他補正なし | パスなしのメモリ増分 | パスありのメモリ増分 |
|---|---:|---:|
| 通常歩行（AutoTapService自動歩行経路） | 1 | 2 |
| World1通常Treadmill | 1 | 2 |
| World1有料Treadmill | 7 | 8 |
| World2通常Tier1 | 5 | 6 |
| World2有料Treadmill | 15 | 16 |

Treadmillは各条件3tickを0.5秒の仮想時計で実行し、全tick同じ増分。手動タップは1のまま、歩道の受動搬送は0。未所有／所有の独立性、Attribute偽装による無効付与防止、API失敗、購入通知再検証・重複通知、参加・再参加、Studio/製作者ゲートを確認。

補正併用例：Dumbbell10、Aura3、Protein2、Rebirth2回（×2）、Belt＋2、TrainingPotion＋1、StrengthPotion×1.5、VIP×1.10、Pet×1.25。World1有料1tickはパスなし660、あり726。`16 × 2 × (7+2+1+[0/1]) × 1.5 × 1.10 × 1.25` と一致。固定報酬＋7、通常Training参照32はパス有無で変わらない。

占有false、死亡signal、CurrentWorld変更、Premium所有喪失後に実TrainingManagerの次tickが増分を止め、sessionを除去することを模擬確認。再入場／前提復帰後は再開。**占有・接地は明示した模擬入力**で、実際の足・Raycast・ジャンプ物理を合格扱いにしない。TrainingManagerの接地・資格・周期Sourceは変更していない。

既存Body診断用builderのGamePass stubには `GetStrengthPassBonus=0` を追加し、新APIと互換を維持した。Body fixtureの生成・起動・再Playは今回行っていない。

### 静的・Edit確認

- 対象Place/Universe/Edit実値、7 Sourceの構文、Configの倍率・ID、既存看板Textとの一致。
- 既存7 Sourceとrepoの開始版が一致。無関係なSource、Body、ダンベル、購入Part、イベントボード・Main無効状態を維持。
- TrainingConfigの歩行／Training周期0.5秒、その他Tier・価格・購入条件・接地／退出／ジャンプ処理を維持。
- イベント関連はrequire・有効化せずSourceとObjectを読んだだけ。

### 実Play・未確認

今回の実Playは未実施。既存副本には通常保存処理があり、既存未保存編集を保持したままPlayを隔離できたことを確認していない。新規Studio／アプリを起動しない指示もあるため、通常副本Playを代用しなかった。

実Marketplace所有応答・課金、実リグ歩行・ジャンプ・設備退出、自然な死亡復帰／World移動、実クライアントの看板更新、複数Player、実機／公開環境／本番保存は未確認。181 assertionはこれらの実Play合格を意味しない。

## イベント用ボード：読み取り調査

Full Pathは `Workspace.EventBoard`（Model、子2個）。`Board` Part（28×12×0.5 studs、位置およそ -11.259,35.917,79.227）と外枠Part（30×14×1）。`Board.SurfaceGui` に `Event1` / `Event2` / `Event3` TextLabel、UIStroke、UIListLayout。BoardにはTextureも存在。ボード自身にScript、Remote、独自Attributeはなし。

Edit文言はそれぞれDevil / Candy / Water Eventの `In 00:00`。これは現在の開催を示す実行結果ではなく、保存されている表示文字。

| 関連Full Path | 内容・現状 |
|---|---|
| `ReplicatedStorage.Modules.Config.Weather` | `Board={"EventBoard","Board","SurfaceGui"}`。20分間隔、5分継続、1秒更新、Devil→Candy→Water順。待機文In／開催文Ends In、イベント色・Speed/Win倍率 |
| `ReplicatedStorage.Modules.Weather` | `Workspace:GetServerTimeNow()`を1200秒で割ったslotと剰余から開催／終了を計算。`running`、`board`、`speedPayout`、`winsPayout`。保存や開催Remoteを使わない時刻計算 |
| `StarterPlayer.StarterPlayerScripts.Services.WeatherClient` | `start`が毎秒boardを描画。開催切替でActiveBoost、通知、Lighting差し替え、フラッシュ、camera zoom。終了時は通常Lightingへ復帰 |
| `StarterPlayer.StarterPlayerScripts.Main` | `Loader.load(script.Parent.Services)`の起点。現物Enabled=false |
| `ServerScriptService.Main` | 同じ購入Mapのserver loader起点。現物Enabled=false |
| `ReplicatedStorage.Modules.Loader` | Moduleをrequireし、init／startを実行する汎用loader。今回実行していない |
| `ReplicatedStorage.Modules.Stack` | 購入Mapの旧Speed補正でWeather.speedPayoutを参照 |
| `ServerScriptService.Services.WinServer` | 購入Mapの旧Win計算でWeather.winsPayoutを参照 |

SpeedClient／SpeedServer／OfflineServerから旧Stackへの参照も存在。現物Source検索ではWeatherClientへの明示的な新起動元は見つからず、上記Main経路は無効。現在のStrengthManager／TrainingManagerはWeatherを参照しない。実Playでの動的起動までは確認していない。

依存する `ReplicatedStorage.Packages.Janitor`、`ReplicatedStorage.Assets.Lightning`（4種）、`Assets.Templates.ActiveBoost`、`Assets.Icons`、`StarterGui.ScreenGui.ActiveBoost` は存在。NotifyClient、TweenService、RunService、Lighting、cameraにも依存する。Weather本体・clientに専用HTTP／DataStore／Marketplace／Remote依存は見つからず、開催時刻はserver同期時計を利用する。現在の旧ロジックはサーバー開始からの独立30分タイマーではない。

**流用候補**はBoard/SurfaceGui/3行の配置とカウントダウン描画。MainやWeatherClient全体を起動すると旧Speed/Win効果や画面・Lighting・camera演出を再導入するため、そのまま有効化しない。将来はサーバー側に「所有済み、または無料期間中」の限定したWorld1 Premium許可を追加し、所有cacheを書き換えず既存TrainingManagerの資格判定へ接続する必要がある。開始／終了、既に乗っている人、終了時の停止、購入Promptとの競合も別途設計する。

将来案は30分ごと3分、Strengthパス併用で7+1=8、有料所有者は期間外も利用可能。ただし開催間隔・共通／サーバー単位・起点は未決定。今回タイマー、無料開放、ボード文言変更、演出、イベント用UIは一切実装していない。

## 引き渡し

副本へ差分反映し、検証用InstanceやScriptを作らず、MCP内の一時helperも終了時に除去。未保存Editで開いたまま。Save／Publish、正本、PR #1、force pushはなし。今回分のみ通常commitし、`origin/main`へpushする。
