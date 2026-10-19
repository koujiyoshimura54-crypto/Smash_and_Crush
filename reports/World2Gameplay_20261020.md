# World2 workbook gameplay integration — 2026-10-20

The actual CurrentCloud Sources and Objects were the implementation baseline. No lobby generator was rerun. The same `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` was overwritten in place; no additional rbxl, backup, migration, or workbook copy was created.

## Authority and implemented behavior

- Read every populated cell (340) and cached/formula value in `C:\Users\kouji\Downloads\World2_数値一覧.xlsx`. Adjacent independent tables were parsed independently. Complete cell evidence and parsed values: [workbook evidence](World2Workbook_20261020.json). Server and UI catalogs obtain approved numbers from `ReplicatedStorage.Config.World2GameplayConfig`.
- World2 Stage1–10 Boss HP, four wall HPs, and Win rewards use that authority on initialization/reset/retry. Existing combat intervals, lottery/attack policy and progress flow were retained. The existing BossHP/5 benchmark is not an admission condition. StageSkip's actual-file World1-only predicate already existed and was left unchanged.
- Shared Rebirth: x1 initially, +0.5 each time. Required levels 10,15,22,30,45,70,90,110,140,160. All ten workbook reference cumulative Strength values exactly match the unchanged current level curve. Only LV is required; reference Strength is not a second gate. Legacy required-level entries 11–30 remain, counts beyond ten are not rolled back/capped. Strength/LV/progress reset; Win, ownership, purchases and equipped Pets/items remain.
- Twelve new `W2_NORMAL_01`–`12` Dumbbells use existing 2D images/stands and shared purchase/equip/save authority. No W2 item is initially owned. World1 IDs, definitions and images were preserved from the actual input.
- Forty-five W2 regular Items: Protein/Glove/TrainingBelt, three existing elements, five rarities. Common–Epic can be purchased. Legendary has no direct purchase price: 405,000 is a reference cost only. Existing point Merge and transactions are retained; mixed-world materials are rejected, same-world generation is preserved. Existing 20% drop chance, rarity weights and stage rarity limits are retained; W2 drops have W2 IDs. Glove modifies Boss damage only.
- Seven existing treadmills retain geometry: old01 x2 at x5/R0, old02 x2 at x7/R7, old03 x2 at x12/R9, old04 x1 at x35/unavailable Robux. Loaded session/current World/conditions are checked server-side. One existing training scheduler handles entry/exit/death/world changes. Belt remains additive in the existing formula.
- Five normal W2 Auras and one unavailable paid definition use separate IDs, existing icons/effects and one equipped slot.
- Four normal Eggs have exact 1/3/8 costs and seven separate species per pool. A disabled Limited pool is also defined: 35 W2 species total with existing visual/model aliases and separate copy GUID ownership. Probability rows sum to one; each 25% slot is distinct. One equipped Pet applies its final multiplier once in either World. No W2 Pet Merge was added.
- Existing durable item/Egg receipts, save normalization, server ownership/price/material checks, and single equipment slots are reused. World2 Win collection uses the existing claim guard. Back uses a server-issued run generation, existing reset/return APIs and no additional Win grant. World1 reward/banking policy stays intact.
- World2 old04 treadmill, paid Aura and Limited Egg remain purchase-disabled, without inferred prices/ProductIds/GamePassIds or inherited World1 paid rights. Effects/display definitions exist; billing remains unconnected.

## Object and Source scope

All original BasePart transforms, sizes and collision flags, original parents, lobby 237x169 floor, Stage geometry, Spawn/Gates, held models and Templates remain unchanged. Added 33 Instances: one Config, seven invisible belt Areas, one invisible Merge Area, twelve status labels and twelve outline children. No original Instance was removed. Existing image URIs and own-Press Adornee links were retained; stand number/effect/price/status rows were arranged within the existing design.

Exact changed Object/property Full Paths, areas, all Source Full Paths and binary checks are in [the manifest](World2Gameplay_20261020.json). Config/Source mirrors were extracted from the actual edited file; they are not wholesale replacements from historical Git Sources. In particular, PlayerDataService has only the scoped Egg purchasability/current-World guard changes. Some current-file Source context already differed from historical Git (including CombatClient wall rendering); the actual-file context was retained. Unrelated pre-existing working-tree edits were excluded from the commit.

## Verification and limits

- Before writing: 903 memory-only Luau assertions, including field comparisons against the actual input World1 catalogs. After writing: 410 assertions using re-decoded saved-file Sources. These exercise actual catalog/service/transaction code with in-memory storage, player, remote and physics adapters, not real accounts or DataStore I/O.
- Covered purchases/insufficient balance/ownership/equip, item Merge/material debit/retry/world separation, Eggs 1/3/8 and receipt retry once, normalization/reload snapshots, single Pet factor/world carry, treadmill conditions/no duplicate training/exit/death/world change, LV-only Rebirth/reset/retention, wall/Boss resets and Glove scope, guarded Win collection/return/reset, Back run generation and World1 banking, and World1-only StageSkip.
- All 50 changed/new Sources compiled externally and in native Studio Edit without starting services. ReDecode/INST/PROP.Ref/PRNT checks passed: 182,118 Instances, referents 0–182,117, no missing/out-of-range references or duplicate UniqueIds; 362 SharedStrings/208,438 indexes validated; canonicalization is byte-idempotent.
- The written exact rbxl was opened in a separately owned Studio Edit instance. Native inspection confirmed all catalogs, 12 icon IDs/Adornees/visible label fields, seven belt Areas with rays hitting actual belt surfaces, disabled paid slots, and all 35 Pet visual models. [Native evidence](World2GameplayNative_20261020.json).
- **Image delivery/rendering was not confirmed:** all twelve ItemIcon IsLoaded values stayed false/AssetFetchStatus.None. Preload and screen capture did not complete; no screenshot is claimed. Runtime UI layout/animation/following and actual walking/transactions/combat remain unverified.
- No local Play, Studio Save/Publish, real DataStore transaction/reset, permanent test grant, Marketplace purchase or Cloud gameplay operation was executed. No three-hour completion-time claim is made. Inspection state was restored and only the agent-owned verification Studio was closed without saving. The user's Studio was untouched; the output hash stayed unchanged.

## File fingerprints

- Workbook SHA256: `c4a177e307a34fdb9abd88842f0b40b594339fff1553389d6e8d77da1ef1ea43`
- Input SHA256: `7ece6d8e887ea248dca746535529977bed45c3dc3c1b4c394777992b9b6f2b8b`
- Output SHA256: `08c9434ec97c3f705c7454744d5355eba6589bb118c88b24f9f8d1c525ee7766`

## Changed Source Full Paths

- `ReplicatedStorage.Config.World2Config`
- `ReplicatedStorage.Config.TrophyRewardConfig`
- `ReplicatedStorage.Config.RebirthConfig`
- `ReplicatedStorage.Config.RebirthMultiplierConfig`
- `ServerScriptService.Systems.Controllers.RebirthService`
- `StarterGui.StrengthGui.RebirthMenuClient`
- `ReplicatedStorage.Config.DumbbellItemMaster`
- `ReplicatedStorage.Config.ItemMaster`
- `ReplicatedStorage.Config.ItemMultiplierConfig`
- `ReplicatedStorage.Config.AuraConfig`
- `ServerScriptService.Services.ItemService`
- `ReplicatedStorage.Config.ItemMergeConfig`
- `ServerScriptService.Services.EnemyDropRoller`
- `ServerScriptService.Services.EnemyDropGachaService`
- `ServerScriptService.Services.PetServer`
- `ServerScriptService.Services.TrophyRewardService`
- `ReplicatedStorage.Modules.Config`
- `ReplicatedStorage.Modules.Egg`
- `ReplicatedStorage.Modules.Pet`
- `ReplicatedStorage.Modules.LimitedPetViewport`
- `StarterPlayer.StarterPlayerScripts.Services.PetClient`
- `ServerScriptService.Services.EggServer`
- `ServerScriptService.Services.PlayerDataService`
- `StarterPlayer.StarterPlayerScripts.Services.EggClient`
- `StarterPlayer.StarterPlayerScripts.Services.HatchClient`
- `ReplicatedStorage.Config.DumbbellStandConfig`
- `ServerScriptService.Services.DumbbellStandService`
- `StarterPlayer.StarterPlayerScripts.Services.DumbbellStandClient`
- `ReplicatedStorage.Config.TreadmillConfig`
- `ServerScriptService.Services.TrainingManager`
- `ServerScriptService.Systems.Controllers.TrainingController`
- `StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient`
- `StarterPlayer.StarterPlayerScripts.UI.TreadmillGuideClient`
- `ServerScriptService.Services.GamePassService`
- `ServerScriptService.Services.TrainingLobbyAreaService`
- `StarterGui.StrengthGui.InventoryPanelClient`
- `StarterGui.StrengthGui.ItemInventoryTabClient`
- `StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient`
- `StarterPlayer.StarterPlayerScripts.UI.TrophyRewardFeedbackClient`
- `StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New`
- `StarterGui.StrengthGui.InventoryCapacityUpgradeClient`
- `ServerScriptService.Services.AuraService`
- `StarterGui.StrengthGui.AuraInventoryClient`
- `StarterGui.StrengthGui.EssentialStudShopClient`
- `ServerScriptService.World.BossCombatService`
- `StarterPlayer.StarterPlayerScripts.Combat.CombatClient`
- `ServerScriptService.World.EnemyManager`
- `ServerScriptService.Services.RunReturnService`
- `StarterGui.StrengthGui.RunReturnClient`
- `ReplicatedStorage.Config.World2GameplayConfig`
