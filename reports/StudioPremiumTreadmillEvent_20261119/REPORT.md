# World1 Premium Treadmill — Studio専用無料開放試作

2026-11-19 / Y01 (DESKTOP-CNFVEH2)

副本の実際の設備 `Workspace.Treadmills.Diamond01` に、既存TrainingManagerを通じる一時利用資格を実装した。**現在の開発Studioへ反映済み、実Playは未実施**。保存・購入・外部送信から隔離したEdit内の模擬実行で、実Strength計算とメモリ更新まで確認した。物理的に乗って増加する動作の確認とは区別する。

## 対象・保全

- 接続中のStudio ID: `b69bc527-9db7-4688-bd3c-082384af0a87`
- 実値: PlaceId **126576845524886** / UniverseId **10765181857** / PlaceVersion **746** / Edit。
- 作業フォルダー: `C:\Users\kouji\Smash_and_Crush\AnalyticsSpawnItems`
- Repository: `koujiyoshimura54-crypto/Smash_and_Crush`
- 開始HEAD: `8710f7628c4959bd33ad4631ef4a77383d7b2809`。fetchで確認したmain `eaa7aea`（完成済みイベントボード）へfast-forwardしてから今回分を追加。開始時の追跡変更なし。既存未追跡 `crashes/` は触れていない。
- 変更前のTrainingManager/GamePassServiceを [before](before/) に保存。両者は当時のStudio Source・Editor・mainと一致。バックアップのバイト一致を確認し、[SHA256一覧](source_manifest.json) を保存。
- [ボードと全14台の判定エリアの記録](before/board_and_treadmills.json) と反映後を比較し、記録対象値は一致。ボードは既存12 Instance（Model自身＋子孫11）、黒・半透明の板、FredokaOne、既存2行を保持。GUIへの状態連動や再デザインは追加していない。
- 旧 `ServerScriptService.Main` と `StarterPlayer.StarterPlayerScripts.Main` のDisabled=trueを維持。
- 既存の未保存編集、新Strength表、Stage1表記、Daily修正を置換する同期は行っていない。別worktree、stash、復旧ファイルは操作していない。

## 変更したStudio Full Path

| Full Path | 変更 |
|---|---|
| `ServerScriptService.Config.World1PremiumTreadmillEventConfig` | 新規。Studio試作の時間・有効設定 |
| `ServerScriptService.Services.World1PremiumTreadmillEventSchedule` | 新規。副作用のない周期・境界計算 |
| `ServerScriptService.Services.World1PremiumTreadmillEvent` | 新規。サーバー側Studioガード、対象設備判定、状態取得 |
| `ServerScriptService.Systems.Controllers.World1PremiumTreadmillEventController` | 新規Script、Enabled=true。状態遷移のOutputのみ |
| `ServerScriptService.Services.TrainingManager` | 既存資格に一時資格を追加。開催中の購入要求抑止と終了後の再判定 |
| `ServerScriptService.Services.GamePassService` | Premium購入要求の開始前・所有確認後に同じ開催情報を再確認 |

Sourceは同名の `src/` 以下に対応する。新規Controllerのファイル名は `World1PremiumTreadmillEventController.server.luau`。**6件すべてでStudio Source・Editor内容・作業ファイルの一致とLuau構文コンパイルを確認**。[反映確認](verification.json)。

TrainingController、StrengthManager、PlayerDataService、AutoTapService、TreadmillConfig、StudioDebugConfig、通常設備・World2設備・ボード・他GUIは変更していない。検証用Instanceは作成していない。

## 手動設定・反映タイミング・戻し方

設定場所は `ServerScriptService.Config.World1PremiumTreadmillEventConfig`。クライアント公開ConfigやRemoteによる開催制御は設けていない。

| 設定 | 最終値 | 意味 |
|---|---:|---|
| Enabled | true | Studio試作の許可。これだけで公開環境を有効化できない |
| StartIntervalSeconds | 1800 | 開始から次の開始までの秒数 |
| OpenDurationSeconds | 180 | 各回の開放秒数 |
| SessionDurationSeconds | 86400 | Play開始からの全体有効秒数 |
| LogTransitions | true | 状態・周期が変わったときだけOutputへ出力 |

**Editで設定し、次のPlayから反映**する。ModuleScriptの値はそのPlay内でキャッシュされる。停止する場合はEnabled=falseにして次のPlayを開始する。値が非正数・無限・NaN、開放時間が開催間隔より長いなどの不正設定は無料開放しない。

時刻はサーバーの `time()`（そのゲームセッションの経過時間）。require・Player参加・死亡時刻を起点にしない。次のPlayは新しいセッションとなる。実装済みのサーバー時計は差し替えておらず、テスト時計は隔離fixture内だけに存在する。

- `0 <= t < 180`: 開放。
- `180 <= t < 1800`: 待機（27分間）。
- `1800 <= t < 1980`: 次の開放。
- 同じ周期を繰り返し、`t >= 86400` で全体終了。24時間ちょうどの新規開催はない。
- 開放中でも全体有効期間へ達したら終了する。
- 必須条件は **IsServer() AND IsStudio() AND IsRunning()**。公開ゲームではEnabled=trueでも常にイベント資格なし。
- 本番開催日・Creator Hubイベント・通知は設定していない。

完全にコードを外す場合は、このコミットの6 Source差分を確認して今回分だけ戻す。新規Moduleだけを先に削除すると既存2 Moduleの依存が残るので、通常の停止にはEnabled=falseを使用する。旧バックアップの一括上書きは、その後の編集を失うため行わない。

## 利用資格・購入・Strength

CanUseTreadmillは既存の登録タグ、World、ロード完了、PurchaseEnabled等を確認した後、Premiumに限り次のいずれかを認める。

1. 既存の正規資格（既存パス効果ゲート＋サーバーで確認済み所有）。
2. 開催中であり、設備のInstanceが実際の `Workspace.Treadmills.Diamond01` と一致する。

同名の別Model、World2 Premium、未ロード、別Worldには広げない。所有キャッシュ・HasPremium属性・保存データをイベント購入済みに書き換える処理はない。

開催中は設備接触側とGamePassService側の両方で購入要求を止める。所有確認APIが待機している間に開催が始まった場合も、戻った直後に開催を再確認して購入要求を止め、ロックを解除する。終了後は既存の非所有者処理へ戻り、乗り続けている場合にも既存の接触単位の購入処理を再開できる。毎フレーム購入要求を繰り返さない。

**既存0.5秒ループをそのまま使用**し、各加算の直前に資格・接地を再判定する。終了境界後の加算を認めない。新しい加算ループやPremium効果の付け外しキャッシュはない。強制死亡・転送はない。

source倍率は従来の `Premium基本7 + Belt + TrainingPotion`。StrengthManager内のStrengthパス＋1、装備・Rebirth・Potion・VIP・Pet等の既存計算を通る。最終倍率7/8固定や上限は設けていない。歩行・手動タップは既存のTreadmill占有判定と共通クールダウンに従う。

**既存Studio設定の注意**: `StudioDebugConfig.GamePassEffectsEnabled=false` と製作者向け無効設定を保持した。そのため現在のStudioでは、購入済みでも通常のパス効果ゲートが無効なら、イベント終了後は従来どおり使用不可となる。「正規資格が有効な所有者が終了後も継続する」検証はfixture内だけで効果ゲートをtrueにして行った。ライブ設定を全体解除していない。イベント中の正規購入は既存のサーバー再確認経路を維持し、イベント終了で所有を消す処理はない。

## Outputでの確認

開始・待機・再開・全体終了の状態変化時に `[StudioPremiumTreadmillEvent]` を1回出力。監視は1秒間隔で、加算判定はこのログ更新を待たず現在の時計を見る。ボードの既存2行は静的表示のまま。

PlayのServer側Command Barで、必要な時だけ次を実行できる。Edit時はDisabledとなるのが正しい。

```lua
local e = require(game.ServerScriptService.Services.World1PremiumTreadmillEvent)
print(e.Describe()) -- state / remaining / elapsed / nextStart
local p = game.Players:GetPlayers()[1]
if p then
    local t = require(game.ServerScriptService.Services.TrainingManager)
    local allowed, _, reason = t.CanUseTreadmill(p, workspace.Treadmills.Diamond01)
    print(p.Name, allowed, reason) -- StudioEvent / Owned / PremiumRequired
end
```

この確認は資格のみ。実際の加算には生存・接地・設備占有など既存条件も必要。

## 検証結果

[生の結果](simulation_results.json)、[spec](../../tests/StudioPremiumTreadmillEvent.spec.luau)、[既存回帰spec](../../tests/GamePassPhase1.spec.luau)。

### Edit内の隔離模擬実行

反映後の**実Studio Sourceを読み取り**、fake game/Players/Marketplace/時計/占有判定を渡してloadstringした。稼働サービスのrequireはしていない。既存PlayerDataServiceのAddStrengthGainとRecordStrengthGainの関数本文、LevelProgression、StrengthCalculation、StrengthManager、TrainingManager、GamePassService、AutoTapService、PlayerActionTimingを使用し、保存のないテーブルへ更新した。

イベントsuite **292 assertions**、イベントOFFの既存回帰 **245 assertions**。実DataStore/API/購入/Analytics送信は0。結果中のMarketplaceCalls=44は**モック呼出し回数**。実購入ではない。

| ケース | 結果・範囲 |
|---|---|
| 未購入・開始直後・Studioパス効果OFF | 0.5秒tickでメモリStrength **+7**。購入要求・所有API呼出しなし。所有属性を付与しない |
| 終了境界 | 180秒のtick以降は増加なし。継続乗車のsession解除・通常購入経路へ復帰 |
| 全周期 | 48周期の開始・179.999・180・1799.999秒、86400秒終了、短い全体期限による打切り |
| 途中参加・再接触・死亡 | 共通時計を維持。1900秒参加時に残り80秒。プレイヤーごとのsessionを分離 |
| 正規資格・イベント中購入 | モック所有再確認を通した所有者は効果ゲート有効時に終了後も継続 |
| OFF・Studio外・非Server・非Running | イベント資格なし。クライアント風の属性改変でも資格を得られない |
| 通常W1・W2・W2 Premium | 既存倍率・要求PassIdを維持。W1イベントでW2を無料にしない |
| 不正対象・ロード待ち・World移動 | 無料資格を認めず、稼働sessionのWorld変更後は加算停止 |
| 歩行・手動タップ | Treadmill中は別加算なし。退出後の既存加算と共有cooldownを維持 |
| 非接地・退出 | fixtureの占有条件をfalseにすると停止。**物理接地の実測ではない** |
| 後始末 | モック退出後にtraining workerを解消。テスト用時計・設定はライブへ持ち込んでいない |

同条件の1 tick比較：

| fixtureの条件 | 無料利用 | 正規利用 |
|---|---:|---:|
| 装備などの組合せ、Strengthパスなし | 660 | 660 |
| 同じ組合せ、Strengthパスあり | 726 | 726 |

組合せ: 基本1＋Dumbbell10＋Aura3＋Protein2＝16、Rebirth2、Premium7＋Belt2＋TrainingPotion1、StrengthPotion1.5、VIP1.1、Pet1.25。したがって `16*2*(7+2+1+[StrengthPass 0/1])*1.5*1.1*1.25`。さらにBelt20の条件も上限なしで一致。装備サービス自体は固定入力のモックで、実Playerの所有品は取得していない。

再実行には [edit_simulation_runner.luau](edit_simulation_runner.luau) にチェックイン済みspec全文を `TestSource` として渡す。runnerは対象IDとEditをassertし、現行Sourceを取得する。実ゲームのModuleをrequireしたり、このファイルを常設ScriptとしてStudioへ置いたりしない。

### 静的・Studio現物確認

- 実対象はタグTrainingTreadmill付き `Workspace.Treadmills.Diamond01`。Area位置(341.2232056,12,-38.9980087)、サイズ(9.4706211,15,16.3103905)を維持。
- 全14設備のArea、既存ボードの記録値、TrainingController/StudioDebugConfigのSourceが変更前と一致。
- 6対象Sourceの構文・Editor一致、Controller Enabled=true、Edit・PlaceVersion746を確認。
- 終了資格はTrainingManagerの既存tick内で再評価。歩行/タップ排他・加算周期・実Strength式・保存処理は変更なし。
- テスト用Instanceやサービス差し替えをStudioへ配置していない。

### 実Play・未確認

**今回の実Playは0回。** `ServerScriptService.Config.DataStoreConfig` の `_Studio` 接尾辞は保存先名の分離であり、保存なしのメモリ隔離ではない。既存Phase1もEdit模擬、過去の物理検証は別Place等を使っており、今回許可された現在のStudio内だけで安全に使えるPlay隔離を確認できなかった。通常Playで実データを使うこと、新Place/RBXLの作成、多数の無関係サービスの差し替えは行っていない。

したがって、実キャラクターでの乗車・接地・Strength画面の増加、実プラットフォーム購入UIの抑止、実購入・死亡復帰・途中参加・通信順序、2クライアント、端末実機、1800秒/24時間の壁時計連続稼働は未確認。境界と購入後継続は上記の模擬結果であり、実Play合格とは扱わない。

**次のユーザーPlayで初回180秒が始まるコード・最終Configを実Mapへ反映した状態**で残している。次の確認は未購入状態で対象台へ接地し、OutputのOpen・通常のStrength増加・購入画面非表示を確認すること。実Playerデータ保護を保証する検証環境は、本報告の模擬fixtureとは別途必要になる。

## 引き渡し

今回のコード・テスト・記録だけを通常commit/push対象とする。ゲームSave/Publish、Creator Hub公開、通知送信、新Studio/Place/RBXL作成は未実施。検証一時物なし。既存の編集と完成済みボードを保持した**未保存EditでStudioを開いたまま**。

参考: [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService)、[RobloxGlobals.time](https://create.roblox.com/docs/reference/engine/globals/RobloxGlobals#time)。サーバー時計の解釈とStudio判定に使用。
