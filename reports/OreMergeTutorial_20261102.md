# Ore-to-Dumbbell onboarding — 2026-11-02

Implemented in the current unsaved canonical Studio, PlaceId **126576845524886**. The eight existing target Sources matched repository baseline `d69d775` before editing. Applied scoped diffs; the other local-file Studio was untouched. Reviewed `PurchasedTutorialAudit_20261101/REPORT.md`, `StoneOnboarding_20261101.md`, live floor guidance, Forge transactions, data creation and the existing reset command.

## Changed Full Paths

| Full Path | Responsibility |
| --- | --- |
| `ReplicatedStorage.Modules.OreMergeTutorialState` | New, separate eligible/completed state; usable Ore quantity count. |
| `ServerScriptService.Services.PlayerDataService` | New/reset defaults, legacy exclusion, load/save, attributes and reset fencing. |
| `ReplicatedStorage.Modules.ForgeInventory` | Complete eligible onboarding only inside successful ordinary MergeOre mutation. |
| `ServerScriptService.Services.ForgePersistence` | Publish the state confirmed by that same durable transaction. |
| `ServerScriptService.Services.ForgeService` | Include tutorial state in the existing Forge snapshot. |
| `ReplicatedStorage.Modules.ForgeClient` | Reject old-session responses and clear stale pending/selection state after reset. |
| `ReplicatedStorage.Modules.MergeShopView` | Read-only guidance state and lifecycle change event; explicit close revision. |
| `ReplicatedStorage.Modules.OreMergeTutorialGuide` | New presentation controller; current-step evaluation, modal/lobby gating and target following. |
| `StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New` | Mount/dispose the guide with the existing view. |
| `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` | Reuse the existing floor renderer exclusively after the original guide completes. |
| `StarterGui.OreMergeTutorialGui` | Authored, editable highlight and message template. |

## Behavior and persistence

Only genuinely new records and the existing `/resetdata` path opt in. A missing field on an existing record normalizes to ineligible. `OreMergeTutorial` has Version, Eligible, Completed and optional CompletionId; the original TutorialCompleted remains separate.

Any available Ore quantities totaling at least two qualify. No TimeReward claim, Strength, developer identity or distinct-type condition is used. The guide waits for the original tutorial, a living character in the actual Lobby floor bounds, and competing return/death/reward/hatch/modal presentation to finish. A shortage pauses it. Fixed paths and existing state events are checked at 5 Hz only while eligible and unfinished; no per-frame full-tree scan was added.

Current UI state determines the step: facility navigation, Ore tab, add2–5, Merge/pending. The existing card callback and drag path each add one unit; the message correctly says to tap again for another unit of the same Ore. Closing dismisses until reopening or returning; death and leaving Lobby suspend. Existing selections are evaluated rather than replaced. The floor destination is the real Merge Area; original wall/Boss/Trophy routing and carpet/occlusion/cache logic remain.

Completion is part of the existing atomic Ore-consume/Dumbbell-grant Forge transaction, including self-directed success before the guide. Failure, button press, sale and Item/Pet merge cannot complete it. Retry identities, journals and reset-token barriers remain. A reset rotates ForgeSessionToken; old server requests and client responses are rejected and old selections clear. Reset also copies the already-preserved StrengthRewards journal back into the new in-memory data table, matching the existing reset write, and clears an old pending first-Boss defeat. No paid/offline reward policy or reward amount changed.

No reward is issued by the guide. Stone introduction, rank UI/fonts/K/M, Ore2–5 arithmetic, probabilities, capacity and ordinary generated-result UI are retained. The inactive purchased Main and 19-step tutorial remain inactive.

## Owner editing / GUI reconstruction

Run `tools/InstallOreMergeTutorialGui.luau` once in Edit to recreate the authored GUI in another document. It preserves an existing template rather than overwriting owner changes. Highlight donor: `ReplicatedStorage.Assets.Tutorial.TutorialHighlight`. Message donor: `StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy.Main.Amount`, with the purchased Config.Tutorial gradient.

| Exact editable location | Properties / attributes |
| --- | --- |
| `StarterGui.OreMergeTutorialGui.Canvas.Highlight.Outline` | UIStroke Color, Thickness, Transparency. Default white,3px. |
| `...Canvas.Highlight.Shadow` | UIStroke Color, Thickness, Transparency. Default black,6px. |
| `...Canvas.Highlight.Corner` | UICorner CornerRadius, default8px. |
| `...Canvas.Highlight` | Attributes PaddingX / PaddingY, default6 /6. |
| `StarterGui.OreMergeTutorialGui.Messages` | StringValue.Value on GoToMerge, ChooseOre, AddOres, Merge, Saving. |
| `StarterGui.OreMergeTutorialGui.Canvas.Message` | FontFace, text/background/stroke/gradient appearance; UITextSizeConstraint; MaxWidth, Gap; HeaderWidthScale=.70, HeaderCenterX=.50, HeaderInset=4. |

The runtime owns highlight position/size/visibility and message text/position/size/visibility only. It never resets the authored outline, corner, font or colors. The instruction occupies the panel title band while open, leaving tabs, close, cards and Merge unobstructed; outside the panel it uses the authored banner dimensions. All overlay objects are noninteractive. Messages can be edited centrally without touching Source.

## Focused verification

Three solo native Play sessions used memory-only DataStore/Badge adapters, native server/client probes and programmatic actions. Both Studio and Production *store names* used by the real reset handler were intercepted by the memory adapter. No production data, real payment or OS input was used.

- Fresh data: actual TimeReward StoneIntro01 claim produced one Stone; no guide. Prepared Strength only accelerated the actual owner Stage1 Boss attack; normal Trophy pickup/return completed the original guide and left two Stones. Floor target became OreMerge.
- Same Stone activated twice: AddOres → Merge; removing one returned AddOres. Close/reopen resumed correctly. Actual UI submission consumed two and created exactly one Dumbbell, completed onboarding, hid the guide and retained the normal result. Real Merge-area proximity also opened the view and advanced the guide.
- The actual existing `StudioDebugService.Execute(player, "/resetdata")` handler ran, without a replacement command. First-Boss and TimeReward flags reset; the two-Stone initial path worked again without manually reloading the session.
- Old request after reset returned InventoryChanged with no consumption/completion; old client response was rejected. One-unit merge returned SelectAtLeastTwoOres. Self-directed two-unit merge before original tutorial completion still completed onboarding.
- Successful replay returned AlreadyApplied, no additional consumption/grant. Memory save/release/load retained completion and one Dumbbell.
- Injected write failure returned InventorySavePending, preserved both Ores and incomplete state. Resolving and replaying produced exactly one Dumbbell and one completion.
- Legacy record with the new field removed remained ineligible despite two Ores and original tutorial completion. Selling to one Ore paused; a separate ordinary Ore grant restored eligibility.
- Leaving Lobby, death/respawn, RunReturnBusy, offline popup and hatch blocking/resume passed. The offline UI normally closes an unsupported forced-open popup, so the modal probe held it visible briefly to test gating.
- Rendered normal1279×662 UI area and isolated460×560 /400×520 native mounts were inspected. Target alignment passed within2px integer-render rounding after selection, removal and resize. No Studio window, display or camera setting changed.
- Authored outline color/5px thickness/12px corner/10×8 padding and edited ChooseOre text survived a new Play start and step changes. Restored final white3px/8px/6×6 settings afterward.
- Initial render exposed instruction overlap with tabs; moved the callout into the title band and checked again. A plugin-VM/native-VM probe mismatch and an overly strict1px test tolerance were corrected in the test harness; these were not gameplay failures. Final Play console had no related runtime error. Existing asset-access warnings remained.

The reusable probes are `tests/OreMergeTutorial.server.luau`, `tests/OreMergeTutorial.client.luau` and `tests/OreMergeTutorialVisualChecks.client.luau`. They are **not production Scripts**: install only with the memory adapters and the documented native view probes. The server fixture requires the existing __UI2Memory module; it must never run the reset check against real stores.

Not verified: production DataStore/rejoin, physical mouse/touch input, actual phone emulation, simultaneous multiplayer and every possible popup. Narrow checks resize an isolated GUI mount, not the user's viewport. Original carpet/wall occlusion was retained by Source comparison, not broadly re-tested visually. Screenshots were inspected transiently, following repository policy; none are committed.

## Cleanup / delivery

Stopped Play; restored all10 temporary Source substitutions from exact pre-test copies and removed temporary adapters/probes. Restored authored appearance after the customization check. Final production Sources compile and match the repository; GUI template remains in Edit. No Save, Publish, rbxl write or Studio exit. Only solo test API was used; the toolbar's remembered test selector is not exposed by MCP.

**Changes remain unsaved in Studio. The owner must manually Save/Publish.**
