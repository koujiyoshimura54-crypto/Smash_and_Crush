# Pet merge onboarding, Phase 2 — 2026-11-03

## Result and authority

Implemented on the current **unsaved Y02 Studio**, PlaceId **126576845524886**, UniverseId **10765181857**, from Git **1592c61**. Phase 1 was already user-approved. Twelve directly relevant live Sources matched the repository before editing. No old place, bulk Source import, save, publish, rbxl writeback, OS input, window arrangement, camera setter or device-preview operation was used.

Only Pet merge guidance and its separate durable completion were added. Shop, Battle Bag, Pet inventory typography/layout, three-equipped limit, additive effects, Best Equip, follow positions, prices, merge points/probabilities/results, acquisition history and protected copies remain unchanged. **UISoundConfig.Added.Hover.Volume remains 0.15.**

## Changed Full Paths

| Full Path | Change |
| --- | --- |
| `ReplicatedStorage.Modules.PetMergeTutorialState` | New: normalize separate lifetime state; enumerate through existing PetMerge.Eligible and validate through PetMerge.Evaluate; commit completion only with a confirmed normal merge result. |
| `ReplicatedStorage.Modules.PetMergeTutorialGuide` | New: current-World facility destination, read-only UI targeting, interruption/resumption, arbitration and short completion pin. |
| `ReplicatedStorage.Modules.MergeShopView` | Read-only GetPetTutorialState accessor. No sorting, layout, selection, pricing or transaction edits. |
| `StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New` | Mount/unmount the additional guide alongside the existing Ore guide. |
| `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` | Feed PetMergeTutorialTarget into the existing floor-arrow route and scheduler. Floors, carpets, occlusion and update cadence unchanged. |
| `ServerScriptService.Services.PlayerDataService` | New/reset defaults, Phase 1 cohort compatibility, serialization, atomic completion and attribute publication. |
| `ServerScriptService.Services.EggServer` | Include accepted mergeTutorial snapshot in the existing Pet responses. Purchase/merge commands unchanged. |
| `StarterPlayer.StarterPlayerScripts.Services.PetClient` | Read-only mergeTutorialState snapshot behind the existing generation/revision acceptance guards. |
| `StarterGui.PetMergeTutorialGui` | New authored 24-object GUI copied from the current approved Ore template, with seven editable message StringValues. |

The **Ore and Egg guide Sources, their GUI instances, OreMergeTutorialPresentation and TutorialPresentationCoordinator were not changed**. The new guide calls the existing first-owner coordinator; it cannot take an active display owner. The purchased white outline, broad black shade, corners, growth, interpolation, clipping and notification animation are reused.

## Start and completion rules

- New/reset data is eligible. For records created during Phase 1 that lack this new field, eligibility follows the existing **EggPetTutorial.Eligible cohort flag**, not Egg completion. Pre-onboarding legacy records remain excluded. Existing Pet IDs/equipment/protection/history are preserved.
- Accepted loaded data, a living player in the current World's real Lobby bounds, and the original floor tutorial finished are required for presentation. No Win, TimeReward, Strength, account or Egg/Ore-completion gate was added.
- Count **individual eligible IDs** using unchanged `PetMerge.Eligible`; use unchanged `PetMerge.Evaluate` for the two-material start condition and selected-material validity. Equipped, protected and existing nonmergeable species are excluded. Two same-species copies work. No five-owned requirement or unequip instruction exists.
- Steps: current Merge facility arrow → Pet tab → visible usable material card (including repeated use of one grouped card) → ordinary Merge → wait for confirmed result and existing hatch → short completion notification.
- Existing open UI/tab/valid selection skips completed presentation steps. Clear/remove returns to material guidance. Card targets follow the scroll viewport and current accepted ownership/eligibility. No auto-open, auto-select, auto-consume, auto-merge or auto-equip was added.
- The durable state is `PetMergeTutorial={Version=1,Eligible,Completed,RequestId?,ResultPetId?}`. Ordinary `Pet.ApplyOperation` must validate and apply the merge first; tutorial completion and the resulting Pet commit in the **same ownership/reset-fenced UpdateAsync** as material consumption.
- Normal merges performed before guidance also complete this field, including more than two valid materials. UI clicks/animation alone cannot complete it. There is no public tutorial-completion command.
- After accepted success, the controller checks pending/hatch/completion **before** material availability; consuming the last two materials does not cancel completion. No extra success sound is added.
- Normal saves preserve durable tutorial state rather than overwriting it with a stale snapshot. Existing reset generation and response revision fences apply to the added snapshot.

Navigation uses `Workspace.RestockShop.Area` in World1 and `Workspace.World2Map.TrainingArea.FacilityDisplays.MergeDisplay.Area` in World2. Lobby membership reads the replicated `ReplicatedStorage.BattleBagLobbyBounds` values already installed in the preceding work.

## Interruptions and editing

Explicit Close suppresses the guide without reopening the screen. The normal proximity re-entry/open, or Lobby re-entry, permits resumption. Death, battle/outside Lobby, World transition, return/skip busy flags, other menus, reward/general notifications, other Egg sheets and hatch temporarily hide presentation. A transaction/hatch keeps the active guide's ownership while hidden; it resumes from accepted state, not old selection assumptions. Completed joins do not replay guidance.

Manual editing is supported under **StarterGui.PetMergeTutorialGui**:

| Location | Editable values |
| --- | --- |
| `Canvas.Highlight` Attributes | GuiGrow, MoveSeconds, PaddingX, PaddingY |
| `Canvas.Highlight.Outline` and `.Shadow` | Thickness, Color, Transparency, StrokeSizingMode, ZIndex |
| `Canvas.Highlight.Corner` | CornerRadius |
| `Messages` StringValue.Value | GoToMerge, ChoosePet, AddPets, AddAnother, ScrollPets, Merge, Complete |
| `Canvas.Notification.Stack.Line.Message` | Authored notification font/color/stroke |
| `Canvas.Notification` Attributes | ReferenceHeight, HeaderWidthScale, HeaderCenterX |
| root `CompletionSeconds` Attribute | Completion pin duration (2.5 initially) |

The runtime changes focus geometry/visibility, not authored styling. [Installer](../../tools/InstallPetMergeTutorialGui.luau) is Edit-only and does nothing if the authored GUI already exists. [Gui.json](Gui.json) records the actual final hierarchy, attributes and GUI properties. The GUI remains in **Edit**, not only in Play.

## Verification: native runtime and numeric state

One isolated solo Play session and one native **two-client StudioTestService** session were used. Before each, all 37 DataStore/Marketplace/Badge acquisition expressions were temporarily redirected to the test-only memory provider. Runtime fixtures prepared inventory, positions and flags; production data and real payments were never used. Debug reset messages still say “Production reset”, but both named store handles were memory-backed during these tests.

| Check | Result |
| --- | --- |
| One eligible copy → two | WaitingForPets → GoToMerge at Win0, Egg tutorial incomplete. |
| Two equipped / one protected | Eligible count 0 / 1; no guidance. |
| Same-species and mixed species | Two Grey Cat IDs used one grouped card; Dog + Grey Cat selection was valid. |
| Full normal flow | Existing view selection/drag/submit methods → actual PetClient remote → normal server merge → two consumed/one Sheep granted → existing hatch/reveal → completion notice. |
| Selection removal | Two selected showed Merge; removing one returned to AddPets with “Add one more Pet.” |
| Eligibility changed mid-selection | Normal equip of a selected copy removed it from the selection; tutorial paused at WaitingForPets. No automatic unequip. |
| Scrolling/order | Targets moved from the top visible card to a lower usable card. Actual rendered rows remained descending raw points (250, 200, 150, 100, 50, etc.); equal-point order remained stable. |
| Explicit Close / reapproach | Dismissed stayed closed, no focus. Leaving/re-entering the facility reopened normally and resumed ChoosePet. |
| Death / return / World | Actual Health0/respawn resumed; prepared World1↔World2 movement resolved each actual facility and opened its normal view. Outside-Lobby and return-busy paused, clearing busy resumed. |
| Notification | Existing notification hid focus; after expiry material guidance resumed. |
| Save failure | Injected precommit failure returned InventorySavePending with no accepted completion; resolve and same-ID replay yielded one grant/one consumption. |
| Lost acknowledgement | Actual injected postcommit loss remained unaccepted/pending; resolution returned PetSaved, replay AlreadyApplied with one result. |
| Invalid generation | Invalid result species returned InvalidPetResult; no merge completion. |
| Early / >2 success | A normal three-material merge succeeded while original tutorial presentation was unavailable; server saved completion without needing guidance. |
| Memory persistence | Real PlayerData Save/Release/Load against memory retained completed state; no completion pin replay on refreshed client generation. Unfinished ownership/progress also survived reload. |
| Reset/stale replies | Existing /resetdata cleared progress; pre-reset server request returned PetStateChanged; injecting the old successful client response did not restore Pets or completion. |
| Cohort compatibility | Real memory-backed load of missing PetMergeTutorial preserved existing IDs/equipped copy. Phase 1 eligible cohort stayed eligible; older excluded cohort stayed excluded. |
| Egg arbitration | Egg first owned GoToEgg; Pet eligibility then became true and Pet merge waited. Spending Win below Egg's existing price let Egg pause normally and Pet merge start. |
| Ore arbitration | Ore first owned its route. A **normal unequip**, without data reload, made Pet merge eligible; it waited behind Ore and retained Ore's Pet-independent tab highlight. Normal Ore merge completion released the owner and Pet guidance started. |
| Two real clients | **20 assertions passed**. Both owned deliberately identical test ID strings in separate profiles. A merged/hatched/reset while B retained both copies and its own guide; B then merged without granting/consuming/changing A. |
| Manual template edits | Edit-time outline .035, shadow transparency .35, growth1.22 and custom route text survived installer rerun, next Play, both clients and step changes. Restored exact approved defaults afterward. |
| Syntax / integrity | 16 production/installer/fixture files compiled. Eight production Sources matched the final disk versions. |

Early test attempts were kept separate from acceptance: a rapid repeat request hit existing PleaseWait and therefore was **not** an acknowledgement-loss test; the test was repeated after the existing cooldown and passed. A memory reload changed the Forge token and released Ore, so that attempt was not proof of uninterrupted Ore priority; the subsequent normal-unequip test supplied that proof. Temporarily setting the original tutorial attribute false did not change the already-completed server field, so calling CompleteTutorial alone did not restore that artificial attribute; the confirmed early merge result, rather than that presentation attempt, is the recorded evidence.

## Verification: actual screen versus input

**Images were obtained and inspected** without moving the camera or changing preview settings:
- Existing floor chevrons on the actual route to Merge.
- Pet-tab focus, grouped material-card focus, broad shade/white outline and readable notification.
- Selected materials and normal Merge button; notification did not cover tabs, material inputs, close or Merge.
- Existing egg hatch, Sheep reveal and post-hatch completion notice.
- Scroll following a lower visible card.
- Existing Ore tab focus/notification while Pet merge waited.

For narrow rendering, a **430×606 in-game fixture container** instantiated the unchanged MergeShopView and approved presentation renderer using the current accepted Pet snapshot. Both material guidance and selected-material/Merge focus were captured with the title, close, inputs and Merge visible. This confirms actual narrow-branch pixels, but is **not** a physical-phone/device-preview test or a second full guide transaction in that container. The temporary clone was destroyed.

Native hit inspection found no active/interactable tutorial overlay blocking Merge. Selection, drag and submit were **fixture calls into the existing methods**, not OS mouse/touch. Four hatch knocks/continue also invoked the existing handler; no animation sequence or speed was changed.

An initial narrow attempt tried setting the ordinary root size, which existing layout correctly restored; it was not counted as narrow evidence. A tool-command attempt to access the native client _G produced three helper-context errors; moving the fixture to a native LocalScript resolved that isolation issue. No shipped Source error was identified. Existing imported-reference asset warnings 95256658378010 / 139190015780830 reappeared, outside this change. No warning suppression or asset replacement was made.

Screenshots are not retained, following AGENTS.md. [Evidence.json](Evidence.json) retains anonymous test states/results; no raw personal console dump is committed.

## Final state and limits

Play stopped and the focused DataModel returned to **Edit**. Restored 40 temporary Source entries after solo and 39 after multiplayer, removed all helper instances and reverted author-test styles. Compared **472 Sources (470 prior +2 new)**, **5,566 baseline GUI/tutorial instances** and **56,566 properties**: no unexpected difference, no test helpers. Camera CFrame/Focus, HttpEnabled and Hover0.15 were unchanged. The eight intended Source changes/additions and the authored GUI remain.

Unconfirmed: physical mouse/touch, physical device viewports, real server persistence/rejoin, full natural World-gate travel and acoustic playback. Memory reload used the real load/save methods with a fixture generation advance to represent a fresh client. Earlier approved Egg visuals were not redesigned or subjected to a new full purchase regression; its Source/GUI and first-owner behavior were checked. This work makes no natural progression-time claim.

Fixtures under `tests/PetMergeTutorial*` are archived only and are **not installed**. They require memory isolation before Play; never install against production service handles.

**Studio remains unsaved. The user must manually Save/Publish.**
