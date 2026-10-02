# Merge to Forge - Legacy World1 Map Interface

## 1. Scope / Authority

再構築日: **2026-10-02 / Y01**。消失した旧manifestの復元ではなく、現在のconsumerから再抽出したWorld1用の契約書。

- 第一正本: `koujiyoshimura54-crypto/Smash_and_Crush` の取得済み `origin/main`、commit **572edcf65a225f14ce83bad80717fc07c55e07f2**。本書はこのcommitのSourceを根拠とする。
- 旧Studio: PlaceId **101572058398926**。EditでInstance構造を読み取り、Sourceが要求する実物を照合した。Studio全ScriptとGitの完全一致を保証する調査ではない。
- 新Studio: PlaceId **126576845524886**。Editの `Workspace.MergeToForge_GameplayGeometryPreview` を読み取り。`Workspace.GeneratedMap` は存在しない。
- 前PCのmanifest本文・推測・過去コメントを根拠に要求を追加していない。World2はWorld1との接続口だけ記載。
- 本作業はdocumentationのみ。Source/Instance変更、Clone、require、Play、Save、Publish、Legacy起動なし。

以下の略記を使用する。`N=1..10`、`NN=01..10`、`i=1..4`。パス内の `StageNN` は `("Stage%02d"):format(N)`、`StageN.i` は `("Stage%d.%d"):format(N,i)`。ドットを含む名前は子Model名そのものであり、階層区切りではない。

| 略記 | 完全パス |
|---|---|
| G | `Workspace.GeneratedMap` |
| S | `Workspace.GeneratedMap.BattleCorridor.StageNN` |
| P | `Workspace.MergeToForge_GameplayGeometryPreview` |
| E | `src/ServerScriptService/World/EnemyManager.luau` |
| SM | `src/ServerScriptService/World/StageManager.luau` |
| WM | `src/ServerScriptService/World/Stage1WallManager.luau` |
| Chase | `src/ServerScriptService/World/BossChaseService.luau` |
| Attack | `src/ServerScriptService/World/BossAttackService.luau` |
| Progress | `src/ServerScriptService/Systems/Controllers/StageProgressController.server.luau` |
| CC | `src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau` |
| Trophy | `src/ServerScriptService/Services/TrophyRewardService.luau` |
| Training | `src/ServerScriptService/Services/TrainingManager.luau` |

Statusは対応の完了状態と混同しない:

- **Confirmed**: consumerと旧Studio実物を確認。新Mapへ実装済みという意味ではない。
- **Adapter needed**: 要求とPreview候補を確認したが、階層・名前・Part契約等の対応が必要。
- **Optional**: consumerが存在しなくても処理できる、または指定機能だけの条件付き依存。
- **Source-confirmed / Studio-unverified**: consumerを確認したが、対応する編集時実物は未照合。
- 未決事項は§10へ分離。以下のID付き表は**38契約項目**（動的なStage/Wallごとには重複計上しない）。

集計: Confirmed **9** / Adapter needed **15** / Optional **11** / Source-confirmed・Studio-unverified **3**。未決事項 **6**、Preview mapping family **11**。runtime生成物はPlayせずに実在確認できなかったため、Source確認と区別した。

## 2. Root Structure

旧Studioで確認した主要構造。機器・Shop・BoardはすべてTrainingAreaの子という設計ではない。

```text
Workspace
├─ GeneratedMap (Model)
│  ├─ TrainingArea (Model)
│  │  ├─ Floor (BasePart)
│  │  └─ SpawnLocation (SpawnLocation)
│  ├─ BattleCorridor (Model)
│  │  └─ Stage01 .. Stage10 (Model)
│  └─ NextWorldArea (Model; optional legacy geometry)
├─ Treadmill (Folder)
│  └─ Tredmill01 .. Tredmill10 (Model; exact spelling)
├─ DailyStrengthRankingBoard / TotalStrengthRankingBoard (Model)
├─ ShopStallTemplate (Model; capacity upgrade mount)
├─ World1DoubleWinShop (Model)
└─ World2Gate (Model; separate from NextWorldArea.NextWorldGate)
```

| ID / Legacy Path / Pattern | Class | Required | Consumer | Purpose | Current Preview Mapping | Status |
|---|---|---|---|---|---|---|
| R01 `G` | Model in old Studio | Yes | Progress.tryInit; E.Initialize; SM.Initialize | World1 runtime root | Pを保持し、将来別の互換rootへClone | Adapter needed |
| R02 `G.BattleCorridor` | Model in old Studio | Yes | Progress.tryInit; SM.Initialize | Stage列挙。起動には直下Stage10の存在を確認 | Pの10 Stageを受ける新規container候補 | Adapter needed |
| R03 `G.TrainingArea` | Model | Yes for lobby | Trophy.GetLobbySpawn; E.updateCombat; Training.applyGroupMats | 帰還・Lobby範囲・機器周辺 | `P.Lobby` | Adapter needed |

**起動境界:** ProgressはGeneratedMapをポーリング/ChildAddedで検知して `E.Initialize()` を呼ぶ。後工程でGeneratedMapを作る際も、LegacyのScriptを休眠のまま保つこと。GeneratedMapを作っただけで安全な検証環境になるとは限らない。現在の休眠rootは `ServerStorage.MergeToForge_LegacySystem`。

## 3. Stage Interface

| ID / Legacy Path / Pattern | Class | Required | Consumer | Purpose | Current Preview Mapping | Status |
|---|---|---|---|---|---|---|
| S01 `S` | Model | Yes, 10 | SM.Initialize; WM.GetCurrentWallForStage; E.spawnEnemy | `^Stage(%d%d)$`を列挙・数値順に処理 | `P.StageNN` | Adapter needed |
| S02 `S.Floor` | BasePart | Yes | Chase.Register; Attack.GetAttackBounds; E.attachEarlyStageVisual / attachStaticStageVisual等 | main Arena矩形・Boss床合わせ・攻撃高さ基準 | `P.StageNN.WalkableGeometry.Floor` と `BossArea.Floor` の範囲を踏まえた**未決の参照床** | Adapter needed |
| S03 `S.LeftWall` / `S.RightWall` | BasePart each | Optional | Chase.Register | main FloorローカルXの内側境界を狭める | `P.StageNN.Boundaries` 内の左右Environment/BossArea境界 | Optional |
| S04 `S.Gate` | BasePart if present | Optional | SM.Initialize | 存在すればCanCollide=false、Transparency=1 | Previewに対応不要。旧Stageにも今回確認なし | Optional |

**main Floorと`.5.Floor`は別契約。** 現行Chase.Registerは `stageModel:FindFirstChild("Floor")` を使い、`.5.Floor`を使わない。FloorのCFrame/SizeからX/Z半径とedge marginを求め、Boss footprintを含めてClampする。左右壁はPositionとSize.X、Stage10終端はPositionとSize.Zで補正する。複雑な岩ModelやObjectValueではこのアクセスを満たせない。

旧main Floorは幅90、厚さ2、Stageごとの全長を持つ一枚。新PreviewはBattle側幅48.4、Boss側幅86の二つの床で、厚さ8・上面Y=4。Battle側Floorだけを `S.Floor` にするとBossAreaをChase範囲に含められない。二つを包む矩形にすると細いBattle側の外まで許可し得る。参照矩形と実際の可動領域の対応は§10 U1を先に解決する。

## 4. Wall Interface

| ID / Legacy Path / Pattern | Class | Required | Consumer | Purpose | Current Preview Mapping | Status |
|---|---|---|---|---|---|---|
| W01 `S["StageN.i"]` | Model | Yes, 40 | WM.GetCurrentWallForStage; CC.wallModel | 個人Wall進行に対応する4子Model | `P.StageNN.Walls.Wall01..04` | Adapter needed |
| W02 `S["StageN.i"].Wall` | BasePart, direct child | Yes | E.updateCombat/boxesOverlap; CC.wallSurface/setWallVisible | WallCombatTriggerとのOverlap対象、壁の個人可視/衝突処理 | 各Wallの `Visual` / `Collider` / `HitZone`。どれを判定正本にするか未決 | Adapter needed |
| W03 `...Wall.StageSurface` | SurfaceGui | Yes for existing wall/Boss UI | CC.wallSurface; WallGaugeLayout.ApplyBoss | 壁HP表示とBoss用表示のreference | PreviewのWallに存在しない | Adapter needed |
| W04 `...StageSurface.Panel` → `HPBar.Fill`, `HPBar.HPLabel`, `StageNumber` | Frame + UI descendants | Yes for existing UI | CC.wallGauge / clearWallGauge / WallGaugeLayout | Gauge更新・コピー元レイアウト。旧PanelにはHeading/Accent等も存在 | 旧UI構造の導入が必要。購入Wall geometryの差し替えは不要 | Adapter needed |
| W05 `S["StageN.i"].CombatZone` / `.Floor` | BasePart each | Not used for current wall combat start | 旧Studio40組確認; E.updateCombatはこれらを読まない | 旧assetに残る補助構造 | Preview.HitZoneを自動的にCombatZoneへ対応させない | Optional |
| W06 Wall `MaxGauge`, `WallIndex`; CombatZone `WallIndex` | Attributes | Not authoritative for current damage | 旧Studio確認; WMの設定はWorld1BossConfig由来 | 旧asset情報。必要HPを属性だけで設定できるわけではない | PreviewのOriginalPosition/OriginalCFrame等とは別 | Optional |

現行戦闘開始は、E.ensureWallCombatTriggerが用意する**Character用runtime `WallCombatTrigger`**と、現在Wall Model直下`.Wall`のOverlap。PreviewのHitZoneや旧MapのCombatZoneが自動的に使用されるわけではない。

CC.setWallVisibleはWall Modelの子孫のうち、**BasePartかつ名前が`Wall`**のものだけ可視性・Collisionを切り替える。単にModel名を合わせ、透明な`.Wall`を一つ追加するだけでは、購入WallのVisualが残り、Colliderが通路を塞ぎ続け得る。将来のClone側で判定Partと表示/衝突Partの対応を設計すること。新Sourceは今回変更しない。

旧Studioは40/40で `.Wall.StageSurface` と補助CombatZoneを確認。Previewは40/40のWall Modelが存在し、Stage01.Wall01の直接子は `Visual` / `HitZone` / `Collider`（すべてPart）。旧UIはない。

## 5. Boss Interface

| ID / Legacy Path / Pattern | Class | Required | Consumer | Purpose | Current Preview Mapping | Status |
|---|---|---|---|---|---|---|
| B01 `S["StageN.5"]` | Model | Yes | Trophy.Spawn; CC.showBossRecommendation; E.attachStaticStageVisual | Boss領域・Trophy・表示基準 | `P.StageNN.BossArea` | Adapter needed |
| B02 `S["StageN.5"].Floor` | BasePart, direct child | Yes | Trophy.Spawn; CC.showBossRecommendation; E.attachStaticStageVisual | Trophy左側配置、推奨Level表示、Bossサイズ基準 | `P.StageNN.BossArea.Floor`（寸法を保持） | Adapter needed |
| B03 `S["StageN.5"].EnemySpawn` | BasePart | Yes, 10 | E.spawnEnemy（Stage配下recursive検索）; Trophy.Spawn（.5直下検索） | Boss初期CFrame。両consumerを満たす配置が必要 | `P.StageNN.BossSpawn` と完全同一CFrameの将来alias Part | Adapter needed |
| B04 `S["StageN.5"].MiniBossSpawn` | BasePart | Optional fallback | Trophy.Spawn | EnemySpawnがない場合のfallback。EはEnemySpawn必須 | Previewには必要なし。B03を優先 | Optional |
| B05 `Workspace.Enemies.StageNN_Enemy` → `HumanoidRootPart`, `CombatZone`, `MiniBossCollider`, Visual | Model + runtime Parts | Runtime | E.spawnEnemy/createMiniBossCollider; Chase.Register; CC.enemy | 個人Combat表示と共有Boss実体 | **Mapへ作成しない**。将来EnemyManagerが生成 | Source-confirmed / Studio-unverified |
| B06 `Workspace.PersonalCombatVisuals.BossDisplaySurface` 等 | Client runtime Folder/Part/UI | Runtime | CC.mount / overheadBounds | Player個別のBoss追従Gauge | **Map固定Gauge marker不要** | Source-confirmed / Studio-unverified |
| B07 `S10.Stage10BoundaryWall` (`S10=G.BattleCorridor.Stage10`) | BasePart | Needed for existing terminal UI; optional Chase clamp | Chase.Register; CC.bossWall | 終端Z境界・Stage10 Gauge用reference | `P.Stage10.World1End.GreenCliffEnd` または `World1EndRock` の終端に合わせるmarker候補 | Adapter needed |

EnemySpawnは位置だけでなく**Rotationも含むCFrame**を一致させる。E.spawnEnemyはそのCFrameにローカルY+3.5を加えてBossを初期配置し、各Visual床合わせを行う。BossSpawnを消す必要はないが、異なる位置のEnemySpawnを複数置くとrecursive検索の選択が曖昧になる。`.5`直下に唯一のEnemySpawnを置けば両consumerを満たせる。ObjectValueは代用不可。

`BossCombatService` は状態/Config主体で、独自のMap markerを要求しない。`BossVisualPlacement.Build` はE.spawnEnemyの **worldId==2分岐**から呼ばれるため、そこにあるWorld2 placeholder要件をWorld1へ転記しない。Bossテンプレート/Animation/VFXは別途System Assetであり、互換MapにScriptとして含めない。

## 6. Lobby / Training Interface

| ID / Legacy Path / Pattern | Class | Required | Consumer | Purpose | Current Preview Mapping | Status |
|---|---|---|---|---|---|---|
| L01 `G.TrainingArea.Floor` | BasePart | Yes for lobby behavior | E.updateCombat; `src/StarterGui/StrengthGui/RunReturnClient.client.luau` Heartbeat | Lobby X/Z判定、Back表示抑制、速度reset | `P.Lobby.Baseplate` | Adapter needed |
| L02 `G.TrainingArea.SpawnLocation` | SpawnLocation preferred; return accepts BasePart | Yes | Trophy.GetLobbySpawn; E.InitializePlayer; Progress.route/arrivalCFrame; RunReturnService.Request | 帰還・Respawn共通基準 | Preview.LobbyにSpawn markerなし。位置未決 | Adapter needed |
| L03 `Workspace.Treadmill` | Folder | Yes when Training loaded | Training module top-level WaitForChild | runtimeロードの待機依存 | 後工程でWorkspace直下へ機器用container。Lobby内の位置は未定 | Confirmed |
| L04 `Workspace.Treadmill.Tredmill01..10` + tag `TrainingTreadmill` | Model + CollectionService tag | Yes for those machines | Training.Initialize/CanUseTreadmill; TrainingController.initialize; TreadmillConfig.Get | Config.Assignmentsの正確なModel名で機器選択 | 後工程のLobby機器。Previewには存在しない | Confirmed |
| L05 各Tredmill直下 `TrainingZone` | BasePart | Yes | Training.GetOccupiedTreadmill/IsPlayerInsideZone | RootのzoneローカルX/Zと実Foot下端のY判定 | 後工程で機器と一緒に導入。固定新座標は未設定 | Confirmed |
| L06 `TrainingZone.VisualRoot` / Config指定のvisual | Attachment / Model | Conditional | `src/ServerScriptService/Services/TreadmillVisualService.luau` Apply | VFX位置。Attachmentがなければruntime生成 | 機器asset側。新Map marker不要 | Optional |
| L07 Tredmill内Belt / `TreadmillUIDisplay.TreadmillInfo.{Required,Strength}` | BasePart / SurfaceGui / TextLabels | Optional presentation | `src/StarterPlayer/StarterPlayerScripts/UI/TreadmillGuideClient.client.luau` findBelt; `TreadmillUIClient.client.luau` refresh | BeltはVisualRole属性または寸法8×0.98×18で発見。案内/倍率表示 | 後工程の機器assetを保持 | Optional |
| L08 `G.TrainingArea.TrainingSpace_1_<index>` | BasePart | Optional | Training.applyGroupMats | `Tredmill(%d+)`からindexを抽出してマットを参照 | Previewにはなし。training本体には必須でない | Optional |
| L09 `Workspace.DailyStrengthRankingBoard` / `TotalStrengthRankingBoard` | Model | Conditional on boards | `src/ServerScriptService/Systems/Controllers/RankingBoardController.server.luau` refresh/labels | Workspace直下Boardを更新 | 後工程のLobby配置。専用Map marker名はない | Confirmed |
| L10 Board子孫 `RankingSurfaceGui.ScrollingFrame` + `UpdatedLabel`（または`Background.RankingFrame`形式） | SurfaceGui / Frames / Labels | Conditional on boards | RankingBoardController.labels/rowObjects | `Row%02d`、TextLabelまたはFrame内Rank/UserName/Amount。旧Studio両BoardはScrollingFrame/Row01..10形式 | Board asset内部を保持。Previewにはなし | Confirmed |
| L11 `Workspace.ShopStallTemplate` | Model | Yes for capacity kiosk | `src/StarterGui/StrengthGui/InventoryCapacityUpgradeClient.client.luau` attachStall | GetPivot×InventoryCapacityPreviewConfig.TriggerOffsetからclient trigger生成 | 後工程のLobby Shop asset。配置/向き未定 | Confirmed |
| L12 `Workspace.World1DoubleWinShop.Pedestal` | BasePart under Model | Conditional on double-win shop | `src/ServerScriptService/Systems/Controllers/GamePassController.server.luau` isInside | Pedestal footprintに左右2stud等を加えた入場判定 | 後工程のLobby Shop asset。配置未定 | Confirmed |
| L13 `World1DoubleWinShop` 子孫 `PurchasePrompt` | ProximityPrompt | Optional | GamePassController top-level | 古いE/Tap promptを無効化しPedestal入場方式を使う | 機器asset内部。新Mapに別triggerを作る要件なし | Optional |

Trainingは現在tag登録を使う。TreadmillがTrainingArea直下である必要はないが、top-level WaitForChildのため `Workspace.Treadmill` は必要。旧Studioで10 ModelとTrainingTreadmill tag、TrainingZoneを確認した。旧assetには一部belt Part内Scriptがあるため、将来機器を移す際はMap geometry-only工程と実行asset工程を分ける。

`Training.CreateTreadmill(area)` は残存helperであり、現行TrainingControllerはこれを呼ばない。そのhelperの `TrainingArea.Treadmill01` を現行 `Tredmill01` と取り違えて必須構造に追加しない。

Rebirth、Speed、RunInventory、一般ShopRewardのServer処理は、今回確認したconsumerでは新しいMap-side machine/markerを要求しない。Rebirth専用machineやSpeedShop位置を推測で定義しない。ただし**Capacity UIはShopStallTemplateのPivotを読む**ため、単なる画面UI扱いにはできない。RunReturnServiceはTrophy.GetLobbySpawnへ帰還を集約しており、別ReturnPointは不要。

この確認で参照したSourceは `src/ServerScriptService/Systems/Controllers/RebirthService.server.luau`、`src/ServerScriptService/InventoryCapacityController.server.luau`、`src/ServerScriptService/Services/` の `SpeedService.luau`, `RunInventoryService.luau`, `RunReturnService.luau`, `ShopRewardService.luau`。機器登録のentrypointは `src/ServerScriptService/Systems/Controllers/TrainingController.server.luau` のinitialize、名前対応は `src/ReplicatedStorage/Config/TreadmillConfig.luau` のAssignments/Get。

## 7. Trophy / Stage Completion Interface

| ID / Legacy Path / Pattern | Class | Required | Consumer | Purpose | Current Preview Mapping | Status |
|---|---|---|---|---|---|---|
| T01 `ReplicatedStorage.UI.Templates.TrophyRewardTemplate.Handle` | Model / BasePart | Yes for Trophy | Trophy.Spawn; CC.showTrophy/addTrophyRewardBillboard | clone元・接触判定寸法。FloorButton.CoreのLightは任意演出 | Map外のSystem dependency。新しい固定TrophySpawn不要 | Confirmed |
| T02 `Workspace.PersonalTrophyHitboxes.Trophy_<userId>_StageN` / client `PersonalTrophy` | runtime Folder/Part / Model | Runtime | Trophy.Spawn/collect; CC.showTrophy | Player別取得判定と表示 | runtime生成。Mapへ事前作成しない | Source-confirmed / Studio-unverified |
| T03 `G.NextWorldArea.NextWorldGate` | BasePart | Optional legacy geometry | SM.Initialize | 無効化する旧Gate。World2Gateとは別物 | Previewに同名不要。World1Endへの採用も未決 | Optional |
| T04 `Workspace.World2Gate.WorldGateTrigger` | BasePart under Model | Conditional on world travel | Progress.route/insideTrigger; `src/StarterPlayer/StarterPlayerScripts/World/WorldGateClient.client.luau` gateDefinitions | unlock後のWorld2移動受付 | Preview終端とはまだ対応未決。Gateの配置は後工程 | Confirmed |
| T05 `World2Gate.PortalSurface` / `Sign.SignAnchor.WorldLabel.{Title,Subtitle}` | BasePart / Model / SurfaceGui / TextLabels | Optional gate presentation | WorldGateClient.refreshWorld2Gate | World unlock表示・色変更 | 後工程のGate asset。終端岩から自動生成しない | Optional |

Trophy.Spawnは `S["StageN.5"].EnemySpawn`（またはMiniBossSpawn）とFloorの存在を要求する。ただし実際のTrophy位置はSpawnの座標ではなく、**`.5.Floor`の中心から左側**へ計算する:

```text
inset = max(Handle.Size.X / 2 + 4, Floor.Size.X * 0.12)
local position = (-Floor.Size.X / 2 + inset,
                  Floor.Size.Y / 2 + Handle.Size.Y / 2 + 0.03, 0)
CFrame = Floor.CFrame * local position * Handle.CFrame.Rotation
```

したがって旧`.5.Floor`（奥行5.6）の代わりに新BossArea全体を対応させると、同じSourceでもTrophyのZ位置は新床中心になる。新しいTrophySpawn markerを足してもこのconsumerは読まない。実装工程で床寸法を変えずに実位置を確認する。

SM.ClearStageは進行状態とWorldCompleteを更新。Trophy.collectは所定StageでPlayerData.UnlockWorldを呼び、既存Bank成功後にLobby帰還/resetを行う。Stage10終端岩を直接読んでWorldをunlockする処理ではない。

`WorldGateConfig` はこのGit Source snapshotにファイルがないが、旧Studioの `ReplicatedStorage.Config.WorldGateConfig` と新Stagingの `Source.ReplicatedStorage.Config.WorldGateConfig` に存在する。旧Studio Sourceの値は `GateName="World2Gate"`, `CompletionStage=10`, `RequiredWorld=2`。Moduleは読み取りのみ、requireしていない。古いコメント「travel unconnected」より、現在のProgress.route実装を優先した。

World接続の到着先は `Workspace.World2Map.TrainingArea.World2LobbySpawn`。World1への帰還元は `World2Map.TrainingArea.World1ReturnGate.WorldGateTrigger`、到着先はL02。これは接続仕様の記録でありWorld2実装の指示ではない。

## 8. New Map Mapping

以下は**候補のみ、未実装**。Previewは+300stud移設済みのgeometry正本。旧GeneratedMap/Lobby/Rock/Floorをコピーして代用しない。

| Legacy target | 現在Preview source / 候補 | 件数 / 注意 |
|---|---|---|
| GeneratedMap | P全体の必要geometryをClone | 1 root、Preview保持 |
| GeneratedMap.TrainingArea | P.Lobby | 1 |
| TrainingArea.Floor | P.Lobby.Baseplate | 1、237×8×149、中心(274.5,0,10.5) |
| BattleCorridor.StageNN | P.StageNN | 10 |
| StageNN.Floor | WalkableGeometry.Floor + BossArea.Floorの領域 | 10、契約のみ。参照Part寸法未決 |
| StageNN.StageN.i | P.StageNN.Walls.Wall0i | 40、Visual/Collider/HitZone変換は§4 |
| StageNN.StageN.5 | P.StageNN.BossArea | 10 |
| StageN.5.Floor | P.StageNN.BossArea.Floor | 10、Resize禁止 |
| StageN.5.EnemySpawn | P.StageNN.BossSpawn | 10、全CFrame保持 |
| StageNN.LeftWall/RightWall | P.StageNN.Boundariesの左右境界 | 10対、複合Modelを直接alias不可 |
| Stage10.Stage10BoundaryWall | P.Stage10.World1End.GreenCliffEnd / World1EndRock | 1候補組、どちらの終端面を採用するか未決 |

**11 mapping family**。TrainingArea.SpawnLocationや後置きLobby機器はPreview側の対応Instanceがないため、このMapping数に含めない。Carpet/Tree/Rock/Decorations/StageConnectorsは外観としてClone保持し、今回調査した旧consumer用の特別な名前を新設しない。

| Stage | Preview BossArea.Floor X×Z (stud) | BossSpawn position (stud; 表は丸め、実装時は元CFrameを使用) |
|---|---|---|
| 01 | 86×76.55 | (287.8, 4.5, 198.900) |
| 02 | 86×79.22 | (287.8, 4.5, 312.840) |
| 03 | 86×82.10 | (287.8, 4.5, 442.627) |
| 04 | 86×85.85 | (287.8, 4.5, 553.740) |
| 05 | 86×89.60 | (287.8, 4.5, 698.278) |
| 06 | 86×170.90 | (287.8, 4.5, 892.070) |
| 07 | 86×194.90 | (287.8, 4.5, 1123.517) |
| 08 | 86×140.90 | (287.8, 4.5, 1313.070) |
| 09 | 86×104.90 | (287.8, 4.5, 1466.070) |
| 10 | 86×164.00 | (287.8, 4.5, 1649.484) |

全BossArea床の厚さ8、中心Y=0。Battle側は幅48.4、厚さ8、長さStage01=42.6、Stage02..10=40.1。BossSpawnは1×1×1のPart。これらは測定結果であり変更指示ではない。

## 9. Adapter Requirements

**Map側で合わせられるもの（次工程でのみ実施）**

1. PreviewのCloneからGeneratedMap/TrainingArea/BattleCorridor/StageNNを構成。StageN.i/.5のModel wrapperを直接の子にする。
2. `.5.Floor`はBossArea床を保持。EnemySpawnはBossSpawnと同一CFrameのBasePartを`.5`直下へ一意に用意する。BossSpawn自体は保持可能。
3. Wallには直接子の判定BasePart `Wall` とStageSurface UI契約を用意し、購入Visual/Colliderすべてが個人破壊表示と整合するようClone側を構成する。UI template移植は後工程。
4. Lobby FloorとSpawnLocation、左右境界/終端のBasePart referenceを必要なconsumerの位置へ置く。**ObjectValueにはCFrame/Size/Position/CanCollideがない**ので代用不可。現在の複合境界Modelは外観として保持する。
5. 後置き機器はWorkspace直下など既存consumerが読むParent/name/tagを維持し、物理位置だけLobby内へ配置する。GeneratedMap内部のLuaSourceContainerは0を目標とし、既存機器に含まれるScriptを紛れ込ませない。

**Source変更が必要になり得るもの（今回は変更しない）**

- 非矩形の新Arenaを矩形Floor＋左右壁だけで安全に表せない場合、Chaseの境界入力に最小adapterが必要になり得る。Battle床だけを採用して解決済みにしない。
- 購入Wall内部名を保持したまま個人可視/Collisionを統一できない場合、CC.setWallVisibleの対象指定に最小adapterが必要になり得る。透明alias一個では未解決。
- TrophyをBossArea中心以外の特定Zへ配置したい場合、現在Sourceは専用markerを読まない。先に現在式による位置を確認し、要求があるときだけ別工程で検討する。
- 未移植のGate/Shop機能を起動するにはMapだけでなくConfig/Remotes/UI/Asset依存も必要。これは本書のgeometry互換化とは別工程。

**読取検証とserialization**

- 新Preview: Stage10、Wall40、BossArea10、BossSpawn10。LuaSourceContainer **0**。GeneratedMapなし。両StudioはEdit。
- 新Staging: `Source`, `StudioDependencies`, `InstallMetadata`。LuaSourceContainer **162**、EnabledなBaseScript **0**。StudioDependencies直下は `MergeToForge_SystemTransfer`。
- 既存programmatic API `SerializationService:SerializeInstancesAsync({staging})` が成功し、**629,915 bytes（約615.2 KiB）**のbufferをメモリ上へ生成できた。Instanceの変更や実行はしていない。
- このサイズは**staging全体**のsnapshotであり、消失した旧`World1Dependencies.rbxm`と同一内容という保証ではない。Binaryファイル保存/Commitなし。将来のrbxm再生成は可能だが、Source/metadataを含めるか、StudioDependenciesだけを対象にするかはexport工程で決める。

## 10. Unresolved Items

| ID | 未決事項 | 判明していること / 次工程で必要な判断 |
|---|---|---|
| U1 | main Stage.Floorの参照範囲 | 新Mapは幅の異なるBattle/Boss床。可動領域を外へ広げずに旧矩形Chase契約を満たす設計が未決 |
| U2 | 購入Wallの判定/可視/Collisionの対応 | Visual/HitZone/Colliderが分離。直接子Wallと、個人非表示対象をどのPartに割り当てるか未決 |
| U3 | Lobby帰還SpawnのCFrame | Preview.Lobby配下にSpawnLocation/Spawn名/Trigger名のmarkerなし。既存元World1を勝手に流用/移動しない |
| U4 | Stage10終端参照面とGate配置 | GreenCliffEnd/World1EndRockのどちらを終端referenceにするか未決。World2Gateは別契約。新しい大壁は不要 |
| U5 | 後置き機器の座標・向き | Treadmill/Board/ShopStall/DoubleWinShop等のParent契約は確定。Preview内の最終配置は未定 |
| U6 | 非Git依存のexport対象とstagingの版一致 | WorldGateConfigはStudio/Stagingに存在するがGit Sourceにない。rbxm全体を前PC版と同一と断定できず、staging全ScriptのGit版一致も今回未監査 |

次工程は本書を正本とした**GeneratedMap互換geometryの作成**。未決事項を推測で埋めず、Preview/元World1/Legacy休眠状態を保持する。本書作成時点では互換Map構築もLegacy有効化も行っていない。
