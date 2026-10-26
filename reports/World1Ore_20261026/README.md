# World1 Ore and Pet Merge — 2026-10-26

Implemented in the user's existing, unsaved Studio Edit document: Place **126576845524886**, Universe **10765181857**, loaded version **267**. Git was safely fast-forwarded to `abdb6a4` before the scoped changes. The current Studio Sources were the baseline; older files were not imported. An existing unrelated untracked report was retained.

## Phase 1.1 — Pet Merge diagnosis and connection

Reproduced with actual mouse input: two eligible normal Pet copies produced Basic/Rare candidates but the Merge button remained inactive. The existing purchased Merge view explicitly implemented a **preview-only** Pet path; there was no execution callback/server Merge action. This was not fixed by making the button always active.

`PetMerge.Evaluate` now shares the existing `Egg.mergePet` points and `Egg.mergePreview` probabilities between UI and server. It requires at least two distinct owned, eligible copies and excludes equipped/protected/limited/ineligible Pets. Item and Pet material rules do not inherit Ore's 1–5 limit. The existing request ID/revision/generation and durable Pet mutation path consume the selected IDs atomically. The server rolls the existing Possible Eggs outcome first, then exactly one Pet from that Egg. As subsequently requested, the resulting Egg immediately enters the existing Hatch presentation; it is not placed in a new Egg inventory. `LastMergeEgg` and the existing last-results journal make the presentation/retry identity explicit. No paid receipt protection was relaxed.

## Phase 1.2 — authoritative values and transactions

- `OreConfig` defines all 20 requested IDs, image IDs, points, rarities and specified sale prices. Only 001–016 are available. 017–020 are reserved and have no invented sale prices; client requests cannot use them.
- `DumbbellItemMaster` is the single authority for the twelve World1 purchase prices, merge thresholds and sale prices. Strength bonuses, IDs and the **current Studio's** transparent images are retained. Shop, Inventory and equipment stands continue using that master.
- World1's existing 20% Item outcome is retained, including its Item type/rank roll. Its former 80% miss becomes one Ore from the specified conditional Stage pool. Stage9 first admits Spark Ore; Stage10 keeps the same pool with the requested weights. World2's draw/grant path is unchanged.
- A legitimate owner/run/stage defeat is deduplicated before yielding. Trophy Win collection remains separate. The owner's acquisition cue uses a local BillboardGui for about two seconds and does not block movement/inputs. Death/respawn cleanup removes it. Images preload independently of gameplay.
- Following the user's later decision, a full existing run bag discards **either Item or Ore**, with no acquisition cue. A discard animation remains future work. Ore quantities are durable inventory, separate from the existing Item run-bag count/capacity and banking lifecycle; this change does not redefine Item carrying or death loss.
- Ore merge accepts **1–5 units total**, including repeated IDs. It consumes no Win, grants one dumbbell, and uses the same threshold interpolation on client/server. Ore selling has no five-unit cap. Dumbbells are never merge materials.
- Quantities preserve legacy `true` ownership as exactly one, idempotently, and retain unknown IDs. Compatibility callers still receive boolean ownership views. Equipment contributes one configured bonus regardless of quantity. World2 reach locks and unowned silhouettes remain.
- World1 dumbbell sales protect the equipped last copy. All prices/deltas/outcomes are server-derived. `ForgePersistence` joins the existing session ownership/reset fencing, pending-mutation barrier and UpdateAsync path. Consumption/output and sale debit/Win credit commit together. An uncertain acknowledgement retains the same operation and chosen outcome. Request sequence/token/generation prevent stale replay. Client retries keep the same identity and back off to eight seconds; they do not silently make a second purchase/roll.
- `/test` uses the existing StudioStartOverride isolation. Ore/dumbbell changes and Pet merge are temporary there and revert on reset. Production paid receipts remain protected.

### World1 dumbbells

| ID | Strength | Merge points | Purchase Win | Sale Win |
|---|---:|---:|---:|---:|
| NORMAL_01 | 3 | 5 | 7 | 3 |
| NORMAL_02 | 5 | 20 | 20 | 10 |
| NORMAL_03 | 9 | 40 | 50 | 25 |
| NORMAL_04 | 15 | 70 | 130 | 65 |
| NORMAL_05 | 25 | 110 | 250 | 125 |
| NORMAL_06 | 45 | 160 | 500 | 250 |
| NORMAL_07 | 75 | 220 | 1,000 | 500 |
| NORMAL_08 | 120 | 290 | 1,500 | 750 |
| NORMAL_09 | 180 | 370 | 2,500 | 1,250 |
| NORMAL_10 | 280 | 450 | 4,500 | 2,250 |
| NORMAL_11 | 450 | 530 | 8,000 | 4,000 |
| NORMAL_12 | 700 | 650 | 13,000 | 6,500 |

## Phase 1.3 — interactive purchased UI

The supplied `Downloads/鉱石マージ・ダンベル生成画面.png` was opened and inspected. The existing purchased Merge factory now has Item/Pet/Ore tabs, a yellow Stud header, three-column Ore cards, independent five-slot input row, shared result probabilities, total points and inline yellow Sell/Back mode. Existing Item stars and Pet Egg previews remain. Ore uses its specified images, not Item stars. Dumbbell Inventory adds quantity and inline quantity-sale controls; no Ore Inventory tab was added.

Responsive portrait rows use design-space font sizes to avoid clipping/double-scaling small labels. A temporary **360×430 parent frame** exercised the same production factory and real input, without modifying Studio's device emulator/window layout. It is not a physical mobile-device test. The main final captures were **1390×497**, whereas the supplied reference is **1615×974**: an identical-resolution comparison was not performed. The final portrait `Selected` font was subsequently reduced from 36 to 28 design units; the retained narrow image predates that one sizing adjustment.

Requested images (actual Studio game captures, not generated artwork):

- [Ore 560 points, #11 75% / #12 25%](ore-560.jpg)
- [Ore sale: eight Forest Stones, 440 Win](ore-sale.jpg)
- [Pet before: two selected, disabled](pet-before.jpg)
- [Pet after: two selected, enabled](pet-enabled.jpg) — candidate Egg models were still loading at this capture.
- [Pet merge Hatch result](pet-hatched.jpg)
- [Duplicate dumbbell equipped with quantity sale](dumbbell-duplicate.jpg)
- [Narrow factory/input check](ore-narrow.jpg) — constrained test parent over the unchanged running UI; not a production second panel.

Spark Ore initially failed to render. Later the specified `rbxassetid://103644070407489` loaded successfully, including the user's ContentProvider success log, and visibly rendered in both cards and input slots in the final 560-point capture. No image ID or artwork was substituted.

## Phase 1.4 — verification, with evidence types separated

| Method | Observed result |
|---|---|
| Native pure/config simulation | [313 assertions](pure-results.json): all twelve values/thresholds, availability/reserved IDs, all ten conditional pool totals/boundaries, 500/530/560/590/620/650 examples, invalid quantities, old boolean idempotence, sale over five, insufficient funds/already-owned rejection, atomic pure transforms and equipped-last-copy protection. |
| Actual Studio Play mouse input | Ore scrolling to the last row; repeated materials; 560-point candidates; sixth unit rejected; Merge consumed 2 Spark + 3 Forest and granted #11 without charging Win. Removing one input slot changed 560→460 and 5→4; Clear reset to zero and disabled Merge. Actual Forest sale selected Max=8 and raised Win 99,880→100,320 while removing all eight. |
| Actual Studio Play mouse input | Pet two-copy selection enabled Merge, consumed exactly two copies, rolled Rare Egg and ran existing Hatch clicks/reveal to Lizard; count 8→7 and Win unchanged. Item representative two-copy merge completed with net count 4→3. |
| Actual Studio Play mouse input | Generated NORMAL_01 duplicates displayed ×2; equip worked. One-copy sale changed ×2→×1, kept NORMAL_01 equipped, added exactly 3 Win, and disabled sale with `Keep 1`. Updated unowned purchase buttons rendered at normal width. |
| Constrained narrow UI / input | Production factory in 360×430 parent; mouse click and drag-to-drop selected Ore. Portrait label clipping was found and corrected. No touch hardware or device-emulator test. |
| Actual remote calls in isolated Play | [27 assertions](remote-results.json): one-Ore merge, duplicate dumbbell ownership, request replay once, reserved/six/excess rejection, eight-unit sale, equipped/duplicate-ID/one-Pet/stale-revision rejection, valid Pet merge and retry without duplicate grant. These are scripted RemoteFunction calls, not mouse actions. |
| Isolated persistence fault and reload | In-memory DataStore used the real mutation/save/load paths. A committed write with lost acknowledgement returned pending; retry acknowledged the same operation once. Explicit Save→Release→Load retained Ore counts, duplicate dumbbells, equipped ID and Pet revision. No production DataStore was written. |
| StudioStartOverride isolation | Called the actual ApplyStudioStartLevel/Restore path (did not type chat `/test`). Ore merge and Pet merge worked in the temporary view, store-write counter stayed 160, reset restored original counts/Pet revision/equipment. |
| Actual combat with controlled fixture | Real EnemyManager attack/defeat on Stage9 and Stage10, with test-only RNG forcing the upper Ore pool: Spark 8→9→10. Full bag then rejected both forced Ore and Item rewards without advancing the Forge sequence. Controlled draws are not a statistical natural-drop test. |
| Native two-client Play | [20 checks](multiplayer-results.json): both real engine clients independently merged through their remotes; one player's real combat defeat left the other Boss alive; reward remote/head cue/ownership stayed with the owner; dedup and death cleanup passed. Inputs were scripted. No two-client physical-click or video capture was made. |
| Static / final Edit readback | [Final audit](final-audit.json): all 22 changed Sources compile and exactly match Edit; 40 scoped Sources checked, including unchanged baseline dependencies. Test fixtures absent, Play stopped. Camera CFrame/Focus/FOV and ShowDevelopmentGui matched their recorded values after restoration. |

The two-client head-cue record sampled `Image.IsLoaded=false` shortly after receipt. It proves owner routing/cleanup, **not successful rendered icon loading**. Background/per-cue preload was subsequently added; Spark's rendered card/slot was verified, but a fresh two-client rendered overhead-icon capture was not obtained. Existing unrelated sound/asset authorization warnings were present. No new Forge/Merge runtime exception was observed in the focused tests; expected injected save-failure warnings are not counted as production failures.

Remaining unverified: published-server behavior, real payments/production saves/rejoin, true World portal round-trip UI (CurrentWorld attributes were simulated), actual mobile touch, identical reference-resolution comparison, final portrait label size after the last small adjustment, two-client rendered overhead image after preload, and a full training-gain measurement after generated equipment. Existing Strength bonus/multiplier code was preserved and ownership/equip values were checked. Do not call these passed.

## Changed Full Paths

New:

- `ReplicatedStorage.Config.OreConfig`
- `ReplicatedStorage.Modules.InventoryCounts`
- `ReplicatedStorage.Modules.OreMerge`
- `ReplicatedStorage.Modules.ForgeInventory`
- `ReplicatedStorage.Modules.ForgeClient`
- `ReplicatedStorage.Modules.PetMerge`
- `ServerScriptService.Services.ForgePersistence`
- `ServerScriptService.Services.ForgeService`
- `ServerScriptService.Systems.Controllers.ForgeController`

Modified:

- `ReplicatedStorage.Config.DumbbellItemMaster`
- `ReplicatedStorage.Modules.Pet`
- `ServerScriptService.Services.PlayerDataService`
- `ServerScriptService.Services.DumbbellService`
- `ServerScriptService.Services.EggServer`
- `ServerScriptService.Services.EnemyDropRoller`
- `ServerScriptService.Services.EnemyDropGachaService`
- `ServerScriptService.Services.TrophyRewardService` (quantity-compatible owned check only)
- `ServerScriptService.Systems.Controllers.DumbbellController`
- `StarterGui.StrengthGui.InventoryPanelClient`
- `StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New`
- `StarterPlayer.StarterPlayerScripts.Services.PetClient`
- `StarterPlayer.StarterPlayerScripts.UI.EnemyDropGachaClient`

`src/` contains the complete restorable Sources; the Merge and Inventory Sources recreate the added runtime controls from existing purchased donors. No new bitmap assets are required. `tests/World1Ore/` contains isolated fixtures; they must never be mounted in a production game. Memory mocks for DataStore/Marketplace/Badge were injected only for QA and all **36** temporary Source replacements were restored, with fixtures removed, before the final audit.

## Delivery state

Implementation is present in the user's current **unsaved Studio Edit session**. User Studio remains open. The temporary native multiplayer clients ended. No Studio Save/Publish, local rbxl rewrite, backup/copy/Place creation, or Cloud publication was performed. Git records are not evidence that the Cloud published version contains these edits. **Manual Save/Publish is required.**
