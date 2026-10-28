# World1 approved balance and one unpaid native Play run — 2026-10-28

**Result: Stage10 first defeat observed at 52:16.654 (52 minutes16.654 seconds).** This is one fresh unpaid Studio automation run. It is not a typical-player time, an optimal route, a public-server result, or evidence of a clear-time distribution. It includes AI investigation/input overhead and ordinary growth during it.

| Run | Policy | First Stage10 defeat | Status at60 minutes | Outcome |
|---|---|---:|---|---|
| 1 | Compare actual upgrades, forging, rebirth, farming and ordinary combat/avoidance | 52:16.654 | Stage10 had already been defeated; the run had ended | Completed |

No second/third main run was started. A separate discarded preflight preceded the fresh run. No artificial60-minute snapshot or human-speed correction was created.

## Live target and implementation

Current unsaved Studio, Place126576845524886 / Universe10765181857. Local checkout baseline7407fcb; current Studio remained authoritative. See the final integration note for pre-existing remote work discovered on push. Current live Sources were read and guarded; neither an old rbxl nor a complete Git Source set was imported. Only these gameplay Sources changed:

- **ReplicatedStorage.Config.World1BossConfig**: RequiredStrength5..10 becomes15000/38000/82000/198000/360000/1000000, retaining Boss HP = reference ×5. Stage5 receives fixed7000/8750/10500/14000 walls. Existing Stage6..10 derivation at2/2.5/3/4 times reference yields40/50/60/80% Boss HP. Stages1..4, lottery definitions, lookup APIs, combat and rewards remain unchanged. No entry/mandatory-hit-count condition was introduced.
- **ReplicatedStorage.Config.DumbbellItemMaster**: only NORMAL_01..12 PriceWin, SellWin and StrengthBonus values change to the supplied table. No IDs, images, Grade, quantities, equipped IDs, 2D objects, save schema or World2 rows change. Existing owned equipment reads the current Master; no migration, deletion or compensation is added.

Approved tables are in [BALANCE_SPEC](../../docs/BALANCE_SPEC.md) and [runtime-config.json](runtime-config.json). Stage9 Boss is1.8M and Stage10 is5M. Ore thresholds remain5/20/40/70/110/160/220/290/370/450/530/650. Ore values/drop weights/sales/RNG and Item/Aura/Pet/Treadmill/Rebirth/payment/World2 values were not retuned during verification.

Scoped consumption audit: DumbbellService reads purchase/effect values from Master; ForgeInventory reads purchases/sales; DumbbellStandConfig and DumbbellStandClient use the same IDs/Master; EssentialStudShopClient and InventoryPanelClient use its prices/effects/sales; OreMerge and MergeShopView use its points/result values. Existing equipment effects are resolved dynamically rather than migrated.

## Minimal checks before the run

A post-implementation guard was captured for446 live Sources **after** installing the approved balance and **before** isolation. Cleanup restores this baseline, not the previous balance.

- Both edited Sources compiled and matched Edit readback. The final cleanup repeated this verification.
- Native client Config readback returned all10 Boss HP,40 wall values and12 Dumbbell definitions correctly. Main-run native Script telemetry also observed all10 Stage Configs through the actual Wall manager. See verification.json, runtime-config.json and summary.json.
- Master text is identical after masking only the three numeric fields; IDs/images/Grade/thresholds/World2 definition code are preserved.
- In a separate isolated preflight, an initial1000 fixture Win exercised normal client purchase→equip NORMAL_01 (995), unequip, ForgeClient sale (998), repurchase (993). Native normal-training gain was2 (base1 + Dumbbell1); actual Strength grew27→151 over the next31.833 seconds on Normal02. Purchase, ownership, protection, sale and native training paths ran normally. These fixture funds were never present in the fresh run.
- Preflight was stopped/discarded and its seeding Script removed before main Play. Main initial read confirmed Strength0, LV1, Win0, rebirth0, empty inventory/equipment, World2 unvisited and no override.

This was not an all-device or rendered-UI audit. No screenshot/virtual click/OS input was used, and no visual-perfectness claim is made.

## Isolation and actual inputs

Full conditions: [conditions.md](conditions.md). A fresh empty in-memory store was used per Play through35 temporary DataStore/Marketplace/Badge dependency substitutions. Ordinary PlayerData defaults and actual gameplay persistence transactions remained authoritative. Pass ownership was false, real prompts blocked, badge ownership empty; no existing account equipment/history, group reward claim or StudioStartOverride shortcut was used. Initial multipliers were1, ordinary speed24; subsequent boosts came from actual acquired equipment/rebirth/potions.

All progression used native Humanoid MoveTo/Jump/physics and the same client Remotes/ForgeClient/Item-merge request identities as UI. Server ownership, payment, rate limits, journals and natural RNG remained active. No server purchase/reward/combat internal function was invoked to progress, and no Strength/Win/item/HP/clear-state grant, CFrame movement, unearned teleport, speed/time acceleration or favorable RNG was used in the main run. The preflight seed is explicitly excluded.

No OS mouse/keyboard, window switch/focus acquisition, emulator/editor rearrangement or camera change was performed. Engine background movement/training and client requests were first confirmed in preflight.

## Clock and stage records

Play request11:52:17.380 UTC; native usable-player clock11:52:23.545 UTC (2026-10-28 20:52:23.545 JST). Loading6.165 seconds is separate. First Stage10 defeat was observed12:44:40.199 UTC /21:44:40.199 JST. Read-only polling interval was0.25 seconds; millisecond formatting does not imply millisecond detection accuracy. The clock uses actual ready native character/data/GUI, without dependence on OS focus or a render-input frame.

| Elapsed | Stage | Strength | LV | Rebirth | Win at defeat | Main equipment |
|---|---:|---:|---:|---:|---:|---|
| 01:41.142 | 1 | 114 | 4 | 0 | 2 | None; no Aura; no Items |
| 08:40.726 | 2 | 828 | 9 | 0 | 7 | NORMAL_01; no Aura; no Items |
| 16:11.259 | 3 | 2314 | 13 | 2 | 12 | NORMAL_03; Pink; PROTEIN_COMMON_ELECTRIC, TRAININGBELT_COMMON_FIRE |
| 19:47.832 | 4 | 7286 | 20 | 2 | 19 | NORMAL_03; Pink; PROTEIN_COMMON_ELECTRIC, TRAININGBELT_COMMON_FIRE, GLOVE_COMMON_ICE |
| 21:56.228 | 5 | 7902 | 20 | 2 | 34 | NORMAL_04; Pink; PROTEIN_COMMON_ELECTRIC, TRAININGBELT_COMMON_FIRE, GLOVE_COMMON_ICE |
| 26:36.900 | 6 | 29400 | 28 | 3 | 14 | NORMAL_04; Purple; PROTEIN_COMMON_ELECTRIC, TRAININGBELT_UNCOMMON_ELECTRIC, GLOVE_UNCOMMON_ICE |
| 33:38.132 | 7 | 61542 | 33 | 4 | 89 | NORMAL_05; Yellow; PROTEIN_UNCOMMON_ELECTRIC, TRAININGBELT_UNCOMMON_ELECTRIC, GLOVE_UNCOMMON_ELECTRIC |
| 39:41.679 | 8 | 132687 | 37 | 4 | 307 | NORMAL_06; Yellow; PROTEIN_UNCOMMON_ELECTRIC, TRAININGBELT_UNCOMMON_ELECTRIC, GLOVE_UNCOMMON_ELECTRIC |
| 47:52.535 | 9 | 239193 | 41 | 4 | 759 | NORMAL_07; Yellow; PROTEIN_UNCOMMON_ELECTRIC, TRAININGBELT_UNCOMMON_ELECTRIC, GLOVE_UNCOMMON_ELECTRIC |
| 52:16.654 | 10 | 479355 | 45 | 4 | 9 | NORMAL_07; Blue; PROTEIN_RARE_ELECTRIC, TRAININGBELT_UNCOMMON_ELECTRIC, GLOVE_RARE_ELECTRIC |

Stage indices come from FirstClears, because CurrentStage may already advance in the same snapshot. Win is measured at defeat, before any later Trophy payment. Stage10 Trophy was not collected and World2 was not visited. Full data: [stage-first-clears.csv](stage-first-clears.csv), [final-export.json](final-export.json).

All1608 recorded events were exported before Stop; no final event gap remains.64 incremental main checkpoints plus events.jsonl preserve progress. Inputs were halted and logs exported after the first-clear confirmation; post-clear snapshots show the same479355 Strength and9 Win. No additional gameplay round was performed. Use the frozen first-clear clock3136.654, not later export Snapshot.Elapsed values.

## Time categories

| Raw exclusive category | Seconds | Minutes |
|---|---:|---:|
| operations | 319.536 | 5.33 |
| training | 760.065 | 12.67 |
| combat | 331.833 | 5.53 |
| death | 16.918 | 0.28 |
| codex_interruption | 1031.571 | 17.19 |
| movement | 676.731 | 11.28 |

They sum exactly3136.654 seconds. Priority is death, combat, treadmill training, physical movement, annotated operations, AI interruption/idle. Thus concurrent AI work during treadmill growth stays in training; some early operation-phase spans also include unlabelled AI inspection. These are raw categories, not a precise human interaction-time estimate.

For example, between820.231 and892.162 seconds, actual Strength76.5→3226.5 (+3150) while ordinary training and helper/AI work overlapped. The whole interval remains in elapsed time. Preparation of observers and command latency also caused overshoot: Stage4 retry intent4500 was already5276 when read, then training/movement raised it further before the actual7286 clear. Later native threshold monitoring reduced such unnecessary training overshoot without editing values.

All available timed rewards were claimed through ordinary requests. Temporary potion time during investigation/travel/combat was not replaced with hypothetical productive training. The naturally elapsed45-minute Item×10 reward supplied material for the later Rare Protein. A faster run might not have this reward at the same progression point; its benefit cannot be retained while subtracting the waiting/AI time that unlocked it.

## Upgrades, merges and choices

Aura purchases: Pink at791.515s (30Win), Purple1380.541s (75), Yellow1853.072s (200), Blue2961.845s (1250). They were compared by incremental training value; no all-products chain was imposed. Main-run Dumbbells were all forged, not purchased. Native preflight separately tested the new purchase path.

| First observed elapsed (seconds) | Ore points | Actual result |
|---:|---:|---|
|227.854|5|NORMAL_01|
|578.109|21|NORMAL_02|
|800.148|43|NORMAL_03|
|1264.764|77|NORMAL_04|
|1796.809|115|NORMAL_05|
|2134.378|160|NORMAL_06|
|2687.778|225|NORMAL_07|

These timestamps are first confirmed observations, not all exact commit instants. Exact material IDs/counts/signatures are in summary.json. Native RNG chose each result; no example outcome was fixed.

**Ore forging had real value relative to Win purchase in this run.** The first free5pt forge provided a Dumbbell while funds were below its5-Win price. Later225pt yielded NORMAL_07 +25 while balance457 was below its750 purchase price. Obsolete forged Dumbbells sold for3/10/25/50/75/200 (363Win total); direct low-Ore sales supplied another170. These actual533Win helped fund Auras. They are not an assertion that buying every intervening Dumbbell would otherwise have been required. The160pt NORMAL_06 had a200 resale value versus110 direct sale for those materials, illustrating a genuine conversion opportunity under the unchanged Ore rules.

Item merges used surplus/compatible materials rather than consuming unrelated core equipment blindly:

| Completion elapsed | Materials / points | Natural result |
|---:|---|---|
|1431.139|2 Common Electric Belts /2pt|Uncommon Electric Belt (50% upper branch)|
|1495.503|Common Fire + Common Ice Glove /2pt|Uncommon Ice Glove (50% Uncommon branch)|
|1788.408|2 Common Electric Proteins /2pt|Uncommon Electric Protein (50% upper branch)|
|2951.281|4 Common +2 Uncommon Electric Proteins /10pt|Rare Electric Protein (94.444%; Epic5.556%)|
|3042.009|Common +Uncommon Electric Gloves /4pt|Rare Electric Glove (16.667%; Uncommon83.333%)|

The early three successful50% upgrades and final16.667% Glove outcome were favorable natural luck, not guaranteed progression. The10pt bulk merge guaranteed at least Rare while keeping type/element. All quantities, identities and server results were checked. Matching the three Electric Items activated the existing1.5 set multiplier; native factor observations confirmed it.

Rebirth1/2/3/4 succeeded at810.213/923.943/1441.555/1905.053 seconds. Gear/currency were retained through normal rules; actual rebuilding time was included. Rebirth3 unlocked Iron01. There was no fixed90-second rebuilding rule. Rebirth5 became eligible during final travel but was deferred because the already prepared Stage10 attempt was next; resetting would delay that immediate first clear.

The three additional Stage2 Trophy laps funded Pink; three additional Stage6 laps funded Yellow and supplied useful Ore/Item materials. Repeated lower stages in normal traversal are visible in events; Trophy receipts are separate from defeats. StageSkip and capacity purchases were not useful/necessary in the observed route.

**Pet/Egg use remains untested.** Normal PetClient requests were inspected, but the Hatch client waits on an Activated callback and exposes no ordinary programmatic advance. A native probe confirmed GuiButton.Activate is unavailable. With OS/virtual clicks prohibited, no hatch bypass/cancel was used to manufacture a completed Pet purchase. This is an input-capability limitation, not evidence that Pets have poor value. A human Pet route might be faster.

## Combat, failures and interpretation

Five ordinary combat deaths occurred: Stage2 at401 Strength; Stage3 at870; Stage4 at2804; Stage8 at117162; Stage9 at220977. [Death snapshots](deaths.json) preserve times, actual positions/equipment/bags. The first two recovery tests exposed ineffective circular/sparse-jump inputs; the route was changed rather than repeated mechanically.

Ordinary held Jump input at the pre-physics input boundary produced real Humanoid Jumping states and vertical motion without changing JumpHeight/JumpPower/collision. Later backward movement stayed inside the authored arena after legitimate wall destruction/contact. Stage8 retry succeeded at132687 after the117162 failure; growth and input changes are not independently isolated.

After the Stage9 failure, ordinary manual-combat requests were used. Existing CombatConfig automatic interval is0.8s; existing manual accepted-hit cooldown is0.5s, with the existing immediate manual hit path. Input sampling0.26s repeats normal taps; server cooldowns reject excess taps. No cooldown/damage/animation timing was changed. Auto was toggled through its normal request and restored outside combat. Stage9 then cleared at239193 with additional travel growth, and Stage10 at479355, below their360000/1000000 reference values. This is a useful legitimate input route, not a controlled proof that manual input alone caused the improvement.

Death lost the confirmed unbanked2 Items at Stage8 (Common Ice Protein, Uncommon Fire Belt) and1 at Stage9 (Common Ice Glove). Earlier death bags were empty. Highest sampled bag count was3/5; no full-bag discard was observed. A dedicated discard counter was not installed, so brief unsampled full states are not exhaustively excluded. Native Ore inventory remained available after deaths.

One sale request during ongoing loot changes was dispatched but not applied; actual counts/Win exposed this, and a fresh lobby request sold the still-owned spare once. The initial rejection code was not captured, so a concurrency diagnosis remains provisional. Sending/accepting a client request is not treated as transaction completion.

Console retains corrected QA-helper syntax/loadstring-availability failures and pre-existing asset authorization warnings. The helper restart did not restart the main run. No new balance-module or purchase/forge unhandled exception was observed; the whole game is not certified error-free. Existing Merge visual mounting after death was not re-audited or fixed.

No further balance retuning was applied. One run with favorable merge luck, timed rewards, manual-input optimization and substantial AI delay does not justify a new numerical recommendation or an average-player claim.

## Cleanup and delivery

Cleanup compared all446 post-implementation baseline Sources against their expected original/temporary forms before restoring: no unexpected edits. Exactly35 dependency substitutions were restored, the three remaining Edit fixtures removed (preflight seed had already been removed), runtime-only helpers ended with Play, and zero __Night/__Balance helpers remain. Both approved Configs compiled/matched and retain the new values. Camera CFrame/focus/FOV/type and development-GUI setting match the initial state. [Cleanup proof](cleanup.json).

The repository changes are the two Configs, scoped specification/status/changelog entries, and this report/harness/evidence. No OS GUI operation, Studio Save/Publish, rbxl writeback/new rbxl/backup/copy/migration or Studio closure occurred. The user's pre-existing unsaved edits remain in the open Edit Studio. **Manual Save/Publish is required before moving PCs or exiting.**

### Final Git integration

The first normal push of feature commit8515e2c was rejected because origin/main already contained12b43fa (Merge controller respawn relocation) and b5677a8 (the prior2026-10-27 adaptive run record). Both remote commits were fetched and retained through a normal merge, without force push, rebase or reset. Their Sources were not copied into Studio; the current live446-Source guard and approved two Configs remained unchanged. The previous3h03m run is a separate old-balance/policy/input trial, not a controlled before/after comparison with this52-minute run. Its result is not combined with the present clock.
