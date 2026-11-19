# World1 Premium Treadmill — 公開環境対応・JST指定日・残り時間表示

2026-11-19。**公開環境で動作する開催判定とUIを実装し、副本Studioへ反映済み。公開・本番検証は未実施。** 開催日は未指定、現在は無料開放・ボード・上空表示が無効。

## 接続・保全

- Y01 / DESKTOP-CNFVEH2。既存Studio `b69bc527-9db7-4688-bd3c-082384af0a87`、PlaceId **126576845524886**、UniverseId **10765181857**、PlaceVersion **746**、Edit。
- 作業フォルダー `C:\Users\kouji\Smash_and_Crush\AnalyticsSpawnItems`、Repository `koujiyoshimura54-crypto/Smash_and_Crush`。
- 開始HEADとfetch後mainは `1dcc5ae52e91e03616a2ac1816df143d631ae8db`。開始時の追跡変更なし、既存未追跡 `crashes/` は変更・stageしていない。
- [変更前Source/Editor一致記録](before_sources.json)、[変更前GUI/設備の型付き値](before_geometry.json) を保全。
- ボードは前回の報告から移動されていた。**今回の実位置**（Board中心約288.74094,31.21864,80.937）を基準に保持し、前回位置へ戻していない。本体2 PartのCFrame・Size・物理属性、既存Treadmillの記録対象値は一致。
- `StudioDebugConfig`、`DataStoreConfig`、`TreadmillUIClient` のSourceを維持。旧Main2件はDisabled=trueのまま。Weather表示の旧起動経路は有効化していない。

## 開催日を設定する場所・停止方法

**`ServerScriptService.Config.World1PremiumTreadmillEventConfig`**

| キー | 現在値 | 意味 |
|---|---|---|
| Enabled | true | 設定を許可するフラグ。日付が空なので現在は開催されない |
| EventDateJST | `""` | 手動入力する開催日。厳密な `YYYY-MM-DD` |
| StartIntervalSeconds | 1800 | 開始から次の開始までの秒数 |
| OpenDurationSeconds | 180 | 各回の開放秒数 |
| LogTransitions | true | 状態遷移時のみOutputログ |

指定日JST 00:00を含み、翌日JST 00:00を含まない1日。UTC開始は指定日00:00をUTCとして組み立てた値から9時間を引き、終了は＋86400秒。OSのタイムゾーンやサーバー起動時刻を使わない。閏年・月の日数・書式を検査する。未指定、不正日付、非整数/非正数/非有限秒数、180秒より短い間隔などの不正設定では資格・表示とも無効。

開放は開始を含み終了を含まない。初回はJST 00:00〜00:03、次は00:30〜00:33。既定値の最終回は23:30〜23:33。23:33〜24:00はボードの上2行を残し、時間行を隠す。翌日に架空のNextを出さない。日付終了で本体も非表示。

**設定はサーバー起動時に読み込む。** StudioではEditで変更した後のPlayから反映。公開時には同一の設定・Sourceを全稼働サーバーへ展開する必要がある。既に動いている旧バージョンのサーバーへ、このローカルConfig編集だけで即時反映する仕組みは追加していない。

停止は `Enabled=false`（または日付を空欄）へ変更し、同じ設定を稼働サーバーへ反映する。現在のサーバーでの即時停止を保証するクラウドスイッチではない。Save/Publish・稼働サーバー更新は今回は実施していない。

旧 `SessionDurationSeconds` とPlay開始からの `time()` 起点は廃止。試験時計・試験日・Studioだけの資格ガードは製品コードに残していない。公開時もIsServer必須、現在時刻は `Workspace:GetServerTimeNow()`。途中参加・再参加・死亡復帰・後から起動したサーバーでも、同じ設定・絶対時刻なら同じ周期。

## 変更Full Path

| Full Path | 内容 |
|---|---|
| `ServerScriptService.Config.World1PremiumTreadmillEventConfig` | JST日付設定。日付空欄 |
| `ServerScriptService.Services.World1PremiumTreadmillEvent` | サーバー私有の検証済み期間・絶対時刻による資格 |
| `ServerScriptService.Services.World1PremiumTreadmillEventSchedule` | 既存参照の互換窓口。共通計算Moduleへ委譲 |
| `ServerScriptService.Systems.Controllers.World1PremiumTreadmillEventController` | 表示用期間を1回複製、状態ログ |
| `ServerScriptService.Services.TrainingManager` | 診断理由名StudioEvent→Eventのみ。前回の既存加算・購入抑止連携を共用 |
| `ServerScriptService.Services.GamePassService` | 診断理由名StudioEventAccess→EventAccessのみ |
| `ReplicatedStorage.Modules.World1PremiumTreadmillEventSchedule` | 共通の日時検証・境界計算・残り時間文字列 |
| `ReplicatedStorage.Config.World1PremiumTreadmillEventStyle` | 共通の手動UI調整値 |
| `ReplicatedStorage.Modules.World1PremiumTreadmillEventPresentation` | 既存ボード・上空の表示反映 |
| `ReplicatedStorage.Modules.World1PremiumTreadmillEventClientRuntime` | 1つの更新ループ、再初期化・Streaming・終了処理 |
| `StarterPlayer.StarterPlayerScripts.UI.World1PremiumTreadmillEventClient` | 上記rendererを起動するLocalScript |

11 SourceすべてでStudio Source・Editor・ローカルの一致と構文コンパイルを確認。[反映・保護属性・最終状態](verification.json)。

追加/変更した表示Instance：

- `ReplicatedStorage.World1PremiumTreadmillEventState`：StringValue。サーバーが作成する表示専用のUTC期間JSON。
- `Workspace.EventBoard.Board` / `Workspace.EventBoard.Part`：非表示時Transparency=1、開催日中はRGB(24,24,24)・Transparency=0.5へ復元。位置・サイズ・衝突設定は保持。
- `Workspace.EventBoard.Board.SurfaceGui`：既存GUIのEnabledを切替。
- 同GUIの **Event1 / Event2 / Event3** と既存UIStroke・UIListLayoutを再利用。TextLabelは3個のまま。
- 同GUIの `PremiumEventPadding`：上部余白用のUIPaddingを1個追加。ボード子孫11→12、ボード/SurfaceGui/ラベルの複製なし。
- `Workspace.Treadmills.Diamond01.Area.PremiumEventCountdown`：BillboardGui 1個。子の `Time` とUIStroke。Part・物理Constraintは追加なし。

GUIのGitからの再適用は [tools/ApplyPremiumTreadmillEventPresentation.luau](../../tools/ApplyPremiumTreadmillEventPresentation.luau)。現在のSourceとConfigを読み、既存のボードへ適用するEdit専用ツール。日付を補完せず、Save/Publish/Playはしない。Sourceの反映とGUI再適用は別手順。旧 `ApplyEventBoardAppearance.luau` は過去の静的2行用なので、この実装後の復元には新ツールを使用する。

## UI仕様・手動調整

**`ReplicatedStorage.Config.World1PremiumTreadmillEventStyle`** が共通設定。変更は次のPlayで読み込み、Editの見た目へは上記ツールで適用できる。

| 設定 | 現在値 |
|---|---|
| TitleTextSize / FreeTextSize / TimeTextSize | 60 / 100 / 52 px |
| TitleHeight / FreeHeight / TimeHeight | 0.28 / 0.38 / 0.22（キャンバス比率） |
| RowWidth / RowGap / TopPadding | 0.94 / 0.02 / 0.04 |
| FreeColor | RGB(255,65,65)、赤 |
| OpenColor | RGB(255,224,102)、黄色 |
| White | 白 |
| StrokeSizingMode / StrokeThickness / OpenStrokeThickness | FixedSize / 2 px / 4 px |
| OverheadOffset | Area中心から (0,16,-8) studs |
| OverheadSize / OverheadTextSize | 150×44 px / 34 px |
| OverheadMaxDistance | 100 studs |
| RefreshSeconds | 0.1秒、ローカル時計の確認間隔 |

1段目 **Premium Treadmill**、2段目 **Free**、3段目 **Next 26:59** または **Now! 02:59**。大小文字・記号を固定し、AutoLocalize=false。FredokaOne、不透明文字。Freeが最大、タイトルは旧48→60px。開放中の時間行は黄色＋太い縁取り、待機中は白＋通常縁取り。

既存UIStrokeはScaledSizeだったため、px値を入れるだけでは太すぎる描画になることをEditで確認し、共通StyleのFixedSizeへ合わせた。UI内側の背景は透明のまま。日付・説明文・追加見出し・終了文言を追加していない。

上空は `02:59` のような時間だけ。AreaをAdorneeにして相対オフセットで追従し、既存Premium/×7 Strengthの上に配置。AlwaysOnTop=falseで、既存の地形等による遮蔽は残す。近接視点では既存倍率と重ならず読めることを確認した。遠方の1視点では既存の手前オブジェクトに遮られたため、その状況まで常時可読とはしていない。

## 権限・同期・負荷

- 利用資格はサーバー内のConfigから生成した私有Planのみを参照。表示用StringValueやクライアント属性の改変では資格を取得できない。
- 表示用期間は単一JSON値として起動時に複製。毎秒RemoteFunction照会、DataStore読書き、開催通知は追加していない。
- サーバーとクライアントは同じSchedule計算・同期されたサーバー時刻を使用。秒数は非負・切上げ、開放終了後にNow! 00:00を表示しない。
- クライアントは0.1秒間隔で対象の固定パスと時計を確認。全Workspace探索なし。Textは秒/状態の変化時だけ代入する。時計同期誤差や描画更新間隔までゼロにする保証ではない。
- Runtime Moduleが前回の更新・破棄接続を解除してから再初期化。Characterに依存せず、死亡復帰で別ループを作らない。
- Streaming途中は不足する既存GUIを待ち、クライアントで代替GUIを作らない。遅れて複製されるGUIとの二重表示を防ぐ。対象再出現時に再バインド。
- TrainingManagerの既存0.5秒ループ、毎加算直前の資格・占有・接地確認を保持。正規資格 OR イベント中のDiamond01だけに一時資格。
- 所有キャッシュ・所有属性・保存を購入済みに変更しない。基本7＋Belt＋TrainingPotion＋StrengthPass等の既存合成を通り、7/8の上限なし。歩行/手動タップの排他は維持。
- 購入要求前と所有確認がyieldした後の開催再判定、終了後の既存購入経路は前回実装を保持。World2・通常台へ無料資格を広げない。
- Studio全体のパス効果無効設定はfalseのまま。正規所有者もその既存ゲートが無効なら、Studioでは従来どおり通常効果を受けない。正規資格が有効な所有者の終了後継続をfixtureで検証した。

## 検証の区分

[実行結果・描画確認値](tests_and_visual_checks.json)、[最終GUI値](after_geometry.json)、[Sourceハッシュ](source_manifest.json)。

**Editでの実描画・実値確認**

- 現在のMapの既存ボードを、PC正面/斜め・iPhone 17 Pro横向き相当で表示。3段の可読性、Freeの赤、Now!の黄色、Nextの白、欠け・重なりを確認。
- 上空表示は接近視点で×7 Strengthと分離して表示。画面を覆うサイズではない。
- 各TextFits=true。Title bounds456×60 / 領域658×80.64、Free180×100 / 658×109.44、Now227×52 / 658×63.36 px。
- これはfixture時刻で表示関数を呼んだ**Editの描画**。実Playの配信・通信・実乗車を確認した結果ではない。スマホ実機性能の検証でもない。
- Device Simulator、既存HUD Enabled、選択を元に復元。描画確認画像はAGENTSに従い検査用のみ、Gitへ保存していない。

**反映後のSourceによる隔離・模擬確認**

| 範囲 | 結果 |
|---|---|
| 日付・絶対時計の純粋計算 | 70 assertions。未設定/OFF/不正書式/存在しない日/閏年/不正秒数、開始直前/一致/直後、180秒/1800秒、最終待機/日末、異なる起動時刻、切上げ |
| 既存Training→Strength→メモリ更新 | 283 assertions。公開サーバー相当、無料/正規同値、各tick失効、ボーナス合成、購入確認またぎ、参加/死亡/再接触/World条件、クライアント風改変 |
| イベントOFFの既存パス回帰 | 245 assertions。通常W1/W2/Premium、歩行・手動タップ排他、既存正規購入経路 |
| 実GUI Instance＋クライアントRuntimeのfixture | 32 assertions。上空/ボード同秒、状態色復元、最終待機、対象/Frame/ラベル/上空GUIの部分再出現、再初期化、所有Script破棄、20回同秒更新でText変更0 |

加算の代表比較は、同じ装備等の条件で無料/正規とも **660**、Strengthパスを加えた同条件で双方 **726**。Studio効果OFF・未購入の無料資格では基礎 **+7/tick**。Belt20のケースでも上限なし。これらは既存AddStrengthGain/RecordStrengthGain本文とLevelProgressionを使った**保存なしのメモリ更新**。実Playerの獲得実測ではない。

テストの2040-02-29等はfixture内だけ。現行Configの空欄をassertしてからfixture用コピーへ日付を入れた。製品Configや時計を差し替えていない。結果中のMarketplaceCallsや購入要求はモック回数で、実API呼出しではない。

再実行は [edit_test_runner.luau](edit_test_runner.luau) へ該当spec全文をTestSourceとして渡す。旧ファイル名の `tests/StudioPremiumTreadmillEvent.spec.luau` も現在の公開日時方式へ更新した。履歴commit 1dcc5aeのspecは当時のStudio試作用。
他のspecは `tests/PremiumTreadmillEventCalendar.spec.luau`、`tests/PremiumTreadmillEventPresentation.spec.luau`、`tests/GamePassPhase1.spec.luau`。

**実Play・公開環境・未確認**

実Playは今回も未実施。現在のDataStoreConfigは保存名へ `_Studio` を付けるだけで、保存なしの隔離を保証しない。現在のStudio内で使用できる安全なPlay経路を確認できず、別Place/RBXL作成や無関係サービスの一括差し替えは行っていない。

実キャラクターでの乗車・接地・Strength画面増加、実購入ポップアップの抑止/終了後再開、実購入後継続、実Playerの途中参加/死亡復帰、実際のStreaming/複数クライアント通信、公開サーバー間同期、スマホ実機、長時間稼働は未確認。模擬件数をそれらの合格根拠とはしない。

## 手動Save/Publish前に残る確認

1. 開催日を決め、ConfigのEventDateJSTへ入力。JSTの対象日とUTC変換、1800/180を再確認。
2. 保存・実購入を遮断した安全な実Playで、対象台への接地、Strength増加、終了後停止、正規資格継続、購入画面抑止/復帰を確認。
3. 実クライアントでの遅延参加・死亡・自然Streaming、ボード/設備表示を確認。
4. 公開時は全サーバーへ同じバージョン・Configを反映する手順と停止手順を確認。未設定の現状をPublishしてもイベントは始まらない。

## 引き渡し

日付 **空欄** / Enabled=true / 検証済みPlan.Valid=false, Reason=DateUnset。無料開放・ボード・上空は **無効**。検証用日時・補助InstanceはDataModelに残していない。追加したGUI、表示用StringValue、Sourceは製品実装。

既存の未保存編集を保持したEditでStudioを開いたまま。Play/Stop、Save/Publish、別Studio/Place/RBXL作成、Creator Hub公開、通知送信、実DataStore/購入APIの操作なし。今回分だけ通常commit/pushし、force push・他worktree・stashは操作しない。

参照: [Workspace.GetServerTimeNow](https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow)、[DateTime.fromUniversalTime](https://create.roblox.com/docs/reference/engine/datatypes/DateTime#fromUniversalTime)、[UIStroke](https://create.roblox.com/docs/reference/engine/classes/UIStroke)。端末相当確認にはRoblox `rbx-device-simulator-lua` 手順を使用。
