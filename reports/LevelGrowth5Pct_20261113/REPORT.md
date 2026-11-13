# LV131以降の必要Strength +5%（2026-11-13）

正本 PlaceId **126576845524886** / UniverseId **10765181857** の未保存Studioを基準に実装。開始時・反映前に取得した main は **9898d9e91a719f520db5a2647da4811e969ef3eb**。今回の対象Sourceはmainと一致していた。正本のPlayは開始・停止していない。正本は最後も **未保存Edit**、Save／Publish・保存GUI・Placeファイル書込みなし。

## 結果と変更箇所

| 変更Full Path | 理由・実装 |
|---|---|
| `ReplicatedStorage.Config.LevelRequirements` | Q(1〜130)を両曲線とも維持。Q(131)から `ceil(Q(L-1)*1.05/10)*10`。LV201以降も同じ式。最大LV10000を維持。旧プロフィール復元用の元の表を独立して保持。 |
| `ReplicatedStorage.Modules.StrengthHUDPresentation` | 既存略記の上限を超える1e36以上を有効数字3桁の指数表記へ。例1e100→`1.00e100`。変更前に長いDc表記のはみ出しを実描画で再現したため。 |

[必要量Source](../../src/ReplicatedStorage/Config/LevelRequirements.luau#L65)、[表示Source](../../src/ReplicatedStorage/Modules/StrengthHUDPresentation.luau#L45)。製品コードの変更はこの2つだけ。LVUP・保存・再生処理やHUDの配置／フォント／最小文字サイズは変更していない。Boss、壁、World2 Treadmill、身体成長、チュートリアルは今回の差分に含まない。

Q(201〜10000)はModule初回読込時に一度計算し、取得は表引き。累計取得は既存の加算ループを維持。`Post200StrengthPerLevel=250000000` は旧形式復元のために残すが、通常進行には使わない。追加の移行フラグ・保存バージョンはない。

## 修正前に確認した実際の経路

| データ／経路 | 確認した役割・根拠 |
|---|---|
| Strength | 所持戦力。通常獲得では獲得量だけ加算する。過去にLVUPで消費した進捗を引き戻す用途ではない。 |
| Level / LevelProgress | 保存済みLVと、そのLV内の獲得済み進捗。追加gainを進捗へ足し、現在LVのQを順に消費する。総Strengthからの通常再計算ではない。[LevelProgression:23](../../src/ReplicatedStorage/Modules/LevelProgression.luau#L23) |
| LevelProgressVersion=1 | 進捗保存形式の識別。未対応値は拒否。Levelまたは進捗がない不完全なversion付きデータも拒否。 |
| LevelCurveVersion=1 / 2 | 育成サイクルの序盤必要量と再生条件を選択。新規は2、既存で欠落は1。今回両方の高LVだけ共通変更する。LV1／Strength0から新規推測しない。 |
| 歩行／手動鍛錬 | AutoTapService→StrengthManager.AddStrength→PlayerDataService.AddStrengthGain→LevelProgression.ApplyGain。[AutoTapService:43](../../src/ServerScriptService/Services/AutoTapService.luau#L43)、[StrengthManager:165](../../src/ServerScriptService/Services/StrengthManager.luau#L165) |
| Treadmill | TrainingManagerの既存0.5秒処理→同じAddStrengthへ倍率を渡す。占有条件・周期・倍率の変更なし。[TrainingManager:209](../../src/ServerScriptService/Services/TrainingManager.luau#L209) |
| Strength報酬 | AddRewardStrengthは計算済み報酬を追加倍率なしで同じcommitGainへ。永続報酬もStrengthRewardPersistenceから同じProgress.ApplyGainを使用。[Persistence:18](../../src/ServerScriptService/Services/StrengthRewardPersistence.luau#L18) |
| 読込 | PDS normalize→Progress.Normalize→Advance(..., gain=0)。保存済み余剰を消費してから属性を公開する。Levelがない古い形式だけCalculateLevelを使う。[PDS:328](../../src/ServerScriptService/Services/PlayerDataService.luau#L328)、[Progress:6](../../src/ReplicatedStorage/Modules/LevelProgression.luau#L6) |
| 保存・報酬スナップショット | Level／LevelProgress／両Versionを保存。StrengthRewardのBeforeとTimeRewardのSnapshotにも曲線情報が既にある。既存所有権・書込み直列化・再試行を利用。[PDS:1025](../../src/ServerScriptService/Services/PlayerDataService.luau#L1025)、[PDS:2063](../../src/ServerScriptService/Services/PlayerDataService.luau#L2063) |
| 再生 | 現サイクルのRebirthConfig条件で判定。正常成立でStrength0/LV1/進捗0/曲線2。保存待ちや未解決報酬は拒否。条件・倍率は変更なし。参考累計は同じ必要量を参照。[PDS:899](../../src/ServerScriptService/Services/PlayerDataService.luau#L899) |
| HUD | サーバー属性のLevel／LevelProgress／LevelCurveVersionと同じGetRequiredStrengthから分母・割合を計算。関連属性の通知をまとめて再描画。[StrengthDisplay:28](../../src/StarterGui/StrengthGui/StrengthDisplay.client.luau#L28) |
| SetStrength | 管理用の所持Strength代入で進捗は付与しない。変更前の実サービスでもLV／進捗が変わらないことを確認。通常獲得の不具合とは扱わない。 |

旧CalculateLevelは歴史的な「必要量を閾値とする検索」であり、累積和での検索ではない。その意味と最初の7閾値、旧LV51〜200式、旧LV201以降の線形式を保持した。通常のGetRequiredStrengthへ依存させたままConfigだけ変える方法は採っていない。

## 必要量の前後

**遷移元LV125〜205の81行全表：[Requirements125To205.csv](Requirements125To205.csv)**。この範囲は両曲線共通。列は遷移元／遷移先と実際のLuau numberを整数表示した値。大きな旧値には既存の浮動小数点誤差が含まれる。

| 遷移 | 変更前Q | 変更後Q |
|---|---:|---:|
| LV130→131 | 2,655,045,539,870 | 2,655,045,539,870 |
| LV131→132 | 3,334,737,198,080 | 2,787,797,816,870 |
| LV132→133 | 4,190,764,236,830 | 2,927,187,707,720 |
| LV136→137 | 10,510,823,745,140 | 3,558,014,953,670 |
| LV200→201 | 85,207,248,960,711,180,288 | 80,783,545,414,780 |
| LV201→202 | 85,207,248,960,961,183,744 | 84,822,722,685,520 |

## 引継ぎと保存の実測

PlaceId 0の別Studioで、現在StudioのSourceと実StrengthGuiを使用したネイティブPlayを実施。PlayerDataService／所有権管理／StrengthManager／進捗／保存／報酬処理は現行コード。外部DataStore・購入・Badge・Messaging・Analyticsだけをメモリ依存へ置換。境界値は検証用注入で設定した。自然育成ルートや公開DataStoreの再参加テストではない。

| ケース | 実サービス結果 |
|---|---|
| 変更前 LV136・進捗4兆・Strength123456 | 保存→読込でLV136／進捗4兆のまま。通常+.5、台倍率5の+.5、報酬+7で生Strength123466、進捗4000000000010。 |
| 変更後 LV136・進捗4兆・Strength9001（両曲線） | 読込でLV137／進捗441985046330／Strength9001。2回の保存→再読込も同一。 |
| 複数LV分の保存進捗 | LV131／進捗8788532617700.5／Strength1234→LV134／進捗0.5／Strength1234。 |
| LV129・130・131・136・199・200・201 | 両曲線×未達0.25／一致／超過0.25、通常加算と報酬で結果一致。小数を保持。 |
| 大きな一括加算 | LV131から3LVUPし、余り0.5。通常加算後の保存→再読込も同一。 |
| 新規／既存曲線欠落 | 新規は1/0/曲線2。欠落した既存サイクルは曲線1で上記繰越。 |
| Level未保存の旧形式 | Strength1e14から旧式通りLV145／進捗0を復元。その後、新Q(145)の報酬でLV146／進捗0。 |
| 保存失敗／応答消失 | 失敗前後の状態と再送後の保存・再読込で二重LVUP／巻戻りなし。 |
| 永続Strength報酬 | 書込み前失敗／書込み後応答消失→同じ操作再送。+20は1回、LV137／進捗10／Strength1020。 |
| 報酬保存待ち中の通常+3 | 再生・二重受付は拒否。報酬+20と合計+23、LV137／進捗13／Strength1023。次の保存→読込も一致。 |
| 通常保存待ち中の+3 | 実行中の加算を古い保存応答で上書きしない。次の保存→読込でLV137／進捗1／Strength1003。 |
| 再生 | 両曲線の条件未達／到達／二重操作を確認。既存曲線1の再生後は曲線2。保存応答消失→再送→読込でも回数2、LV1／進捗0／Strength0を保持。 |
| 最大LV | 9999→10000。その後Q(10000)の2倍を加えても10000で止まる。進捗は既存仕様どおり保持、HUDはMAX。 |

ネイティブサービス検証は**最終60ケース成功**、別途複数LV読込・再生保存再試行・精度限界を実行。初回の報酬3ケースは、補助がメモリ保存側に報酬履歴を置かなかったためRewardUnavailableとなった。通常Saveが永続履歴を保持する仕様を確認し、**補助データだけ**を修正して3ケースを再実行し成功。失敗記録も[Evidence.json](Evidence.json)に残す。

保存前のサーバー消失など、既存の未保存進捗が失われる可能性を解消したという意味ではない。実DataStoreの競合・通信・公開再参加は未実施。

## HUD・端末表示

実StrengthDisplayのサーバー属性複製→再描画を12状態で確認。LV、丸め／略記された分子・分母、割合は全状態で一致。連続3LVUP後は `Lv.134`／`1 / 3.23T`（生進捗0.5は既存整数丸めで1）、割合1.54931894e-13となり、古い分母は残らない。曲線1→2のLV1表示は `4 / 7`→`4 / 5`、割合0.5→約0.7。

| 確認区分 | プリセット／実Camera.ViewportSize | 結果 |
|---|---|---|
| 隔離Play・PCエミュレーター | average_windows／1366×763 | LV131・201・9999・10000、繰越例。分母／ゲージ一致。 |
| 隔離Play・スマホ横画面エミュレーター | iphone_17_pro／747×380 | 繰越例とLV9999の指数表記。分母／ゲージ一致。 |
| 隔離Play・タブレット横画面エミュレーター | ipad_pro_M5_13in／1371×1030 | 繰越例・巨大値・序盤両曲線・連続LVUP。分母／ゲージ一致。 |
| 実機・公開環境 | 未実施 | 実機タップ／公開受信／公開保存の合格とはしない。 |

プリセットの公称解像度と実ビューポートは異なるため実測値を記載。変更前の1e100はExp幅454.3pxに対しTextBounds1326pxで明確にはみ出した。変更後は指数表記でLV／進捗文字が枠内に収まり、スクリーンショット上の文字重なりは観測しなかった。最小フォントは既存の48を保持。画面は確認後に保存・コミットしていない。

**残る表示制限**：所持Strength／単位の既存自動幅計測には縮尺による端数差があり、`TextFits=false` が残る。例PC `100T`はTextBounds92px／幅91.918px、スマホ`9K`は24px／23.497px、指数表示時PCの`Strength`は141px／139.910px。LV／進捗欄の全確認状態はTextFits=true。微小なラベル幅超過までゼロとは報告しない。今回は画面の再設計やフォント縮小範囲の拡大は行わない。

## 数値・負荷・精度の限界

LuauネイティブでQ(1〜10000)の正数・有限・単調性、両曲線のQ(1〜130)一致、Q(131+)式、累計有限値、旧復元比較、指定6値を確認。**40,044 assertion成功**。これは計算検証であり、これだけを実Play成功の根拠にはしていない。

- Q(10000)≈3.65135278008665e221、LV10000到達累計≈7.302705560173296e222。NaN／Infinityなし。
- 全数検査（1000回ごとのフレーム待機を含む）約0.147秒。累計LV10000取得5回で約0.00509秒。単一PC上の測定でありモバイル負荷保証ではない。
- Q130を起点に整数演算で厳密な十進式を再計算すると、初差は**Q301**：実数11154294727106170／厳密11154294727106180（差-10）。
- 最初に表現された値が整数として10の倍数から外れるのは**Q311=18169170746475248**（末尾8、ULP4）。
- Q340ではULP16となり、10単位の値を全て区別できない。
- Q299=10117274128894480付近で+1が消える。実PDSでLV300、Strengthと進捗をこの値にした後、通常+1を実行して**両増分0**を確認。有限値でも小さいgainの保持は保証されない。
- 同じ「Q付近へ足す」比較で、+.001消失がQ169、+.25がQ269、+.5がQ283、+10がQ354、+1000がQ439から観測された。進捗が0付近なら同じLVでも小加算を保持できるため、LVそのものの一律停止境界ではない。
- Q10000付近のULP≈8.02633e205。累計・連続減算も浮動小数点であり厳密整数ではない。

[Precision.json](Precision.json)はPython整数演算との比較、Evidenceのadditional.precision／smallGainはLuauと実サービスでの照合。Luauの巨大数に対する剰余演算も10刻みの正確さを保証しないため、整数へ展開した値でも確認した。ユーザー指定どおり、任意の上限追加・丸め方式変更・大規模数値システム置換はしていない。

## 保持・清掃・未確認

正本の78関連SourceとScriptEditorServiceの内容を照合し、変更2・維持76、食い違い0。Studio側に存在するOreConfig／UISoundConfig／SlapPassConfig／Modules.Config／ElementSetBonus等のmainとの差分、Gitに不足する現行依存も、復元せず保持した。これらは今回のGit差分に含めない。

検証Studioでは外部依存の置換、データ注入、診断Scriptを使用。自分のPlayを停止し、端末シミュレーターを解除、検証Source・Remotes・GUI・Spawnを除去（残Source0）してから、確認済みの隔離プロセスだけ終了した。正本へ補助は一度も追加していない。正本はEditのまま。取得した隔離Playコンソールは変更前・変更後とも空で、関連Runtime Error／Warning／Infinite Yieldなし。意図した保存例外は失敗戻り値として記録した。

未確認：実機、公開環境／本番DataStore、実課金、フルゲームの全ルート、物理歩行やTreadmillへの入退出の再検証、自然な高LV到達、複数公開サーバー競合、保存前のプロセス消失。今回の加算検証は実サービス入口で行い、接触不具合の再検証と混同しない。

## Git提出

この報告書・数値表・証拠・関連SPECと2 Sourceだけをcommitし、`origin/main`へ通常pushする。PR #1はopen/draft/unmergedを確認し、変更・マージしていない。コミットとpush結果は[Delivery.md](Delivery.md)に記録する。過去の報告書は変更しない。

**Studioは未保存。Save／Publish未実施。**
