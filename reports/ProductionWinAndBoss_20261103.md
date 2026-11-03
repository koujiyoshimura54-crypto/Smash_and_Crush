# Production /setwin and Stage1 loot verification — 2026-11-03

## Applied to canonical unsaved Studio

PlaceId126576845524886 / UniverseId10765181857. Latest live Sources were the baseline; no repository or rbxl replacement of Studio.

Changed Full Paths:
- `ServerScriptService.Systems.Debug.StudioDebugService`
- `ServerScriptService.Services.PlayerDataService`
- `ServerScriptService.Services.PlayerDataOwnership`
- `ServerScriptService.Services.ProductionWinState` (new ModuleScript)
- `ServerScriptService.Services.ProductionWinService` (new ModuleScript)
- `ServerScriptService.Services.ProductionWinController` (new Script)

`/setwin <integer> <UserId>` now targets the existing production `PlayerData_v1 / Player_<UserId>` record. Both command parsing and the server request API require issuer7467238848 in canonical Studio. The two tester IDs receive no administrator permission. Omitted-ID setwin and all other command permissions remain unchanged; Limited Egg is untouched.

The former command accepted only two words and changed its issuer's Studio session. The existing production reset API is unsuitable for changing only Win or coordinating a live session. The new request uses the same production store and session ownership mechanism, preserving other fields, key metadata/user IDs, and reset token. Missing/invalid target records are rejected, not created.

A durable `AdminWin` directive is queued on the same player key. MessagingService wakes the owning public server; a15-second poll and session acquisition recover missed notifications/offline players. Live application waits for existing inventory/save transactions, writes under the existing owner fence, updates session Win/attribute/HUD, then confirms synchronization. Uncertain writes retain the save/spend barrier until retry. Applied IDs prevent stale snapshots and retries from restoring or reapplying the old amount. Reset cancels older directives. No normal gameplay data is recalculated.

Responses include target ID, amount, request ID and state. Only `Applied` returns success; `PendingOnlineSessionOrNextLogin`, `CommittedAwaitingLiveSync`, conflicting request, write/read failure and reset cancellation are not reported as success. Queuing does not claim that an online player's HUD already changed.

**Deployment boundary:** the new receiver/load logic must be manually published and running on the target public server. Existing servers running older code cannot gain this handler from an unsaved Studio edit. Their requests remain pending until supported code consumes them; this task did not Publish or restart any server.

## Focused isolated verification

- Native Studio Play used memory-only DataStores/badges, mock purchase/policy dependencies, and an isolated MessagingService. No real target account or production record was modified.
- Both example target IDs: production-shaped memory records queued1000 while leaving old Win untouched; separate production-session Load consumed the directive to1000 and retained existing Ore data. Target players did not join Studio.
- Online simulation: a native module instance with production store naming owned a separate in-memory session. The real new controller callback consumed a queued2345 request, live Win/HUD showed2345 / `2.3K`, save/reload retained2345. Earlier1000 application survived autosave.
- Injected lost commit response: no success returned, saving remained blocked, retry applied0 exactly once; earning7 afterward and retrying did not reapply0. These were separate memory sessions in one Studio server, not actual cross-server production communication.
- Omitted-ID command retained own Studio23→1000→0. An offline-target request left issuer Win0 unchanged. Negative/fractional/invalid IDs and excess arguments rejected.
- Full request-function simulation denied10591394123,10653503502 and an outsider, with zero writes; public-runtime issuance rejected. Developer path passed natively.
- Additional exact-Source unit execution: duplicate queued request retained its ID; conflicting value rejected; message outage stayed pending; metadata/user IDs and non-Win fields preserved; login applied once; reset token rejected an old directive.

## Stage1 Boss / Battle Bag finding

No repeated-guarantee or bag-update defect reproduced. Used the **actual EnemyManager combat → defeat → normal RunReturnService return → StartRun/recombat path**, never a cloned drop service. Prepared Strength/wall access and controlled only random inputs to the existing roller for deterministic coverage; production probabilities/candidates were untouched. Each native defeat, grant, client notification and bag text was correlated by the same Drop ID:

| Defeat | Drop ID | Roller result | Granted result | Actual client bag |
|---|---|---|---|---|
| 1 | `31d9d084-2304-4f47-9300-d21acdf9a553` | PROTEIN_COMMON_FIRE | First replacement: ORE_001 | 0 / 5 |
| 2 | `f008c274-bc9d-4330-b4b0-ac826e74e6d9` | PROTEIN_COMMON_FIRE | Normal: PROTEIN_COMMON_FIRE | 1 / 5 |
| 3 | `9a24598d-8e0c-4ec3-bc79-c15433435630` | ORE_002 | Normal: ORE_002 | 0 / 5 |
| 4 | `d61d4469-d709-4c60-b3c0-8b5021097f42` | ORE_001 | Normal: ORE_001 | 0 / 5 |
| 5 | `099b25e3-03c8-447b-b8e6-4b6e0d579753` | PROTEIN_COMMON_FIRE | Normal: PROTEIN_COMMON_FIRE | 1 / 5 |

The first flag became consumed on defeat1 and retained the same first DefeatId throughout. Native Item drops entered the provisional bag and became OwnedItems on normal return (two Items ultimately banked). Ore drops went directly into OwnedOres: Stone1 after the first kill, Coal1 after kill3, Stone2 after kill4. Thus Ore correctly leaves bag count0; increasing that display would misrepresent the existing inventory model. Notifications matched each grant; Stone/Coal overheads used5pt/7pt. The actual rendered bag showed1/5 after Item reacquisition.

Memory save/reload followed by actual character death/respawn and another native defeat retained consumption and normal Item routing. Existing Stage1 guarantee, legacy exclusion, TimeReward and tutorial Sources were not changed.

## Limits / cleanup

- No real target-account login, production datastore write, real MessagingService cross-server delivery, real client chat typing or public rejoin. The user-observed repeated-Stone symptom itself was not reproduced; normal Stone rerolls and Ore's separate storage are confirmed distinctions, not an assumed diagnosis.
- No separate rebirth transaction or reset→combat cycle in this run. Reset fencing was tested in isolation; original first-reward state and reset gameplay remain unchanged.
- Client properties and one actual bag capture were inspected; temporary capture not committed per AGENTS.md. Expected badge-stub failure warnings appeared; no task-related runtime error remained.
- Stopped Play, removed all test dependencies/fixtures, verified475 Source/Enabled baselines and74 SoundIds. Final live six Sources compiled; Limited Egg and Boss/UI production Sources remained unchanged.
- Left Studio in **unsaved Edit**. No Save/Publish, rbxl write, Studio exit, OS input, camera/device/window changes. User manual Save/Publish is required.
