# Shared World1 / World2 Ore — 2026-11-09

Implemented in the connected canonical Studio, PlaceId **126576845524886**, loaded version **475**, after Boss commit **92bdfb9**. Current live Sources were the baseline. World1 Ore points had already been manually updated to the requested table; those edits were preserved and exported. No older UI or gameplay Source was restored.

## Result and causes

World2's normal non-Item branch previously remained MISS because EnemyDropRoller enabled Ore only for World1. Both Worlds already shared the provisional Bag/banking path. The roller now reads the independent World/Stage rows below and feeds the existing path. Item identity/rarity draws, first personal World1 Stage1 Stone, TimeReward direct Stone, capacity, Drop, five-second replacement cues and return-gated notifications remain on their existing implementations.

The four reserved IDs are enabled without renaming or migrating ownership. Twelve missing definitions are appended once. The withdrawn eight SuperRare definitions are absent. No new rarity text, frames, glows, World headings or buttons were added.

OreMerge previously used only World1 candidates and rejected totals above the final threshold. Client preview, request selection and durable Forge application now share the same sorted eligible candidate calculation. Server-owned arrival eligibility is frozen with the retained operation; client-supplied unlock fields are ignored. Returning to World1 does not remove eligibility. The existing Forge sequence/signature journal handles consumption, output and sale Win atomically across retries.

## Changed Full Paths

| Full Path | Change |
|---|---|
| ReplicatedStorage.Config.OreConfig | Stable 32 Ore definitions, availability, World/local index; compatibility drop view |
| ReplicatedStorage.Config.EnemyDropConfig | New sole World/Stage category and conditional Ore pool authority |
| ReplicatedStorage.Config.ItemMaster | Legacy DropHitChance reads the common Config; Item content unchanged |
| ReplicatedStorage.Config.DumbbellItemMaster | Adds only the twelve World2 MergePoints |
| ReplicatedStorage.Modules.OreMerge | Shared eligible candidates, adjacent probabilities and highest-candidate cap; up to 32 sale IDs |
| ReplicatedStorage.Modules.ForgeInventory | Validates the retained server eligibility using the same merge evaluation |
| ReplicatedStorage.Modules.ForgeClient | Refreshes the existing state when server arrival changes |
| ReplicatedStorage.Modules.MergeShopView | Passes accepted eligibility to three existing Ore previews/validation calls |
| ServerScriptService.Services.EnemyDropRoller | Both Worlds read their Stage row and can roll Ore |
| ServerScriptService.Services.ForgeService | Publishes server eligibility and retains it with the existing operation |

No Boss Source, Player attack timing, Egg price, Dumbbell purchase/sale/effect/image, Item/Pet merge, equipped/Best Equip behavior or authored UI property changed in this phase.

## Confirmed definitions

Rows 001–016 are World1, rows 017–032 are World2. IDs 017–020 already existed; their RARITY_04 / “Super Rare” attributes are retained. New 021–030 use Rare; 031–032 use the existing Super Rare representation.

| World | Local # | ID | Name | Points | SellWin / unit | Image asset |
|---|---:|---|---|---:|---:|---|
| 1 | 1 | ORE_001 | Stone | 5 | 1 | 131452437678251 |
| 1 | 2 | ORE_002 | Coal | 7 | 3 | 83727497047517 |
| 1 | 3 | ORE_003 | Iron | 9 | 5 | 111308943708149 |
| 1 | 4 | ORE_004 | Copper | 11 | 7 | 106917824814020 |
| 1 | 5 | ORE_005 | Quartz | 15 | 9 | 98802386870713 |
| 1 | 6 | ORE_006 | Silver Stone | 20 | 10 | 92842832362846 |
| 1 | 7 | ORE_007 | Sand Crystal | 30 | 15 | 100254430391832 |
| 1 | 8 | ORE_008 | Brown Ore | 35 | 20 | 90313945125672 |
| 1 | 9 | ORE_009 | Rock Core | 45 | 25 | 74885090507086 |
| 1 | 10 | ORE_010 | Gray Crystal | 50 | 30 | 131216796823283 |
| 1 | 11 | ORE_011 | Amber | 60 | 35 | 122870709116506 |
| 1 | 12 | ORE_012 | Topaz | 75 | 40 | 95006906073775 |
| 1 | 13 | ORE_013 | Jade | 90 | 45 | 80400820880542 |
| 1 | 14 | ORE_014 | Aqua Crystal | 100 | 50 | 111060074263221 |
| 1 | 15 | ORE_015 | Forest Stone | 130 | 55 | 133113647660531 |
| 1 | 16 | ORE_016 | Spark Ore | 145 | 65 | 103644070407489 |
| 2 | 1 | ORE_017 | Sunstone | 175 | 90 | 136139361458479 |
| 2 | 2 | ORE_018 | Moon Quartz | 200 | 95 | 136614965232146 |
| 2 | 3 | ORE_019 | Blue Crystal | 230 | 100 | 95334159293900 |
| 2 | 4 | ORE_020 | Green Core | 260 | 110 | 99321545969483 |
| 2 | 5 | ORE_021 | Fire Crystal | 500 | 125 | 123040533451102 |
| 2 | 6 | ORE_022 | Ice Crystal | 800 | 150 | 131904521722854 |
| 2 | 7 | ORE_023 | Thunder Crystal | 1200 | 175 | 91063489732839 |
| 2 | 8 | ORE_024 | Wind Crystal | 1800 | 200 | 86680826462250 |
| 2 | 9 | ORE_025 | Earth Crystal | 2700 | 225 | 73601508560022 |
| 2 | 10 | ORE_026 | Ruby Core | 4000 | 250 | 116198836377017 |
| 2 | 11 | ORE_027 | Sapphire Core | 6000 | 280 | 81308625825873 |
| 2 | 12 | ORE_028 | Emerald Core | 9000 | 315 | 134950477291874 |
| 2 | 13 | ORE_029 | Amethyst | 12000 | 345 | 115312330145120 |
| 2 | 14 | ORE_030 | Frostbite | 16000 | 375 | 82851451613885 |
| 2 | 15 | ORE_031 | Blood Ore | 24000 | 440 | 127269924651631 |
| 2 | 16 | ORE_032 | Crimson | 30000 | 500 | 132695351248923 |

## Stage tables and manual editing

Edit **ReplicatedStorage.Config.EnemyDropConfig.Worlds[worldId][stage]**. Every row has `ItemChance=0.20` and `Ores={{Id=...,Weight=...},...}`. Ore is the remaining 80%. Weights below are conditional on the Ore category, total 100 per Stage, and are not multiplied by 80% again. The twenty authored rows are independent, so future edits to World2 do not alter World1.

The local-number mapping below applies to BOTH Worlds. Convert local n to ORE_n for World1 and ORE_(n+16) for World2, using three digits. World1's live candidate combinations/weights were preserved exactly.

| Stage | Local Ore number : conditional percent |
|---:|---|
| 1 | 1:45%, 2:30%, 3:17%, 4:8% |
| 2 | 1:40%, 2:28%, 3:17%, 4:10%, 5:5% |
| 3 | 1:35%, 3:25%, 4:18%, 5:12%, 6:7%, 7:3% |
| 4 | 3:35%, 5:25%, 6:18%, 7:12%, 8:7%, 9:3% |
| 5 | 5:35%, 6:25%, 8:18%, 9:12%, 10:7%, 11:3% |
| 6 | 6:35%, 8:25%, 9:18%, 10:12%, 11:7%, 12:3% |
| 7 | 8:35%, 10:25%, 11:18%, 12:12%, 13:7%, 14:3% |
| 8 | 10:35%, 11:25%, 12:18%, 13:12%, 14:7%, 15:3% |
| 9 | 11:35%, 12:25%, 13:18%, 14:12%, 15:7%, 16:3% |
| 10 | 11:10%, 12:12%, 13:13%, 14:15%, 15:35%, 16:15% |

Edit **ReplicatedStorage.Config.OreConfig.rows** for Points/SellWin/images. Keep row order and stable IDs. `OreConfig.DropPools` and `ItemMaster.DropHitChance` are compatibility views, not independent settings.

Edit **ReplicatedStorage.Config.DumbbellItemMaster** for merge thresholds: existing World1 `MergePoints` fields, and `world2MergePoints` for World2. Purchase/sale Win, StrengthBonus and image definitions are untouched.

| Dumbbell # | World1 threshold | World2 threshold |
|---:|---:|---:|
| 1 | 5 | 1000 |
| 2 | 20 | 2500 |
| 3 | 40 | 5000 |
| 4 | 70 | 9000 |
| 5 | 110 | 14000 |
| 6 | 160 | 20000 |
| 7 | 220 | 28000 |
| 8 | 290 | 38000 |
| 9 | 370 | 50000 |
| 10 | 450 | 65000 |
| 11 | 530 | 82000 |
| 12 | 650 | 100000 |

Two to five total units are required; repeated Ore types and cross-World mixtures are allowed. Candidate eligibility uses existing server-confirmed World2 arrival, not current location or ownership. Exact thresholds yield one candidate at 100%; intermediate totals use the adjacent two thresholds; above the highest eligible threshold yields that candidate at 100%. No fee was added.

## Verification

Native solo Play used in-memory DataStore/Marketplace/Badge/Policy/Messaging adapters. Every service acquisition was redirected before starting Play; no real payment, production-data initialization or test reward occurred. The reset command's “production” log names refer only to its memory-backed logical store in this fixture.

- **2,147 core assertions passed**: all 32 definitions; both Worlds/all ten Stage candidates and conditional interval weights; deterministic category samples 20 Item / 80 Ore for each Stage; 12/24 eligible candidates; one/six/fractional/invalid/insufficient-material rejection; two through five accepted; low-point World1 candidates retained after unlock; 650–1000 boundary; 100,000 exact and 150,000 capped results.
- Native Forge requests matched preview candidates and actual consumption. Blood×4 + Ruby×1 generated W2_NORMAL_12. A client unlock spoof remained restricted to World1. No merge fee. World2 eligibility and result remained valid after returning to World1.
- Single/all sales for Stone, Sunstone and Crimson paid their configured integer units. One each of all 32 Ores paid **4,190 Win**, matching the sum. Replays and stale sequence requests did not pay twice.
- Injected precommit failure and lost acknowledgement retained the existing operation. Repeated requests applied exactly once. Memory save/reload preserved Ore counts, Win and generated Dumbbells, including legacy reserved IDs. This is memory-store persistence testing, not public DataStore reliability certification.
- **54 native battle/service assertions passed**. Prepared real Boss encounters used ordinary manual damage/defeat: World2 Stage2 produced Sunstone and Trophy touch banked it; Stage3 produced Blue Crystal and death discarded it. World1 Stage1 guaranteed Stone and Trophy banked it; Stage2 and World2 Stage4 also exercised ordinary Item results. Run replay was rejected.
- Both Worlds' service fixtures preserved combined Item/Ore capacity, rejected full Bags, discarded only the latest displayed same-type acquisition, retained the other copy and owned inventory, and added no Win. Stale/repeated Drop was rejected. Unbanked Ore could not be sold or merged.
- Latest-only cue fixtures replaced old notices in **0.332–0.343 s**; surviving native cues closed at **5.019–5.034 s** after GUI creation. A dedicated Crimson cue closed at **5.032 s**; its Bag unit remained and owned inventory was unchanged. These are GUI lifetime measurements, not raster-onset timing.
- After a memory reset, TimeReward Stone was still direct (Bag count zero), the ordinary Ore guide showed “Choose 2 ores.” then “Press Merge.”, one unit was invalid, two were valid, and the successful normal merge completed the existing tutorial. World2 Stage1 did not consume World1's first-defeat guarantee.
- Actual MCP images confirmed the existing layout, new Ore list/images, 100K inputs, candidate/completed result, K formatting, counts, Sunstone90/Crimson500 sale UI, and reset tutorial. All 32 icon ImageLabels reported loaded after initial streaming. UI reopened after respawn and World travel. No new display style or additional quantity display was introduced.

[Core checks](CoreChecks.json), [battle checks](BattleChecks.json), [cue measurements](CueTimings.json), [presentation checks and limits](PresentationChecks.json).

### Fixture corrections and limits

The first seed changed live OwnedOres without seeding the memory record; ordinary Save correctly preserves durable Forge-owned counts. This caused a fixture-only NotEnoughOres condition. The memory seed was corrected and the full native Forge group passed without a production change. [Initial attempt](FixtureAttempt1.json).

A QA BindableFunction placed directly under PlayerGui disappeared on respawn. Reparenting only that probe to PlayerScripts allowed verification of the existing persistent Merge view. No production respawn code changed.

Acquisition Billboard pixels were cropped, blurred or omitted in the MCP captures; **their final appearance is not claimed verified**. Runtime image/point properties and the five-second/replacement behavior were checked. Physical touch input, real device layouts, public persistence, natural full runs and every old World1 icon individually were not re-tested. Existing unrelated asset permission/not-found messages appeared; all requested Ore icons loaded. Expected injected save warnings and stub Badge failures are distinguished from shipping errors.

## Cleanup, Save and delivery

Removed the memory provider and Edit QA Script; restored all **40** temporary Source substitutions. Final Edit contains **491 Sources: 481 unchanged from this phase's live baseline, nine intentional existing-Source changes and one new Config**. Boss common Config and earlier manual edits remain. Script Enabled values, original HttpEnabled=false and Edit camera/focus were preserved. Play stopped; viewport focused on Edit. No verification screenshots were written to disk or committed.

SaveWithoutPublish was attempted only after cleanup against PlaceId126576845524886. The API returned:

`Game:SavePlace can only be called from a server script, aborting save function`

**Canonical Studio remains UNSAVED.** No Publish, OS input, window foregrounding, UIAutomation, Studio close or rbxl writeback was performed. The user must Save manually. Git delivery does not constitute Studio Save. [Cleanup and Save result](Cleanup.json).

Boss work is retained in commit92bdfb9; this report and the scoped Ore Sources are delivered in the subsequent normal commit/push to origin/main. The unrelated pre-existing untracked visual-template report is excluded.
