# Phase 1 — Stage1 wall Click / Tap prompt

Date: 2026-11-13. Canonical Studio: PlaceId **126576845524886**, UniverseId **10765181857**. Repository: `koujiyoshimura54-crypto/Smash_and_Crush`.

## Scope and preservation

Implemented the manual wall-attack cue in the existing first tutorial. The five existing investigation targets matched the current repository after newline normalization; current Studio edits were retained. Synced main from `a8b6595` to the already published `8d2d2b6` before adding this work.

Phase 2 is not implemented. Stage1 retains four walls (HP 50 / 75 / 100 / 135) and Boss HP 200. Initial Stone, sale rules, time rewards, intro training threshold/order, Strength, level curves, rewards, AutoTap initialization and existing funnels are unchanged. No DataStore field, attack remote, attack sender or input action was added.

## Changed Full Paths

| Studio Full Path | Change |
| --- | --- |
| `ReplicatedStorage.Config.Stage1WallPromptConfig` | New image, anchor, size and animation settings |
| `ReplicatedStorage.Modules.Stage1WallPromptState` | New client state and accepted-attack predicate |
| `ReplicatedStorage.Modules.Stage1WallPrompt` | New noninteractive presentation, projection, blockers and lifecycle |
| `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` | Mount in the existing wall-guide branch; reuse its CombatState listener and RequestState path |
| `ServerScriptService.World.EnemyManager` | Additional World1 notification context; combat calculations and timing unchanged |

Repository Sources have the corresponding paths under `src/`. `AutoTapClient`, `CombatClient` and `TutorialPresentationCoordinator` were inspected and retained byte-for-byte. The new presentation uses the existing coordinator's ownership API.

## Image and presentation

The user supplied image ID **85558189403057**. Configuration: `ReplicatedStorage.Config.Stage1WallPromptConfig.Image = "rbxassetid://85558189403057"`. Runtime destination: `Players.LocalPlayer.PlayerGui.Stage1WallPromptGui.Finger.Image`.

The registered Image's metadata was Approved / Active, 1024 × 1024; the actual image rendered in native Play. The white finger, thick black outline, three emphasis lines, original shape/color and transparency are retained. Fit, white ImageColor3 and no crop are used. No upload, generation, replacement or permission change was needed.

All devices use one implementation and animation. PreferredInput selects exactly `Click` for KeyboardAndMouse and `Tap` for Touch, including session changes; TouchEnabled alone is not used. Unknown/gamepad input hides the cue. AutoLocalize is false. Text uses the existing Fredoka font, white fill and black stroke; no explanation panel is added.

Image base size is 80–116 logical pixels from viewport height; text is 24–30. The 0.9-second motion moves up-left by at most four pixels and scales from 1 to 0.95. Fingertip anchor is (0.29, 0.20). Position derives from the actual wall CFrame/Size, character and camera, without fixed World coordinates. Shared candidate rules put text below or alongside the finger according to available space. They exclude the real SurfaceGui HP region, character bounds, visible menus/HUD, touch controls and the dynamic stick's larger transparent input region. Safe screen bounds are respected. No clear visible candidate, offscreen/back-facing projection, or Scriptable camera means no cue.

## Display and completion

Display requires the existing guide to select a World1 Stage1 wall under its current intro/progression rules, TutorialCompleted explicitly false, a matching personal Initialize/snapshot for the current character/run/reset epoch, a positive-HP current wall 1–4 that is neither cleared nor skipped, matching active Wall combat, and actual contact through the owner's replicated WallCombatTriggerRef. AutoTap must be explicitly false and the character alive and not training. Stage must be explicitly 1. The game's initial nil CurrentWorld is accepted only after a confirmed World1 stream, matching its existing initial World1 convention. Unknown state and unloaded targets wait.

Menus, Roblox purchase modals, hatch, death overlay, return/travel/skip states, text entry, notifications and conflicting tutorial ownership temporarily hide the cue. Conditions are reevaluated on close/return. AutoTap ON hides it; OFF before completion restores eligibility. Lobby, Treadmill, Boss phase, Stage2+, World2 and completed tutorials fail the gate.

Completion requires the existing server CombatAttack emitted **after accepted damage**, matching local owner, World1, current run/reset epoch, Manual=true, CombatType=Wall, Stage1 and current wall, with matching wall combat. Raw input, gauge changes alone, misses, automatic attacks, Boss/other targets and stale messages do not complete. The attack packet precedes gauge/clear messages, including lethal/Carry attacks.

EnemyManager adds CombatType/WallIndex to successful World1 wall attack packets, TutorialResetSequence to World1 packets, and Character/ActiveCombat to World1 Initialize. These provide target/reset/character correlation and support repeated RequestState while already in contact. World2 packet behavior is retained. No damage/reward/attack-timing code changed.

Completion is a client session latch mirrored in a client-only Player attribute for controller remounts. Death/new walls do not clear it; the existing TutorialResetSequence does. Rejoining follows existing saved tutorial state. No profile schema changes were made.

ImageLabel and TextLabel have Active, Interactable and Selectable false; their parent is a ScreenGui without an interactive panel. They do not qualify for AutoTapClient's GUI exclusion. Existing mouse and TouchTapInWorld paths remain the only manual senders.

## Verification

Tests used agent-owned native solo Play with temporary in-memory DataStore/Marketplace/Badge/Messaging/Policy services and a stubbed analytics transport. Progression, positions and selected states were prepared in memory. This is actual engine/client/server Play with controlled starting states, not a naturally earned full tutorial or public server run.

| Requested check | Result and evidence |
| --- | --- |
| 1. Treadmill → wall | Native prepared Level1/Strength4 intro state hides; Level2/Strength10 and real wall contact displays. Existing intro helper/order retained. Full earned training traversal was not replayed. |
| 2. Click / Tap | Desktop and desktop simulator show Click; iPhone/iPad simulators show Tap. Same-session device/input changes redraw. Physical hybrid-PC switching is untested. |
| 3. Input on image | Native mouse and simulated phone/tablet touches on the displayed finger pass to the existing manual path. Final image positions have no interactive GUI ancestor in the exclusion check. |
| 4. Accepted hit / no duplicate | Final phone: requests 2→3, HP 50→40, one new Manual=true Wall/1 packet, completion epoch1. Tablet: 3→4, HP 50→40, one packet, epoch2. Desktop: 4→5, HP 50→40, one packet, epoch3. All cues disappeared. |
| 5. Non-attack input | Simulated visible-stick drag and camera drag left request/attack counts and completion unchanged. Native Inventory open/close hid/restored without attack or completion. State tests reject input-only, automatic, wrong owner/target/type/run and stale notifications. |
| 6. Reevaluation | Native Auto ON hides; actual automatic 50→40 wall damage does not complete; OFF shows again. Contact distance 4→20→4, Inventory open/close and injected RunReturnBusy true/false hide/restore. Actual purchases and return/travel transactions were not exercised. |
| 7. Death / reload | An earlier isolated Play confirmed accepted completion survives real death/respawn/new run with one GUI; existing reset sequence restores eligibility. Client target unparent/reparent simulates unload/reload and hides/restores with one GUI and no extra requests. Final Play's additional incomplete-death case stopped rendering after frame17362: its post-respawn appearance is **unverified**. Actual network streaming and connection-count introspection are not claimed. |
| 8. Other stages | Native prepared Stage2, World2 and TutorialCompleted=true states hide. A native automatic Carry cleared all four walls (index5); OFF remained hidden without manual completion. Actual Boss entry/World2 travel were not replayed; Boss notification/state exclusion also passes isolated assertions. |
| 9. Device geometry | Rendered native views inspected at desktop 1390×601 and 1366×768, iPhone7 landscape 667×375, iPad Pro M5 13-inch landscape 1376×1032. Final cue avoids HP, character, controls and side/bottom UI without clipping in these views. Existing LandscapeSensor retained. No physical device was operated. |

The final **53 standalone state assertions** passed. All five production Sources and three test Sources compiled with `luau-compile --null`. The final isolated Play console showed only four existing startup lines, with no related Runtime Error, Warning or Infinite Yield. Earlier investigation had a corrected fixture Floor path, an unsupported desktop orientation call and a hidden-image preload failure; the final visible-image path loaded successfully. A one-off camera assignment was overwritten by Roblox's camera, so the behind-camera check was repeated using a temporary render-step override. An unsuitable click on a transparent modifier was not counted as stick-test evidence; the visible-stick drag was tested separately.

HP overlap and a phone candidate inside the transparent stick input region were found and corrected during rendered checks. Final phone/tablet/desktop screenshots and image-input tests occurred after these corrections. Screenshots were inspected transiently and not retained, per AGENTS.md.

Reproducible sources: `tests/Stage1WallPromptState.luau`, `tests/Stage1WallPromptPlay.server.luau`, `tests/Stage1WallPromptPlay.client.luau`. Play fixtures require temporary isolation and are not shipped in Studio. PinCamera supports deterministic geometry; camera gestures must also be checked without a pin. Simulator input is not physical-device acceptance.

## Cleanup and handoff

Only agent-owned Play was stopped. All 40 temporary service/analytics Source changes were restored after checking Source and editor buffers against exact installed versions. Removed memory and backup folders, three QA fixtures, temporary camera/input observers and image preview. Simulator returned to `default`; no `__WallPrompt*` helpers remain.

Final checks: five intended Sources match repository candidates; AutoTapClient, CombatClient and TutorialPresentationCoordinator match their starting Sources. All eight relevant editor buffers match Source. Canonical Place/Universe were rechecked. Preexisting untracked `reports/Visual_Templates_Secret_VIP_Green_20260917.md` is preserved and excluded from this commit.

Studio remains open in **Edit with unsaved changes**. No Studio Save, Publish, Place-file save or PR #1 merge was performed. This commit contains only five production Sources, three tests, this report and current entries in GAME_SPEC, UI_SPEC, DEV_STATUS and CHANGELOG. Physical devices, public asset delivery/servers, actual network streaming, purchase dialogs and the noted final incomplete-death rendering case remain unverified.
