# Ore merge tutorial: purchased presentation reuse — 2026-11-02

Implemented directly in the open canonical Y02 Studio, PlaceId **126576845524886**, starting from its unsaved Edit state and Git `3386385`. Read the purchased tutorial audit, its Evidence.json, the previous ore tutorial record and installer. The existing active target Sources matched that commit. No old place file or source bundle was imported.

## Cause and correction

The v1 installer cloned TutorialHighlight but replaced its scaled white/black strokes with fixed 3px/6px borders, its relative corner with 8px, and its target growth with 6px padding. The guide snapped to rectangles instead of using the purchased interpolation. Its message came from a purchase-button label rather than NotifyClient.pin, including that button's AutomaticSize.X.

The current donor and original display Sources were read in Studio. Reused only their presentation:

| Component | Final default / reused behavior |
| --- | --- |
| Highlight outline | White, Thickness **0.025**, ScaledSize, transparency 0, outer border, round joins, stroke ZIndex 2 |
| Surrounding dark area | Black, Thickness **100**, **ScaledSize**, transparency **0.25**, outer border, stroke ZIndex 1 |
| Corner / frame | CornerRadius **UDim(0.1,0)**; centered anchor; transparent frame; no descendant clipping |
| Target rectangle | TutorialClient.guiRect center and **1.18** growth, normalized to the overlay; default extra padding 0 |
| Following / switching | TutorialClient.draw's **1-exp(-dt/0.12)** interpolation on RenderStepped; initial GUI target snaps, subsequent GUI targets interpolate |
| Layering / coordinates | Original tutorial ZIndex 50, original ScreenGui IgnoreGuiInset=true; current Merge display order retained below the overlay; notification above the dark focus area |
| Notification | NotifyClient.pin's centered line stack, GothamBlack typography, original tutorial yellow/orange gradient, text stroke scaling, horizontally faded black shade, 0.8 pop scale, Quint/Back opening and Quad closing |

The notification is adapted to the current Merge title band while open. Its safe width reserves the close button and its height leaves tabs/cards/Merge accessible. Outside the panel it uses the purchased notification position. Short editable instructions remain readable at narrow sizes. The existing label Instance and its extra attributes were retained and reparented; inherited content-driven width and obsolete default corner/text-size constraint were removed. TextScaled is enabled after TextWrapped, matching the effective original Notify label behavior.

Scroll clipping is an intentional current-UI adaptation: project only the visible part of a card, and choose a visible card with usable remaining quantity using the existing card-action eligibility function. Prefer a fully visible card and, within that group, a partially selected ore that can be added again. A single Stone selection therefore keeps Stone highlighted and says `Tap this ore again.` If no addable card is visible, the list is the scroll target. No selection or scroll position is changed by the guide.

## Changed Full Paths

| Full Path | Change |
| --- | --- |
| `ReplicatedStorage.Modules.OreMergeTutorialPresentation` | New display-only adapter of the purchased rectangle, interpolation and pinned-notification renderer. |
| `ReplicatedStorage.Modules.OreMergeTutorialGuide` | Connect existing eligibility/lifecycle steps to that renderer and the actual material target. |
| `ReplicatedStorage.Modules.MergeShopView` | Extend its read-only tutorial state with a usable visible material target and current selection count. |
| `StarterGui.OreMergeTutorialGui` | Migrate the existing authored GUI, including Highlight and Notification descendants and message values. |

`tools/InstallOreMergeTutorialGui.luau` now creates v2 or migrates the existing v1 template. It no longer exits merely because a v1 GUI exists. Migration changes recognized v1 defaults while retaining other properties, attributes and extra children; v2 reruns return without altering authored edits. **It is an Edit tool, not a runtime startup script.**

The complete before/after GUI properties and hierarchy are in `GuiBefore.json` / `GuiAfter.json`; the installer is the executable non-Source reconstruction/migration. In particular, `Canvas.Message` moves to `Canvas.Notification.Stack.Line.Message`. Notification Shade, Stack, UIListLayout and UIScale are added, and AddAnother / ScrollOres message values are added. These object changes are part of the Git delivery, not Play-only creations.

No server production Source changed. Fresh/reset eligibility, total two-ore condition, TimeReward independence, original-tutorial/living/Lobby gating, ordinary server-confirmed Forge completion, earlier self-directed completion, persistence, retry/reset fencing and floor-arrow code are retained. The original Main loaders remain disabled. TutorialClient, NotifyClient, Config, ForgeClient, HUDLayout, ResponsivePanels and the Merge owner controller were checked unchanged. No legacy 19-step tutorial, old profile store, HUD holding or action restriction was started. No item ID, sale, unrelated font, economy or map change was made.

## Native Play verification

Four short **single-client native Studio Play sessions** used the current unsaved Edit document. All DataStoreService, BadgeService and MarketplaceService acquisition expressions were temporarily redirected to the memory adapter in `tests/World2HPWalls/Memory.luau`; 38 temporary Source edits include the native view probe. No production account store or payment was used. Prepared fixtures completed the prior tutorial through its existing server API and granted two Stones through Forge. This is a focused prepared test, **not natural reward progression or a completion-time measurement**.

Screens were actually acquired and inspected through the Studio connection, without OS input, window arrangement or camera changes. The first capture attempt stalled and was abandoned; later captures succeeded. Images were transient and are not committed.

| Check | Observed result |
| --- | --- |
| Purchased versus revised highlight, same Ore tab / Stone card and viewport | Alternating captures showed matching broad darkness, white contour and relative corners. The independently copied purchased guiRect/draw used the same live target. |
| Purchased notification comparison | Called the actual NotifyClient.pin with the same text/colors, temporarily mapped only its host position/layer to the same header. Compared with the revised rendering. Original tutorial was never started. |
| Moving / resizing target | Native comparison over 24 render samples matched the original exponential rectangle calculation within **0.000042px**. Screens also showed target-size changes and intermediate movement. No video was recorded. |
| Normal and narrow display | Native overlay canvas 1390x622; isolated **460x560** and **400x520** mounts. Inspected Ore, Stone, repeated-Stone instruction and Merge; text avoided tabs/materials/Merge/close. Narrow mounts resize in-game test containers, not the Studio viewport or a real device. |
| Scroll and target movement | Normal and narrow list scrolling selected visible available ORE_010 after Stone moved out of view; resizing and moving the isolated container kept the focus attached. Extra ores were explicitly prepared only for this visual test. |
| Input access | Native GUI hit queries found the actual Ore/card/Merge controls active and interactable, with no active/interactable overlay blocker. Invoked the real card and drag handlers; dragging added exactly one unit. Physical mouse/touch input was not simulated. |
| Stone x2 | No TimeReward claims. Floor target -> Ore -> one Stone/repeat hint -> two Stones/Merge -> ordinary UI submission. Server consumed both Stones, granted one NORMAL_01, set saved tutorial completion, and removed the focus/notification. Also repeated ordinary submission in the final normal-width session. |
| Open / close / death / return | Closing hid all pinned lines/focus; reopening made one guide. Death suspended it (existing 5Hz lifecycle polling), respawn resumed one guide with the current selection. No persistent duplicate or leftover overlay. |
| Author editing | Edited outline color/thickness, shadow thickness/transparency, corner, growth, interpolation, padding and ChooseOre text in **Edit**, reran the installer, then started another Play. All survived startup and step changes. Removed the test customizations afterward. |

The captured runtime measurements are in `Verification.json`. The final console had no related game runtime error or infinite yield; existing unrelated asset-permission/audio warnings remained. Two test-harness issues were corrected: compare render samples after all RenderStepped listeners, and compare Float32-authored stroke values with tolerance rather than exact decimal equality. During visual refinement the inherited purchase-label AutomaticSize.X and TextWrapped/TextScaled assignment were corrected; the final narrow capture has bounded, readable text.

Reusable temporary native probes: `tests/OreMergeTutorialDisplay.server.luau` and `.client.luau`. Install the memory adapter and service substitutions before Play; the client fixture is appended only temporarily to the existing MergePanelClient_New owner so it exercises the actual view/callbacks. The earlier `OreMergeTutorial.client.luau` / VisualChecks fixtures describe the historical v1 GUI and are not the v2 display probe.

## Owner-editable template

| Edit location under `StarterGui.OreMergeTutorialGui` | Editable settings |
| --- | --- |
| `Canvas.Highlight.Outline` / `.Shadow` | Color, Thickness, Transparency, StrokeSizingMode, stroke ordering and other stroke properties. Defaults use **ScaledSize**, not pixels. |
| `Canvas.Highlight.Corner` | CornerRadius. |
| `Canvas.Highlight` | `GuiGrow`, `MoveSeconds`, optional `PaddingX` / `PaddingY`; anchor and authored appearance are retained. Runtime owns only position, size and visibility. |
| `Messages` | StringValue.Value for GoToMerge, ChooseOre, AddOres, AddAnother, ScrollOres, Merge and Saving. |
| `Canvas.Notification.Stack.Line.Message` | Authored notification text appearance; runtime clones this line. Keep AutomaticSize=None and TextScaled enabled for bounded instructions. |
| `Canvas.Notification` | HeaderWidthScale / HeaderCenterX for mapping into the current title band; ReferenceHeight for authored text-stroke scaling. |

Unverified: physical mouse/touch/gamepad, real phone emulation, continuous animation video, multiplayer, public-server persistence/rejoin and every modal. Save/reset/payment regressions were deliberately not repeated; their production Sources did not change. The retained floor-arrow routing attribute was checked, but carpet/occlusion behavior was not broadly retested.

## Final Edit integrity

Stopped Play and restored every temporary Source from its exact pre-test copy. Removed memory adapters/probes and the private GUI/style backups. Restored the purchased defaults after the author-edit test. Final three implementation Sources matched disk and compiled; seven inspected protected Sources matched their original live copies. The GUI remains in Edit with PresentationVersion=2 and no test objects. Both Main loaders remain disabled; HttpEnabled=false and the original editor camera/focus were unchanged. The pre-existing untracked Visual_Templates_Secret_VIP_Green report was not included.

**Studio remains open in unsaved Edit. No Save, Publish, rbxl writeback or Studio shutdown was performed. The owner will save manually.**
