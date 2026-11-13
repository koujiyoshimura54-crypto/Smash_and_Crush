# Treadmill・成長後の設備判定の調査 — 2026-11-13

1. **過去の修正は残っている。** 10月1日の実際のR15足裏判定と、11月10日のWorld2限定の接地・Raycast補助を、現在のStudioで確認した。Trophyの11月12日の表示復元修正も残っている。
2. **今回の症状の実Play再現は未確認。** 現行EditのSource・設備寸法・静的Raycastと、過去の実測を調べた。今回の実Play、特定アバターでの比較、実課金、本番データ検証は行っていない。
3. **単一の共通原因とは確定できない。** 成長による身体と判定位置のずれは共通候補だが、Treadmillは鍛錬セッション、ダンベルはRoot中心、マージは円柱内のRoot中心、TrophyはCharacter配下Partの空間検索で、それぞれ別の判定で止まり得る。

## 最新の症状・調査基準

途中のユーザー訂正を優先する。Treadmillの対象は **World2のみ、最大Bodyのみ、特定アバターのみ**。「アニメーションはギリギリ起こるが、Strength増加が無し」という報告。最初の「World1で再発」は今回の対象条件から訂正した。ショップ・WinTrophyの報告は別件として保持する。

アバター名／アセット構成、該当Treadmillの台・倍率、最大BodyがAUTOか手動選択か、サーバーの生のStrength値は未取得。アニメーションの「ギリギリ」が短時間の開始・停止なのか、継続する小さな動きなのかも時系列未取得。ユーザー報告を今回のエージェント実測と混同しない。

- 正本Studio: PlaceId **126576845524886** / UniverseId **10765181857**、接続ID `f80707a4-0320-442f-803c-78a5775d0da0`。
- 開始時にorigin/mainを取得。基準 `49f70907513be7e41c44f5dd5e8b67af49572076`。
- StudioはEditのみ。Playerオブジェクトは1個あるがCharacterは0体で、接地・足裏・RigTypeを測る実行中Characterはない。
- DataModelのPlaceVersionは**621**。これは接続中Editの値であり、ユーザーの公開V1321を確認した証拠ではない。現行Editと現在公開版の同一性、発症バージョンは未確認。新チュートリアルV1321以降という情報から発症時期を断定しない。
- AGENTSと関連SPEC・現行Source・修正履歴を照合。古いSPECの「Zone監視0.2秒」は現行の占有監視と異なる。現在は占有判定が毎Heartbeat、利用資格の表示更新が0.2秒。
- PR #1は読取確認時点でopen / draft / merged=false。変更・マージしていない。

[Evidence.json](Evidence.json)にSourceハッシュ・Editor照合・各設備のCFrame/Size/衝突属性・静的Raycastを記録した。CFrame配列は位置XYZと3×3回転成分。

## 設備別の事実と停止箇所

「確定」はコード・Editの実測事実を指す。報告された不具合の原因確定とは区別する。行番号は照合した現行Sourceに対応する。

| 設備 | 確認した事実 | 再現条件／原因の位置付け | 止まり得る判定 | 根拠のFull Pathと行 | 未確認事項 |
|---|---|---|---|---|---|
| World2 Treadmill | Areaは高さ0.8。両足裏が外れても接地・同じ設備へのRaycastで救済する。占有が切れるとセッションを破棄し、次の開始から0.5秒待ち直す | ユーザー報告: 最大Body・特定アバター。**占有の瞬断とtick待ち直しが有力候補** | Root X/Z、実足裏Y、FloorMaterial==Air、Raycast未到達・別設備・Area上端より高いhit。どの条件が実際に落ちたかは未確定 | [ServerScriptService.Services.TrainingManager:145–154,176–210,215–255](../../src/ServerScriptService/Services/TrainingManager.luau#L215)、[ServerScriptService.Systems.Controllers.TrainingController:38–58](../../src/ServerScriptService/Systems/Controllers/TrainingController.server.luau#L38) | 同一アバターの基本／中間／最大、自然歩行、成長直後、再進入、実際のセッション寿命と加算回数 |
| World1 Treadmill（比較） | 実足裏方式を維持。AreaはY=4.500〜19.500、高さ15。World2補助の対象外 | 最新申告では発症対象外。過去の約1.2 studsの浮きだけで上端超過にはならない | Rootの水平条件と、少なくとも片足の足裏Y。R6／足Partなしだけ旧Root/HipHeight推定 | [ServerScriptService.Services.TrainingManager:220–255](../../src/ServerScriptService/Services/TrainingManager.luau#L220) | 同じ問題アバターを使ったWorld1との実比較 |
| マージショップ | World1のAreaは縦向きCylinder。Root中心に対して半径12.5、世界Y約2.446〜20.054 | **成長でRootが範囲外になること自体は条件として確定**。ただし既存の最大Body測定値では上限に達しないため、今回の原因としては未確認 | `now=false`ではopenShopを呼ばない。入場後にfalseになるとHide。Touchedは入口ではない | [StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New:103–124](../../src/StarterPlayer/StarterPlayerScripts/UI/MergePanelClient_New.client.luau#L103) | 実際のRoot、円柱の水平範囲、UI mount/表示状態、サーバー処理受付。ショップ全般への一般化不可 |
| ダンベル台 | 12台ともPress上面からRoot中心まで6 studs以内。Rootを0.1秒周期で検査 | **成長により高さ上限を超える有力候補**。過去の最大Bodyは床→Root約8.085で、この6を超える | `GetStandingIndex=nil`なら購入・装備処理を呼ばない。資格・Win・購入保存は別段階 | [ReplicatedStorage.Config.DumbbellStandConfig:7,24–36](../../src/ReplicatedStorage/Config/DumbbellStandConfig.luau#L24)、[ServerScriptService.Services.DumbbellStandService:9–38](../../src/ServerScriptService/Services/DumbbellStandService.luau#L9) | 同じアバターでPress上に自然に乗った際のRoot高さ。入口が成立した場合の購入拒否コード |
| WinTrophy 通常 | 全10 StageのHandle=8×0.3×5、床Y4。検索箱はY4.030〜4.930。Touchedの後もoverlapで再確認し、0.1秒周期の検索もある | **足裏の浮きにより薄い検索箱に届かない有力候補**。ただし足以外のCharacter配下Partも検索対象 | eligible、本人Character/所有者、overlap、読込、並行処理、Win加算、Bank、帰還の各段階 | [ServerScriptService.Services.TrophyRewardService:37–49,110–157,203–242,354–360,387–415](../../src/ServerScriptService/Services/TrophyRewardService.luau#L37) | 現行Characterの全query対象Part、Touched履歴、overlap返却数、拒否段階、Win／帰還結果 |
| WinTrophy Double | 通常と同じ箱寸法。接触資格の後に所有権確認／購入Prompt。購入済み継続経路は別にある | 通常と同じ高さ候補。**購入資格の不成立と接触不成立を分ける** | overlapが空なら通常の入場Promptまで届かない。InsideDouble・Prompting・Processingのラッチもある | [ServerScriptService.Services.TrophyRewardService:245–289,358–360,405–408](../../src/ServerScriptService/Services/TrophyRewardService.luau#L245) | 実課金は未実施。未所有／既所有の受取、取消し、自然再進入は今回未確認 |
| Trophy表示 | owner向けTrophySpawnで表示許可。離脱したInstanceも元の表示へ復元する修正が残る。CanTouch/CanQueryを書き換える処理ではない | 表示復元の修正消失は確認されなかった。表示成功は受取成功の証明ではない | grantなし、死亡、World切替、受信順序などで非表示。受取資格はサーバー別判定 | [ReplicatedStorage.Modules.PersonalTrophyVisibility:26–58,65–100,126–135](../../src/ReplicatedStorage/Modules/PersonalTrophyVisibility.luau#L65) | 発症時の実際のGUI・Handle表示、受信したTrophySpawn |

## World2 Treadmillの切り分け

### 既存修正と今回の観測

- `572edcf65a225f14ce83bad80717fc07c55e07f2`（2026-10-01）はR15実足裏方式へ変更。回転を含む足Partの最下面をArea座標で求める。現在も同じ計算がある。
- `a9ce5f9d9b44dbfc82a112a76a2a875f06b2d5c1`（2026-11-10）はWorld2の補助を追加した。今回の問題を「World2に補助がない」とは説明できない。
- [11月10日の報告](../Phase11To14_20261110.md#phase-13--world2-physical-support-and-common-headings)には最大Body・HipHeight約6.95で全7台が各4tick加算した記録がある。ただし当時のアバター条件の結果であり、今回の特定アバターや自然な接触の成功を保証しない。同報告の「最大Bodyの復活配置で台から落ちたケース」は成功扱いではない。
- 今回のEditでは7台×9点、AreaのX/Z半幅に対して−0.85/0/+0.85の位置から下向きに調べた。63点とも同じ台の衝突面で、hitはArea上端以下。**台中央付近の支持面が一律欠落している証拠はなかった。** これはCharacterなし、Area基準の高さ8・長さ12の静的Raycastであり、実際のRoot起点・HipHeight由来の到達距離・FloorMaterialの検証ではない。
- 台にはAreaより高い衝突Partもある。大型アバターが縁・手すり等へ干渉する可能性は残るが、今回それに接触している証拠はない。63点の結果で端や移動中まで正常としない。

| World2設備Full Path（末尾はArea） | Size X/Y/Z | Area中心Y | 中央の衝突面Y | 衝突面からArea上端まで |
|---|---:|---:|---:|---:|
| Workspace.World2Map.TrainingArea.TreadmillDisplays.01.Area / .02.Area | 8.994 / 0.800 / 18.534 | 3.560 | 3.410 | 0.550 |
| Workspace.World2Map.TrainingArea.TreadmillDisplays.03.Area / .04.Area | 10.874 / 0.800 / 22.408 | 3.854 | 3.704 | 0.550 |
| Workspace.World2Map.TrainingArea.TreadmillDisplays.05.Area / .06.Area / .07.Area | 16.862 / 0.800 / 33.323 | 4.789 | 4.279 | 0.910 |

World2のArea自体はCanCollide/CanTouch/CanQuery=false。それでも占有計算はCFrameとSizeを直接読むので、この属性だけでは不具合とならない。World1のAreaはCanCollide=false、CanTouch/CanQuery=true。対象設備のCollisionGroupはDefault。Characterの実行時属性は未測定。

### 資格・占有・加算・アニメーションを分ける

1. **利用資格**: TrainingManager:157–165。タグ、対象モデル、CurrentWorld、Data読込、PurchaseEnabled、再生回数、Premium所有・効果有効を確認する。アバター名・MuscleHeightScaleの直接判定はない。StudioDebugConfig.GamePassEffectsEnabled=falseがあるため、Premiumの実Play比較にはこの条件も記録が必要。今回設定は変更していない。
2. **占有**: Root X/ZがArea外なら、接地補助まで進まずfalse。R15で片足の最下面がArea高さ内ならtrue。両足が外れると、World2かつFloorMaterialがAirでないことを要求する。Rootから下に `HipHeight + Root.Size.Y/2 + Area.Size.Y/2` のRaycastを行い、同じ台に命中し、hitがArea上端以下ならtrue。単に見た目が台に重なるだけでは足りない。
3. **鍛錬状態／加算**: StartTrainingはIsTrainingとTrainingTreadmillを先に立て、その後0.5秒待つ。同じ台で継続中ならStartTrainingの再呼び出しは待ち時間をリセットしない。**falseになってStopTrainingした場合だけ**旧sessionを失効させ、新sessionが0.5秒待ち直す。1Heartbeatでも検査時に外れれば止まる。例えば0.3秒ごとに成立→不成立を反復すると、アニメーション開始はあっても最初のtickに届かない。この例はコードからの条件説明で、今回の実測周期ではない。
4. **加算処理の別候補**: StrengthManager:132–146,165–188からPlayerDataService:870–883へ進む。セッションが0.5秒以上安定しても増加しないなら、AddStrength呼出回数、計算gain、戻り値／拒否理由、保存データとStrength属性の前後を確認する必要がある。TrainingManagerはAddStrengthの戻り値を見て訓練停止する実装ではない。したがって「IsTraining=true」だけでは加算成功の証拠にならない。
5. **アニメーション**: [StarterPlayer.StarterPlayerScripts.World.TreadmillRunClient:21–24,85–117,149–150](../../src/StarterPlayer/StarterPlayerScripts/World/TreadmillRunClient.client.luau#L85)は属性を見てRunAnimation `913376220`をMovement優先度で再生する。再生成功をサーバー加算の条件にしていない。ユーザー報告から、アニメーションのみの問題より占有／加算経路を優先する。ただし「見えた走り」が専用Trackか通常Runかは未取得。
6. **表示との分離**: 現行[StarterGui.StrengthGui.StrengthDisplay:28–37](../../src/StarterGui/StrengthGui/StrengthDisplay.client.luau#L28)は[ReplicatedStorage.Modules.StrengthHUDPresentation:43–54](../../src/ReplicatedStorage/Modules/StrengthHUDPresentation.luau#L43)の3桁表示を使う。例えば6,000,000,000と6,000,000,005はどちらも6Bになる。ユーザーの「増加無し」がHUDだけの確認なら、生のサーバー値も必要。この丸めだけで特定アバター依存を説明したことにはならない。

**有力候補**は、最大Bodyとアバター固有の寸法／姿勢によって占有が途切れ、0.5秒tickが成立しない経路。**未確認**は、Root水平外れ・FloorMaterial Air・Raycast到達不足／別物命中／高い面命中のどれか、または安定訓練中の加算拒否なのか。今回、症状の直接原因を確定した項目はない。

## 身体成長・基準サイズ・各設備の高さ

[ServerScriptService.Systems.Controllers.MuscleCharacterService:11–42,44–71,74–101](../../src/ServerScriptService/Systems/Controllers/MuscleCharacterService.server.luau#L11)はCharacterごとの元Part寸法、Attachment、Motor6D、HipHeightを保存し、その元値から再計算する。現在サイズへ繰り返し倍率を掛ける方式ではない。HipHeightは元値×HeightScale。胴・腕・脚のYを拡大するが、Head・Hands・Feet・Rootは対象外。

[ServerScriptService.Config.MuscleScaleConfig:3–17,36–44](../../src/ServerScriptService/Config/MuscleScaleConfig.luau#L3)の高さは基本1、段階1〜13が1.10 / 1.175 / 1.25 / 1.35 / 1.45 / 1.70 / 2.00 / 2.15 / 2.40 / 2.65 / 2.95 / 3.25 / 3.55。AUTOはStrength、手動はSelectedSizeTierを使う。同じ最大倍率でも元アバターの寸法・HipHeightは同一ではない。

[ServerScriptService.Services.LobbySpawnService:236–265](../../src/ServerScriptService/Services/LobbySpawnService.luau#L236)ではLoadCharacterAsyncが戻ってからSpawnEngineReadyを立て、Muscle側が基準を取得・適用し、MuscleScaleReady後に配置する。[184–201行](../../src/ServerScriptService/Services/LobbySpawnService.luau#L184)はロビー内で成長した現在位置を必要に応じ持ち上げる。新しいCharacterで基準を取得する。読み込まれたアバターの実イベント順序や、一部身体の後からの交換は今回未観測。単純なコード順だけで全アバターの競合がないとは判断しない。

現行ServerScriptService／StarterPlayerのSource検索では、ApplyDescription、CharacterAppearanceLoaded、AutomaticScalingEnabledの一致はなく、HipHeightの代入はMuscleCharacterServiceを確認した。GitにあるHisarinoHairAutoEquipは期待Full Pathに現行Instanceがなく、現行の動作原因として採用していない。エンジンのアバター処理やクライアントの実行時生成コードまで不存在と断定するものではない。

次は[10月20日の実測記録](../MuscleGrowth13_20261020/Verification.json)からの値であり、今回のアバターの測定ではない。

| 過去の段階 | HeightScale | Root−床 | 足裏−床 | 同じ床相対姿勢を仮定したダンベル上面+6判定 | 同じ姿勢をWorld1マージ床Y4へ換算した高さ判定 |
|---|---:|---:|---:|---|---|
| 基本0 | 1.00 | 3.113 | 0.178 | 内側 | 内側 |
| 1 | 1.10 | 3.316 | 0.233 | 内側 | 内側 |
| 5 | 1.45 | 3.982 | 0.377 | 内側 | 内側 |
| 8 | 2.15 | 5.342 | 0.694 | 内側 | 内側 |
| 最大13 | 3.55 | 8.085 | 1.351 | 上限超過 | 内側 |

同記録の手動段階13では足裏−床1.198、死亡復帰・World往復でも約1.197〜1.199。報告本文の約1.2と整合する。表は比較計算であり、設備へ移動した結果ではない。足以外のquery可能なPartの最低位置はこの記録だけでは分からない。

- **ダンベル**: `Workspace.PerStepButtons.1.Press`は中心(233.212,7.136,32.420)、Size(6.996,1.369,7.300)。上面7.821、Root上限13.821。台1〜4は同じ高さ、5〜8は上面11.582／上限17.582、9〜12は上面15.123／上限21.123。どの台も上面からの余裕は6。成長の境界段階は今回未確定。入口後も所有済み／装備済み、Win不足、保存待ちなどは[ServerScriptService.Systems.Controllers.DumbbellController:33–84](../../src/ServerScriptService/Systems/Controllers/DumbbellController.server.luau#L33)で別扱い。PressのCanQuery=falseやTouchedの有無は、この座標判定の成否を直接決めない。
- **マージ**: `Workspace.RestockShop.Area`は中心(307.836,11.250,37.686)、Size(17.607,29,25)。CylinderのローカルX軸が世界の鉛直方向なので高さは17.607。床Y4からRoot上限まで約16.054あり、上記最大Bodyの8.085では超えない。大きいから必ず上限超過するという説明は支持されない。半径12.5の水平条件、入場状態、UI mount/他パネルとの表示制御を発症時に区別する必要がある。
- **Trophy**: `Workspace.GeneratedMap.BattleCorridor.Stage01.TrophyNormalButton.Handle`は中心(255.120,4.180,165.875)、Doubleは(320.480,4.180,165.875)。全Stageの高さ・寸法は一致。通常の検索箱は8×0.9×5、中心Y4.480、上端は床上約0.930。過去の約1.2の足裏浮きはこれを上回るため候補になる。ただしGetPartBoundsInBoxはCharacter配下の他のPartも対象なので、足裏だけから返却0件とは断定しない。
- Trophyの資格確認は本人のrecord、Owner、同じCharacter、生存、World、Boss撃破済みを保持している。接触後にも重複・データ読込・資格再確認があり、Win付与の後にBank／ロビー配置がある。**Winが増えたのに戻れないケースは、接触不良と別に扱う。**

## 今回の確認区分と残る検証

| 区分 | 今回の結果 |
|---|---|
| 現行Studioの静的調査 | 対象12 Sourcesはmainと一致。追加のStrengthManager／DumbbellControllerも一致。TrainingConfigはGitのsrcにないためStudioから直接確認（BaseGain=1、TrainingInterval=0.5）。15個の存在する対象SourceはEditor表示とSourceが一致。主要12本は調査前後で一致 |
| 設備のEdit実測 | 14台のTreadmill Area、World1 Merge Area、World1ダンベル12台、World1 Trophy通常/Double全20個。CFrame・Size・CanCollide/CanTouch/CanQuery・CollisionGroupを記録 |
| 静的Raycast | World2内部63点。実際のCharacter接地・実際のreach・自然接触の合格ではない |
| 数値比較 | 過去の成長記録と現行閾値を床相対で比較。今回の模擬Characterやゲームサービスを実行した結果ではない |
| 過去の実Play | 10月20日の成長・歩行、11月10日の最大Body Treadmill、過去のTrophy表示修正を参照。今回の再現・合格とはしない |
| 今回の実Play／エミュレーター／実機 | 未実施。接続は正本Editだけ。現行未保存編集を保持し、本番DataStoreを事前遮断できる独立Runtimeを確保できなかった。通常Playを起動して試すことはしていない |
| 公開環境／公開V1321 | 未確認。発症時期、公開Sourceとの同一性、Creator Hub等の証拠なし |
| Runtime Error／Warning／Infinite Yield | 今回のPlayログは未取得。Edit調査をエラーなしの実Playと呼ばない |

次の隔離Playでは、まず問題アバターと正常アバターを同じ台で比較する。基本・途中・最大、通常歩行→その場成長→退出再進入を優先し、症状が出たら直前段階を調べる。死亡復帰・World往復は基準取得／姿勢の差を解消する必要がある場合に追加する。テレポートだけの配置を自然接触成功としない。

取得する最小時系列は、アバター構成/RigType、SelectedSizeTier/AUTOとMuscleHeightScale、Root CFrame/Size、HipHeight、左右足裏、FloorMaterial、接地Part、X/Z条件、左右足裏Y条件、Raycastの起点/長さ/hit/高さ、利用資格、IsTraining/TrainingTreadmillとsession開始終了、AddStrength呼出／戻り値、データの生Strength前後、専用RunTrackの再生状態。Trophyでは所有record・Boss撃破・同一Character・GUI表示・Touched・overlap全Part・拒否段階・Win・帰還を対応させる。診断補助は隔離先だけに置き、終了時に撤去する。

## 修正案は提案のみ

- **World2 Treadmill**: まず実際に落ちる分岐を特定する。接地・支持面判定が原因なら、同じ台の水平範囲と支持面を確認できる方式を検討する。単にAreaを大きくする、Airを無条件に許す、World1へ補助を広げる、退出後もtickを配る変更は今回の根拠から決めない。微小な状態揺れを吸収する場合も、実際の退出・他台・死亡・資格喪失で加算が止まり、空中で補助判定が無条件に通らない再検証が必要。
- **ダンベル**: 高さ上限超過が実証されたら、Root固定高さに依存しない接地位置／身体寸法を用いた入口判定を検討する。購入・所有・装備・Win・保存・入場ラッチは維持。基本／最大、台の縁・下・隣の台、成長中、再進入で確認する。
- **Trophy**: eligibleな本人の接地位置または身体基準の接触判定を検討する。通常／Double、Touched／定期検索／再確認に整合が必要。Owner・Character・World・Boss撃破・所有権／購入・二重付与防止は緩めない。足が浮くアバターに加え、ジャンプ・隣接者・未撃破・取消し・死亡／帰還中を再検証する。
- **マージ**: 現在の測定は高さ原因を支持していない。問題時の水平／高さ／UI状態を確認してから、その層だけの案を作る。身体サイズ全体や全ショップ一括の変更は提案しない。
- **成長方式**: 共通HipHeightや身体サイズの変更は歩行・戦闘・全設備へ及ぶため、今回の不具合候補だけを理由に変更しない。

## 保持・清掃・Git

ゲームコード、設備、Body、判定範囲、設定値は変更していない。Studioへの補助追加も0件で、除去すべきRuntime補助はない。Playの開始・停止・再起動、Save／Publish、保存GUI、Placeファイル直接書込み、本番DataStore操作、reset、実課金、PR #1変更を行っていない。既存の未保存編集を復元／上書きしていない。

Git変更はこの報告書・数値証拠・DEV_STATUS/CHANGELOGの調査記録のみ。仕様変更はないためGAME_SPEC/BALANCE_SPEC/UI_SPECの既存仕様を書き換えない。古いSPECの監視周期などは、現行Sourceと異なる点としてこの報告書に残す。文書commitと通常pushの結果は作業完了回答に記載する。
