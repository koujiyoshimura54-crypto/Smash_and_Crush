# Y01 Merge UI and permanent World2 Item access — 2026-10-26

Applied to the currently open authoritative Studio: Universe **10765181857**, Place **126576845524886**, Studio connection `44a1a94d-a74c-4664-928a-acde2990e8a3` (loaded place version 278). The work was based on current Studio Sources and objects, with `d1f8213` and [the Ore implementation record](../World1Ore_20261026/README.md) used for comparison. No place restore or bulk source replacement was performed.

**Handoff: Studio is open in Edit and the changes are UNSAVED. The user must manually Save/Publish before moving PCs or exiting.** No Studio Save/Publish, rbxl write-back, new rbxl, backup, copy, or migration was performed. The initial minimized window state was restored. Edit camera CFrame, Focus, FOV, camera type, and ShowDevelopmentGui were verified unchanged. Device preview settings and editor layout were not changed.

## Changed Studio full paths

| Full path | Change |
| --- | --- |
| `ReplicatedStorage.Modules.MergeShopView` | New shared interactive view factory: stable three-tab shell, grouped material cards, points, ranks, input slots, result candidates, sale controls, drag/drop and narrow layout. |
| `StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New` | Uses the shared view while retaining current proximity, authoritative state, request sequencing, response/retry and transaction wiring; refreshes the effective arrival state. |
| `ReplicatedStorage.Config.ItemMergeConfig` | Shared rank display, deterministic group ordering, and World2 eligibility validation. Existing points, per-world rarity interpolation, sampling, and mixed-world material restriction remain unchanged. |
| `ServerScriptService.Services.ItemMergeService` | Returns `World2Unlocked` and validates submitted materials with `PlayerDataService.HasReachedWorld2(player)`. Existing durable transaction and replay identity remain intact. |
| `ReplicatedStorage.Modules.PetMerge` | Shared eligibility and canonical-species grouping; individual IDs still drive evaluation and consumption. |
| `ReplicatedStorage.Modules.Pet` | Preserves the optional existing `Protected` map during normalization so protection cannot disappear between server/client inventory views. No ownership migration. |

The generated live UI is `Players.<player>.PlayerGui.MergeShopGui.MergeShopPanel`. Its `Body` contains `Item`, `Pet`, `Ore`, `Materials`, `Result.ResultItems`, `DropArea.Inputs`, `Selected`, `Clear`, `Merge`, and sale controls. The factory is the Edit-time source of this runtime UI. It uses existing basket, stud, button, star, Item, Pet, Ore, Egg and Dumbbell assets.

The separate Merge ScreenGui keeps ordinary HUD promotions below the panel. During the existing HatchGui presentation it moves below HatchGui, then returns above the HUD. Developer GUIs are untouched. Cloned labels keep TextWrapped enabled so Roblox does not disable TextScaled. Drag coordinates use InputObject.Position directly; an extra GUI-inset subtraction was found and fixed through real pointer testing.

## Authority and identity

World2 access uses the existing formal arrival authority, not level or CurrentWorld. In ordinary sessions that authority reads saved `World2Visited`. In Studio it retains the configured `ResetWorld2ArrivalOnStudioPlay` behavior and uses the effective per-Play arrival. `StudioStartOverride`, save protection, and all test settings were left unchanged. Actual gate travel marks arrival; returning to World1 does not revoke it.

The client list, material eligibility, candidate/probability calculation, server execution and sampled/granted Item use the same effective gate. Existing point requirements and the existing restriction against mixing World1 and World2 materials remain. Unlocking does not itself grant a high-rank item or change the probability formula.

Item cards group identical canonical ItemIds, which encode kind, rank/world and element. Element variants remain distinct because they have different set identities. Sorting is rank 1–10, then existing element order, then the fixed Glove / Protein / TrainingBelt order; only visible owned groups occupy cells. The Fire-only fixture displayed exactly three cards for each rank. Ranks 1–5 use five lit/unlit stars; ranks 6–10 use a blue star and rank number in owned, input, drag, candidate and completed-result views.

Pet cards group canonical species/performance identity, not shared artwork. Owned counts include all copies; the eligible ID list excludes equipped/protected copies. Selection holds unique actual IDs, and points are added per selected ID. The unchanged server path rejects duplicates, unowned IDs and ineligible individuals. Counts are rebuilt from confirmed inventory after completion. Click adds one, input click removes one, Clear empties selection, and owned counts remain unchanged until confirmed consumption. Card connections are disposed on removal; shared input/state connections are installed once per view.

Ore points, thresholds, probabilities, prices, strength bonuses and sale values were not changed. Ore inputs remain 1–5 individual units, and a successful merge grants one countable Dumbbell. Sale uses the existing authoritative transaction. Pet Merge retains Egg sampling, immediate server opening and Pet grant, with the existing hatch presentation.

## Verification

The latest isolated native Play regression completed **96 assertions**, recorded in [verification.json](verification.json). These include individual rank/order assertions, rather than 96 separate game features. The fixture, native LocalScript bridge and regression runner are in [tests/MergeUI](../../tests/MergeUI). They were temporarily installed with the existing [memory dependency](../../tests/World1Ore/Memory.luau), never left in the shipped DataModel.

All 35 Source dependencies on datastore/payment/badge services were temporarily redirected to memory mocks. Together with the instrumented client, **36 temporary Sources were restored exactly** after Play. Real storage, payments and badge awards were not used. The fixture seeds transaction-owned fields in the memory store as well as the session, preserving session metadata. It does not disable the Studio arrival reset or restore/disable an existing StudioStartOverride.

| Requested scenario | Observed result |
| --- | --- |
| Three tabs, switching and reopening | All three remain visible at identical positions/widths; footer positions match across tabs. Reopening repeatedly adds exactly one unit per activation. |
| Rank order, 5/6 boundary, list end | All 30 Fire Item groups ordered correctly; rank 10 reachable at the end. Four reference-proportioned Item rows fit around ranks 4–7. |
| Not reached → arrival → World1 return | W2 inventory hidden and server request rejected before arrival. A saved flag alone remains locked under the unchanged Studio reset. Real whitelisted gate travel unlocks; real return retains access. |
| High rank in World1 | Three W2 Rare Glove copies consumed and one W2 Epic Glove (rank 9) granted in World1. Counts changed 8→5 and 8→9. Production RNG was unmodified; this material mix has a 100% result under the existing Config. |
| Item/Pet group quantities | Multiple additions, remove-one, Clear, confirmed consumption/grant and refresh passed. Five owned Dogs allowed only three eligible IDs; selected points were 30, then 20 after one removal. |
| Pet identity/protection | Duplicate ID, unowned ID, equipped and protected requests rejected through PetRequest. Protected/equipped Dogs and the different-performance `W2 Dog` remained owned after merge. |
| Pet and Ore execution | Pet Egg selected, immediately opened server-side, and exactly one resulting Pet ID granted. Ore consumed 3 Forest Stones + 2 Spark Ores and granted one Dumbbell. 560 pt and 75% / 25% were calculated from Config, not fixed display values. |
| Ore sale and duplicate Dumbbells | Two Forest Stones sold for 110 Win; inventory 9→7 and Win 100000→100110; selection cleared. Two separate 40-point merges produced two owned NORMAL_03 copies. |
| Narrow layout | Same factory mounted in a temporary 360×640 Frame. Three tabs, points/count separation, footer separation, selection and Clear passed. No device-emulator setting change. |

Additional real Windows pointer tests in the actual Studio viewport confirmed: two clicks on one Item group → selected 2 while owned stays 8; input click → selected 1; drag/drop → exactly 1; narrow Pet card two clicks → selected 2 and 100 pt; narrow Clear click → selected 0. The MCP mouse helper did not reliably deliver activation in this session, so actual Windows pointer events were used. Physical touchscreen hardware was not tested.

Studio initially had no rendering frames (white viewport, camera viewport 1×1), delaying visual checks. Rendering later resumed at 1279×720 with the original device preview. Final visual checks and captures used the functioning native renderer. Early fixture issues (transaction-owned seed fields and an entry-timing/scroll assertion) were corrected; the final complete regression passed. The final source was syntax-compiled and checked in Edit. Twenty-two other audited relevant Sources, including PlayerDataService and the existing Ore/Pet execution services, were verified exactly preserved from the current Studio baseline. No temporary QA objects or memory-mock references remain.

## Actual image comparisons

All three requested PNGs were opened from the resolved Downloads directory `C:\Users\kouji\Downloads`. Comparisons crop each reference to its outer Merge panel and align it to the **819×540 native Studio panel crop**. No screenshot was used as an in-game background.

- [Item — rank 5/6 boundary comparison](screenshots/item-comparison.png) · [native panel](screenshots/item-studio.png)
- [Pet — grouped copies and points comparison](screenshots/pet-comparison.png) · [native panel](screenshots/pet-studio.png)
- [Ore — selected quantities and computed outcomes comparison](screenshots/ore-comparison.png) · [native panel](screenshots/ore-studio.png)
- [Narrow native panel after two physical Pet clicks](screenshots/narrow-studio.png)

Visible differences found during comparison were corrected: tiny cloned header/button text, Item row proportions, HUD overlap and material icon size. Pet always has the required Ore tab. Live icons, their intrinsic padding/tints, real counts and generated candidates remain authoritative; the reference illustrations and example values were not substituted. The existing developer preview label remains visible by instruction. These are inspected comparisons, **not a claim of pixel-perfect reproduction**.

Only the listed implementation files, focused test harness and this report/evidence are included in the commit. Normal push targets `origin/main` from the working branch; no force push.
