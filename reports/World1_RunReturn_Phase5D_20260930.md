# World1 Run Return — Phase 5D, 2026-09-30

## Scope and baseline

Y02 / Studio Place 101572058398926. Fetched and fast-forwarded main; main and origin/main matched `396c036ea4e0957592c7519fcd1009ecddf2531e` before implementation. Preserved and excluded the pre-existing untracked `reports/World1_Balance_Audit_20260916/build_report.md`.

Implementation scripts:

| Script | Change |
| --- | --- |
| Services.RunInventoryService | Snapshot/freeze, current character/run validation, release/complete APIs; frozen generations reject drops |
| Services.PlayerDataService | RunReturn-only dispatch in existing serialized item mutation pipeline |
| Services.RunReturnPersistence (new) | Existing-store atomic deltas, durable ID/state metadata, idempotent retry and cancellation reconciliation |
| Services.RunReturnService (new) | Player lock, validation, bank ordering, cancellation observers, existing combat reset and relative Lobby placement |
| RunReturnController (new) | RunId-only RemoteEvent request, cooldown and explicit result |
| StrengthGui.RunReturnClient (new) | World1 Return button; busy/failure presentation |
| Modules.HUDLayout | Include visible sixth left-menu slot in existing touch/status collision checks |

The button is `PlayerGui.StrengthGui.LeftMenu.RunReturnButton`; its layout slot is `HUD.LeftHUD.RunReturnButton`, order 6, the existing menu's third-row right. Inventory text is not clickable. Placement and responsive scaling remain centralized in HUDLayout.

## Commit protocol

1. Validate actual Player membership, string RunId, World1, active current generation, living current Character and player-specific Return lock. Resolve Lobby and normal speed before committing.
2. Freeze the Run and clone its quantities. Delayed same-generation drops are rejected while this snapshot is pending. Preserve the same transaction token across unconfirmed writes.
3. Stage all positive item deltas through ItemService.RunItemTransaction. PlayerDataService retains its existing PendingItemMutation serialization and existing store/key.
4. UpdateAsync adds the delta once and records RunReturnId / RunReturnState in existing key metadata. Repeated callbacks or requests using that ID do not add again. Existing OwnedItems is merged, not replaced by a stale full inventory snapshot.
5. Require a confirmed matching saved ID/state and still-valid character/run. Only then update local permanent ownership, invalidate/empty the Run, reset World1 combat, mark the Lobby Run inactive, heal and move the same Character to the existing Lobby spawn. No Trophy reward function, Win award or death is invoked.

An unconfirmed save retains Run items/count/ID, does not teleport, releases the active Return request lock and permits manual retry. The immutable Run snapshot and the existing item mutation remain reserved until resolution; additional drops and other item mutations cannot race that unresolved bank. Autosave is not permitted to retry the provisional grant itself.

If death, character replacement, world/run invalidation or disconnection wins before confirmation, the return is cancelled. If the backend had already applied this transaction while its response was pending, cancellation reverses only its recorded delta. Local OwnedItems is not exposed as granted before confirmation. Confirmed returns survive later death. Cancellation retries can remove an ambiguous write but cannot create a grant.

Normal exit and BindToClose have no new bank hook. Run tables are never part of a PlayerData save payload. Empty returns require no item mutation.

## Play evidence

Fault injection used a temporary **Studio-only memory adapter for the existing store handle**, executed through the actual runtime Script/module cache. It seeded 27 permanent items and three equipped items; no fixture data reached the real DataStore. Adapter modes covered failure before write, failure after write but before response, delayed writes/responses, and callback re-execution. The adapter, suppressed ranking writes and runtime probes were removed afterward. These hooks are absent from the shipped sources.

| Case | Observed result |
| --- | --- |
| 0 items | Return succeeded; permanent 27→27, no item write, Run 0, Lobby horizontal distance 0 |
| 1 item | Permanent 27→28, one mutation, Run 0 |
| 5 items | Permanent 28→33, one atomic mutation, Run 0 |
| Old ID resend | StaleRun; no additional ownership |
| Failed write before apply, 5 items | Permanent/store stayed 33, Run stayed 5 with same ID, no teleport, busy released |
| Save while failed return pending | InventorySavePending; did not execute another grant write |
| Manual retry | 33→38 exactly once; Run 0 and Lobby |
| Write applied but response failed, 1 item | Local stayed 38 / Run 1 while saved count was 39; retry reconciled to 39, no second grant |
| Callback executed twice, 5 items | 39→44 exactly once |
| Concurrent request during delayed write | ReturnBusy; one bank operation |
| Death before write | ReturnCancelled, permanent/store 44 unchanged, Run lost, no voluntary Lobby return |
| Death after backend write but before response confirmation | Transient saved 49 reconciled back to 44; local remained 44, Run lost, pending cleared |
| Death immediately after confirmed success | Confirmed 45 retained; LoadCharacter retained 45 and equipment |
| Drop during return / after return | Old RunId rejected with StaleRun; did not contaminate Lobby/new generation |
| Actual button failed save then retry | `失敗\n再試行`, Active=true and Inventory 1 / 5; second click succeeded once |
| Actual button double click | Only one permanent increment |
| RemoteEvent 20 sends | Permanent 48→53 exactly +5, Run 0 |
| Invalid Player / stale ID / inactive / World2 | InvalidPlayer or StaleRun; refused |
| Sixth item | InventoryFull; Count remained 5 |
| New StartRun | Fresh generation with Count 0; old drop rejected |

After refining Lobby inactive state and cooldown replies, a fresh Play repeated 5-item and empty returns. Run Active=false, Count=0, HUD `Inventory 0 / 5`, Return button hidden. New StartRun exposes the button again.

### Actual Studio DataStore

Restored the normal existing `PlayerData_v1_Studio` store path and tested real persistence through the final code. Cache-disabled GetAsync readback verified +1, then another +5 (cumulative +6); LoadCharacter retained +6. Removed **only those six newly added test quantities** through the existing ItemService negative mutation and read back exact original OwnedItems and EquippedItems equality. Empty return then produced no quantity change.

With five further provisional items, ordinary PlayerData Save left stored OwnedItems equal to the original snapshot. Kicked the player to exercise the actual PlayerRemoving path; a server observer read the real store afterward and logged `[Phase5D Exit] read=true ownedUnchanged=true`. These unconfirmed five were not banked. Production store names/config were not modified.

A separate zero-item combat-state fixture entered the real BossCombatService and BossAttackService, set Fighting=true and HP25, then called Return. Before: boss=true, attack=true. After: both false, Fighting=false, HP100, same Character=true, Run Active=false. EnemyManager's existing reset also clears recognition/chase targets, stage/wall states and client combat notifications. This was a service-state fixture, not a complete natural boss fight/chase replay.

### Responsive UI

Landscape simulation, CoreUISafeInsets. Screenshot inspection plus actual button bounds/TextFits:

| Device | Viewport | Button size | TextFits |
| --- | --- | --- | --- |
| Average Laptop | 1365×768 | 122×122 | true |
| iPad Pro M5 13in | 1375×1031 | 179×179 | true |
| iPhone 7 | 666×374 | 64×64 | true |
| iPhone 17 Pro | 749×361 | 60×60 | true |

No overlap with existing menu buttons, Inventory text, visible thumbstick/jump controls or status HUD. The broad transparent DynamicThumbstickUIModifier input area intersects the left menu by design; visible control bounds and screenshots were checked separately. No new GUI assets or panels were saved.

## Regression evidence and limits

- Source fingerprint comparison: 500 original Studio scripts, only the three listed existing scripts changed; four new scripts; no missing scripts or QA leftovers. All seven implementation sources match local files (ignoring existing trailing-newline differences in PlayerDataService/HUDLayout).
- ItemMaster remains DropChance 20%, rarity 80/13/4/2/1; Run capacity remains 5. Drop grant logic, existing FULL presentation, World2 logic/config, EquippedItems mutations, reward/shop/merge paths, combat damage/timing, animation and VFX sources are unchanged.
- Permanent/equipment equality was measured, not inferred from source alone. Normal save and actual exit were exercised. BindToClose has no bank code and was source-reviewed; forced process termination and a real backend outage during cancellation were not tested.
- Ambiguous remote writes cannot be made atomic with an in-memory death event. Cancellation reconciliation requires a running server and available DataStore. A hard server crash or prolonged outage between an already-applied write and its compensating cancellation is **not covered by a durable cross-session recovery journal in this phase**; do not interpret these passing races as a crash-recovery guarantee. Roblox documents that a failed write may still have applied: [DataStore error guidance](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits).
- Full World2 fights, all reward purchases, full Chase behavior, animation and VFX playback were not replayed; their preservation evidence is source comparison plus targeted reset tests.
- Existing unrelated console issues remain in Unused_Assets.BossAnimationReferences: TungTungSahur.Script:756 nil Chatted; missing Walk_LaGrandeCombinasion; Ballerina/Tralalero references waiting for Workspace.Brainro_pack_3. No new Return errors appeared.

Final Studio state: Play stopped, Edit, device simulation stopped / normal viewport restored. No Place save, GUI save, export or Publish was performed.
