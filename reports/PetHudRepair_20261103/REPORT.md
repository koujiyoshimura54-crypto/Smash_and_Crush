# Pet UI, Hover feedback and Battle Bag repair — 2026-11-03

## Status and authority

Applied six scoped Source changes and four authored GUI-object changes to the currently open, unsaved Y02 Studio, PlaceId `126576845524886`. Git baseline was `49271bd`; origin/main had no newer commit when fetched. No whole-Source import from Git or rbxl was performed.

**Visual acceptance is still open.** Studio-native screen capture and pointer requests did not return. A two-second runtime observation recorded 120 Heartbeats and zero RenderStepped callbacks. No screenshots were obtained. GUI geometry, text counts, Sound events and native gameplay state are evidence below; they are not pixel or listening confirmation.

**One setting remains pending:** the live, unsaved `UISoundConfig` already contained Hover.Volume=0.15 and Rebirth/Offline/Merge.Volume=1.3, unlike Git. An explicit preservation clarification was sent under AGENTS.md's local-edit rule. No answer arrived during this work, so that entire Config Source remains untouched. The requested change of Hover's initial coefficient to 1 has NOT been applied to this Studio. The new playback code honors the existing 0.15; absent coefficients default to 1. The three unrelated 1.3 values are retained and are not included in this commit.

## Causes and implementation

| Area | Observed cause / finding | Scoped implementation |
| --- | --- | --- |
| Best Equip text | Pet text styling added contextual UIStroke even to transparent TextButtons with residual text. The current donor had Title; the alleged TitleShadow was not present in this donor. Stacking paths still needed explicit cleanup. | Keep one Title caption, remove other cloned TextLabels, clear underlying GuiButton.Text and contextual text strokes. Existing visible labels retain the common Fredoka One and black outline. Backend and hit area unchanged. |
| Card scaling | Purchased ButtonClient tweens the button's parent Frame on hover/press. | Mark only inventory card buttons NoButtonScale before parenting. The shared binder cancels active tweens and restores a previously animated card, including a return-to-base tween. Static cards retain responsive layout sizes. Material-card builders are excluded. |
| Pet behind HUD | Pet ScreenGui.DisplayOrder=0 versus StrengthGui=10. Child ZIndex alone cannot fix this. | MenuClient raises Pet ScreenGui to 11 while Inventory is open, restores its original order on close/shroud, and uses one transparent input shield. Inventory interaction/shield turn off immediately on close. Existing HatchGui order 20 and higher purchase screens remain above it. Tooltip is in the same raised ScreenGui. |
| Pet merge order | Groups already sorts raw Points descending, then stable Name; reconciliation assigns LayoutOrder and manual row-major positions from this order. | No PetMerge/MergeShopView change. Generated card coordinates, selection and reopening were checked. Pixel acceptance remains open. |
| Hover targets | Generic feedback also bound left-menu actions and noninteractive counter buttons. | UIFeedback scopes exact StrengthGui.LeftMenu action names to click-only; exact HUD.WinAmount/RebirthAmount counters become noninteractive and silent. Right-side reward buttons, purchases and internal tabs keep Hover. NoUISound makes the input shield silent without disabling it. |
| Hover volume | Hover played SoundService.UI.Hover directly and ignored its Config coefficient. | Reuse a dedicated local clone, copy current SoundId/PlaybackSpeed/SoundGroup, and apply source.Volume × Added.Hover.Volume at playback. Never scale the source itself. Existing interval, nested-hover coalescing, duplicate and visibility checks remain. |
| Battle Bag | Old client always displayed the count and did not test location. HUDLayout continually reapplied original dimensions. | Gate on valid count/capacity, living current character, CurrentWorld and authored floor footprints. Hide in Lobby; show on a Stage LevelFloor/Floor before Boss combat. HUDLayout scales original icon/text/gap by BattleBagScale=1.5 without accumulation; Back uses its original anchor calculation. |

## Changed Full Paths

1. `StarterPlayer.StarterPlayerScripts.Services.PetClient`
2. `StarterPlayer.StarterPlayerScripts.Services.ButtonClient`
3. `StarterPlayer.StarterPlayerScripts.Services.MenuClient`
4. `ReplicatedStorage.Modules.UIFeedback`
5. `ReplicatedStorage.Modules.HUDLayout`
6. `StarterGui.StrengthGui.RunInventoryHUDClient`

Authored properties (reproducible with [ApplyPetHudRepairProperties.luau](../../tools/ApplyPetHudRepairProperties.luau)):

- `StarterGui.StrengthGui.HUD.RunInventoryIcon.Visible` = false.
- `StarterGui.StrengthGui.HUD.RunInventoryLabel.Visible` = false.
- `StarterGui.StrengthGui.HUD.WinAmount.Button`: Active, Interactable, Selectable, AutoButtonColor = false.
- `StarterGui.StrengthGui.HUD.RebirthAmount.Button`: same four flags. This is the numeric display, not `LeftMenu.RebirthButton`.

User-editable settings:

- `ReplicatedStorage.Config.UISoundConfig` → `Config.Added.Hover.Volume`. Current Studio value **0.15, preserved pending clarification**; requested initial value **1**.
- Source sound remains `SoundService.UI.Hover`; playback clone is `SoundService.AddedUIFeedback_Hover`.
- `ReplicatedStorage.Modules.HUDLayout` → `M.BattleBagScale = 1.5`.

## Isolated native Play evidence

No production data or real payment was used. Before Play, 41 temporary service references were redirected to an in-memory DataStore/Marketplace/Badge fixture. Production remotes, LocalScripts, server Pet logic and GUI generators still ran. Event-observation wrappers retained real connections and also allowed direct callback delivery. Those callback tests are simulated input, not physical pointer acceptance.

- Best Equip callback reached the existing server once, selected three Pets and produced Equipped (3/3), Strength ×3.7. One Click.Played event was counted. Pet instances and bonuses were fixture-prepared, not naturally earned.
- Generated Best Equip had exactly one visible caption, “Best Equip”, and no residual underlying button text. This held after equipment update, reopening and death/respawn.
- Card MouseEnter/Down/Up/Leave callbacks preserved identical UDim2 sizes. Inventory retained numeric Strength ordering; merge retained Points ordering. The final return-tween cancellation edge was separately checked using the actual resize function and a real Tween on detached Edit instances: Playing → canceled/base restored; later responsive size retained. No test object was parented into Edit.
- Opening Pet set DisplayOrder=11 and activated the shield; closing restored 0 and disabled the shield and panel interaction. Reopening restored 11. Actual click blocking could not be demonstrated: the inactive renderer returned no GUI hit-test objects.
- Layout measurement used a temporary runtime UIScale=1 because natural open Tween rendering did not progress. Normal header bottom 191.954, list top 202.491 (10.537px gap). A temporary 390×460 panel had header bottom 179.815, list top 192.448 (12.633px gap). These are property measurements, not device-preview or pixel tests.
- Merge cards sorted by **actual coordinates, left-to-right then next row**: Chimpanzini Bananini 6250; Ninja 1250; Turtle 1250; Shark 1000; Elephant 250; Bat 200; Bear 30; Dog 10. The same order held after selection and reopening. K-formatted labels were not used for comparison. Bat precedes Elephant in Pet inventory because its Strength bonus is larger; Elephant precedes Bat in merge because its Points are larger.
- Left Pets action: Hover.Played=0, Click.Played=1. Counter Win/Rebirth buttons: both 0 and noninteractive. Internal Merge Pet tab: Hover.Played=1; repeated enter, disabled and hidden cases: 0. Exact path-policy checks covered other left actions and right reward buttons. Hidden/unavailable Skip stayed silent.
- Runtime Hover coefficients 0 / 0.5 / 1 produced playback-clone Volume 0 / 0.5 / 1 with source Volume consistently 1. SoundGroup copied correctly; source Volume=0 yielded clone Volume=0. Runtime Config/source/group mutations were restored. This confirms numeric properties and Sound events, not audibility.
- Both Worlds: Lobby → Stage01 wall floor → Lobby yielded bag hidden → visible → hidden, with IsFighting=false. World1 battle location was (287.8, 8, 165.875); World2 (27.92, 6, 2095.055). These positions were fixture teleports using actual floors.
- World2 death immediately hid the bag; World1 death/respawn and reentry restored correct behavior. Existing WorldTravelRequest successfully returned to World1 and entered World2; the first too-early travel retry was ignored by the existing cooldown, then succeeded after it elapsed.
- Bag count/capacity stayed intact across display toggles (fixture mirrored 3/5, then hid it). Missing attributes in battle kept both elements hidden. Existing service reset restored 0/5; the display code never writes inventory attributes.
- At the existing 1106×564 viewport: icon 42×42, label 276×42, gap 12, TextSize 36, icon origin (22,4). This is 1.5× the original 28px / 8px / 24px dimensions. The next main counter rectangle starts at y=54. Pixel borders/icons and narrow-device overlap remain unaccepted.
- Scoped console review found no repair-related error/infinite yield. A BadgeAward warning occurred with the isolated fake Badge provider; it is not evidence of a production badge regression.
- All changed Source and the authored-property reproducer compiled with the local Luau compiler.

## Visual and other limits

No screenshot, listening, native pointer click/drag, rendered tween/tooltip overlap, real click-through prevention, or pixel-level Pet/merge/Bag acceptance is claimed. Studio-native input and capture timed out; OS input, window switching, camera or device-preview changes were not used to work around this. Hatch/payment stacking is verified by order values and preserved code, not rendered interaction. Narrow testing resized only a disposable runtime Pet panel, not the Studio device setting. The Battle Bag was not visually verified on a narrow device. Stage01 in each World was exercised; every Stage was not traversed.

The latest isolated Play tested the production changes except the final small return-tween cancellation edge, which was checked directly with actual Tween instances in Edit. No unrelated full-game regression was added.

## Preservation and cleanup

Play was stopped through the existing Studio connection. All 41 temporary Source edits and four fixture objects were removed. The final Studio mode and focused DataModel were **Edit**. No server/client simulation remains running. The toolbar's visual test-mode selector was not captured or manipulated.

Compared 465 initial Sources, 16,401 authored GUI/asset objects and 51,131 captured properties against the baseline plus intentional deltas: no unexpected differences; script Enabled values, parents and attributes retained. Camera CFrame/Focus and HttpEnabled were unchanged. Final Source export matched the six edited repository files. Existing unsaved UISoundConfig edits and the unrelated untracked report were retained.

No Save, Publish, rbxl writeback, Studio exit, production persistence, real transaction or OS input occurred. Canonical Studio is intentionally **unsaved**. The in-memory verification snapshot was removed only after final checks.

Pet count/bonus/Best Equip authority, strongest center placement, history/silhouettes, Basic Egg 3 Win, all tutorial logic, merge gameplay and Back source were unchanged. No Egg tutorial was added.

[Machine-readable evidence](Evidence.json). This change is implemented with limited runtime acceptance; it is **not a declaration that the user-visible defects are fully resolved**.
