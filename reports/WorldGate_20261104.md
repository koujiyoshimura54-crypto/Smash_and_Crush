# Gate World selector — 2026-11-04

Applied to the current unsaved canonical Studio, PlaceId 126576845524886 / UniverseId 10765181857. Baseline commit e9a91b7; origin/main matched before work. Existing Studio content was authoritative. Only the gate feature, its GUI and the two new opening blockers were changed.

## Source and authored paths

- ReplicatedStorage.Config.WorldGateConfig
- ReplicatedStorage.Modules.WorldGateContact
- ReplicatedStorage.Modules.WorldSelectionPresentation
- ServerScriptService.Services.WorldGateService
- ServerScriptService.Systems.Controllers.StageProgressController
- StarterPlayer.StarterPlayerScripts.World.WorldGateClient
- StarterGui.WorldTravelGui.Modal.Card (replaces the retired YES/NO card inside the existing observed Modal)
- Workspace.World2Gate.WorldSelectionWall
- Workspace.World2Map.TrainingArea.World1ReturnGate.WorldSelectionWall

The installer in tools/InstallWorldSelectionGui.luau reproduces the authored GUI, static UI-only scenery and blockers from the existing purchased/current objects. Re-running it retains an existing selector and edited appearance. No uploaded assets, gameplay Map or destination were created. Existing gate decoration, portal appearance rules and world placement were retained.

## Reference measurement and rendered comparison

Both supplied PNGs were actually opened. The first measures 1672 x 941; the locked reference measures 1671 x 941. Approximate reference rectangles:

| Element | Reference pixels |
|---|---|
| Outer panel | x169, y60, width1312, height844 |
| Header | 104 high |
| Card horizontal inset | 36 |
| Three cards | approximately1240 x234, gaps15 |
| Action button | 338 x99, right/bottom inset21 |
| Close | approximately106 x98 |
| Black borders | panel7, cards5, button6 |
| Corner radii | panel/card30, action23 |

The shared Fredoka One comes from StrengthHUDStyle.Font. Actual captures led to larger World names/title, a separate white close label (the red button gradient had tinted its original text), white native GUI padlocks, and removal of excess narrow-layout bottom space. The selector is above the existing Studio animation-preview button, so that debug control cannot cover the close target.

Rendered native client observations:
- Normal UI area1279 x720: panel1005 x646, cards950 x179, action258 x75. Current blue, Teleport yellow-green and Locked gray rendered correctly.
- Isolated UI area390 x650: panel366 x412, cards337 x108, actions126 x40. All World names, state labels and title reported TextFits and were visibly readable without overlap.
- Isolated UI area390 x300: panel366 x270; vertical scrolling exposed the complete last card/button.
- Locked shading is RGB26/28/31 with transparency0.12 (88% opacity), plus gray preview tint. The actual captures showed only faint scenery while labels and locks remained clear.
- Final white close label rendered at65px in the normal area and fit the button. Native hit testing placed Close ahead of the modal/card.
- Screenshots were inspected and kept temporary per AGENTS.md. No OS input, camera movement or device-preview settings were used. Narrow checks resize only the test GUI region. Native rendering was not forced to the PNG's exact1672 x941 resolution; this is a proportional comparison, not a pixel-identical claim.

Differences retained: backgrounds use the current owned World1/World2 scenery inside static ViewportFrames rather than the reference's exact landscape. World3 has no official map/preview/destination; its dark background is an explicitly tagged purchased-scenery sample. It does not reproduce the reference candy landscape and must be replaced with an official World3 preview when provided. These GUI-owned preview cameras do not modify Workspace.CurrentCamera or Studio camera settings.

## Authority, contact and travel

The old client opened YES/NO only after the root entered a non-collidable trigger, and only for unlocked players. The server route checked mirrored HighestUnlockedWorld and allowed a padded trigger area. The new service retains the existing placement/streaming, combat deactivate/activate, World2 reached and badge calls, but uses PlayerDataService.CanAccessWorld against loaded session data.

Both authored blockers are12.2 x26 x0.5 studs, transparent and collidable. They follow the opening orientation, not a global axis, and leave adjacent passage geometry alone. The existing PortalSurface/WorldGateTrigger were not resized.

Every0.1s the server examines the player's real character body bounds against the current world's blocker. It ignores tools/accessories and combat-only volumes. Contact padding0.3, release padding0.9 and release delay0.2 prevent limb jitter from reopening the UI. One per-character contact latch sends a private Open. Closing is local and does not rearm it. Leaving/death/world changes close and rearm appropriately; arrival has a1s suppression and uses the existing safe lobby spawn, far outside the wall.

Teleport checks a whitelisted ready destination, saved access, living current character and actual wall contact before streaming, then rechecks contact, world, character, placement ownership and ForgeSessionToken after the yield. Concurrent/burst requests are bounded by the existing-style busy/rate guard. No touch event teleports. The legacy route request names retain the same validation. State requests never open the GUI.

World1/World2 unlock conditions are unchanged (the existing persisted HighestUnlockedWorld gate unlock, not CurrentWorld or mere inventory ownership). World3.Ready=false; the service explicitly has no World3 destination fallback, even if that display setting were accidentally toggled. A future official destination/unlock must be connected intentionally.

## Isolated native Play verification

All39 external persistence/payment/badge/policy/messaging dependencies used memory/stubs during QA. No production player data or real purchase was used. Native client button callbacks and the actual WorldTravelRequest Remote were exercised programmatically; movement used real Humanoid.MoveTo physics. This is not a claim of physical mouse/touch input.

The native StudioTestService two-client test passed19 checks, with independent real Players and client GUIs:

| Case | Result |
|---|---|
| W1 unlocked participant walks against wall | Blocked at localZ0.810–0.815; private prompt opens |
| W2 wall | Blocked at localZ0.820; correct current/return states |
| Locked participant | Cards remain visible; World2/3 actions disabled |
| Close while touching | Remained closed; no additional Open |
| Leave/recontact | Exactly one new Open |
| Six rapid native button activations | One travel; no duplicate destination transition |
| W1 -> W2 -> W1 | Existing lobby placement succeeds; no arrival contact/reopen |
| Direct locked W2 and unprepared W3 requests | Locked response; no movement |
| Peer stays at lobby | No UI Open, unlock or world change from the other player |
| Independent second-player unlock/travel | Only that player moves; peer remains World1 |
| Death/respawn | No automatic popup or duplicate GUI; next contact works |

Solo physics also stopped at approximately0.803 studs from the wall center on both Worlds, rather than crossing its0.25-stud half-depth. Successful arrival was approximately63.10 studs from the destination gate plane. All three displayed states were checked with live server state. The first solo fixture initially waited for a nonexistent PlayerModule; that test-only dependency was removed. The final solo console contained no gate runtime errors/warnings. The multiplayer run emitted existing asset-fetch warnings and a deliberately stubbed badge-award failure; no audio IDs/permissions were changed.

Not verified: public-server persistence/rejoin, physical mobile input, every avatar scale and device/aspect ratio, exact reference-resolution rendering, or an official World3 map/preview. Existing world unlock persistence and non-gate gameplay were not rewritten or subjected to unrelated campaign tests.

## Manual editing

- Layout/text-size attributes: StarterGui.WorldTravelGui.Modal.Card (ReferenceWidth/Height, HeaderHeight, SidePadding, CardHeight, CardGap, TitleTextSize, WorldTextSize, ButtonTextSize, CloseTextSize).
- Shared font: ReplicatedStorage.Config.StrengthHUDStyle.Font.
- State gradients: StarterGui.WorldTravelGui.Appearance.Current / Teleport / Locked.Color.
- Locked darkness: StarterGui.WorldTravelGui.Modal.Card.WorldList.World1/World2/World3 attributes LockedBackgroundTransparency; smaller means darker. LockedShade.BackgroundColor3 changes the gray.
- Borders/corners: each Outline or TextOutline ReferenceThickness/MinimumThickness attributes, each Corner.ReferenceRadius.
- Backgrounds: each card.MapPreview.Scenery and PreviewCamera, GUI-only.
- Future World availability: WorldGateConfig.Worlds; a real destination also requires an explicit WorldGateService route.
- Transparent blockers: the two WorldSelectionWall Parts listed above.

## Completion

All temporary helpers removed,39 dependency substitutions restored,486 Source/Enabled entries and74 sound references verified unchanged across each cleanup. Six final feature Sources compiled and match their repository exports. Native Play stopped and viewport focus returned to Edit. No Save, Publish, rbxl write or user Studio close occurred. The implementation remains unsaved in Studio and requires the user's manual Save/Publish.
