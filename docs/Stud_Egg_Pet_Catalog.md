# Stud Egg & Pet 実物一覧 — Phase 1

[Pet画像一覧の閲覧ページ（20体×9ページ）](Stud_Pet_Photo_Catalog.html)。2026-10-08再撮影: 購入実物の判別可能な画像175件／取得できない5件。モデル名・一覧番号を維持し、画像クリックで原寸を表示できます。Pet_041／095／119／130／159は理由を一覧・CSVに記録し、空画像や代替画像は採用していません。Camera・選択・一時非表示は開始時へ復元確認済みです。

[Egg全192件の対応表](Stud_Egg_Catalog.csv) · [Pet全180件の対応表](Stud_Pet_Catalog.csv)

2026-10-08、既存StudioのEditを読み取り。PlaceId: 126576845524886。対象: Workspace.Stud Egg & Pet。モデル名順でEgg-001〜192／Pet-001〜180を採番。番号は本一覧の識別子で、能力・レアリティ順ではありません。

Egg: 192モデル・191名（Egg_001が2件）。Pet: 180モデル・180名。Full Pathだけでは重複を区別できないため、モデルPivotのワールド座標とGetChildren取得時の同階層順番を記載。順番はセッション依存なので、座標・名前・親の子構造を併せて確認してください。

## Studioでの見つけ方

Workspace.Stud Egg & Pet.Modには同名Modelが2つあります。EggModelsフォルダを持つModelがEgg側、Petsフォルダを持つModelがPet側です。Pathの最初の名前一致だけで選ばないでください。

重複Egg_001:
- Egg-001: (-113.987137, 111.719208, 1786.684082)、同階層順番80。
- Egg-002: (120.413147, 111.719193, 2267.039551)、同階層順番186。

## 画像の取得状況

Petは既存StudioのEditで撮影した175画像を掲載しました。周辺設備・他Petの一時非表示とCamera変更を使用し、各プロパティ・Camera・選択を復元しました。4件は既存Editの本体描画が欠け、1件は極小の2群が離れていて判別できませんでした。具体的な状況をCSVのImage failure reasonに記載しています。描画欠けの原因やAsset権限は未確認です。Eggは今回撮影していません。全180件の番号・対応表・Rig情報・仕様空欄は維持しています。

## 記入欄・次のPhase

Eggの排出Pet、およびPetの系統・レアリティ・排出Egg・能力・マージ先はすべて空欄です。勝手な分類・数値設定はしていません。

確定事項: Petもマージ対象です。これは今後の設計方針であり、現在のゲームにマージが実装済みという意味ではありません。

Phase 2以降の未決定事項: 使用モデル選定、EggとPetの対応、系統・レアリティ、価格・排出確率・能力、マージ組合せ／必要数／消費／結果、重複Petの保存方式と既存還元仕様の扱い、装備枠・Strengthへの適用、画像の取得方法。今回は決定・実装しません。

## 保存済みファイルとの区別

CurrentCloud.rbxlにも同じ対象フォルダと件数が保存済みです。既存Studioから取得した位置・順番が本一覧の正本です。Studioとdiskの全プロパティ・未保存差分の一致を意味しません。前回記録の小さな階層差を上書きで解消していません。

初回一覧・Rig調査は読み取りのみ。今回のPet撮影では許可されたCamera・選択・表示プロパティだけを一時変更し、復元しました。Studio新規起動・終了、モデル移動・複製・改名、Source／Gameplay変更、Play、Save／Publish、rbxl書き戻し・Backupは実施していません。

## Rig／Animation限定調査（2026-10-08）

既存StudioのEditで180種を読み取り。CSV末尾に個数と接続検査列を追加しました。Boneの親がBone／BasePartか、Motor6D両端が同じPet内の部品か、AnimatorがHumanoid／AnimationController直下かを検査。HumanoidRootPartの存在だけではRigと判定していません。Motor componentsは有効Motor6Dを辺とする無向グラフの連結成分数です。骨格とメッシュのskin weight、関節階層とクリップの完全互換性は未検証です。

- Boneあり115種（合計3226）、Motor6Dあり179種（合計2281）。全180種に少なくとも一方あり。Boneの不正親0、Motor両端有効2280／不正1。
- HumanoidはPet_180に1個。AnimationControllerは180個（Pet_130に2個、Pet_180に0個）。Animatorは176個、全176個の親種別は有効。
- Animatorなし: Pet_058、Pet_089、Pet_103、Pet_114。
- Pet_137.Model.Root.MotorJoint_002はPart0=同Pet内Root、Part1=nil。未接続として記録、修正なし。
- Pet_130はSpike／Puffの2つのRig構造、Motorグラフ2成分。Pet_079はMotorなし・Boneあり。外側HumanoidRootPartからのMotor到達数だけでは、内側Modelの骨格を否定できません。

### Animation 12個の対応表

Full Pathは下表の通り。格納先と同居Rigは確認済みですが、外部AnimationIdのクリップ内容・用途・対応骨格は未確認です。名前から勝利／待機／歩行等の用途を断定していません。Egg内のクリップをPetへ対応付ける根拠はありません。

| 名前 | Full Path | AnimationId | 格納先・対応Pet | 同じ格納モデルのRig（Bone／Motor／Animator） | 用途・実再生・利用権限 |
|---|---|---|---|---|---|
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_152.DarkWinAnimation` | rbxassetid://100747355580894 | Egg内。対応Pet未確認 | 51／9／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_152.LightWinAnimation` | rbxassetid://77370551573285 | Egg内。対応Pet未確認 | 51／9／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_153.DarkWinAnimation` | rbxassetid://108687111191446 | Egg内。対応Pet未確認 | 24／8／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_153.LightWinAnimation` | rbxassetid://75175132819461 | Egg内。対応Pet未確認 | 24／8／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_154.DarkWinAnimation` | rbxassetid://135909692722395 | Egg内。対応Pet未確認 | 20／6／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_154.LightWinAnimation` | rbxassetid://126596643439445 | Egg内。対応Pet未確認 | 20／6／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_155.DarkWinAnimation` | rbxassetid://98012025044588 | Egg内。対応Pet未確認 | 26／6／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_155.LightWinAnimation` | rbxassetid://74287011605505 | Egg内。対応Pet未確認 | 26／6／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_156.DarkWinAnimation` | rbxassetid://77712811996924 | Egg内。対応Pet未確認 | 25／6／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_156.LightWinAnimation` | rbxassetid://122731312101610 | Egg内。対応Pet未確認 | 25／6／1 | 未確認 |
| Animation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_179.Animation` | rbxassetid://119165623278067 | Egg内。対応Pet未確認 | 0／2／1 | 未確認 |
| Animation | `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_180.Animation` | rbxassetid://83127051434605 | Pet_180内。クリップ適合未確認 | 0／2／1 | 未確認 |

### ローカルKeyframeSequence等

7個のKeyframeSequence（Keyframe合計432）が対象内にあります。格納Pet内のPose名とBone／BasePart名はすべて名前対応しました。ただし名前一致は完全な階層互換・再生確認ではありません。全7個Loop=true、Priority=Action。AnimationId12個との紐付けは未確認です。

| Full Path | 格納Pet | Keyframe数 | Poseのユニーク名一致 | 用途 |
|---|---|---|---|---|
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_046.Model.AnimSaves.centipede_idle` | Pet_046 | 61 | 78／78 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_046.Model.AnimSaves.centipede_walk` | Pet_046 | 25 | 78／78 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_048.Model.AnimSaves.organic_croc_idle` | Pet_048 | 48 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_048.Model.AnimSaves.organic_croc_walk` | Pet_048 | 48 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_082.Model.AnimSaves.idle` | Pet_082 | 81 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_082.Model.AnimSaves.idle_1` | Pet_082 | 96 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_082.Model.AnimSaves.walking` | Pet_082 | 73 | 27／27 | 未確認（名称は原文のまま） |

AnimationRigDataも7個付属。Rig編集情報としての存在のみ確認し、実行時Animationや公開クリップとの対応は断定しません。

Keyframeの時刻・Pose.CFrameの変化も読み取りました。Pet_046の2本は0〜1秒／0〜2.5秒、変化するPose名は各76。Pet_048の2本は各0〜1.958333秒、各25。Pet_082のidle_1／walking／idleは0〜1.583333／1.2／1.333333秒、各25／26／20です。静止データだけではなく時系列の関節姿勢データがありますが、「歩行・待機として正しく見える」ことは未確認です。

AnimationRigDataの格納先は上表の各KeyframeSequence直下です。子名はPet_046でCentipede_WalkAnimationRigData／Centipede_IdleAnimationRigData、Pet_048で各Organic_CrocodileAnimationRigData、Pet_082で各frognumber1AnimationRigData。上表のFull Pathにこの子名を加えた場所が実物です。

### PetFollowClientの流用範囲・不足

根拠: `StarterPlayer.StarterPlayerScripts.Services.PetFollowClient`全文。`dress`は全BasePartをAnchored=trueにし、`resize`はPrimaryPart姿勢とScaleを調整。`update`は追従位置・旋回・上下動・pitchを計算し、`model:PivotTo(...)`でモデル全体を動かします。`Animator:LoadAnimation`、AnimationTrackのPlay／Stop、Bone.Transform／Motor6D.Transform操作はありません。したがって現在の追従処理自体はRig Animation再生に対応していません。

流用時の不足は、承認済みクリップとRigの対応表、適切なAnimator選択（複数Rigを含む）、Animator欠落／Motor未接続の扱い、待機・移動の切替／再生停止と破棄処理、全パーツ固定・姿勢変更と関節アニメーションの整合確認です。実再生と利用権限は別途確認が必要です。今回は追加・修正・再生をしていません。


## Permanent Robux Egg Phase 1 - mapping (2026-10-10)

This section repairs the corrupted Phase 1 text using its confirmed file/catalog evidence. Phase 1 was read-only: origin/main `2cca755`, CurrentCloud SHA256 `7f3a4c4f8742c3769ef9a7c07842bcaa1bd8c15b28ca0e69e85ec5ce295a85f7`, 179132 instances. No Studio was connected or launched. No game, Camera, Source, purchase or data changes were made.

The user confirmed a permanent 149 Robux Developer Product offering one individually saved Pet, maximum one equipped, no abilities/merge. The Product ID was **unset during Phase 1**; Phase 2 subsequently supplies 3717610547.

### Seven purchased Pet mappings

Full Path prefix: `Workspace.Stud Egg & Pet.Mod.Model.Pets.`. Each exact path resolves uniquely despite repeated ancestor names elsewhere. Catalog IDs/model names and PrimaryPart coordinates were cross-checked; no model was selected by the first name match.

| Catalog / model | Odds | Full Path suffix | Root position (studs) | Visible world AABB (X x Y x Z) | Purchased photo |
|---|---:|---|---|---|---|
| Pet-042 / Pet_042 | 25% | Pet_042 | 125.013,113.335,2234.585 | 2.706 x 3.911 x 4 | [Photo](Stud_Pet_Photos/Pet_042.jpg) |
| Pet-064 / Pet_064 | 25% | Pet_064 | 134.213,112.844,2239.439 | 1.640 x 2.249 x 4 | [Photo](Stud_Pet_Photos/Pet_064.jpg) |
| Pet-081 / Pet_081 | 25% | Pet_081 | 120.520,111.719,2244.224 | 4 x 2.370 x 3.982 | [Photo](Stud_Pet_Photos/Pet_081.jpg) |
| Pet-086 / Pet_086 | 15% | Pet_086 | 143.413,112.368,2244.250 | 4 x 3.508 x 3.217 | [Photo](Stud_Pet_Photos/Pet_086.jpg) |
| Pet-094 / Pet_094 | 6.5% | Pet_094 | 180.213,111.758,2244.126 | 3.659 x 4 x 1.500 | [Photo](Stud_Pet_Photos/Pet_094.jpg) |
| Pet-135 / Pet_135 | 3% | Pet_135 | 184.813,111.794,2253.220 | 3.676 x 4 x 1.431 | [Photo](Stud_Pet_Photos/Pet_135.jpg) |
| Pet-024 / Pet_024 | 0.5% | Pet_024 | 134.230,113.660,2229.865 | 3.081 x 4 x 2.948 | [Photo](Stud_Pet_Photos/Pet_024.jpg) |

Total: seven Pets, 100%. All use HumanoidRootPart and have one AnimationController/Animator. Bone counts (042/064/081/086/094/135/024): 0/0/9/0/27/15/0; Motor6D counts: 8/11/3/23/7/7/19. No Animation or KeyframeSequence inside these seven; Pet_081 has 60 CFrameValue pose records. Pet_081 Root yaw is +30 degrees; others face negative Z. These are structural facts, not proof of animation playback or permissions.

`ReplicatedStorage.Modules.Pet.model` searches `ReplicatedStorage.Assets.Pets` (direct/one child); these seven were absent. Existing `HatchClient.mount` and `PetFollowClient.resize` reset only the primary CFrame. Future multipart Pet integration must preserve whole-model transforms and fit visible geometry, not treat the transparent root as the visible body.

### Entrance and purchased UI

- `Workspace.Chill Octopus`: Model/PrimaryPart=PetMesh; position (7.428,8.665,32.960), yaw -45 degrees; size (12.092,9.331,14.588), Anchored=true. Preserve appearance/location; no World2 relocation.
- `Workspace.Chill Octopus.ProximityPrompt`: direct Model child, Enabled, Equip/Chill Octopus, distance20, hold0, line-of-sight required.
- `Workspace.Chill Octopus.BillboardGui`: Enabled, Adornee=nil; AlwaysBetter="ALWAYS 200% BETTER", Price="ONLY [Robux]99". Those labels describe the retired offer, not the limited Egg.
- `StarterPlayer.StarterPlayerScripts.Services.StandClient`: old Triggered handler used PurchaseClient.promptGamePass or QuickNet.EquipPet and purchased Data.client.
- `ServerScriptService.Services.StandServer`: old Billboard/GamePass price initialization.
- `ReplicatedStorage.Modules.ProductIDs.Gamepasses.Pets["Chill Octopus"]`: old Pass1962289090; never reuse for this Developer Product.
- Purchased Server/Client Main were disabled; narrow LeftMenuClient -> PetClient.bootstrap started Egg/Pet but not Stand. Source existence did not mean an active entrance.
- `ReplicatedStorage.Assets.Templates.OpenEgg.Background.Pets`: six ImageLabel candidates with Button/Percent, wrapping layout. Extend only a limited-offer clone to seven and replace only pet bitmap display with ViewportFrame; retain regular four Eggs.
- `ReplicatedStorage.Assets.Templates.PetInventory.Main.Icon` and `Services.PetClient.buildTile/showCard`: mount per-copy 3D content while retaining ID/Checkmark/Button/Janitor and one equipped.
- Phase 1 considered `ReplicatedStorage.Assets.RGBEgg` (Part/SpecialMesh, MeshId110218693, TextureId223479930) and `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_002` (catalog Egg-003; Hitbox primary, three meshes/three welds) as unselected existing assets. Phase 2 explicitly retains Octopus as the entrance and selects RGBEgg for later Hatch only; neither replaces the station.

### Deferred payment, persistence and policy

Existing path: `Services.EggServer.open` -> `Modules.Egg.pick` -> GUID -> `Services.PlayerDataService.MutatePets`; regular Win deduction and Owned update share the existing mutation/save path. `Modules.Pet.NormalizeState/ApplyOperation/Publish` retain per-copy Owned IDs and one valid equipped ID.

`Systems.Controllers.StageSkipController` is the sole ProcessReceipt registration. Reuse `Systems.Purchases.ReceiptService` and its `DeveloperProductReceipts_v1` journal; do not start purchased PurchaseServer/Data/Main or a second ProcessReceipt. Phase 3 must reserve the result, pool version and copy GUID durably per PurchaseId, then atomically add Owned plus a durable grant marker in the existing player record. Mark journal Granted only after durable player save. Retry/crash/cross-server replay must retain the same result and not grant twice; current latest-only LastRequestId is insufficient for delayed paid receipts. Keep session ownership and existing pending-mutation safeguards. Client effects require receipt/result deduplication but must not grant Pets.

Before enabling purchase:
- Show all seven numerical odds before payment; no hidden luck modifications. [Official paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
- Enforce `PolicyService:GetPolicyInfoForPlayerAsync` / `ArePaidRandomItemsRestricted` on the server; deny new purchases for restricted or unresolved policy. Existing ShopRewardService policy is for SecretPack and does not automatically cover this Egg. No trading added. [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService#GetPolicyInfoForPlayerAsync)
- Verify the product belongs to the intended experience, fetch actual Marketplace pricing, and decide supported sales surfaces before enabling. [Developer Products](https://create.roblox.com/docs/production/monetization/developer-products), [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)
- Phase 1 did not query Creator Hub inventory, create a product, send a purchase, test Studio/Cloud Viewports, asset permissions, Hatch/follow or receipt retries. Phase 2 display evidence is recorded below separately.


## Permanent Robux Egg Phase 2 - facility and display (2026-10-10)

**Implemented locally; purchase is deliberately disconnected.** The same latest CurrentCloud was updated directly. No original models were moved, renamed or replaced. Phase 1's damaged text above was repaired in English; new records are English.

### Saved instance and Source changes

| Full Path | Change / purchased provenance |
|---|---|
| `Workspace.Chill Octopus.ProximityPrompt` | View Pets / Limited Egg 01; original enabled Prompt, distance20 and geometry retained. |
| `Workspace.Chill Octopus.BillboardGui` | Adornee=PetMesh; AlwaysBetter becomes Limited Egg 01; Price becomes149 Robux /1 Pet. Original typography/gradients/layout retained; obsolete200%/99 offer removed. |
| `ReplicatedStorage.Assets.LimitedEgg01Pets` | Display-only copies of the exact seven catalog Models from the Phase 1 table; names unchanged. All380 donor instances copied with original geometry/rig properties and internal references remapped. Original Workspace models unchanged. Dedicated replicated folder avoids dependency on the distant streamed catalog and does not register Hatch/follow/ownership yet. |
| `ReplicatedStorage.Config.LimitedEggConfig` | Display registry: Limited Egg 01, Product3717610547, base149, one Pet, PurchaseEnabled=false; exact seven odds100%; future Hatch template RGBEgg. No receipt/product-sales route added. |
| `ReplicatedStorage.Modules.LimitedPetViewport` | Static WorldModel/Camera fit using visible part bounds and whole-model PivotTo. Purchased geometry only; no animation or per-frame visual loop. Inventory title band reserved. Hide/close/dispose destroys temporary models/cameras and disconnects listeners. |
| `StarterPlayer.StarterPlayerScripts.Services.StandClient` | Replaces station's purchased Data/GamePass/direct-equip flow with the limited candidate display. Idempotent Prompt/start binding and one active sheet; original purchased OpenEgg panel cloned to seven candidates, one disabled purchased green Robux button. Close/escape/proximity exit cleanup. Marketplace price lookup only, never PromptProductPurchase. |
| `StarterPlayer.StarterPlayerScripts.Services.PetClient` | Existing active LeftMenuClient -> PetClient.bootstrap now starts only StandClient. Existing buildTile mounts3D for these seven names; old icons, per-copy tile IDs, equip/request code and max1 untouched. Undefined rarity text hidden; no rarity/ability invented. |
| `ServerScriptService.Services.StandServer` | Removes retired GamePass price lookup; display-only initializer. Purchased Server Main remains disabled and this service is not added to active server startup. |

UI provenance: `ReplicatedStorage.Assets.Templates.OpenEgg.Background` and its six candidate ImageLabels/Percent/Button; seventh is a clone of candidate6 only in the limited sheet. Names reuse `ReplicatedStorage.Assets.Templates.PetInventory.Title`. Green button: `StarterGui.ScreenGui.Menus.RestockShop.Main.Common.BuyRobux`. Close: `StarterGui.ScreenGui.Menus.Inventory.Exit`. Inventory still uses `ReplicatedStorage.Assets.Templates.PetInventory.Main.Icon`, with its bitmap replaced by an inner Viewport only for the seven registered names. No substitute images/models/VFX.

The regular OpenEgg template, EggClient/EggServer, four Win Eggs, six candidates,1/3/8 controls, Hatch, RGBEgg, PlayerData, receipt routing, equip1 and follow remain byte-identical. Purchased Main Server/Client remain disabled. No full purchased startup, saved preview UI or granted test Pets.

### Actual Edit verification

- Input SHA256 `7f3a4c4f8742c3769ef9a7c07842bcaa1bd8c15b28ca0e69e85ec5ce295a85f7`; final SHA256 `7cdc289399aa87bf35ab0d737ee4507a5abde4196e843f05d53ae616b39ce384`.
- Final reDecode179515 instances: added383 (380 exact donor-tree copies, one display Folder, two ModuleScripts). Dense referents/header/complete PRNT checked;76082 instance-reference values valid;366 unchanged SharedStrings and205757 valid indexes; UniqueId duplicates0. New internal references remapped, new UniqueIds assigned. Property-by-property comparison confirmed only three existing Sources and eight station display properties changed; subsequent edits affected only the new viewport Source and StandClient text alignment. All original parents and all other properties preserved.
- All five changed/new Sources compile with Luau. Final file actually reopened in Studio Edit, PlaceId0. No saved fixtures were present. Seven names/odds exactly match Config, sum100%, TextFits true, full models visible within their cells. All mesh/UI assets in the displayed sheet successfully preloaded.
- Candidate open/close/reopen exercised through the actual show/close functions: three cycles, exactly seven Viewports each; repeated show returns the same GUI. Destroyed sheet resources do not survive. Start/start/stop was exercised in Edit; actual player Prompt input remains a Cloud check.
- Actual PetClient.buildTile exercised in a disposable module clone with seven display-only IDs and purchased tile clones; no PlayerData, GetState, Equip or Remote request. Ancestor hide removes Viewports, reopen restores one per tile; original title/card/checkmark/button structure retained. Final title-clearance capture below. Fixture/module and temporary screens destroyed, original ScreenGui Enabled flags restored.
- Marketplace read for Product3717610547 returned **135 Robux** in this verification session. The implementation displays the fetched price when available,149 fallback otherwise. Candidate screenshot intentionally uses the offline149 fallback. No explanation of the135/149 difference is assumed; owner should verify Creator Hub pricing before Phase 3.
- Own verification Studio sessions only: PID10436 (initial view) and PID24868 (final file), sequentially, never concurrent. Both closed without Save; remaining own lock removed. No Studio process or target.lock remained; final file hash unchanged after verification. No user Studio existed at launch or was closed.

| Actual purchased display capture | Scope |
|---|---|
| [Octopus entrance](LimitedEgg01_Phase2_Station.jpg) | Original facility/location; updated labels, no replacement Egg. |
| [Seven candidates](LimitedEgg01_Phase2_Candidates.jpg) | Final file, actual models, exact odds and disabled purchased button; Edit/149 fallback. |
| [Pet Inventory tiles](LimitedEgg01_Phase2_Inventory.jpg) | Actual buildTile on disposable purchased tiles; shows display support, not owned/awarded data. |

### Phase 3 remaining work / limits

- Confirm Product3717610547 ownership/experience association, intended live price and supported sales surfaces in Creator Hub; no product creation/change was performed here.
- Add server PolicyService purchase eligibility, numerical-odds disclosure at purchase, durable per-PurchaseId reserved roll/copy ID, atomic player grant marker and receipt retry deduplication through the existing ReceiptService/PlayerData path described in Phase 1.
- Connect actual purchase Prompt, receipt/roll/grant/save, existing Hatch + RGBEgg and whole-model-safe follow only in the authorized next phase. Current button is noninteractive and has no purchase callback. The seven display templates are outside Assets.Pets; they cannot be treated as already integrated with ownership/Hatch/follow.
- Cloud has not been reflected/published. Live E/touch input, published-client bootstrap, real inventory refresh/ownership, responsive phone/touch rendering, purchase/Hatch/follow/persistence/policy/retry behavior remain unverified. This phase proves Edit rendering and scoped static integrity, not paid gameplay.
- No local Play, purchase, DataStore mutation, Save/Publish, backup, alternate rbxl or work folder. Only task Sources, these images and English documentation are committed; unrelated local report preserved.


## Limited Egg 01 active Lobby relocation (2026-10-10)

After the user reported the missing facility and explicitly authorized movement, `Workspace.Chill Octopus` was moved from the original purchased map to the active World1 Lobby. Its saved primary `Workspace.Chill Octopus.PetMesh` now has position **(315,8.665255,40)** and yaw+45 degrees toward Spawn. The original hierarchy, appearance, size, Prompt, UI and Phase 2 behavior are unchanged; the earlier keep-original-position instruction is superseded.

[Actual Edit view from the Spawn side](LimitedEgg01_World1_Placement.jpg). Ground contactY4, zero other parts overlapping the footprint with2 studs of X/Z padding, unobstructed Spawn-eye ray, distance38.58 studs. This corrects the earlier verification gap: the initial station screenshot proved only visibility in the original purchased map. Only one CFrame property changed. Cloud/live interaction still requires user reflection; purchase remains disabled. Verification Studio exited and target.lock cleared; no further Studio launch.


## Limited Egg 01 Phase 4 - Hatch models, equipment and follow (2026-10-10)

**Phase 3 is still absent.** Latest origin/main1d12daf and CurrentCloud had only the display Product ID, no limited receipt/roll/grant/save route. PurchaseEnabled remains false and the green button remains disabled. This phase prepares presentation and connects the seven model names to existing owned-copy equipment/follow; it does not enable paid gameplay.

The current user instruction supersedes the earlier024/135 odds assignment: Pet_042/064/081 each25%,08615%,0946.5%,**0243%,1350.5%**, total100%. Product3717610547 / Limited Egg 01 and the Chill Octopus facility remain.

### Changed Full Paths

| Full Path | Change |
|---|---|
| `ReplicatedStorage.Config.LimitedEggConfig` | Align024=3% and135=0.5% with the latest instruction; keep purchase disabled. |
| `ReplicatedStorage.Modules.Pet` | Resolve only the seven registered names from existing Assets.LimitedEgg01Pets, making the existing server ownership/equip checks and follower/Hatch lookup accept their actual purchased models. Add clone-only whole-model orientation, visible-bounds scaling and center/bottom pivot preparation. Do not add abilities, rarity, merge, a grant or a save schema. |
| `StarterPlayer.StarterPlayerScripts.Services.PetFollowClient` | Use whole-model preparation only for limited names; visible height uses existing Config.PetFollow.height=3. Bottom pivot plus existing bob amplitude avoids embedding the multipart body in the floor. Existing movement, yaw smoothing, hop, sway and cleanup retained; normal Pet branch unchanged. |
| `StarterPlayer.StarterPlayerScripts.Services.HatchClient` | Mount limited models together instead of resetting the root alone. Fit their visible bounding sphere during the existing rotating-camera display. Keep existing RGBEgg/animation/SFX/result-name flow. Add a guarded, currently unbound post-save result consumer and session visual deduplication. |

No server Source, receipt routing, PlayerData save function, Remote, purchased UI artwork, normal Egg config, facility transform or template instance was changed by this implementation.

### Deferred post-save notification contract

`HatchClient.playCommittedLimited(notice)` is reserved for a **future trusted server notification sent only after durable save success**. Required fields are ProductId, PurchaseId, Saved=true, Status="Granted", Result={id,pet,percent} and State containing that owned copy. Wrong product/odds, unowned/mismatched copy, cancellation/unconfirmed status are rejected. Claim the PurchaseId before queueing; repeats are rejected even after a different receipt. Failed presentation setup releases that visual claim for retry. This cache is session-only and is not a durable receipt or grant marker.

The ordinary Win-Egg Hatch entry rejects the seven paid names; a state refresh alone never starts their reveal. The prepared consumer reuses RGBEgg and the existing Hatch queue. **There is no limited notification sender/listener yet**, because no Phase 3 durable receipt exists. The consumer validates a future notification contract; it does not establish persistence authority by itself. Phase 3 still must validate payment/policy, atomically save/deduplicate the award, then wire this entry from its server-confirmed result. No purchase Prompt/completion event has been connected.

### Verification and limits

- Extended existing BasicEggOffline.py/spec: **545 assertions passed**, including all regular Egg1/3/8 price/pool/save-retry tests, seven registered model names, exact server PetServer.equip path with synthetic in-memory ownership, unowned refusal/no write, swap/toggle-off, same-species copy IDs, legacy two-equipped normalization and unchanged Win. Also tested exact limited notification consumer with a presentation spy: cancelled/unconfirmed/invalid inputs do not reveal, correct result selects RGBEgg fallback, duplicate/older notifications do not replay, setup failure can retry. No real player/store/Remote or purchased grant.
- Four production Sources compiled. Same-file write initially changed only those Source values; reDecode179515,76082 references,366 SharedStrings/205757 indexes, UniqueId duplicates0. Agent output SHA2561fc67a98c2269969013dc1e5a84e46d9e04684f7f37611d7ecd2ad7283464e8a.
- One actual Studio Edit load, PlaceId0, PID11620. Disposable copies exercised the exact follower refresh/update code against local mock player tables, not Players or real character data: each model visible height3, max relative-part error0.00000236 studs, movement13.9222 studs, one-slot/idempotent refresh and unequip cleanup passed. No Rig Animation played.
- Exact existing Hatch.mount displayed all seven purchased models. Checked visible bounds at16 camera orbit angles per model: all fit, worst normalized viewport ratio0.819. RGBEgg fallback identity and current percentages verified. [Actual Edit geometry montage](LimitedEgg01_Phase4_HatchModels.jpg) uses disposable candidate cells to inspect Hatch mounting; it is **not a capture of the full timed Hatch sequence or a purchased result**.
- Removed all preview modules/UI and restored original ScreenGui states. During shutdown, PID11620 had already exited before the close command executed. No Studio process or target.lock remained; no lock deletion was needed. Earlier Codex verification sessions were also absent. No new Studio was opened for the final check.
- A separate file write at19:39:07 occurred after the display checks; no agent Save/Publish was issued. Preserved that newest file instead of restoring the earlier output. Final SHA256**c5d080bcd0f0adc97c5fa85cd4b8bd7bb6cdd1e8628dfdb4b6e44d419419399b**,179534 instances: all four task Sources still match, no task preview instances,366 SharedStrings/205776 indexes,76112 references,UniqueId duplicates0. Purchased Main remains disabled; saved StrengthGui/StageSkipGui enabled and purchased ScreenGui disabled. This newest external version was reDecoded, not reopened after cleanup.
- Cloud has not been reflected or played. Full timed Hatch/SFX, real replicated equip/follow, actual receipt dispatch, purchase/cancel/save-uncertain behavior on a server, mobile devices and cross-session receipt handling remain unverified. Phase 3 must precede an end-to-end purchase test. No local Play, purchase, real grant, DataStore change, Save/Publish, backup, alternate rbxl or work folder.
