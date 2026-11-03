# Egg purchase → Pet equipment tutorial, Phase 1 — 2026-11-03

## Result and authority

Implemented on the **current unsaved Y02 Studio**, PlaceId **126576845524886**, UniverseId **10765181857**, starting at Git `bcee859`. All 13 inspected live entrance Sources matched the current repository before editing. The current Studio, including existing authored GUI edits, was the baseline; no old place or bulk Source import was used.

Phase 1 ends after one confirmed Basic acquisition is equipped. **No Pet merge tutorial, extra purchase requirement, auto-purchase, auto-equip or automatic Phase 2 transition was added.** The future two-mergeable-unequipped-Pet trigger remains deferred.

Preserved Battle Bag, Shop, Pet presentation/equipment/effects/Best Equip, acquisition history, silhouettes, Basic price 3 Win and existing audio. `ReplicatedStorage.Config.UISoundConfig.Added.Hover.Volume=0.15` is unchanged. The original 19-stage tutorial/Main/profile pipeline remains disabled.

## Changed Full Paths

| Full Path | Responsibility |
| --- | --- |
| `ReplicatedStorage.Modules.EggPetTutorialState` (new ModuleScript) | Validated separate lifetime state and confirmed acquisition/equipment transition. |
| `ReplicatedStorage.Modules.EggPetTutorialGuide` (new ModuleScript) | Read-only eligibility, navigation, current-control targeting, interruption/resumption and short completion presentation. |
| `ReplicatedStorage.Modules.TutorialPresentationCoordinator` (new ModuleScript) | Client-local first-owner arbitration between Egg and Ore displays; no gameplay authority. |
| `StarterPlayer.StarterPlayerScripts.Tutorial.EggPetTutorialClient` (new LocalScript) | Mount guide on the already idempotent current Pet bootstrap. |
| `ServerScriptService.Services.PlayerDataService` | Defaults, legacy exclusion, serialization and atomic tutorial progress in ordinary Pet transactions. |
| `ServerScriptService.Services.EggServer` | Return accepted tutorial state alongside the existing Pet revision/generation response. |
| `StarterPlayer.StarterPlayerScripts.Services.PetClient` | Read-only accepted tutorial snapshot, behind existing stale generation/revision rejection. |
| `StarterPlayer.StarterPlayerScripts.Services.MenuClient` | Read-only explicit-close revision counter. Existing open/close/input/audio logic remains intact. |
| `ReplicatedStorage.Modules.OreMergeTutorialGuide` | Three lines: require coordinator, release on hide, acquire before displaying. Existing eligibility, messages, targets and renderer are unchanged. |
| `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` | Route the Egg target through the existing floor chevrons and scheduler. Existing floor registry, carpet, occlusion, caches, cadence and appearance are unchanged. |
| `StarterGui.EggPetTutorialGui` (new, 24 objects including root) | Edit-time clone of the current approved Ore GUI, new message values and noninteractive target/notification regions. |

`OreMergeTutorialPresentation` is reused **without any Source change**. No new thin outline, notification design, HUD suppression or input lock was introduced.

## Start, progress and persistence

New records and the existing `/resetdata` defaults receive:
`EggPetTutorial={Version=1,Eligible=true,Completed=false,Acquired={}}`.
Existing records missing this field normalize to Eligible=false, matching Ore's migration policy. Existing Pet IDs, counts, equipment and save fields are preserved.

Before purchase, the guide requires accepted loaded Pet/tutorial state, an unfinished eligible tutorial, Basic's existing price (currently 3 Win), completion of the existing floor tutorial, and a living player inside World1 Lobby. It reads the real replicated Lobby bounds installed in bcee859. No TimeReward, Strength, Win-source, account or Ore-completion requirement was added.

- **GoToEgg:** existing floor chevrons point to the actual `Workspace.Eggs.Basic`.
- **OpenOne:** the currently enabled Basic sheet's `Opens.Open1` is projected from its existing Billboard dimensions/Adornee into a noninteractive focus proxy. No camera is set.
- **Hatch:** wait for the ordinary request to be confirmed, Pet state accepted and existing HatchClient to finish. The guide hides during hatch; it does not accelerate/replace it.
- **OpenPets:** focus the existing `StrengthGui.LeftMenu.PetsButton`.
- **Equip:** focus the actual runtime `ScreenGui.Menus.Inventory.Main.PetBestEquip`.
- **Complete:** a short pinned “Pet equipped!” notice, then remove focus/navigation/notification. Completion comes from the server, not the click.

Successful ordinary Basic Hatch records the purchased result IDs (up to the existing eight-result batch). The ordinary Equip/BestEquip save marks completion only if an acquired ID is still owned and actually equipped. Purchase, Win debit, Pet grant and purchase progress commit in the **same ownership/reset-fenced UpdateAsync**; equipment and completion also commit together. Ordinary saves preserve the durable tutorial value instead of writing a stale snapshot over it. A failed purchase, saving state, unrelated equipment or “AlreadyBestEquipped” without the acquired Pet cannot complete the tutorial.

Progress is recorded even if the guide has not started. The controller skips already confirmed acquisition/equipment. Rejoin after completion does not replay instructions; unfinished state resumes from accepted ownership/provenance. The accepted Pet generation/revision also protects tutorial responses; reset advances the existing generation and clears local presentation. No additional public completion remote exists.

There is no new capacity rule. Current normal Pet ownership has **no owned-count capacity check**. The existing three-equipped limit is separate: an attempted fourth equip returns PetSlotsFull and leaves tutorial incomplete. If a player already owns three stronger equipped Pets, unchanged Best Equip may retain them; the player must use the existing manual unequip/equip route for the acquired Basic Pet. No strength-ranking override or automatic replacement was added.

## Display arbitration and interruptions

The coordinator never takes an active guide from another owner. Egg waits behind active Ore; an active Egg hides for generic/reward notification, hatch, return/skip, death, other World/location, inventory/shop/rebirth screens, ordinary non-Basic Egg sheets and Limited sheets. The actual separate `MergeShopGui.MergeShopPanel` is included; opening Merge releases Egg's display ownership so the existing Ore guide can operate.

Explicit Pet Close is remembered. It does not reopen any UI. Manual reopening, leaving/re-entering the Lobby, or leaving/reapproaching Basic can resume the current step. Death/reset retires the relevant local presentation. Spending below 3 Win before a purchase returns to WaitingForWin. After a confirmed purchase the guide can continue with 0 Win.

The only presentation adaptation is the destination/control reference and editable notification region. Highlight geometry/growth/interpolation/clipping and pinned-message animation use the same purchased renderer. The original GUI's colors, scaled strokes, broad black shade, corner and translation/font settings are cloned as-is. Runtime owns focus/proxy position/size/visibility; it does not reset authored style properties.

## Owner-editable locations

All under **`StarterGui.EggPetTutorialGui`**:

| Location | Editable values |
| --- | --- |
| `Canvas.Highlight.Outline` / `.Shadow` | Thickness, Color, Transparency, StrokeSizingMode, ZIndex. The approved defaults are copied, including the broad 100 ScaledSize black shade. |
| `Canvas.Highlight.Corner` | CornerRadius. |
| `Canvas.Highlight` Attributes | GuiGrow, MoveSeconds, PaddingX, PaddingY; existing appearance and anchor remain editable. |
| `Messages` StringValues | GoToEgg, OpenOne, OpenPets, Equip, Complete — edit Value. No new localization opt-out is applied. |
| `Canvas.Notification.Stack.Line.Message` | Notification font/color/outline and other authored text appearance. The existing renderer clones this template. |
| `Canvas.Notification` Attributes | ReferenceHeight, HeaderWidthScale, HeaderCenterX. |
| `Canvas.NotificationRegion` | Position/Size of the instruction band. Initially above the relevant controls. |
| root Attribute `CompletionSeconds` | Completion-notice duration, initially 2.5 seconds. |

`Canvas.TargetProxy` is a runtime position adapter, not an editable visual replacement. [InstallEggPetTutorialGui.luau](../../tools/InstallEggPetTutorialGui.luau) is Edit-only and clones the **current Ore template** only when Egg GUI is absent; rerunning preserves existing Egg edits. [Gui.json](Gui.json) records the complete authored hierarchy/properties needed to review/recreate this instance change. It is not a Play-only GUI.

## Verification

Five isolated native test sessions: three solo Play sessions and two two-client attempts. Every DataStore/Marketplace/Badge acquisition was redirected to the existing memory provider before starting (37 dependency substitutions). Additional callback observers/fixtures were temporary. No production persistence, real payment or natural progression loop was used.

| Check | Actual result / evidence type |
| --- | --- |
| Win2 → Win3 | Native guide WaitingForWin → GoToEgg. Actual floor chevrons and purchased notification captured. |
| Ordinary full flow | Existing Open1 activation callback → server saved Win3→0 and one Grey Cat → existing four-knock hatch/reveal → Pets entry callback → actual Best Equip callback → one equipped/×1.02 → saved completion. Clicks/hatch continuation were **fixture-invoked native callbacks**, not physical mouse input. |
| Native rendered UI | Captured chevrons, notification, hatch egg/Grey Cat, Pets button focus, actual Best Equip focus and completion notice. Broad shade/white outline retained. No screenshots are retained, per AGENTS.md. |
| Basic Open1 image limit | The enabled ordinary Billboard had real dimensions, 3 Win label, accepted callback and projected focus, but the purchase board itself was absent in capture. A direct-parent clone did not resolve this capture result; a later isolated mirror attempt sampled zero sheet size and was not acceptance evidence. **Actual Open1 pixel alignment/readability remains unconfirmed.** |
| Narrow render | A 460×540 in-game canvas and 380×430 Pet-menu region showed readable notification, Best Equip target, close button/card and completed state. This was an isolated drawing-region test, not Studio device preview or a physical phone. |
| Input obstruction | Native GUI hit inspection found no active/interactable overlay blocker over Best Equip. Normal request callbacks worked once; no physical mouse/touch claim. |
| Purchase insufficiency | Native NotEnoughWin at2; no grant/acquired state. Spending from3 to2 suspended the prompt. |
| Save failures/retries | Precommit failure and lost acknowledgement produced InventorySavePending with no accepted progress. Resolving/replaying the same request returned AlreadyApplied and one grant/one debit. |
| Equipment full | Three prepared stronger equipped Pets: fourth manual equip returned PetSlotsFull. Best Equip returned AlreadyBestEquipped; neither falsely completed onboarding. This is not an owned-count capacity test. |
| Early self-directed completion | Final native run purchased/equipped through ordinary server requests while TutorialCompleted=false. After the floor tutorial completed, acquisition/equipment instructions were skipped. |
| Close and return | Explicit Close hid all lines/focus and remained dismissed. Reapproach resumed OpenPets. Death/actual respawn, prepared World2/World1 movement and unfinished memory-store reload resumed the accepted step without duplicates. |
| Notifications and Ore | Notification paused Egg and later resumed. Ore first → Egg WaitingForGuide → normal Ore merge success → Egg GoToEgg. Opening actual Merge while Egg owned display released Egg, showed Ore's original tab focus/notification, captured on screen. No Ore completion prerequisite added. |
| Other Egg/Limited displays | Final native client tested the known panel/sheet predicates with temporary UI fixtures; pause/resume passed. These are simulated display occupancy checks. |
| Reset/stale replies | Existing /resetdata used isolated stores, cleared progress and resumed after normal floor prerequisites. Pre-reset server request returned PetStateChanged; replaying an old client response did not restore old Pets/tutorial. |
| Persistence/legacy | Real PlayerData Save/Release/Load against memory retained pending/completed progress. Completed reload had no lines/focus. Missing field on an existing stored record remained ineligible. Same-process reload used a fixture generation advance to emulate a fresh client; public-server rejoin remains untested. |
| Two real clients | Native StudioTestService run passed 19 checks: one player purchased/hatched/equipped/reset, peer retained Win2/empty ownership/incomplete state/WaitingForWin; then peer started independently at3 Win. No shared progression/display. |
| Manual editing | Temporary Edit outline1.125, shadow transparency0.35, growth1.22 and edited GoToEgg text survived installer rerun, next Play and step changes in both clients. Restored exact original authored values afterward. |
| Final regression | Default-style final run passed early completion and normal/Limited occupancy checks. Original Ore renderer/GUI, protected Sources and Hover config matched the starting copies. |

The first multiplayer attempt failed only because a fixture waited for phase **exactly 1** after the first player had already advanced to phase2; changed the barrier to ≥1 and reran successfully. An early solo inspection selected the fixture LocalScript instead of its same-named BindableFunction; renamed the probe. Neither issue was a shipped game error. The final console had no related runtime error/warning/infinite yield. Earlier unrelated asset approval warnings remain outside this task.

Native fixtures are archived as `tests/EggPetTutorial*.luau`. They are **not installed** in final Studio. They require the memory dependency substitution described above; never run against production service handles.

## Final integrity and remaining limits

Stopped all Play/testing and returned to **focused Edit**. Restored 43 / 38 / 38 / 41 / 37 temporary Source entries respectively, removed helpers and temporary UI/style customizations. Compared **470 Sources (466 original +4 new)**, **5,542 baseline GUI/tutorial instances** and **30,442 properties** against baseline plus intentional Source additions/edits: no unexpected difference. Camera CFrame/Focus and HttpEnabled stayed unchanged. No OS input, window layout, camera setter or device-preview change was used.

Remaining: ordinary Basic Billboard raster acceptance, physical pointer/touch, real-device viewport behavior, public-server save/rejoin and an owned-count-full purchase condition (not present in current normal Pet code). Broader unrelated game regressions were not added. Phase 2 remains unimplemented.

**Studio内は未保存。ユーザーの手動Save／Publishが必要。** No Save/Publish, rbxl writeback or Studio exit was performed.

[Detailed test evidence](Evidence.json).
