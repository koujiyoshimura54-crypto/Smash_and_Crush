# Mobile landscape policy and left-menu floor — 2026-11-12

## Outcome and scope

Canonical open Studio: PlaceId **126576845524886**. Baseline Git main **5dc3cac**. Changes were based on current unsaved Edit Sources/editor buffers, which matched their focused Git mirrors at the start. No Git-to-place restore was used.

Implemented an authored landscape policy plus event-based repair, and a 70% floor for additional left-menu avoidance shrinkage. **The reported intermittent portrait behavior on physical devices was not reproduced; its complete cause and resolution remain unconfirmed.** The current Studio was in Edit throughout. No gameplay Play was started or stopped.

Preserved the previous WinTrophy restoration, Egg close controls, notification image/motion, Slap Hand suppression and all unrelated unsaved work. Merge UI, movement capture area, default stick/jump controls, camera behavior, purchases, saves and gameplay were not edited. No new directories or retained screenshots. PR #1 was not merged or incorporated.

## Changed production Full Paths

| Full Path | Change |
| --- | --- |
| `StarterGui.ScreenOrientation` | Authored property changed from `Sensor` to `LandscapeSensor` in unsaved Edit. This instance-property change is recorded here; the source-only Git mirror does not serialize StarterGui properties. |
| `StarterPlayer.StarterPlayerScripts.UI.TouchControlZoneClient` | Keep the existing landscape request; verify/repair it on property change, app focus, character spawn and CurrentWorld change. Disconnect added lifetime connections on destruction. |
| `ReplicatedStorage.Modules.HUDLayout` | Compute the normal viewport-specific left-menu scale independently of control avoidance; enforce a final relative floor and expose passive scale metrics. |

## Phase 1.1 — evidence, hypotheses and correction

Confirmed in current Studio:

- TouchControlZoneClient is an enabled LocalScript under StarterPlayerScripts.UI. It already assigned PlayerGui.ScreenOrientation=LandscapeSensor after waiting for PlayerGui. No module loader or remote/data dependency precedes that assignment.
- The authored StarterGui.ScreenOrientation was Sensor. The initial policy and the later client policy were therefore different.
- A search of all live game Sources found this LocalScript as the only ScreenOrientation writer. No game script writing Portrait, LandscapeLeft or LandscapeRight was found.
- StarterPlayerScripts persists across ordinary character respawns; the existing client had no later orientation repair. There was no live PlayerGui/current-device orientation to sample in Edit.
- HUDLayout already invalidates layout when its ScreenGui.AbsoluteSize changes and when visible touch controls change. It uses the current GUI safe-area size on each layout, rather than retaining the first Camera.ViewportSize. ResponsivePanels also already observes GUI AbsoluteSize. These resize paths were retained.
- The only other live Source mentioning LeftHUD/MenuScale/MenuLayoutScale was SizeChangeClient, which reads LeftHUD geometry to place its own controls. It does not write left-menu scale.

The initial Sensor policy is an evidenced configuration inconsistency and a plausible startup exposure to portrait. A platform/launch-route delay, app-resume behavior or delayed viewport delivery is still a hypothesis. Script inspection alone cannot establish which occurred on the reporting device. Roblox distinguishes the requested ScreenOrientation from the read-only actual CurrentScreenOrientation ([PlayerGui API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/PlayerGui.yaml)); the starter setting controls the initial policy ([StarterGui API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/StarterGui.yaml)).

Correction:

1. Set the authored StarterGui property to LandscapeSensor, allowing both landscape directions.
2. Keep the early client assignment. Later events call the same function, which writes only if the requested policy differs. There is no per-frame orientation setter, fixed delay, or one-sided lock.
3. Add no movement/camera replacement. The existing DynamicThumbstickFrame code still changes only BackgroundTransparency.
4. Retain the existing event-driven HUD reflow. Simulated portrait, landscape-left, landscape-right and resolution changes reached updated GUI dimensions and current menu geometry.

The event repair does not claim to force the OS to rotate when PlayerGui already requests LandscapeSensor. That distinction is specifically covered by the device observer below.

## Phase 1.2 — what 100% and 70% mean

The single setting is **HUDLayout.LeftMenuMinRatio = 0.70** ([line 8](../src/ReplicatedStorage/Modules/HUDLayout.luau#L8)). The baseline starts at [line 205](../src/ReplicatedStorage/Modules/HUDLayout.luau#L205); the final floor is applied at [line 278](../src/ReplicatedStorage/Modules/HUDLayout.luau#L278).

The normal-size calculation is the `normalLeftScale` block inside Mount/layout, immediately after counterStack is calculated. It reuses the current preferred viewport scale, width budget, three-row/two-column design (302 x 460), existing tablet design budget and 3x multiplier, counter stack (217), and viewport containment. For this baseline, bottom space is `h-16`, **before visible controls reduce leftBottom**. It is recomputed from current GUI dimensions; it is not a fixed desktop UIScale.

For touch layout, `minimumLeftScale = normalLeftScale * LeftMenuMinRatio`. The existing shrink and positioning paths remain: control-bottom allowance, counter allowance, tablet viewport/right-HUD collision limit and per-button physical-control avoidance. The floor is applied before counter positioning and again **after the final tablet avoidance loop, before counter geometry and follow() copy the final scale to visible buttons and their hit targets**. There are no later left-scale writes. PC's minimum is zero, retaining its previous output.

Existing counters remain coupled to the left-menu scale by the original calculation; their design/placement policy was not redesigned. Right-menu calculations and the default input controls were retained.

Passive diagnostic attributes on StrengthGui are `LeftMenuBaseScale`, `LeftMenuFinalScale`, and `LeftMenuAvoidanceRatio`. They do not decide visibility or input.

## Verification performed

- [MobileOrientationPolicyEdit.luau](../tests/MobileOrientationPolicyEdit.luau): **44 assertions** against the exact current client Source with fake orientation/lifecycle signals and a native DynamicThumbstickFrame fixture. Portrait startup requests LandscapeSensor, lifecycle events do not write redundantly or add connections, a foreign property write/app-focus reset is repaired, the input frame's size/position are unchanged, and destruction disconnects the lifetime.
- [LeftMenuFloorEdit.luau](../tests/LeftMenuFloorEdit.luau), using [MobileHUDPreviewEdit.luau](../tests/MobileHUDPreviewEdit.luau): **345 native Edit layout assertions**. Three mobile presets, seven joystick heights each, release/repeat/mount idempotence, portrait-to-right rotation and final GUI resizing. Baseline remains independent of joystick height; every final ratio is at least 0.70 within native float tolerance. All six actual button paint rectangles match their native GuiButton hit rectangles.
- Native old/new comparison at PC 1366 x 768: **161 GUI objects had identical AbsolutePosition and AbsoluteSize**, including left/right menus, counters and lower HUD.
- Both changed Sources compile and match editor buffers/reviewed candidates. The six previous Egg/badge/Trophy Sources still match their previous approved candidates and compile.
- No actual death/respawn, World teleport, app backgrounding, physical stick/jump/menu input or live join route was exercised. Lifecycle tests are synthetic. Geometry agreement is not proof of physical tap dispatch.

### Rendered Edit previews

Screenshots were inspected using the Studio Device Simulator and current cloned StrengthGui artwork. Production LocalScripts were removed from the clones. Blue translucent circles represent **synthetic control bounds**, not a claim of actual Roblox CoreGui touch execution. No button or purchase callback ran.

| Device preset | Observed GUI viewport | Normal scale (100%) | At 70% | Normal / floor 144-design-pixel button |
| --- | --- | ---: | ---: | ---: |
| iPhone 7 | 667 x 375 | 0.450517 | 0.315362 | 64.87 / 45.41 px |
| iPhone 16 Pro Max | preset 956 x 440; safe viewport 832 x 440 | 0.546529 | 0.382570 | 78.70 / 55.09 px |
| iPad Pro M5 13-inch | 1376 x 1032 | 1.369306 | 0.958514 | 197.18 / 138.03 px |
| Average Windows | 1366 x 768 | 0.858564 | Not applied | 123.63 px, unchanged |

Inspected normal/floor left menus, a simulated pressed/released stick, left/right landscape and a forced 375 x 667 portrait to 667 x 375 landscape transition. Buttons kept two columns, existing art/captions and aligned hit rectangles. No stale portrait menu dimensions remained after the simulated landscape size settled. These are Edit screenshots, not mobile Play or a demonstration that a portrait app launch automatically rotated.

At a low simulated stick origin (8% X, 73% Y, 70 x 70), the inspected small/large phone and tablet layouts had no left-button/control overlap. Tablet's ratio there was 0.743630. At a high origin (8% X, 35% Y), **overlap remains** at the 70% floor:

- Small phone 667 x 375: Skip, Inventory, Rebirth and Shop intersect simulated ThumbstickStart/End.
- Tablet 1376 x 1032: the same first two rows intersect the simulated stick bounds.

The menu remains at 70%; the control zone is not shrunk and no collapsing or replacement UI was added. Visual obstruction and competing tap targets are possible there. Actual gesture capture/dispatch impact is unverified and needs the physical-device check; resolving that overlap is a separate user decision.

The first test harness used too short a settle interval after device switching and observed transitional dimensions, failing a baseline assertion. It was corrected to allow the documented simulator update interval and two native render boundaries; the full matrix then passed. This wait is confined to the test harness. A desktop orientation setter was initially rejected by the simulator; the test was repeated after activating a mobile preset. Neither initial attempt is counted as passing evidence.

## Physical-device observation and app/link comparison

Prepared [ObserveMobileHUD.client.luau](../tests/ObserveMobileHUD.client.luau), **not installed in the canonical Studio**. It compiles; physical-device execution remains unverified. It is a passive opt-in observer: no RemoteEvents, AnalyticsService, DataStores, input interception or UI overlay. It retains at most 128 rows in memory and prints client-console lines beginning `[MobileHUDObserve]`.

For a user-controlled private verification build, temporarily place it as a LocalScript under ReplicatedFirst. Use its optional EntryRoute attribute or an external test note to label `app` and `shared-link`; it does not pretend to infer the launch route. Remove it after testing. Save/Publish for such a build remains a manual owner action and was not performed here.

Compare on the **same device and build**, once from Roblox app navigation and once from a shared link:

1. Start with the device physically portrait; record OS/device, rotation-lock state, build/version, launch route and a screen recording.
2. Observe initial join, then turn landscape left and right; allow normal rendering to settle, without imposing a fixed pass/fail timeout.
3. Hold/move/release the standard stick, tap Jump and each left-menu button, then repeat after ordinary death/respawn and World1 -> World2 -> World1.
4. Background and resume the app in both physical orientations. Capture console rows and screen appearance around failure.
5. The observer records elapsed time from its own start (not server join time), requested and actual orientations, camera viewport, StrengthGui absolute size, world/character transitions, scale ratios, painted/hit rectangles and current control bounds. Focus, orientation, camera/GUI size, touch begin/end and lifecycle events trigger coalesced snapshots. In a client command context, `_G.MobileHUDObserve.Mark("label")`, `.Dump()`, and `.Stop()` are available.

Interpretation:

- Requested LandscapeSensor but Actual Portrait and portrait viewport: device/engine orientation request remains unresolved.
- Actual landscape and landscape viewport, but portrait GUI bounds: GUI/safe-area update issue.
- All dimensions landscape, but old button rectangles: layout scheduling or a subsequent geometry writer.
- Final/base below 0.70: identify the scale writer and whether the current HUDLayout version is loaded.
- Missing startup rows/client errors: investigate LocalScript startup rather than assuming an orientation setting was absent.

An app-internal versus shared-link comparison cannot be executed with the connected desktop Studio tools; it is explicitly outstanding.

## Cleanup, preservation and delivery

Removed all review GUIs/control fixtures/baseline clone/globals. Returned the simulator to the original default viewport and LandscapeLeft simulator setting. StarterGui.ShowDevelopmentGui was restored. Canonical Studio remains Edit and **unsaved**. No OS input, UI Automation, Save/Publish, direct Place-file write or Studio shutdown occurred. The prior unrelated untracked report remains untouched and excluded.

Only the two production Source diffs, property record, focused test/observer files and task documentation are included in the normal main commit/push. **Manual Save and, when ready, Publish are required** for these changes to persist and reach players.
