# Tutorial floor arrows fix and UI layout audit — 2026-10-20

## Scope and safety

Input and output: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. The actual 420 embedded Sources and 182,118 Instances were the baseline, not historical source snapshots. Read AGENTS, relevant specifications, the floor-only build report, c512f06, PerformanceAudit/60ea616 and the latest World2 gameplay record. Only `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient.Source` was changed in the place. No layout, model, balance, gameplay, UI implementation or production save changes.

Two local Play sessions used a Studio-only in-memory DataStore adapter in all six direct DataStore callers (ProfileStore, LeaderboardServer, PlayerDataService, ReceiptService, ItemPurchaseService, StudioDebugService); the existing disabled loader remained disabled. This protected account data rather than bypassing a failed production load. No reset, purchase, claim, hatch or persistent grant was executed. Temporary client/server fixtures and instrumentation were discarded on Stop. All 49 temporarily replaced Edit Sources, mock/monitor objects and the original camera were restored before ending the owned verification Studio. No Studio Save/Publish was performed. No extra place, backup or migration file was created.

## Actual carpet defect and fix

The old floor whitelist included generated structural floors but omitted the purchased walking carpets. Lobby floor top is Y=4; walking carpet top is Y=4.4000144 (lower trim top about 4.212). The floor-only ray therefore hit the lower floor and the carpet itself rejected the arrow as a visible obstruction. Native before/after probes and screenshots reproduce this, rather than inferring from names or colors.

Permit only the direct Upper/Lower walking surfaces in these verified World1-owned groups:

- `Workspace.GeneratedMap.TrainingArea.EntranceCarpets` and its direct `Path` / `PathToRun` groups (two sibling Path groups share the same Full Path).
- `Workspace.GeneratedMap.TrainingArea.PathToTreadmills` (not nested `ThreadmillStand`).
- `Workspace.GeneratedMap.BattleCorridor.StageXX.WalkableGeometry.PathToRun` and `StageXX.StageN.5.PathToRun`.

Raycast to the actual permitted upper surface and retain the original 0.055-stud arrow lift. Equipment mats, treadmill stands, ramps, panels and generic assets named Floor/Mat are not whitelisted. No real part's collision, query setting, transform or dimensions changed. A chevron straddling a real height step remains hidden by the existing 0.08-stud coplanarity test; it reappears once all samples fit a surface.

## Algorithm and behavior retained

The route remains a straight player-to-current-tutorial-target line: same 3.5 spacing, two arms, dimensions, white/neon appearance, 160-stud reach and 0.2-second update threshold. Thirteen center/arm/tip/edge surface samples and oriented-bounds blocker tests remain. An obstruction hides affected chevrons, not the remaining route beyond it. Tutorial progression/remote handlers and completion/save semantics are retained; no World2 tutorial was added.

Replace each arrow's full candidate scan with a 16-stud static XZ grid, a large-part fallback, and a live dynamic-part set. Cache original oriented bounds for anchored parts; `.Changed` invalidates moved/resized/visibility/anchoring information. Descendant add/remove handles streaming and new parts. Query-independent indexing retains CanQuery=false blockers. Candidate selection is route-local then chevron-local. Skip equivalent writes and unchanged route snapshots. Finish, death, character removal and World2 release the index and timer; reset/respawn/World1 resume them. The one-time initial registration cost is not claimed to disappear: the instrumented initial cache build took 56.63ms (60.75ms complete initial refresh), outside the settled sample.

## Before/after native Play measurements

Same isolated memory fixture, character pivot `(325,6.939267,25)`, Normal01 treadmill target, camera `(325,55,80)` looking at `(280,4,0)`, viewport 1366×767; 2-second settle plus 10-second sample each. Cached assets, no cache deletion. Foreground could not be guaranteed; treat FPS as background/uncontrolled-focus Studio observations, not public-client improvement. Both samples had arrows visible. Initial exploratory hot-swaps with stale guide folders were rejected; only clean samples below are used.

| Measurement | Before | After |
|---|---:|---:|
| Update samples | 45 | 47 |
| Arrow update mean / p95 / max ms | 136.710 / 167.021 / 171.211 | 1.662 / 1.806 / 1.837 |
| Collection mean ms, including periodic refresh zeros | 3.033 | 0 during steady sample |
| Broad phase mean ms | 131.553 | 0.835 |
| Detailed blocker tests mean ms | 1.816 | 0.654 |
| Drawing mean ms | 0.292 | 0.157 |
| Candidate visits per update | 268,553 | 1,061 |
| Detailed OBB tests per update | 646 | 63 |
| Visible chevrons | 7 | 17 |
| Render FPS | 6.20 | 15.07 |
| Frame p50 / p95 ms | 183.71 / 203.77 | 66.70 / 70.89 |

Detailed raw samples, stage timings and conditions are in Arrow_Before.json, Arrow_After.json and PerformanceSummary.json. Collection zeros after settle mean index reuse, not zero initial build cost. FPS is not extrapolated to foreground clients. This does not establish that startup delays or all game stutter are fixed.

## Validation

Native geometry probes use the actual parts and Luau implementation: ordinary floors, walking carpets, excluded equipment stand, carpet boundary, off-floor, actual character and actual Stage01 enemy. The final repeat correctly hid a carpet chevron under the respawned character; the earlier clean visual/benchmark confirmed unobstructed carpet display. Twenty-six unchanged white-floor probes have zero before/after allow/deny mismatches. Added, moved, removed and unanchored CanQuery=false fixtures, an outer-arm-only thin blocker, restoration and reappearance all passed. Geometry.json contains results (local account name redacted).

Lifecycle.json records completion releasing all records/timer, reset rebuilding them, World2 suspension/World1 resume, target switching, and server-induced fixture death followed by ordinary respawn. Exactly one local guide was retained while active; completion removed it. These presentation fixtures do not claim a full gameplay tutorial walkthrough or production save test. The movement/target code and progression handlers were retained; real mobile input, streamed network arrival under a remote server, complete combat-to-finish progression and public-client operation remain unverified.

Actual screenshots: [before carpet](Carpet_Before.jpg), [after carpet](Carpet_After.jpg), [overview](Arrows_Overview.jpg). These show rendered arrows, not only Image/Part configuration.

## All-UI investigation (no fixes applied)

UI_StaticInventory.json inventories 94 UI-related Sources and all 416 authored ScreenGui/BillboardGui/SurfaceGui/ViewportFrame Instances, including non-StarterGui facility UI and shared/client/server builders. Forty-one applicable source containers compiled with temporary boundary counters; raw runtime measurements cover 25 client containers/shared modules and ShopRewardController server tags. Disabled/vendor/nonexecuted Sources are cataloged, not labeled runtime-normal. Instrumented function durations are inclusive wall-clock; nested timings must not be summed.

Observed dynamic screens include StrengthGui, StageSkipGui, StrengthGainGui, LevelUpGui, WorldTravelGui, NotifyGui, SizeChangeGui, death/World1-double-Win/legacy Merge screens and engine Freecam/ScreenGui. Runtime collectors include Pet/Egg client startup, InventoryPresentation, item panels, notification systems, purchase skinning and facility-related Sources. The facility inventory is static plus observed builder calls; every 3D panel was not individually interacted with.

Native mouse activation exercised Shop open/reopen, Inventory open/close, Dumbbells/Items/Aura/Speed tabs and additional Rebirth/Pets/reward-menu opening attempts without purchase/claim. Snapshot panel states prove the Shop/Inventory transitions. Button-dispatch success alone does not establish every additional screen opened. UI_Measurements.json records each observed state. Physical resolution change and direct signal-connection enumeration were not obtained; the single actual 1366×767 viewport is recorded. Connection accumulation under repeated resize remains unverified.

| Priority / status | Full Path / evidence | Impact and proposed repair (not applied) |
|---|---|---|
| P1, runtime confirmed recurring cost | `ReplicatedStorage.Modules.HUDLayout`, `Mount.layout` and `placeReturnButton` | Mount is correctly deduplicated, but one RenderStepped callback runs full layout, scans `gui.Parent:GetDescendants()` for return-button obstruction and writes layout properties every frame. Initial sample: 762 layouts / 7,592ms inclusive; return placement alone 759 / 7,501ms. Later sampled totals imply roughly 10–12ms/call and continued hidden-panel work. Cache visible rectangles, invalidate on actual layout/visibility/viewport changes, and diff writes. Preserve touch/overlay/return placement. Improvement magnitude after a fix is unmeasured. |
| P2, runtime confirmed startup storm; current-session error not reproduced | `StarterGui.StrengthGui.EssentialStudShopClient.layoutDumbbellShop` | Reproduced exactly 493 initial calls / 201.15ms total, max 3.99ms. Watches Holder.AbsoluteSize, UIListLayout.AbsoluteContentSize and responsive scale while writing card sizes/CanvasSize. Opening/reopening did not increase this counter in the tested viewport. Previous audit recorded the event-depth error; current captured console did not. Coalesce deferred layout, compare target values, separate sizing from canvas measurement. Preserve wrapping/design/price binding. |
| P3, code-level shared feedback risk; not a universal reproduced loop | `ReplicatedStorage.Modules.ResponsivePanels` with InventoryTabs/ItemInventory/InventoryCapacity/TimeRewards/DailyRewards clients | Fit/set/layout helpers write properties unconditionally while screens watch AbsoluteSize/content. Initial 598 Fit calls and 97 shared refresh calls; finite tab/open samples, no growing duplicate Mount shown. Cache derived layout keys and share one scheduled pass; test mobile/tablet/resize before changing. |
| P4, observed low-cost continuous updates | `StarterPlayer.StarterPlayerScripts.UI.SizeChangeClient`, `.ItemEffectHUDClient`, `StarterGui.StrengthGui.ShopBenefitsClient`, `StrengthGainGui.StrengthGainClient` | Initial counters respectively ~750, 752, 784, 784 calls. Small in this sample (about 11.18ms, 2.26ms, 15.48ms, 4.05ms totals), so not equivalent to the HUD hotspot. Gate hidden/equivalent updates only if measured worthwhile. |
| Bounded in tested cases; not globally certified | InventoryPresentation, inventory tabs/items, AutoTap, LevelUp fit, notification startup, facility tag builders | Executed counters and open/close states were finite; no captured runtime layout exception. Mount guards and cleanup exist in HUD/purchase skin modules. Unopened hatch/paid/detailed facility UI, touch layouts and connection growth need separate representative testing. |

Captured console includes preexisting unauthorized sound assets and engine UIBlox FoundationProvider warnings. No UI fix was made, and these unrelated asset/engine warnings were not recategorized as tutorial regressions. The remaining performance work should start with recurring HUD layout, then the Shop initial layout feedback, then shared resize/write coalescing. Do not assume all UI shares the same bug.

## Same-file integrity

FileValidation.json records hashes and repaired referent validation. Only one PROP chunk changed; PRNT, all other property chunks, shared strings, Instance count/classes and every UniqueId remain unchanged. ReDecode, Source compilation and canonicalization idempotence passed. All 182,118 referents are dense 0..182117; no duplicate UniqueId. The place was reopened separately in Studio Edit for native verification (see NativeReopen.json). UI audit edits are absent from the written file. World1/World2 layout and gameplay Sources are unchanged.
