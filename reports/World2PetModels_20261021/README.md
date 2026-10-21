# World2 approved Pet model assignment — 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, applied to the current file after `58849b4`. The current file already contained `ae7c5d0`, `c63a393`, `2ee20a4`, the World2 premium passes, and Limited Egg 02's single Open 1 purchase connection. No historical place or source bundle was restored.

## Assignment and compatibility

The columns below are fixed slots with probabilities **25%, 25%, 25%, 15%, 6.5%, 3%, 0.5%**. Each row totals 100%. Numbers identify purchased `Pet_` models, not Roblox AssetIds.

| Egg | 1 | 2 | 3 | 4 | 5 | 6 | 7 | Preserved Strength multipliers |
|---|---|---|---|---|---|---|---|---|
| Basic | Pet_027 | Pet_028 | Pet_032 | Pet_052 | Pet_030 | Pet_141 | Pet_098 | 1.6, 1.6, 1.6, 1.8, 2, 2.3, 2.6 |
| Rare | Pet_035 | Pet_040 | Pet_063 | Pet_006 | Pet_054 | Pet_112 | Pet_014 | 1.8, 1.8, 1.8, 2, 2.3, 2.6, 2.9 |
| Legendary | Pet_115 | Pet_082 | Pet_092 | Pet_072 | Pet_004 | Pet_168 | Pet_113 | 2, 2, 2, 2.2, 2.5, 2.9, 3.2 |
| Mythic | Pet_104 | Pet_131 | Pet_164 | Pet_026 | Pet_018 | Pet_129 | Pet_051 | 2.2, 2.2, 2.2, 2.5, 2.8, 3.1, 3.5 |
| Limited Egg 02 | Pet_107 | Pet_089 | Pet_093 | Pet_172 | Pet_133 | Pet_117 | Pet_178 | 2.9, 2.9, 2.9, 3.2, 3.6, 4, 4.5 |

`Assignments.csv` records every old saved species ID, new model ID, unchanged effect, probability, source Full Path and destination Full Path. Existing `W2 Dog` through `W2 Chimpanzini Bananini`, and `W2 Pet_042/064/081/086/094/024/135`, remain the saved species and receipt-result keys. Only their presentation lookup changes. Individual GUIDs, duplicate copies, equipped IDs, existing state/revision/merge semantics and unknown owned names are not migrated or cleared. The existing persistence services and schemas are unchanged.

Catalog identification used `docs/Stud_Egg_Pet_Catalog.md`, `docs/Stud_Pet_Catalog.csv`, `docs/Stud_Pet_Photo_Catalog.html` and their selected photographs, together with the actual purchased models. The structurally identified source is `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_XXX`; this is the Pets branch, not the other identically named Mod containing Eggs. All 35 selected models were found once. Only those 35 model subtrees are registered in `ReplicatedStorage.Assets.World2Pets.Pet_XXX`. Original reference assets remain intact. Shapes, mesh/texture references, colors, materials, rig-relative transforms and attributes are preserved; internal Instance references are remapped to each clone.

## Changed Full Paths

- `ReplicatedStorage.Config.World2GameplayConfig`: separate immutable saved names from the approved model table and presentation metadata; unchanged odds, multipliers, prices and paid offers.
- `ReplicatedStorage.Modules.Pet`: shared saved-name-to-model lookup and display caption, purchased-model preparation, and separate paid classification from use of model viewports. Normal World2 purchased models must still be accepted by the normal hatch path. World1 model lookup and paid IDs remain intact.
- `ReplicatedStorage.Modules.Egg`: tie ordering for World2 uses its existing explicit slot. This fixes Mythic's former alphabetic ordering of the three 25% names without changing their odds or any saved result. World1 and Pet Merge membership/order rules remain unchanged.
- `ReplicatedStorage.Modules.LimitedPetViewport`: reuse the existing model renderer for all 35; retain corner/aspect camera fitting and whole-rig placement. Normal candidates use the whole square instead of reserving the Inventory title band.
- `StarterPlayer.StarterPlayerScripts.Services.EggClient`: use actual model viewports for the selected World2 candidates; preserve the existing maximum-four-column layout and probability bands.
- `StarterPlayer.StarterPlayerScripts.Services.PetClient`: display the assigned model name on the existing tiles/cards. Correct the wrapping Inventory canvas extent to include its scale-based padding; Play exposed an inaccessible final row with a full test collection. Automatic sizing and the existing layout/design remain in use, and connections are owned by the existing rebuild janitor.
- `StarterPlayer.StarterPlayerScripts.Services.StandClient`: use the same assigned display names in Limited Egg 02; retain the existing dedicated UI, Marketplace price lookup and purchase flow.
- `StarterPlayer.StarterPlayerScripts.Services.HatchClient`: display the assigned name; the existing reveal uses the same Pet lookup and whole-rig preparation.
- `StarterPlayer.StarterPlayerScripts.Services.PetFollowClient`: use grounded purchased-model presentation for the new normal models as well as Limited models. Follow placement, one-pet limit and cleanup remain the existing implementation.

The existing uniform per-model height fit remains 3 studs. Low/long World2 rigs also cap their visible width/depth at 1.6 times that height (4.8 studs), preserving proportions and scaling each fresh clone from its template. Invisible root boxes do not determine the visible geometry fit. No animation was authored or added; World1 presentation metadata is unchanged.

Limited Egg 02 retains Developer Product **3720640383**, base price **279 Robux**, **Open 1 / one Pet**. The actual Marketplace-derived displayed price in this verification session was 252 Robux. No quantity was inferred from either price. `LimitedEggConfig`, `ReceiptService`, `PlayerDataService`, PolicyService gates and receipt version 1 were not changed. A previously recorded result such as `W2 Pet_042` keeps its result ID and now resolves visually to Pet_107; it is not rerolled. Premium Aura 2045204630 and Premium Treadmill 2044250678 are untouched.

## Verification performed

Two real local Play sessions used temporary memory DataStore/Marketplace/Policy adapters. Fixture setup supplied test Win, old saved Pet names and positioning; no live data or real payment was used. Actual production UI and server methods ran against that isolated state. No test adapters, forced grants or fixture instances are written to the completed place.

- All 35 models, unique assignments, explicit slot order, each 100% probability sum and unchanged Strength values were checked. Every owned species resolved to its approved model. The 35 catalog photos were inspected against the selected source models.
- All 35 models were visually inspected in the actual five candidate sheets and across the actual scrolling Inventory. All use model viewports, with no unrelated placeholder icons, missing body parts, sideways rigs or clipping in their individual viewports. The normal sheets remain four-plus-three candidates with probabilities beneath. The sixth left-menu Pets entry is unchanged.
- A full old-ID fixture loaded 39 copies: the 35 World2 species, an extra duplicate, two World1 specimens and an unknown species. Count, equipped GUID and every name survived load. The unknown entry remained owned; its existing missing-icon warning was expected from that deliberately unknown fixture, not one of the 35 models.
- Each normal Egg used its existing server Open1 request and saved one result. Actual hatch clicks revealed the new model/name, and the client equip request selected the granted individual. Representative first-session results were Basic Pet_027, Rare Pet_063, Legendary Pet_115 and Mythic Pet_026. Final-session additional Basic/Rare reveals showed Pet_030 and Pet_040. No low-probability roll was waited for.
- Limited Egg 02 used the actual server ProcessReceipt with an isolated mock receipt. It granted exactly one saved result (`W2 Pet_042` / Pet_107), delivered the existing server-confirmed hatch notification, and was equipped through the client. Replaying the same receipt did not increase the collection. Save/release/load against the memory store retained all 44 copies and equipment; another receipt replay still did not add a copy.
- All 35 were equipped in turn in the running server. The real follower's mesh-ID signature matched the assigned template for every species, and each committed Strength multiplier matched its original slot. The client observed at most one follower throughout. Actual Humanoid death and automatic respawn retained the equipment and returned to one follower. Fixture World2-to-World1-to-World2 travel retained one follower at approximately 5.4 studs from the character, without an old-world model left behind.
- A fresh second Play confirmed the final Inventory scroll fix without runtime layout overrides: the final visible tile bottom was 520.46 within a frame bottom of 524.08. It also confirmed Mythic's exact approved order after the tie-order fix.
- World1 Basic's actual candidate UI and Limited Egg 01's existing seven-model UI were inspected. All four World1 normal pools and model lookups passed; the World1 Limited product remains 3717610547. Limited Egg 01's price fetch was deliberately disabled for the render-only check. No World1 balance, assets or ownership keys changed.
- Console review found no changed-code runtime errors or infinite yields. Existing unauthorized sound-asset and Roblox Core UI warnings were outside this task. The explicit unknown saved-name fixture produced the expected icon warning and was not discarded.

`Basic.png`, `Rare.png`, `Legendary.png`, `Mythic.png`, and `LimitedEgg02.png` are retained at the user's request. These are crops of the actual owned Studio game viewport (HD720 emulation, displayed at 801-by-450), not photo-catalog icons or mock candidate sheets. Native window capture was used because the MCP screenshot path did not faithfully capture BillboardGui layout. Extra diagnostic screenshots were inspected and removed.

Not performed: real Robux payment, production DataStore writes, a live disconnect/rejoin, physical-device testing, multiplayer or unrelated Boss/balance regression. Reload persistence was simulated through the real PlayerDataService with a memory store; it is not claimed as live rejoin verification.

## Saved artifact and cleanup

`tools/write_world2_pet_models.py` guards the exact current input hash, compiles the nine changed Sources, adds only the 35 approved templates, and verifies every existing property outside those nine Sources remains identical. `Writeback.json` contains the final file hash, clone counts and property/reference comparisons; `Assignments.csv` contains the complete compatibility map. No extra rbxl, backup, copy or migration was created. Studio Save/Publish was not used.

The final fresh-file Studio check and lock state are recorded in `SavedStudioCheck.json`. Only task-owned Studios were stopped/closed without saving. All test substitutions were restored before closure, and any task-owned stale lock marker was removed only after its recorded process had exited and exclusive target-file access succeeded. The original dirty documentation, BossChaseService working-copy edit and unrelated untracked files are excluded from this commit.
