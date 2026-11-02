# Merge floor-arrow visibility audit — 2026-11-02

## Outcome and scope

The current canonical Y02 Studio, PlaceId **126576845524886**, was investigated without implementing changes. Its six directly relevant Sources matched commit **351b4b5**. The completed purchased highlight, dimming and notification presentation was preserved. Git contains this report and evidence only; no production Source, specification or layout change is proposed as an already-completed fix.

Two different mechanisms were reproduced:

1. Merge navigation correctly stops for insufficient ore, other notifications/modals, death, leaving Lobby, or an open Merge panel. It resumes when the relevant condition clears, unless an explicit close has latched `dismissed`. That latch is documented in the previous implementation report; ending a notification does not clear it. No missing controller startup, destination lookup, or scheduler restart was reproduced.
2. The broad red treadmill stand is absent from the floor whitelist. Its opaque Upper/Lower parts then block the floor renderer's vertical clearance test. Arrows are generated but made transparent. This is a separate rendering defect for the requested walkable carpet, not the cause of the reproduced Merge eligibility/dismissal transitions.

The user's earlier unspecified transition cannot be uniquely identified retrospectively. The observations below identify reproducible causes, rather than claiming the user must have experienced one particular cause.

References: [initial ore tutorial](../OreMergeTutorial_20261102.md), [approved display](../OreMergeTutorialDisplay_20261102/REPORT.md), commits `3386385` and `351b4b5`. The former explicitly states: “Closing dismisses until reopening or returning”.

## Processing chain and exact conditions

`StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New` constructs the view and mounts `ReplicatedStorage.Modules.OreMergeTutorialGuide` immediately (line 55), before the first facility visit. Mount calls `Forge.Refresh` and `refresh`, then observes view/Forge/player changes and polls at 5 Hz while eligible and incomplete. In Play, `ControllerMounted=true`, `CloseRevision=0`, and `Open=false` preceded the first visible Merge arrows.

The guide resolves the actual Lobby floor and Merge Area. It publishes `LocalPlayer.OreTutorialTarget` only for `GoToMerge`. `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` listens to that attribute, starts its 0.2-second scheduler/cache, and routes `Workspace.TutorialFloorGuide` to `OreMerge`. It destroys/clears the route and stops its scheduler when no applicable tutorial destination remains. Actual Parts and screenshots were checked separately from the target attribute.

Conditions are evaluated in the order below; `Waiting` alone does not identify which gate failed.

| Condition | Guide state / floor destination | Resume condition | Evidence this audit |
|---|---|---|---|
| `OreTutorialEligible ~= true` | `Ineligible`; target nil | Eligible becomes true, other gates pass | Source only |
| `OreTutorialCompleted == true` | `Complete`; target nil | Intentionally finished; no normal restart | Source only |
| Original `TutorialCompleted ~= true` | `Waiting`; Merge target nil; original tutorial may still render its own route | Original tutorial completes and living player reaches Lobby | Actual Stage1 Boss/Trophy flow |
| Dead, missing character/root, outside actual Lobby bounds | `Waiting`; Merge route absent | Alive inside Lobby; also clears dismissal | Death/automatic respawn and outside/inside tested |
| `RunReturnBusy` / `StageSkipBusy`, modal, general notification, reward feedback | `Waiting`; target nil | All blockers end, next 5 Hz refresh, other gates pass | TimeRewards panel, real NotifyClient.pin, Trophy flow, prepared return flag tested; other variants Source only |
| Forge state missing/unloaded, token mismatch, or usable ore total below 2 | `WaitingForOres`; target nil | Loaded current-token state and at least 2 available ores | Stone 1 → 2 tested; initial load observed; token mismatch Source only |
| Explicit close latched `dismissed`, panel closed | `Dismissed`; target nil | Reopen Merge, leave/re-enter Lobby, death/respawn, or Forge token/tutorial reset event | Close, notification end, outside/inside, reopen, death tested; token/reset Source only |
| Closed, all gates pass, Merge Area missing | `WaitingForFacility`; target nil | Correct Area exists | Source only; Area existed throughout Play |
| Closed, all gates pass, Area exists | `GoToMerge`; target is Area.Position | Active navigation | Actual visible screenshot and renderer trace |
| Merge open | `ChooseOre` / `AddOres` / `Merge` / `Saving`; floor target nil | Automatic panel hide can resume navigation; explicit Close dismisses | Proximity open → ChooseOre; automatic exit tested |

Usable ore count sums quantities of available OreConfig entries; two `ORE_001` Stones qualify. Reserved/unavailable entries do not qualify. **No TimeReward claim is required.** The isolated profile had no claimed TimeRewards throughout all reported starts.

Lobby is the bounding box of `TrainingArea.Floor` in floor-local X/Z, with absolute local Y at most 40, and a living Humanoid/root. `CurrentWorld == 2` selects `Workspace.World2Map`; otherwise the guide selects `Workspace.GeneratedMap`. It selects `Workspace.World2Map.TrainingArea.FacilityDisplays.MergeDisplay.Area` for World2 and `Workspace.RestockShop.Area` for World1. World2 was traced in Source but not entered in this focused Play.

The exact modal filters are StrengthGui's OfflineRewards, TimeRewardsPanel, DailyRewardsPanel, CommunityRewardsPanel, InventoryPanel, ShopPanel and RebirthPanel; DeathGui.Overlay, WorldTravelGui.Modal, StageSkipGui.Panel; enabled HatchGui/EnemyDropGacha; visible GuiObjects taller than 1 pixel in NotifyGui.Stack; and WinLabel.RewardFeedbackScale differing from 1 by more than .001. Visible ancestors and ScreenGui.Enabled are considered for the listed GUI objects. The approved ore guide's own notification did not block itself.

## What actually changed when arrows appeared

All rows below are from **one native single-client Play with isolated in-memory services**. Coordinates, one Stone, and combat Strength were prepared; these are not natural progression timing measurements. Stage1 damage/Boss attack, Trophy contact/return and the Forge sale used ordinary game handlers. UI probes called the native view close path or existing notification/panel state; no OS input was sent.

`Evidence.json` records named samples and the state-change timeline, including Step, target, blockers, ore count, dismissal, route existence/scheduler and visible Part counts. Times are seconds since the client observer started. Each chevron consists of two Parts; pooled Part count can exceed the current requested chevron count.

| Comparison | Observed result / causal difference |
|---|---|
| Original tutorial incomplete, 1 Stone | `Waiting`; controller and Forge already loaded, Merge destination resolved, no Merge target. Original treadmill arrows still existed. |
| Prepared Stage1 victory grants second Stone; ordinary Trophy contact completes tutorial and returns to Lobby | `OriginalComplete=true`, 2 Stones, no Merge open yet → `GoToMerge`. During brief post-return feedback, `Blocked=true` → `Waiting` → blockers end → `GoToMerge`. Settled result: 8 chevrons / 16 Parts, **14 visible Parts**. Screenshot visibly showed Merge arrows on red carpet and green floor. |
| Ordinary Forge sale takes 2 Stones to 1; grant restores 2 | 1: `WaitingForOres`, no target, route/scheduler absent. 2: `GoToMerge`, target present, scheduler active, 14 visible Parts. No TimeReward claim changed. |
| TimeRewards panel shown then hidden | `Waiting`, 0 Parts → `GoToMerge`, 14 visible Parts. This tested panel visibility, not claiming a reward. |
| Actual general `NotifyClient.pin` shown then released | Same pause/resume, without reopening Merge. |
| Enter real Merge Area | Proximity owner automatically opens view; `ChooseOre`, floor target cleared, floor route removed. |
| Invoke the same `view:Hide('Closed')` path used by Close | CloseRevision 0 → 1; `Dismissed=true`; no target or arrows. Exiting the facility but remaining inside Lobby does **not** clear this latch. |
| Show/release general notification while dismissed | `Waiting` during notification → **Dismissed**, still no arrows. Notification completed normally; a different gate still blocks navigation. Same-Lobby screenshot confirmed absence. |
| Leave Lobby, then return | Outside: `Waiting`, dismissal cleared. Inside: `GoToMerge`, 14 visible Parts. |
| Reopen at facility, then automatically leave its Area | Open: in-panel guide. Automatic `Hide()` does not increment CloseRevision; closed back in Lobby: `GoToMerge`, 14 visible Parts. |
| Explicit close again, then death and normal respawn | Death: `Waiting`, alive=false, dismissal cleared; respawn: `GoToMerge`, 14 visible Parts. No persistence reset was used. |
| Prepared `RunReturnBusy=true`, then restore original value | `Waiting`, 0 Parts → `GoToMerge`, 14 visible Parts. This is a flag fixture, distinct from the actual Trophy return above. Its very short natural true interval was not sampled at 0.1 s. |

Snapshots can catch a gate change just before the next scheduled refresh; e.g. a momentary `Blocked=true` with the previous Step. The timeline records this bounded update delay, not a permanent state inconsistency. No tested target-present / scheduler-stopped failure persisted.

## Explicit close is different from an automatic hide

`ReplicatedStorage.Modules.MergeShopView:GetOreTutorialState` exposes CloseRevision. Only `Hide('Closed')` increments it. The owner uses plain `Hide()` when leaving the facility or when certain other panels open. `OreMergeTutorialGuide.refresh` latches a changed CloseRevision, clears the latch while Open or outside Lobby, and clears it on a transition into Lobby or Forge token/tutorial reset event.

Therefore waiting longer, ending a reward notification, or changing ore quantity while staying inside Lobby cannot by itself undo an explicit close. This behavior matches the previous recorded dismissal contract. It would be a behavior change to make every explicit close immediately restore the navigation arrows. It is **not established as a notification/return resume bug**, and this audit does not recommend silently removing that gate.

## Treadmill red carpet: exact rendering exclusion

`TutorialGuideClient.refreshFloors` (lines 59–100) explicitly registers only the **direct** Upper/Lower children of PathToTreadmills. Its comment excludes nested equipment stands/mats. The real broad walkable red platform is nested under the misspelled existing name `ThreadmillStand`, so it is omitted.

| Full Path under `Workspace.GeneratedMap.TrainingArea` | Center / Size (studs) | Top Y | Registered |
|---|---|---:|---|
| `Floor` | (274.5, 0, 10.5) / (237, 8, 149) | 4 | Yes |
| `PathToTreadmills.Upper` | (287.800, 4.200, -12.700) / (13, .4, 27) | 4.400015 | Yes |
| `PathToTreadmills.Lower` | (287.800, 4.100, -12.450) / (16, .224, 23.5) | 4.212015 | Yes |
| `PathToTreadmills.ThreadmillStand.Upper` | (290.879, 4.200, -40.450) / (121.158, .4, 28.5) | 4.400015 | **No** |
| `PathToTreadmills.ThreadmillStand.Lower` | (290.953, 4.099, -40.200) / (125.517, .221, 33) | 4.209009 | **No** |

All four carpet/stand parts are opaque and CanQuery=true. The raycast includes only registered floor parts; over the stand it hits the base Floor at Y=4, not the red top at Y≈4.4. `floorOnly` then checks clearance against non-floor opaque parts, using their oriented bounding boxes and all 13 chevron footprint samples. The stand's own Upper/Lower parts intersect that vertical segment and return false. The renderer sets both chevron Parts to Transparency=1. This is **deliberate suppression by the current predicate**, not merely an arrow buried 0.4 studs below a carpet, and not a missing arrow generator.

The initial route to `Workspace.Treadmills.Normal01.Area` (237.453, 12.000, -43.431) requested 21 chevrons, created 42 Parts and showed 16 Parts. Samples 14–21 all failed with the broad stand Upper/Lower as the first recorded blocker. A second prepared character position on the stand requested 7 chevrons and showed 0 Parts; traces identified stand parts or actual treadmill machinery as blockers. The diagnostic predicate matched the real `floorOnly` boolean and actual Part transparency for every sampled current chevron.

The Merge route from the normal Lobby spawn did **not** cross this platform. Its 8 requested chevrons had 7 visible: four on EntranceCarpets.Upper and three on the base Floor. The remaining chevron straddled a raised carpet edge; its footprint height spread exceeded .08 studs, an intentional edge exclusion. Other original-tutorial route gaps were attributable to a pet mesh or a height edge. These should not be conflated with a route-wide eligibility/dismissal pause.

Direct Studio screen captures were inspected at 1390×622 without camera or window changes. Merge visibility and the same-position dismissed absence were visually confirmed. Initial tutorial arrows were visible on the central red carpet. The second treadmill capture was heavily obstructed by machinery/avatar due to the existing camera's collision response: a complete unobstructed visual inspection of the broad platform is **unconfirmed**. Its whitelist/clearance failure is directly established by runtime geometry and predicate traces. No screenshots are retained or committed.

## Classification and smallest possible follow-up

- **Normal, reproduced:** ore threshold, original tutorial/Lobby/life gates, in-panel guide replacing floor navigation, notification and return-busy suspension/resumption, documented explicit-close dismissal. No Merge controller/destination/scheduler repair is justified by these results.
- **Rendering defect, reproduced:** the intended walkable broad treadmill carpet is excluded as an equipment stand and blocks its own arrows. If a fix is subsequently requested, add only this exact stand's Upper/Lower surfaces to the existing floor-registration helper. Preserve clearance checks for actual treadmill bodies, the 13-point footprint test, cache/scheduler, arrow color/shape/size, and all authored geometry. Do not whitelist every descendant or disable occlusion globally. Recheck platform edges and actual machinery after that change.
- **Optional behavior clarification, not a bug fix:** if explicit Close should allow floor guidance again during the same Lobby visit, change only the dismissal lifecycle after that behavior is explicitly chosen. Do not remove ore/tutorial/life/modal gates, force a target attribute, or alter the finished highlight/dimming/notification adapter.

Neither proposal was implemented.

## Preservation, evidence and limits

Play used the existing memory adapter for every current direct DataStore/Badge/Marketplace service dependency: 37 Sources were redirected, and three Sources received temporary native observers (40 temporary Source edits total). Two fixture Instances were added. No production account was reset; the adapters blocked real purchases/badge awards and replaced persistent stores with memory stores. The expected memory Badge adapter reported a failed award; existing asset authorization warnings were also present. No arrow/guide runtime error or infinite yield was observed.

After stopping Play, all 40 temporary Sources were guarded against unexpected edits and restored to their exact captured strings. **All 459 Sources** matched the start. **3,391 protected Instances / 22,555 checked properties**, plus their attributes, matched the current start baseline, covering the approved GUI/template and relevant Lobby/Merge/treadmill geometry. No helpers or extra/reparented authored game-service objects remained. Engine Stats, CommandBar and plugin memory connections were recreated by Studio itself and were left alone. Camera CFrame/Focus and HttpEnabled=false were unchanged. Studio is in **Edit, focused Edit**, retaining its existing unsaved state. No Save, Publish, rbxl writeback, Studio shutdown, OS input, window rearrangement or camera-setting modification was performed.

Not replayed: World2 travel, stale-token/reset-data races, legacy eligibility/persistence, every offline/hatch/modal variant, ordinary physical mouse/keyboard interactions, or gameplay duration. Those gates are reported as Source findings only. The natural Trophy busy flag's short true interval and a full unobstructed stand image remain unconfirmed as noted above. The actual user session that first exposed the issue was not available for reconstruction.

The only tracked additions for this audit are this report and [Evidence.json](Evidence.json). Existing unrelated untracked work was left untouched.
