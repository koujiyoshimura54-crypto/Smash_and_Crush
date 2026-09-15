# GAME_SPEC — ゲーム仕様正本

Version: 1.1 / 監査・更新日: 2026-09-15 / プロジェクト: Smash_and_Crush

## 適用と情報の優先順位

本書・[BALANCE_SPEC](BALANCE_SPEC.md)・[UI_SPEC](UI_SPEC.md)・[DEV_STATUS](DEV_STATUS.md)を今後の開発の正本とする。これは現在の実装を記録する初期版であり、暫定実装をすべて最終承認したという意味ではない。

初期整理の根拠は、(1) 現在のStudio実装、(2) プロジェクト内の最新レポート/CSV、(3) 明確に確定した設計、(4) 古い仕様・コメントの順。今後のユーザー最新指示はSPECに優先する。実装とSPECが食い違った場合は「仕様不一致・要確認」を残し、既存の片方を黙って書き換えない。

状態は **実装済み／暫定実装／未実装／将来予定／要確認** に分ける。「実装済み」は今回のソース・Object監査で存在と接続を確認した意味で、全機能のPlay合格を意味しない。今回Playを開始せず、ModuleScriptのrequire・DataStore読書き・Studio変更・Publishを行っていない。

証拠: [監査概要](../reports/Implementation_Audit_20260915/audit_summary.md)、[2026-09-15 World1後半Play報告](../reports/World1_Stage6_10_20260915/build_report.md)。既存のPlay結果と今回の静的監査結果は区別する。

## 名称・接続対象

| 項目 | 現在確認できる値 |
|---|---|
| プロジェクト名 | Smash_and_Crush |
| ユーザー指定の英語ゲーム名 | Train to Smash Everything |
| 接続Studioの表示名 | +1 スマッシュ&クラッシュ |
| PlaceId | 101572058398926 |
| プロジェクトルート | C:\Users\kouji\Smash_and_Crush |

英語名・Studio名・公開タイトルの統一は未確認（DEV_STATUS K01）。公開ページの名称やUniverseIdを推測して補完しない。別プロジェクトのHaisarino Churarino Blender成果物は今回のゲーム仕様の完成機能に含めない。

## コアループとソロ進行

LobbyでTrainingまたは歩行によってStrengthを増やす → 自分の現在StageのWall .1〜.4を壊す → Bossを倒す → 次Stageへ進む、または出現した黄色RewardPadを取得してWinを得てLobbyへ戻る → 装備購入・Merge・Rebirthで育成を続ける。

「ソロ進行」は同じサーバー内でもPlayerごとにHP・Stage・報酬状態を持つ方式。単一Player専用サーバーという意味ではない。Wall/Boss HP、Cleared、Skipped、戦闘判定、Reward所有はPlayerごと。Bossモデルと物理Colliderの一部はサーバー共有であり、完全に相互干渉がないと断定しない。多人数同時Boss戦・Gate表示は別途検証する（K12）。

根拠: [ServerScriptService.World.EnemyManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.EnemyManager.luau)、[ServerScriptService.World.Stage1WallManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.Stage1WallManager.luau)、[ServerScriptService.Services.TrophyRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrophyRewardService.luau)。

## World / Map / Lobby

| 対象 | 状態 | 実装 |
|---|---|---|
| World1 | 実装済み | Workspace.GeneratedMap。TrainingArea、LobbyCorridorConnector、BattleCorridor、NextWorldArea |
| World1 Stage1〜10 | 実装済み | BattleCorridor.Stage01〜Stage10。各StageにWall .1〜.4、Boss区画 .5 |
| World1 Map拡張 | 実装済み | 各Stage Floor幅90stud。全体配置は監査Object記録参照 |
| Lobby | 実装済み | GeneratedMap.TrainingArea。SpawnLocation、育成・購入UIへの導線 |
| Training機器 | 実装済み | Workspace.Treadmill.Tredmill01〜10。World2Map内の複製とは別 |
| World2Gate | 暫定実装 | Workspace.World2Gate。Lobby側の表示・装飾。配置属性はTemporary - BackWall preview |
| World2 Map | Grayboxのみ | Workspace.World2Map。SourceWorldId=1、WorldId=2、IntegrationStatus=AuthoringOnly |
| World2 HP Config | 暫定実装 | Studio上は旧World1基準×25,000の旧暫定値。今後採用するWorld2専用BalanceはBALANCE_SPECを正とし、まだStudio未反映 |
| World2移動・Combat・Stage進行 | 未実装 | StageProgressControllerはGeneratedMapだけを初期化。World2Mapに接続しない |
| World2 Enemy Asset | 未確定 | World2用Assetは今後選定 |
| World2育成・Inventory | 設計確定・未実装 | World2到達時にWorld2専用Inventoryを解放。World1 ItemもWorld2で装備可能で性能値は変えず、World2専用Itemの方を強く設計する |
| 以降のWorld | 将来用領域のみ | NextWorldAreaの存在はプレイ可能Worldの実装完了を意味しない |

StageWidth/StageLength属性やModel Pivotには古い配置情報が残る。配置変更時は実Floor/Spawn/ZoneのCFrameとSizeを監査する。属性を実寸の代わりに使わない（K05）。詳細: [Object監査](../reports/Implementation_Audit_20260915/scene_objects.json)。

### 2026-09-15追記：World1後半のBoss位置

Stage6〜10のEnemySpawnを既存位置から相対+Zへ4 / 3.5 / 3.25 / 6 / 1stud後退した。変更後Zは365.54001 / 463.13998 / 555.98993 / 636.83997 / 715.93994。X/Y/回転、Wall .4、Floor、RewardPad位置は維持。

EnemyManagerのStatic Boss表示倍率は、移動するRootではなく既存StageN.5.Floor中心を参照して算出する。Spawn後退に伴う自動縮小を防ぐためで、実Scale・DisplayHeight・Collider/CombatZone Sizeは変更前と一致する。実位置は引き続きEnemySpawnから生成する。

歩行での接近・戦闘開始/離脱/再接近/撃破、HP UI追従、Pad非干渉をPlay確認した。今回の目的は「Wall .4撃破後にBossが近すぎて見づらい状態を改善すること」であり、Wall .4手前の低いカメラからBoss全体を見せることは要件ではない。Spawn後退による間隔調整は完了扱いとする。詳細は[間隔レポート](../reports/World1_Stage6_10_Spacing_20260915/build_report.md)。Carry・Balance・World2は変更していない。

## Strength / Step / Training / Level

- Strengthはサーバーが保持する非負の数値。小数を保持する。表示のK/M短縮を内部値に使わない。
- Stepは現行実装では「地上歩行時間に応じた0.5秒tick」。一定移動距離ごとの歩数ではなく、独立した保存Step通貨・StepCount・Step Levelは確認されない。
- 歩行中、HumanoidがRunning/RunningNoPhysicsで入力方向または水平速度条件を満たすとStrengthを得る。Training中・戦闘中・Treadmill占有中には歩行分を付与しない。
- TreadmillのTrainingZoneに入ると、自動で使用条件を判定して0.5秒ごとにTraining。退出・死亡・機器消失で停止。固定席数の予約ロックは確認されず、Player単位のTraining状態を持つ。
- 歩行ではDumbbell加算なし。TrainingはDumbbell/Aura/Proteinを基礎値に加算し、Rebirth・Treadmill・Potion・VIPを計算する。正確な式はBALANCE_SPEC。
- Levelは現在Strengthから導く値。独立XPを加算する方式ではない。Lv1〜50は固定表、その先はLv50を基点にした二次式。

根拠: [ServerScriptService.Systems.Controllers.TrainingController](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.TrainingController.luau)、[ServerScriptService.Services.TrainingManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrainingManager.luau)、[ServerScriptService.Services.StrengthManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.StrengthManager.luau)。

## Rebirth

実装済み。World1上限5回。次回に必要なLevelを満たすとRebirthCountを1増やし、Strength=0／Level=1へ戻す。現在のControllerはStage進行・Win・所有装備・HighestUnlockedWorldをリセットしない。Rebirth6以降の数表は存在するが、現行World1の操作では到達不可。World2用のRebirth解放条件は未実装。

根拠: [ServerScriptService.Systems.Controllers.RebirthService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.RebirthService.luau)、[ReplicatedStorage.Config.RebirthConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.RebirthConfig.luau)。

## Stage / Wall / Boss / Combat

実装済み。参加・通常Run開始はStage1。Skip開始は指定Stageから始まり、前StageはSkipped扱い。現在StageのWallを順番に進め、4枚突破後にBossを解放する。

Wallの攻撃力は攻撃時のStrength。Glove補正はWallには加えない。余剰は同Stageの次WallへCarryし、同一攻撃で複数枚を突破する場合がある。Wall4後の余剰はBossへもQueueされる。**Boss Carryは現在実装済みだが、今後維持するかは要検討**（K03）。

自動戦闘はPlayer前方のWallCombatTriggerとWall/CombatZoneの接触で開始。CombatTypeは実装上「Wall」または「MiniBoss」。Boss CombatZoneは戦闘開始判定、MiniBossColliderは物理衝突であり、役割を分ける。

Bossは戦闘開始時のStrength・Glove・RequiredStrength比率を固定する。比率1以上は通常ダメージ、1未満は抽選ルート。抽選と回数制限はBALANCE_SPEC。離脱時は現在戦闘を終了し、同じBossのHP・抽選結果は同Run内で保持する。Boss再生成やRunリセットとの境界はEnemyManager/BossCombatServiceに従う。

Boss撃破で個人のStageが進む。Stage10撃破でWorldComplete=true。敗北では死亡演出後にLobbyへ再SpawnしRunをリセットする。Stage6〜10のBoss差し替え、大型Collider、HP UIは実装済み。過去のシーサー用分岐や名前だけのコメントを現在のBoss仕様と混同しない。

根拠: [ServerScriptService.World.EnemyManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.EnemyManager.luau)、[ServerScriptService.World.BossCombatService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.BossCombatService.luau)、[ServerScriptService.World.StageManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.StageManager.luau)。

## RewardPad / Win / Item Drop

- Boss撃破時にWinを直接付与しない。本人用の黄色PadがBoss区画左側に出現する。
- Pad踏み込みをサーバーが所有者・Boss撃破済み・身体との実重なりで検証。取得ロックにより二重付与を防ぐ。
- 取得でStage別Win×有効DoubleWin倍率を加算し、全Padを消し、回復してLobbyへ戻りRunをStage1へリセットする。
- 途中StageのPadを取らず、次Stageへ進むことも可能。PadとBoss進行は独立している。
- Item DropはPadと別。各Player/Run/StageのBoss撃破につき1回の抽選。ITEMなら所有Inventoryへ付与し、本人へ結果通知。現在は20% ITEM／80% MISS。
- Winは非負整数。Pad以外にDaily/Time/Community/Packから獲得する。通常Item・Dumbbell・Aura・Speed・Stage Skipに消費する。
- TrophyRewardConfigに「Temporary World1 Play-debug」とあるため、現在のWin報酬表は実装済みの暫定値として扱う（K02）。

## World解放 / HighestUnlockedWorld / WorldComplete

| 状態 | 保存 | 更新条件 |
|---|---|---|
| CurrentStage / Cleared / Skipped / Wall・Boss HP | Run内のみ | 各Playerの進行 |
| WorldComplete | 永続保存しない | Stage10 Boss撃破でtrue、Run初期化でfalse |
| HighestUnlockedWorld | 永続保存する | 初期値1。**Stage10 RewardPad取得**で2へ上げる |
| GateのLocallyUnlocked | ローカル表示のみ | LocalPlayer.HighestUnlockedWorld>=2 |

Stage10 Boss撃破だけでHighestUnlockedWorldは上がらない。永続World2解放はStage10 RewardPad取得時にHighestUnlockedWorld=2とする現行仕様で確定。保存時はHighestUnlockedWorldを既存値とのmaxで保持する。CanAccessWorld(player,world)はサーバーの保存セッションを確認するが、Gate移動にはまだ接続されていない。

根拠: [ServerScriptService.Services.TrophyRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrophyRewardService.luau) collect、[ServerScriptService.Services.PlayerDataService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.PlayerDataService.luau) UnlockWorld/CanAccessWorld、[StarterPlayer.StarterPlayerScripts.World.WorldGateClient](../reports/Implementation_Audit_20260915/sources/StarterPlayer.StarterPlayerScripts.World.WorldGateClient.luau)。

## Inventory / Merge

実装済みInventoryはDumbbells／Items／Merge／Aura／Speedの5タブ。通常ItemはProtein、Glove、TrainingBeltに各1装備枠。3属性×5Rare度×3種=45 Item定義。所有数は数量、装備には所有を検証する。Best Equipは各種類の最高Rarityを選び、同等の有効な現装備は維持する。

Mergeは同一ItemId3個を消費して同種・同属性の次Rarity1個にする。LegendaryはMerge不可。Dumbbellは7種の購入・所有・装備を実装しているが、Mergeable=trueという定義だけでDumbbell Merge実装済みと判断しない。現行MergeServiceは通常Itemのみ（K07）。

Auraは同時に1つ、Speedは購入済み/Pass所有から最適なWalkSpeedを適用。金額・効果・装備状態の決定はサーバー。

根拠: [ServerScriptService.Services.ItemService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.ItemService.luau)、[ServerScriptService.Services.ItemMergeService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.ItemMergeService.luau)、[ServerScriptService.Services.DumbbellService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.DumbbellService.luau)、[StarterGui.StrengthGui.InventoryTabsClient](../reports/Implementation_Audit_20260915/sources/StarterGui.StrengthGui.InventoryTabsClient.luau)。

## World2 Inventory / Item 方針

World2到達時にWorld2専用Inventoryを解放する。World2専用Item群はWorld2のStrength帯に合わせて新規設計する。World1 ItemはWorld2でも装備可能で、World移動による性能値の弱体化は行わない。World2 Itemをより強く設計することで、World1 Itemは相対的に弱くなる。World1 InventoryとWorld2 InventoryのUI/データ構造の詳細は実装Phaseで確定する。

## Shop / Game Pass / Developer Product

- 実装済み: Starter Pack、Secret Pack、VIP、Premium Speed、World1 DoubleWin、Red Aura、通常ItemのRobux購入、Stage Skip。
- 商品IDと効果はBALANCE_SPEC。表示価格はMarketplace取得を優先し、ConfigのFallbackPriceを確定販売価格と呼ばない。
- Premium Treadmillは機器・倍率定義のみあり、専用PassId=0で利用不可。
- BUY WINの導線はあるがWinProductsが空。未確定IDを使ったWin販売は未実装。
- Game Pass所有はサーバー確認。StudioではGamePassEffectsEnabled=falseにより所有状態と効果適用を分離する。
- Developer Productは単一ProcessReceipt経路。Item購入は選択ItemのIntentとReceiptの永続管理を行い、未解決処理を重複付与しない。
- Secret PackはPaidRandomAllowed確認を持つ。権利確認や商品効果をクライアント表示から推測しない。

## Daily / Time / Community Reward / Potion

DailyはUTC日付で1日1段階、7段階の一度きり系列。欠席で連続日数を初日に戻す処理や、Day7後に循環する処理はない。VIPの日次Winは通常Day7完了後も別枠。

Time Rewardは累積オンライン時間とClaim状態を永続保存。最後の閾値2700秒まで蓄積し、日次リセットではない。受取順番号は定義されるが、Serviceの実条件は各閾値到達・未取得であり、前報酬の取得を必須にしていない。

Daily/TimeのItemRollにはMISS抽選がない。ただし受取時のCurrentStageによるRarity解放制限がかかる。過去最高到達Stage基準ではない（K08）。

通常Potionは取得時に即時発動し、同種は倍率ではなく残り時間を加算する。通常タイマーはセッション内。Shop PackのPotion期限はShopRewardsにUTC期限として保持するため同一扱いにしない。

Community RewardはGroupId 787332211への加入をサーバーで検証して一度だけ3 Win＋Item1個。今回、外部グループの実在や実課金の再検証はしていない。

## Data保存

根拠: [ServerScriptService.Services.PlayerDataService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.PlayerDataService.luau)、[ServerScriptService.Systems.Controllers.PlayerDataController](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.PlayerDataController.luau)、[ServerScriptService.Systems.Purchases.ReceiptService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Purchases.ReceiptService.luau)。

| Store | 本番 | Studio |
|---|---|---|
| プレイヤーデータ | PlayerData_v1 | PlayerData_v1_Studio |
| 累計Strengthランキング | TotalStrengthRanking_v1 | 同名＋_Studio |
| 日次Strengthランキング | DailyStrengthRanking_YYYY-MM-DD | 同名＋_Studio |
| 商品Receipt台帳 | DeveloperProductReceipts_v1 | セッション内メモリ |
| Item購入Intent | ItemPurchaseIntents_v1 | セッション内メモリ |

PlayerData keyはPlayer_<UserId>。主な保存項目はStrength、RebirthCount、Win、TotalStrengthEarned、DailyStrengthEarned、DailyDate、OwnedSpeeds、OwnedDumbbells/EquippedDumbbell、OwnedAuras/EquippedAura、OwnedItems/EquippedItems、TutorialCompleted、TimeRewards、DailyRewards、CommunityRewards、ShopRewards、HighestUnlockedWorld、ResetToken。Receipt/Mutationの再実行防止用メタデータも使用する。LevelはStrengthから再計算し、CurrentStage/WorldCompleteは保存しない。

通常Autosaveは90秒、最大6並列。退出・Shutdown時の保存あり。UpdateAsync、Dirty世代、ResetToken、数量更新のPendingItemMutationを使用する。日次StrengthランキングはJST、Daily RewardとVIP DailyはUTC。今回は保存処理を実行せず、ソース監査だけを行った。

## 今後の変更

未確定・予定は[DEV_STATUS](DEV_STATUS.md)へ集約する。World2再計算、移動、Combat、Asset選定を今回の仕様書作成だけで承認済み実装タスクにしない。変更時は[AGENTS.md](../AGENTS.md)に従って範囲を限定し、関連SPECと検証根拠を更新する。
