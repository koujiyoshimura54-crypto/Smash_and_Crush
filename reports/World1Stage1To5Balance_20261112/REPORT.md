# World1 Stage1〜5バランス・LV曲線・再生条件 — 2026-11-12〜13

**指定値とサイクル別曲線を実装した記録。全体1.5倍、描画／モバイル、複数プレイヤーの物理経路は合格条件を満たしていない。実装確認と未達・未確認を分けて記載する。**

正本：未保存Studio PlaceId126576845524886、UniverseId10765181857、取得時PlaceVersion577。開始時mainは `35ed907496d40953e2514369c367b74c21a14304`。既存の未保存Studioを比較基準にした。GitHubからPlaceやSource全体を復元していない。PR #1はopen／draft／未マージ、開始時head `67a9ca51522b24d02c711f1d339e4a4cf349d653`。[開始Git監査](start_git_audit.json)。

## 1. 変更前の実装と変更Full Path

Stage1手動変更（壁50/75/100/135、Boss200、推奨LV4）と前日の短縮案Q(1〜7)=7/20/33/60/95/145/170は、開始時Studioへ既に入っていた。mainとの差分を古いコードに戻さず、この状態で変更前Playを行った。PR #1の該当実行コードとも一致するが、PR全体は取り込まない。mainに欠けていたLevelProgressionは、現在のStudioから取得した実Sourceを基に今回追跡する。過去fixtureを現行モジュールに流用していない。

変更前18 Sourceは [before/](before/)、改行を含む取得時文字列は [before_sources_exact.json](before_sources_exact.json)、SHA256は [source_manifest.json](source_manifest.json)、全499 Sourceと画面方向の開始記録は [studio_before_manifest.json](studio_before_manifest.json)。Stage1WallManager／BossCombatService／StrengthManager／World2Config等は確認対象で、今回の本体変更対象ではない。

| Full Path | 今回の変更理由 |
|---|---|
| ReplicatedStorage.Config.World1BossConfig | Stage1〜5の指定HP・推奨LV。固定壁とStage6以降の派生壁を分離した既存構造を維持 |
| ReplicatedStorage.Config.LevelRequirements | 変更直前曲線1を保持し、新曲線2のQ1〜29を追加。選択曲線の累計・必要量を提供 |
| ReplicatedStorage.Modules.LevelProgression | 保存形式Version1を維持し、曲線に沿ったNormalize／Advance／ApplyGain。実Studio由来の不足ファイルをGitへ追加 |
| ReplicatedStorage.Config.RebirthConfig | 新旧の再生条件と、同じ曲線によるReferenceStrengths |
| ServerScriptService.Services.PlayerDataService | 新規判定・曲線の保存／複製・報酬snapshot・原子的な再生切替。既存所有権管理とSaveを使用 |
| ServerScriptService.Services.StrengthRewardPersistence | 再送可能な報酬snapshotの曲線を永続結果にも保持 |
| ServerScriptService.Systems.Controllers.RebirthService | 保存Dataの曲線／LV／回数による検証とTryRebirth。既存Gain端数リセット・応答・Badge経路を維持 |
| ServerScriptService.Systems.Debug.StudioStartController | 現在サイクルの曲線でプレビューLVを計算 |
| StarterGui.StrengthGui.StrengthDisplay | サーバーと同じ曲線の必要量をLVゲージに表示し、曲線変更時も更新 |
| StarterGui.StrengthGui.RebirthMenuClient | 同じ曲線の再生条件を表示し、曲線変更時も更新 |
| StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient | Studioでは既存編集をそのまま保持。mainに不足していたStrength10の初期案内条件を関連変更として記録 |

PDSのゼロ加算時の余剰進捗正規化も開始時Studioの既存編集を保持した。Tutorial Sourceは改行を含め開始時と同一。UIのサイズ・位置・画像・色、Ore5スロット、横画面、左Menu70%、Trophy、PetEggの×、通知を再設計していない。初期AutoTap OFFは既存のロード経路を維持する。

値の経路：World1BossConfig → Stage1WallManagerの互換Config／BossCombatService／BossVisualPlacement → EnemyManagerの本人別HP・状態通知 → CombatClientのHP・推奨LV表示。LevelRequirements → LevelProgression → PlayerDataService.AddStrengthGainと保存／報酬snapshot。StrengthManagerは現在の保存LVを参照し、Gain倍率は変更しない。RebirthConfig → PDS.TryRebirth／Controller／RebirthMenuClient。純粋Configからサービスへ戻るrequireはなく、循環依存を追加していない。

## 2. HP・推奨LVの前後

| Stage | 変更前の壁1/2/3/4 | 指定後の壁1/2/3/4 | Boss前→後 | Stage合計前→後 | 推奨LV前→後 |
|---|---|---|---:|---:|---:|
| 1 | 50/75/100/135 | 50/75/100/135 | 200→200 | 560→560 | 4→4 |
| 2 | 300/325/350/425 | 275/300/320/390 | 2250→1800 | 3650→3085 | 10→8 |
| 3 | 600/750/900/1200 | 565/705/845/1130 | 12500→10000 | 15950→13245 | 15→15 |
| 4 | 3000/3750/4500/6000 | 2880/3600/4320/5760 | 30000→25000 | 47250→41560 | 20→20 |
| 5 | 7000/8750/10500/14000 | 6860/8575/10290/13720 | 75000→70000 | 115250→109445 | 25→25 |

| 集計 | 変更前 | 指定後 | 減少量 |
|---|---:|---:|---:|
| Stage1〜5 Boss | 119950 | 107000 | 12950 |
| Stage1〜5 壁 | 62710 | 60895 | 1815 |
| Stage1〜5 総HP | 182660 | 167895 | 14765 |
| World1全体 | 27869660 | 27854895 | 14765 |

各壁・Boss・Stage合計に増加なし。Stage6〜10は全数値一致、World2Config Sourceは変更なし。[全10 Stage表](hp_before_after.csv)。Boss=RequiredStrength×5を維持し、内部値は40/360/2000/5000/14000。新しいStrength表示は追加しない。

## 3. LV必要量・再生条件

全変更対象Q1〜29、Q30〜50の同一性と各LV累計は [levels_before_after.csv](levels_before_after.csv)。Qは累計ではなく、そのLVから次LVへの必要量。

| LV | 旧Q | 新Q | 新曲線の到達累計 |
|---|---:|---:|---:|
| 1 | 7 | 5 | 0 |
| 2 | 20 | 12 | 5 |
| 3 | 33 | 23 | 17 |
| 4 | 60 | 45 | 40 |
| 5 | 95 | 60 | 85 |
| 6 | 145 | 90 | 145 |
| 7 | 170 | 125 | 235 |
| 8 | 190 | 145 | 360 |
| 9 | 235 | 170 | 505 |
| 10 | 290 | 195 | 675 |
| 11 | 330 | 225 | 870 |
| 12 | 375 | 260 | 1095 |
| 13 | 420 | 300 | 1355 |
| 14 | 470 | 345 | 1655 |
| 15 | 535 | 400 | 2000 |
| 16 | 610 | 480 | 2400 |
| 17 | 760 | 580 | 2880 |
| 18 | 1110 | 700 | 3460 |
| 19 | 1360 | 840 | 4160 |
| 20 | 1510 | 1100 | 5000 |
| 21 | 1760 | 1400 | 6100 |
| 22 | 2010 | 1800 | 7500 |
| 23 | 2260 | 2200 | 9300 |
| 24 | 2510 | 2500 | 11500 |
| 25 | 3010 | 3200 | 14000 |
| 26 | 3510 | 4000 | 17200 |
| 27 | 4010 | 4750 | 21200 |
| 28 | 4510 | 5400 | 25950 |
| 29 | 5010 | 5965 | 31350 |

主要累計：LV4=40、8=360、10=675、12=1095、15=2000、17=2880、20=5000、24=11500、25=14000、30=37315、50=1018015。Q30以降は元の有限カーブを維持し、全10000 LVで旧値と照合した。

| 成立後の再生回数 | 旧条件LV | 新条件LV | 旧参考Strength | 新参考Strength | 倍率（維持） |
|---|---:|---:|---:|---:|---:|
| 1 | 10 | 12 | 955 | 1095 | 1.5 |
| 2 | 15 | 17 | 2840 | 2880 | 2 |
| 3 | 22 | 24 | 10485 | 11500 | 2.5 |
| 4 | 30 | 30 | 37315 | 37315 | 3 |
| 5 | 45 | 45 | 462965 | 462965 | 3.5 |

6回目以降の条件・全倍率は維持。ReferenceStrengthsは選択中の必要量と条件から導く。旧ConfigのWorld1MaxRebirth=5という互換項目は実際の操作上限ではなく、現在の共有条件表は30回まで存在する。この実動作を今回狭めていない。

## 4. 新規・既存プロフィールへの適用と保存

- 既存所有権取得処理が保存値nilと確認して新規作成する場合、defaultsに曲線2を保存。LV1／Strength0から新規と推測しない。
- 既存保存値でLevelCurveVersionがない場合は曲線1。旧曲線と旧再生条件で現在のサイクルを続け、正常な次回再生時に曲線2へ切り替える。明示された1／2は再読込後も保持。未対応バージョンは推測変換しない。
- 保存済みLVを優先し、小数進捗・余剰進捗を選択曲線で正規化する。Strengthはその正規化で増減させない。保存LVがない旧形式に限り、従来の歴史的Threshold変換をそのまま使用する。現在Strengthから保存LVを再計算しない。
- 再生はサーバーDataのLV・曲線・回数で検証。所有権喪失、Save中、未完了ItemMutation／初回報酬、退出処理中を拒否。回数+1、Strength0、LV1、Progress0、Curve2を待機なしで一括変更し、既存のGain端数リセットを通る。
- 通常Saveのpayload／merged値、TimeRewardのsnapshot、StrengthRewardのBefore snapshotと永続結果、StudioStart退避へ曲線を保持。未確定報酬は先に解決し、二重付与防止の既存marker／所有権を使用する。別の保存系統は追加しない。
- Win、装備、所持品、再生回数を移行のために削らない。既に再生可能な旧サイクルを新条件だけで不可能にしない。新旧プレイヤーは同じサーバーに同居できる。

制限：曲線marker導入前の公開データが、さらに古いQ1=10等の時期に作られたか、現在StudioのQ1=7等のサイクルかは、履歴がなければ識別できない。現在の変更直前Studio曲線を旧曲線として保持し、推測のStrength補填・減算はしない。既に生じた過去の曲線変更の影響を遡って修復したとは主張しない。また再生応答は従来と同じランタイム成立であり、直後の永続ACKではない。既存自動保存前のサーバー消失では未保存進行が戻る制限が残る。

## 5. 検証方法と区分

| 区分 | 方法・範囲 |
|---|---|
| 数値・模擬 | 実Sourceを独立Luau環境で実行。153326 assertions合格。新旧Q、主要累計、全HP、境界直前／一致／直後、小数、ゼロ、大量加算、保存形式を検査。[結果](pure_result.json) |
| 既存報酬の模擬回帰 | 現行候補Sourceで既存StrengthRewards.specを実行。応答消失・再試行・途中Gainを含む60 checks合格。[結果](strength_reward_regression.json) |
| 通常ルート実Play | StudioTestServiceの独立したネイティブServer／Client、物理・実Remote・実サービス。操作のみプログラムで反復。保存先はメモリ。人間の手操作時間ではない |
| データ注入実Play | 通常タイミングとは別サーバー。準備済みStrength／LV／位置、メモリ保存障害を使い、実サービス・UI・物理を検査 |
| エミュレーター | 後段の端末表示／入力記録を参照。実機とは別扱い |
| 実機／公開環境 | 実機タップ、公開再参加、本番DataStore、Creator Hub受信は未確認。Save／Publishを行っていない |

通常ルートではStrength・装備・Winの付与、強制ドロップ、StageSkip、テスト用テレポートを使用しない。39 Sourceの外部サービス取得だけを一時的にメモリ／課金禁止の依存へ置換し、正確なBefore／Afterを退避した。Hatchの既存押下callbackを一時公開して通常の確認操作を繰り返し、結果や演出完了を強制していない。公開DataStore／実プレイヤーデータ／実課金／resetdataは使用しない。

## 6. 各実Playと速度比較

[個別結果CSV](individual_runs.csv)、[全イベント・地点状態CSV](route_events.csv)、[Stage別集計CSV](aggregates.csv)、[装備経路別CSV](equipment_strata.csv)。未成功の試行も除外せず元JSONに残す。死亡・再試行を含む経路はその時間を含める。

方針：Manualは通常Tapを0.25秒周期、Autoは通常ToggleでON、MixedはAutoと0.9秒周期Tap。全て初期Auto OFF。共通サーバーの既存最小間隔が有効入力を決める。各遠征でその版の推奨LVへ育成し、Stage1から目標Stageまで進み、Trophyで帰還。帰還後に条件を満たす場合だけ再生。自然な死亡後はStrength目標を25%増やして最大5回まで再試行する。自然にReadyとなるStoneIntro01／IronIntro01／Reward03だけ受領する。

未装備なら通常獲得Stone2個、未装備またはDumbbell1ならIron2個で合成し、実際のRNG結果をBest Equipする。装備抽選を固定しない。変更前後とも同じ選択ルールで、**各版の推奨LVを目安に進む比較**である。同一Strength・同一再生時刻を固定した速度比較ではない。Stage2の推奨LV10→8と再生条件変更は、経路選択にも影響する。

育成はロビーの固定された地上歩行経路と通常Tap／AutoWalkingを使う。Treadmill中心の育成、Winによる追加購入、Glove／Aura／Petの追加装備を組み込む別方針の時間測定ではない。これらを含む全ての通常プレイが同じ速度になるとは主張しない。装備補正自体は別枠の実サービス検証で確認する。

各モード最低3回に加え、通常RNGによるDumbbell2／3の差が大きいため4回目を追加した。1・4回目は3クライアント、2・3回目は6クライアント同居で独立プロフィールを測り、前後の構成を揃えた。4回目のみ0.1秒単位の排他的活動区分を追加。全回のTrainStart〜Endは合成区間を含み得るので、合成控除後の育成列も出す。戦闘／移動を含む厳密な排他的区間の全回測定とは区別する。

変更前1回目だけ参加起点の精度は所有権取得の整数秒proxy（約1秒の誤差）。以降はサーバーPlayerAdded時刻。共通StartAt、クライアントOperable通知、初回ready時刻は別の値として保持。Bossダメージと進入は0.1秒観測、各イベント時刻には通信・フレームの量子化がある。

`Operable` は操作用スクリプトが通常Remoteと移動を開始できた通知であり、全クライアントの画面表示完了を保証しない。After2・3とAfter4の一部では下記の描画停止／ClientPlayable欠測が見つかった。したがって本表は実エンジン・物理・サービスによる自動操作時間であり、全24件を「表示と人間操作も確認済みの実Play」と扱わない。人間が画面を見て操作可能になった時刻は、これらの試行では未確認。

Stage5までの本比較はStage5初撃破で終了。Stage6入口・最初の壁・設定確認、最後の帰還／再生は追加区間であり、Stage5速度比へ混ぜない。Stage6 BossやWorld1全クリアは実施しない。

[全24ルートの個別表・各Stage区間・参加からの累計・再生時刻・活動区分](RUNS.md)。変更前／後、Manual／Auto／Mixedそれぞれ4回。全ルートがStage5初撃破とStage6最初の壁まで完了し、自然な死亡・再挑戦は0回だった。7605イベントを保持した。通常ルートにはBack要求を組み込まず、全帰還はTrophyである。死亡・Backの成立は別枠の注入検証で扱う。

| モード | Stage1累計 前→後 秒 | Stage2累計 前→後 秒 | Stage3累計 前→後 秒 | Stage4累計 前→後 秒 | Stage5累計 前→後 秒 | Stage5速度比 |
|---|---:|---:|---:|---:|---:|---:|
| Manual | 24.52→19.93 | 136.88→88.21 | 268.00→203.72 | 505.57→406.08 | 826.76→812.85 | 1.017 |
| Auto | 43.04→35.14 | 201.20→131.57 | 464.12→357.12 | 951.23→809.90 | 1618.85→1737.29 | 0.932 |
| Mixed | 37.62→30.30 | 176.57→130.55 | 411.13→315.77 | 844.88→688.00 | 1438.73→1447.35 | 0.994 |

**Stage5までの約1.5倍目標は未達。** 1.5倍に達したのはManual／AutoのStage2区間（1.646／1.640倍）とStage2までの累計（1.552／1.529倍）。他Stage・Mixedの区間／累計は未達。Stage5区間はManual0.790／Auto0.720／Mixed0.782倍で遅くなった。

平均だけではRNG差が混ざる。ManualのNORMAL_01→NORMAL_03は前1回・後2回、Mixedの同経路は前0回・後1回だった。同じ装備名の経路で両版に標本がある比較はStage5速度比0.931〜0.949倍で、いずれも遅くなった。獲得時刻まで揃えた実験ではなく、標本数も小さいので、差の統計的保証とはしない。結果の悪いルートや抽選結果は捨てていない。

理論上の注目点：Stage4壁合計は17250→16560に減るが、推奨LV到達Strengthは7215→5000なので壁4枚を通す最小攻撃数は3→4。LV25→30は20050→23315育成量となる。Stage6最初の壁76000は維持され、新LV25の14000では6発、旧LV25の17265では5発。Stage6 Boss190000は新LV30の37315でも6発。通常ルートは移動中のGain・装備があるため、この理論値と実回数を同一視しない。

今回の「遠征帰還後、条件を満たせば再生」方針では、旧条件の1・2回目はStage2／Stage3後、新条件ではStage3／Stage4後になる。したがってStage5直前の育成は、旧版のLV20→25（追加10050）に対し、新版は再生後LV1→25（14000）となる。両方ともその区間の再生倍率は2倍なので、装備等が同じならこの区間の必要Gainは約1.39倍になる計算。これは実時間の測定値ではないが、序盤短縮が最終区間で相殺される要因として、実測の再生時刻・装備経路と照合する。指定HP・付与量・再生条件を目標に合わせて再調整しない。

## 7. 保存・複数プレイヤー・戦闘・表示

[実サービス境界検証](native_boundary.json) は、別の3クライアントPlayで10ケース・1076 checks合格。データと位置を注入しており、通常ルートの所要時間には含めない。

- 新規曲線2、markerなしLV1／Strength0の既存曲線1、再生済みの旧サイクルを区別。Strength17.75、LV30、進捗0.125、再生3回、Win37、Dumbbell2、Protein所持数を保持した。
- 新旧曲線のQ1〜29境界直前／一致／直後、小数、余剰進捗へのゼロ加算、LV50へ進む一括加算を実際のAddStrengthGainで確認。他プレイヤーのStrength・LV・曲線は変わらなかった。
- 再生条件の直前／一致／超過、12連打、所有権喪失、保存待ちを確認。旧LV10の再生は1回だけ成立し、曲線2・次条件LV17へ切り替わった。
- 保存前失敗、保存後ACK消失、再送、メモリ再読込で同じ曲線・LV・進捗を保持。未確定報酬中の再生を拒否し、12.5の報酬と途中3.125の育成を一度だけ合算した。正常再生後の5.125はLV2／進捗0.125として保存・再読込された。
- 実Boss／壁サービスでStage1〜5の5発、Glove+50%時のStage2ダメージ540・4発、壁間の余剰7.5、Boss開始時の満HP、本人別のHP・壁リセットを確認。Stage4壁の最小回数は実サービスでも4回だった。
- World2で曲線2のLV16→17、再生2回目、次条件LV24、Boss1 HP10000000を確認。World2のHP表は変更していない。

LVゲージは新曲線LV10／進捗0.5で `1 / 195`、旧曲線で `1 / 290`。再生UIは各々LV12／LV10を参照した。表示の端数丸めは既存仕様で、保存進捗0.5を切り捨てていない。初期案内はStrength5・9のLV2でTreadmillを維持し、Strength10でWall1.1へ進んだ。これらは実際のUI文字列／案内属性の検証であり、描画された画面の目視合格とは区別する。

[準備済みデータによる物理戦闘](native_combat.json) は各StageにつきManual／Auto各1回。推奨LV到達直後のStrength、補正なし、Player HP100を用意し、実際の接触判定が成立してから通常入力を開始した。全10ケースが正確な基準Strengthで5発撃破、死亡0回。

| Stage | Strength | Manual初撃／5発目 秒 | Auto初撃／5発目 秒 | Auto5発目時のPlayer HP |
|---|---:|---:|---:|---:|
| 1 | 40 | 0.082／1.150 | 0.167／3.893 | 25 |
| 2 | 360 | 0.082／1.132 | 0.284／3.518 | 25 |
| 3 | 2000 | 0.100／1.133 | 0.315／3.583 | 25 |
| 4 | 5000 | 0.082／1.148 | 0.351／3.600 | 50 |
| 5 | 14000 | 0.082／1.149 | 0.332／3.582 | 25 |

接触認識は準備位置から約0.031〜0.034秒。Autoの有効間隔は多くが約0.80〜0.82秒だが、Stage1には約1.13／0.97秒の間隔もあった。毎秒25ダメージの実被弾を記録し、Stage4は初回被弾が約2.02秒だった。接触・スケジュールによる差を含む観測であり、全条件で5発目が保証されるという結論ではない。撃破時の既存回復で100へ戻るため、表は回復前の5発目時点を使う。追加のStage2 Back8連打ではHP1440から帰還後1800へ初期化し、同じ生存Characterと曲線2を維持した。

モバイルは [端末設定と文字列記録](mobile_configuration_and_text.json)。iPhone17 Pro横874×402、iPad Pro M5 13インチ横1376×1032へ切り替え、曲線ごとの再生表示は取得した。しかし両クライアントのCamera.ViewportSizeは1×1、Autoボタンは0サイズのままだった。**エミュレーターの見た目、移動しながらのタップ、Auto／Back／再生のGUI入力、実機タップは未確認。** 無効な座標へクリックして合格を作らない。元のGeneric Handheld1280×720・向き・DPI・Scalingは [照合して復元](mobile_restore_verified.json) した。最初の復元で非モバイル端末への冗長な向きsetterが拒否されたが、向きは元値と同一で、その後の全設定照合は成立した。正本Editの端末設定は変更していない。

## 8. Analyticsとログ

FirstPlayAnalyticsService／Transport／BossAttackService／RunReturnServiceの定義は今回変更しない。既存4本と追加2本の名前・条件・順序を維持。通常ルートの [Funnel出力](funnel_outputs.csv) はStudio記録でありCreator Hub受信ではない。合成は実Forge要求を使うがUIの素材選択contextを通さないため、Oreファネルの完了を通常ルートだけで検証したとは扱わない。

順序比較は各ファネル内のStep列を対象とする。実PlayではTimeRewardでOreEligibleになる時刻が異なり、OreのStep1がStage1戦闘の途中へ入る場合が変更前から存在する。異なるファネル同士の全体的な到着順や経過秒を、前後で同一とは扱わない。生ログの順序は並べ替えず保存した。

After2・3の6プロフィールではEntryがStep1・2まで、FirstCombatは0件で、既存4ファネルの観測出力一致を満たさなかった。After4の途中調査でもMixed・Autoで同じ欠測を確認した。読み込み・Character・ロビー配置の属性は成立していたが、Autoボタンの表示サイズが0で、既存ClientPlayableの表示要件は成立していなかった。3クライアントで1秒／4秒観測中のRenderSteppedは0回、Heartbeatは継続していた。[観測記録](native_render_readiness.json)。画面キャプチャも約1分で完了せず取得できなかった。ウィンドウは非最小化、入力デスクトップはDefaultだったが、描画停止の根本原因は未確定。検証環境に整合する現象として記録し、製品コードの変更原因と断定しない。

Entry・FirstCombatの合格条件は緩めず、失敗した証拠検査も残す。ClientPlayableを模擬送信して過去Stepを補完しない。Stage2用3本は独立した観測条件なので、これらの欠測と分けて評価する。初期取得15ルートでの一致結果を、後から取得した全ルートへ一般化しない。

追加2本は `MTF_FirstStage2BossDeath_v1`（DamagedStage2Boss → KilledByStage2Boss）と `MTF_FirstStage2BossBack_v1`（DamagedStage2Boss → BackBeforeStage2BossDefeat）。同じ新規初回参加・正常Bossダメージから開始し、最初の撃破後は新規完了しない。死亡・Backの完了者は重複するため、合算して未撃破人数・ゲーム離脱人数と解釈しない。

送信失敗／飽和の既存制限は維持。[前回の59件Transport検証](../FirstStage2BossOutcomes_20261112/REPORT.md) では20人×50イベント同時発生時に380送信／620期限切れ。今回の実Play観測は、本番負荷で欠測しない保証ではない。Creator Hub確認は手動Save／Publish後、公開PlaceVersionで6本を絞り、View Eventsで同じ参加GUIDと各Stepを確認する。[既存の確認手順](../../docs/FIRST_PLAY_ANALYTICS.md#creator-hub-verification-after-the-owners-manual-savepublish)。本作業では公開操作を行わない。

[通常ルートの証拠検査](evidence_validation.json) は644項目中627成立・17未達。未達は8プロフィールのEntry／FirstCombat期待prefix各2件と、既存4本の全体一致1件である。全24件で参加GUIDが独立し、各参加内のGUID・PlaceVersion577・cohortフィールドを保持。Stage2の既存撃破ファネルは全24件Step1〜5、追加死亡／Backは各Step1だけで、TrophyをBackとする誤完了・死亡の誤完了・同Step重複はなかった。Funnel計352件。既存4本が全件一致したとは報告しない。

別枠の死亡／Back初回試行は [失敗記録](native_analytics_attempt1.json)。3件とも移動timeoutで、追加ファネルの合格証拠には使わない。検証クライアントに本体と通常ルートが持つOwnerUserIdフィルターが欠け、他プレイヤーの戦闘通知を受けていた。検証補助だけを修正して新しいメモリセッションで再試行した。本体Analyticsや移動・壁・攻撃条件を緩めていない。

OwnerUserId修正後の [2回目](native_analytics_attempt2.json) も移動timeoutとなった。読み取り専用raycastでは、進行中のPlayer5が別所有者 `Owner_-1.Stage01_Enemy.Torso` にZ197.9で衝突していた。本人のStage1は撃破済み、Stage2最初の壁はZ213.65。[衝突観測](analytics_movement_obstruction.json)。画面は引き続き1×1。複数プレイヤーの物理経路が正常という合格は出さない。Source変更と描画停止のどちらが原因かは、この結果だけでは断定できない。追加の切り分けは、待機中の合成プロフィールを退出させて一人ずつ検証する方式に限定し、本体の衝突設定は変更しない。

[単独での再検証](native_analytics_solo.json) は、別々の新規プロフィール3件・43 checksでStage2の結果条件が成立した。全件でStage1の正当なBackを先に行った。死亡→再挑戦→Back、Back→再挑戦→死亡では、追加2本がそれぞれStep1・2を1回ずつ記録し、その後も既存Stage2撃破のStep5へ進んだ。先にBoss撃破→Trophy→再周回の死亡・Backでは、追加2本はStep1だけを維持した。各ケースでAutoOn送信を1件失敗させても通常Toggleと既存Saveが成功し、失敗イベントは補完されなかった。

この単独検証でもEntryのClientPlayableは3件とも未成立なので、レポートの全体Passedはfalse、Stage2OutcomesPassedだけtrueである。先の複数プレイヤー衝突を解消したことにはしない。Stage1のBoss HP・関連戦闘／表示Sourceは今回変更しておらず、身体サイズの参照も従来どおりStrength。衝突は別所有者のStage1 Bossで観測されたが、変更前の同じ待機プレイヤー構成による再現比較と、描画が正常な公開環境での再現は未確認である。

Before1・4／After1・2・3・4、別枠境界／戦闘の取得済みログに、今回変更した本体SourceのRuntime Errorは見つからなかった。メモリアダプターが意図的にBadge付与を拒否する警告、過去のasset権限／欠損IDの警告、下記GUI待機警告を区別する。境界／戦闘の [全7 Studioログ](boundary_combat_consoles.json) にはInfinite Yield警告はなかった。モバイル設定復元時のsetterエラーは上記の通り解決・照合した。ログ未取得区間まで「警告なし」とはしない。

After2・3の6クライアント同時Playでは、3クライアントに `WorldGateClient:7` のWorldTravelGui待ちと `SpawnFacingCameraClient:93` のDeathGui待ちの警告が各1件あった。[取得ログ](after_2_3_mid_consoles.json)。後続確認では全対象で両GUIが存在し、LV進行・Stage攻略を継続していた。[確認時刻と状態](after_2_3_gui_wait_followup.json)。両待機Sourceは今回変更していない。起動時のGUI到着遅延と整合するが、到着の正確な時刻・待機時間・遅延原因は計測しておらず、警告ゼロや原因解消とは扱わない。

Before2・3はサーバーログのみ取得し、6クライアント側のconsoleは未取得だったため、同じ同居数での警告頻度の前後比較はできない。Before1・4、After1は全クライアントとサーバーを取得しており、その取得分にこのGUI待機警告はない。

## 9. 清掃・未確認・Git

[最終Studio照合](final_studio_audit.json)：全499 Sourceのうち今回変更10、変更前と一致489、予期しない変更0、欠落0。外部サービス／Hatch補助の40 Sourceを正確な退避値へ復元し、検証用ルート・Remote・Module・結果オブジェクトを除去。`__W1Balance` 残留0、全ての所有テストPlayを終了し、接続Studioは正本Editだけとなった。LandscapeSensor、元のGeneric Handheld720設定、PlaceVersion577を保持した。Tutorial Sourceは改行も含めて変更前と一致する。

[Gitの11 Source照合](final_repository_source_check.json) も記録済み候補とSHA256一致。Studioでは既存だった未追跡LevelProgressionと、mainに不足していた関連の既存編集を含む。Ore5スロット、左Menu70%、Trophy、PetEggの×、通知のSourceは最終照合の変更なしに含まれる。画面目視による全機能合格を意味しない。

新しい曲線・保存・再生の変更で未解消のRuntime Error／データ損失は検証範囲では見つからなかった。一方、待機プレイヤーのBossによる衝突は未解消であり、複数プレイヤーの移動に関する受け入れ確認は完了していない。関連のStage1設定・戦闘Sourceは今回変更していないが、原因を既存実装／検証環境のどちらかへ断定する証拠も不足している。公開前に正常に描画される環境で再現確認が必要。

実装commitは [7104c61](https://github.com/koujiyoshimura54-crypto/Smash_and_Crush/commit/7104c61ff54c92316e60e7334a5c7cf8987957c1)。2026-11-13 02:15 JSTに `git push origin HEAD:main` が成功し、origin/mainは `35ed907` → `7104c61` と通常のfast-forwardで更新された。[push記録](push_receipt.json)。本節の結果追記は後続の文書専用commitで、ゲームSourceの追加変更はない。

PR #1はopen・draft・未マージ、head `67a9ca51522b24d02c711f1d339e4a4cf349d653` を維持。force push、PRのマージ、過去報告の数値書換えは行っていない。これは指定実装と検証記録の反映であり、上記の未達・未確認を全て解消した完成判定ではない。

実機タップ、公開サーバーでの実再参加、本番DataStoreの保存／通信挙動、Creator Hub受信は未確認。メモリ保存の実サービス検証を公開保存の合格とは扱わない。既存の保存前クラッシュ制限、marker以前の曲線履歴不明、RNGと少数試行のばらつき、高LVのIEEE754精度限界を残す。速度目標未達を合格と呼ばず、指定値を検証都合で変更しない。

Studioは未保存のまま保持する。Save／Publish、保存GUI、Placeファイル直接書込みは実施しない。ユーザーが開始したPlayは停止しない。検証のために自分が開始したネイティブテストだけを終了する。
