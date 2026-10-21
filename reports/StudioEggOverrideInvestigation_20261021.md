# Studio normal Egg refusal investigation — 2026-10-21

Investigation only. No game Source/configuration edit, place writeback, Studio Save/Publish, purchase, data reset or test-data injection was performed. Only this report is committed.

## Finding

The reported notification identifies the server's **active `session.StudioStartOverride` snapshot**, created by the Studio level-test API. It is not a price, model, probability or World2-arrival failure. The normal Egg handler can pass its Win and proximity checks and then be rejected by `PlayerDataService.MutatePets` before any debit, Pet grant or durable write.

The current file does **not** automatically enable this snapshot on ordinary Play: `StudioDebugConfig.Start.AutoApplyOnPlay=false`. Its level-bearing `/test` commands explicitly enable it. Native Studio logs from the user's latest sessions show automatic start disabled and successful level-test commands, including Level 160. The exact command text was not logged; the reported refusal establishes the active snapshot, while the source and command logs identify its supported activation route. Merely entering World2 or enabling its arrival preview does not set it.

## Evidence and limits

- Read the repository instructions, relevant specifications, current Sources, history and the records for `58849b4`, `4cb3188`, Studio test commands and World2 arrival preview. Compared three candidates: level-test override, arrival-preview configuration, and leftover Pet-test/fallback state.
- Decoded the actual `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` read-only: **6,894,904 bytes**, SHA-256 **`54cbff432b4405c8ccdc44aaef8f4c7024e60a2544d5cc31ec40c67f43c1ee57`**. This matches the completed Pet-assignment artifact.
- Compared ten relevant saved Sources: PlayerDataService, EggServer, PetServer, ReceiptService, DataStoreConfig, StudioDebugConfig, StudioStartController, PetClient, EggClient and StandClient. Nine match their current mirrors after newline normalization. StudioDebugConfig differs only by one trailing blank line; its settings match. No mirror was written into the place.
- Checked saved instance paths and script references for the prior `PurchasesTestEnvironment`, `PetSwapTest` and `PetModelTest` fixtures; none remain. All saved references to the override setter/state are in PlayerDataService and StudioStartController.
- An already-running **user** Play was inspected read-only. It reported Studio=true, PlaceId 126576845524886, UniverseId 10765181857, CurrentWorld=2, World2Visited=true, Level=160 and Win=10,000,000, with no named purchase/Pet fixtures found in ServerScriptService or ReplicatedStorage. No Player attribute exposes the private override snapshot. The first tool response abbreviated the nested Sources; it is not evidence of a complete live-to-disk Source comparison. The Studio connection subsequently became unavailable, so no private live-session field or complete live Source dump was obtained.
- Read existing native logs instead of starting another Play. In `0.743.0.7431133_20261021T120513Z_Studio_77B05_last.log`: line 2273 records `Dependencies ready; automatic start=false` at **21:06:13 JST**; lines 3069–3070 record a test `DataNotLoaded` response at **21:07:44**; lines 3074–3075 record `TEST OK: Level=160 World=1 Stage=1` at **21:07:59**. The preceding `...20261021T115246Z_Studio_F92DA_last.log` also records multiple successful level-test results in World2. Player names are deliberately omitted here.
- No new Play, click reproduction, mock test or payment was needed to identify the rejection. The user's reported notification, saved code and existing command logs are the evidence. Exact raw chat input and the private live snapshot were not captured; an unsaved difference in the user's open Studio cannot be fully excluded.

## Full paths and rejection chain

Line references below use the current Source mirrors, which match the saved code as described above.

| Full Path | Function / lines | Role |
|---|---|---|
| `StarterPlayer.StarterPlayerScripts.Services.EggClient` | purchase dispatch, line 204 | Calls `PetClient.request("OpenEgg", name, button)` for Open 1/3/8. |
| `StarterPlayer.StarterPlayerScripts.Services.PetClient` | `request`, lines 586–611 | Sends request ID/revision to `ReplicatedStorage.Remotes.PetRequest`; passes a non-retry failure reason to `notify`. |
| `ServerScriptService.Services.EggServer` | `start`, `request`, `open`; lines 17–49, 51–78, 95–109 | Binds the RemoteFunction, validates the player/session/World/count/position/balance/models, rolls server results, then calls `Data.MutatePets(...,"Hatch",...)`. |
| `ServerScriptService.Services.PlayerDataService` | `MutatePets`, lines 1330–1334 | After loaded/ownership checks: `if s.StudioStartOverride then return false,"StudioOverrideActive" end`. It precedes pending mutation creation and saving. |
| `StarterPlayer.StarterPlayerScripts.Services.PetClient` | `notify`, lines 574–583 | Maps that reason to **“Pet purchases are unavailable during a Studio data override.”** and calls `NotifyClient.push`. |

The message is server-result-driven. The visible balance and enabled Open buttons do not promise eligibility: the UI does not expose/check this private snapshot before requesting. EggServer already checked the server balance before the snapshot guard is reached. More Win cannot bypass the guard. Open 1/3/8 are the intended normal-Egg controls; Limited Egg 02 still uses its separate Open 1 UI.

## What the override is

`ServerScriptService.Services.PlayerDataService` keeps a weak-keyed, per-player `sessions` table. `StudioStartOverride` is a **server-memory snapshot table**, not a client attribute, saved data field, Game Pass state, DataStore failure flag or global lock.

- `Load` (lines 612–657) creates a session without that field: its initial value is **nil**.
- `ApplyStudioStartLevel` (lines 704–712) requires `RunService:IsStudio()`, loaded data, no active save and valid inputs. On its first call it snapshots Strength, Level, LevelProgress, total/daily Strength counters/date, Win and RebirthCount. It then changes the live Strength/Level and sets LevelProgress to zero. Repeated level tests retain the original snapshot.
- `ServerScriptService.Config.StudioDebugConfig.Start` currently has **Enabled=true, ChatCommandsEnabled=true, AutoApplyOnPlay=false**, Defaults **Level=45, World=2, Stage=1**. The saved controller is present; those defaults do not apply themselves.
- `ServerScriptService.Systems.Debug.StudioStartController.apply` calls the API when `level` is supplied (line 55). `/test level <n>`, `/test start <level> <world> <stage>`, numeric shorthand and `/test default` supply a level. `/test world` and `/test stage` alone move without creating this snapshot, but do not clear an existing one. Help/status also do not create or clear it.
- If AutoApplyOnPlay were true, `auto` would apply the configured default after data loads (lines 105, 135–136). It is false in the actual file and in the recorded startup output.
- `RestoreStudioStartOverride` (lines 714–727), used by `/test reset`, restores the snapshot fields and sets it to nil after the normal loaded/not-saving checks. This is distinct from destructive `/resetdata`; neither was invoked in this investigation. `Release` (lines 1844–1846) removes the session on exit; a new Play/session starts without the snapshot unless a level override is applied again.
- Death, character respawn, World travel, earning Win, waiting and ordinary autosave do not clear it. `Save` explicitly returns `true,"StudioRuntimeOverride"` before writing when Studio and this snapshot are active (line 811).

### Related mechanisms are separate

| Mechanism | Actual behavior / relationship |
|---|---|
| `ServerScriptService.Config.DataStoreConfig.ResetWorld2ArrivalOnStudioPlay=true` | `studioArrivalPreview = IsStudio() and flag` at PlayerDataService line 39. It uses the separate `World2VisitedThisPlay` session field for effective arrival and the replicated World2Visited attribute. Successful `MarkWorld2Reached` sets the field true (lines 1005–1010). A new session starts effectively unvisited. It never assigns StudioStartOverride and normal Egg purchase does not consult it. The inspected Play already had effective World2Visited=true. Turning this flag off would not clear the Pet refusal. |
| Studio store separation | `DataStoreConfig.GetName` appends `_Studio` in Studio. Player data and permitted Limited receipt tests use `PlayerData_v1_Studio` and `DeveloperProductReceipts_v1_Studio`. These are persistent Studio stores, not automatically in-memory stores. Store selection alone does not create the override. |
| Previous isolated test adapter | The temporary `PurchasesTestEnvironment` used empty memory-backed stores and mocked purchase services. It is absent from the saved artifact. It is different from the supported `/test` level override. |
| DataStore read/acquisition failure | `Load` returns failure and keeps data unloaded/nil; the controller retries three times and warns instead of supplying a fabricated playable record. Missing records after a successful normal acquisition can receive defaults; that is not an error fallback. An unloaded Pet request produces `DataNotLoaded`, not `StudioOverrideActive`. The earlier test-command DataNotLoaded log does not by itself prove a DataStore outage: ApplyStudioStartLevel also uses that reason while a save is active. |

## Normal and paid purchase scope

| Operation | Override handling |
|---|---|
| World1 normal Win Eggs, Open 1/3/8 | Shared EggServer → MutatePets; refused while the player's snapshot exists. |
| World2 normal Win Eggs, Open 1/3/8 | Exactly the same mutation guard. No World2-specific rejection is involved. |
| Pet equip / unequip | `ServerScriptService.Services.PetServer.equip` also calls MutatePets with action `Equip` (line 24), so this guard also refuses equipment changes despite the notification saying “purchases.” |
| World1 Limited Egg 01 and World2 Limited Egg 02 | Shared `ServerScriptService.Systems.Purchases.ReceiptService.processLimitedReceipt` → `PlayerDataService.GrantLimitedEgg`. GrantLimitedEgg has the identical snapshot check at line 1257. The receipt handler returns **NotProcessedYet**, preserving the reserved immutable result for retry; it does not falsely acknowledge a new grant. |

Paid prompt eligibility is **not identical** to normal purchase rejection: `ReceiptService.eligibility` (lines 187–205) checks session/ownership/busy state, Studio creator/context authorization, PolicyService, model availability and Marketplace information, but does not check StudioStartOverride. An otherwise eligible Studio prompt can therefore be offered while its later new Pet grant is deferred. It does not send the normal Egg's exact notification for that receipt failure. Already-completed journal entries can legitimately return PurchaseGranted without making another grant. No actual prompt or receipt was processed here.

## History and purpose

| Commit | Evidence |
|---|---|
| `b42805f` — 2026-09-30 | First tracked level-test snapshot/apply/restore support in PlayerDataService, StudioDebugConfig and StudioStartController during combat work. Runtime testing used the override to prevent test progression from being saved. |
| **`f38316d` — 2026-10-08** | Introduced the normal Pet `StudioOverrideActive` guard and the exact client message while restoring Basic Egg with durable per-copy Pet transactions. It predates the current World2 work. |
| `e475b75` — 2026-10-10 | Added the matching guard in GrantLimitedEgg when integrating durable Developer Product receipts. |
| `cfc1257` — 2026-10-19 | Restored missing saved `/test` entrypoint scripts. Its record explicitly preserves ApplyStudioStartLevel/RestoreStudioStartOverride and Save exclusion; automatic application remains false. |
| `9ade422` — 2026-10-21 | Added the separate first-arrival preview setting/field. It did not introduce the Pet override rejection. |
| `58849b4` — 2026-10-21 | Broadened Limited receipt validation to product-specific offers, including Product 3720640383; kept the existing snapshot guard. |
| `4cb3188` — 2026-10-21 | Changed models/presentation while preserving species keys. It did not change PlayerDataService, ReceiptService, StudioDebugConfig or StudioStartController. PetClient retained the pre-existing notification. |

The protective purpose is supported by the persistence implementation and original records: normal Pet debit/grant/equip transactions directly perform an owned UpdateAsync, and paid grants have their own durable transaction. They do **not** pass through the ordinary `Save` early return. Simply deleting their snapshot guards would let test-session Win/Pet changes reach a persistent store even though ordinary saves are suppressed. The current symptom is an interaction with that older intentional protection, not evidence that the selected Pet models broke buying.

## Why the previous Play validation missed this

The `reports/World2PetModels_20261021/README.md` validation was real client/server Play **against isolated memory data**, not ordinary saved-data startup followed by `/test level`. The retained temporary fixture source confirms:

1. `PurchasesTestEnvironment` starts with empty `Stores={}` and implements memory GetAsync/UpdateAsync. Test data is not loaded from the user's Studio store.
2. `PetSwapTestControl` seeds Win using `Data.SetWin`, saves/releases/reloads against that memory store, supplies the 39-copy legacy-Pet fixture, and positions the character directly while setting CurrentWorld. It does not call ApplyStudioStartLevel or `/test`.
3. The normal hatch checks then call the real `EggServer.request`; the normal override guard was not deleted or replaced. The fixture's setup **avoided activating the condition**, so successful hatches established behavior only with StudioStartOverride absent. No level-override integration case was included.
4. Paid tests additionally substituted the local-file Experience context and creator authorization inside the temporary Receipt adapter, and mocked Marketplace/Policy services. Those substitutions were reported as isolated testing and restored; they do not establish ordinary Studio billing/receipt behavior. No such test Source remains in the artifact.

The earlier native test log `...20261021T110741Z_Studio_E9142_last.log` records `[PetSwapTest] isolated fixture ready` and `automatic start=false` in both runs. The later user logs record `/test` results instead. That is the relevant missing coverage. The prior “actual Play” results must not be read as verification of purchasing under the user's level-test snapshot.

## Production impact

Under the current saved code's supported paths, **this specific refusal is Studio-only**. Both the controller entrypoint and ApplyStudioStartLevel are gated by IsStudio; the snapshot is session-only and is not read from saved data. Published servers do not create it through these paths. The guard itself checks snapshot presence rather than IsStudio, so an unrelated future server-side writer could make it trigger elsewhere; no such writer exists in the inspected saved Sources. Other genuine purchase/load/policy failures remain possible in production. No live production behavior was exercised here.

## Minimal repair proposal — not implemented

- Keep the durable mutation and paid-receipt protections. For ordinary saved Studio purchases, an explicit existing `/test reset` can first restore the real session state; it also restores the prior Win/level and is not a solution for testing with an elevated level. Nothing was reset during this investigation.
- To support normal Egg testing **while the level override is active**, add a narrowly scoped **Studio-only, per-player volatile Pet/Win transaction branch**. Reuse the existing server eligibility, price/count/World/model validation and Pet.ApplyOperation request/revision rules; only Hatch and Equip use this branch. Debit test Win and publish inventory/hatch updates immediately, without calling ownedUpdate, creating durable pending operations or writing a receipt journal. Other players and non-override sessions retain the existing path.
- Keep preview Pets/equipment and test Win isolated from the saved snapshot. Discard/restore them on `/test reset`, release and shutdown, and fence late requests/retries from the previous preview generation. The current snapshot does not contain Pets, so merely allowing in-memory mutations without this restoration would be incomplete. Never merge preview grants into a later normal save. Preserve the existing Save exclusion and `_Studio` store selection.
- Leave **GrantLimitedEgg's override refusal intact**. Add the same rejection to paid offer/prompt eligibility, including its post-yield recheck, to avoid opening a prompt whose new grant cannot currently complete. A previously paid receipt remains NotProcessedYet with its original reserved outcome and is retried through the existing durable path after the override ends; never acknowledge, reroll or fake-grant it in the preview branch. Preserve PolicyService and Studio authorization.
- A later implementation needs only focused isolated checks: normal Hatch/Equip in an active override, duplicate/reordered request behavior, zero store writes, reset restoring original inventory/Win, ordinary Studio startup, and paid prompt/deferred-receipt protection. No broad gameplay regression is needed for this diagnosis.

## Preservation and completion

Only this new English report is in the commit. Existing dirty docs, BossChaseService edits and unrelated untracked files remain untouched. No specification change was implemented. The target place hash is unchanged; all read handles are released. No Studio was launched, started/stopped, saved, published or closed by this investigation, and no task-owned Studio/file lock was created. The user's existing Studio was only queried read-only; its connection loss was not caused by a Stop/Close action from this task. No extra rbxl, backup, copy or migration was created.
