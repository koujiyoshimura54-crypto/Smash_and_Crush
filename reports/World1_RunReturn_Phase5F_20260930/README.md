# World1 Run Return persistent safety — Phase 5F, 2026-09-30

## Baseline and scope

Y02, Studio Place 101572058398926. Fresh fetch confirmed main = origin/main = `8e0d1d9ae9cf557827f720e1891440a39a0f1b65`, ahead/behind 0/0. Preserved and excluded the existing untracked `reports/World1_Balance_Audit_20260916/build_report.md`.

Production changes: `PlayerDataService`, `RunReturnPersistence`, `RunReturnService`, and new `PlayerDataOwnership`. The ReturnService change only supplies the snapshot RunId to the journal. RunInventoryService, Return client/controller, HUD/layout, ItemMaster and World2-specific sources were not edited.

## Durable representation

The existing PlayerData key holds:

```text
SessionOwnerToken: unique GUID for this loaded Player session
RunReturnJournal:
  TransactionId, OwnerToken, Sequence, RunId
  ItemDelta: { itemId: positive quantity }
  CreatedAt, State: Pending | Granted | Cancelled
  ResolvedAt (terminal), Reason (recovery cancellation)
```

This is a bounded current journal, retaining the last terminal record until a valid successor is prepared. It is not a full historical ledger. A retained operation carries immutable ID/owner/sequence/deltas; the per-owner sequence high-water mark rejects an older operation even after its ID has been replaced. A different owner's operations fail the durable owner fence. Retries never mint a fresh ID/sequence for an existing operation. Full Run Inventory is not persisted and ordinary pickups/exit/death do not create a journal.

Legacy RunReturnId / RunReturnState metadata remain compatibility markers, not the deduplication authority. ItemMutationId is updated with a real Grant, not with an unrelated old Cancel. Ordinary saves keep the latest stored OwnedItems, journal and owner fields.

## Protocol and ownership

Load reads without local cache and conditionally claims the observed owner using UpdateAsync. The same acquisition attempt/token survives an ambiguous response. If another session owns the key meanwhile, the old attempt cannot reclaim it. Validation, Pending recovery and new owner installation occur inside that same atomic update, before Loaded=true or gameplay ownership is exposed.

All normal PlayerData writes go through PlayerDataOwnership.Update. Every callback, including a callback re-execution, checks the stored SessionOwnerToken before invoking the caller's transform. Session release or owner loss also prevents writes. AutoSave, item deltas, return transitions, receipt item grants, size/speed purchases and online Reset use this boundary. Reward/shop/merge business rules are unchanged. Explicit administrative ResetByUserId remains a privileged reset operation; it rotates the owner and ResetToken and clears the Return journal. No administrative reset was run against real data for this phase.

Return first takes the existing frozen snapshot. The mutation stores Pending without changing OwnedItems, confirms that write, and only then requests Grant in a separate UpdateAsync. Grant requires exact owner/ID/sequence/run/delta identity; quantity addition and State=Granted are one atomic write. A replay of Granted does not add again. Successful persistence still precedes Run clearing and Lobby movement.

Cancel only changes an exact matching Pending journal to Cancelled. It never subtracts quantities. A different ID/owner/sequence returns nil and does not write either data or metadata. Granted is terminal even if death, leave, response loss or movement failure happens afterward. This deliberately supersedes Phase 5D's rollback after a backend grant but before acknowledgment.

Join recovery chooses cancellation: Pending has never added ownership, so it becomes Cancelled without an item delta. Granted remains unchanged. There are no detached cancellation retry tasks after Release. A surviving old request is either already durably Granted or is fenced out after takeover.

## Current verification

[evidence.json](evidence.json) contains the final 18 transition/resolver tests plus 14 PlayerDataService integration tests, all passing. Tests run the actual production modules in Studio Play. The integration suite uses independent copies of PlayerDataService, each with its own session table, sharing one in-memory DataStore adapter. Only the store handle and ordered-ranking sink in the temporary copies are redirected. Production services remain on the normal Studio store.

| Required case | Result |
| --- | --- |
| A/B: normal Return 1 / 5 | Real Studio store readback +1 / +5, Run 0 and Granted |
| C/D: same transaction / Granted resend | Repeated callbacks, lost responses and retries add once; old Run request refused |
| E: old Cancel vs new metadata | Data and metadata equality preserved; no write for stale same-owner transaction; old owner rejected |
| F: Phase 5E race | Starting at 10: T +5 Granted cannot be cancelled; U +1 and retry end at **16**. T cancelled while Pending yields **11**. No 12/17/15 result |
| G: Pending persisted then crash-equivalent | New independent Load cancels Pending before exposing data; no added item |
| H: Granted persisted then crash-equivalent | New Load preserves quantity and Granted |
| I: AutoSave | Stale session quantity cannot replace stored count/journal. Actual 90-second autosave ran with normal Studio store; restored counts and Granted remained intact |
| J: PlayerRemoving near Pending / Granted | Pending cancels; Granted response-loss remains granted in integration tests. Actual exit with five unconfirmed Run items did not save them |
| K: BindToClose-equivalent | Repeated Save/Release around Pending never grants it; next Load cancels. Granted remains terminal |
| L: ownership handoff | Old item mutation, ordinary Save, Return Cancel/Grant and online Reset rejected; new owner writes normally |

Additional assertions cover Pending write failure before apply, response loss after Pending, response loss after Grant, death/leave on both sides of durable Grant, same-owner stale Prepare, changed deltas/reused sequence, ownership acquisition response loss, callback retry, released-session writes, first-ever Join, legacy boolean ownership/5D markers and malformed-journal Load refusal without overwriting data.

Actual Studio persistence used the existing `PlayerData_v1_Studio` path. A +1 and a +5 return were read back with cache disabled; LoadCharacter retained cumulative +6 and equipment. Only those six test-created quantities were removed using existing ItemService.RemoveItem. Both session and persisted OwnedItems matched the original snapshot afterward; EquippedItems also matched. No user-owned pre-existing item was removed.

The 90-second AutoSave advanced LastSave after the explicit verification save while preserving the restored item quantities and Granted journal. With another five provisional Run items, the real player's exit observer read `[Phase5F Exit] read=true ownedRestored=true`. The next Play acquired a different owner from the old journal owner, loaded matching stored ownership, kept Granted and initialized Run Count=0.

## Reproduction

The four files under `tests/RunReturnPhase5F*` are manual Studio QA sources, not deployed server scripts. During Play, use the privileged Server command context to call the factory in `RunReturnPhase5FStudioRunner.luau`, passing the source strings as `{unit=..., integration=..., memory=...}`. It creates only Play-time modules/scripts. Read the returned script's Results attribute. The expected result is unit 18/18 and integration 14/14. Stop removes the fixtures. Do not install the runner as an automatic production Script.

The two-session tests deterministically reproduce old/new server data-state interleavings and response failures. They are not a claim of two live production servers, a real process kill, or a backend outage experiment. BindToClose cases exercise its Save/Release-equivalent persistence behavior; no crash recovery relies on BindToClose being called.

## Regression, cleanup and deployment limits

- Source fingerprints: 504 original scripts; only the three intended existing services changed, one new ownership module, no missing scripts. All temporary Phase5F instances were absent in Edit afterward.
- Run capacity 5, sixth rejection, Boss drop 20%, rarity weights, normal death/exit Run loss, UI, equipped-item rules, daily/time/community rewards, shop/merge rules, World2-specific logic, combat, Chase, Damage, animation and VFX sources are unchanged. Shared PlayerData writes now receive the requested owner check. This is source preservation plus targeted transaction tests, not a replay of every reward/gameplay feature.
- Console retained the known Unused_Assets reference-model error and waits (TungTungSahur nil Chatted, Walk_LaGrandeCombinasion, Brainro_pack_3). The final isolated stale-owner test intentionally triggered the existing generic item-mutation warning with SessionOwnershipLost. An earlier temporary probe called a nonexistent MarkDirty helper; that probe was replaced with the existing Dirty/Save path and removed. It was not a production-script failure.
- Ownership fencing works between servers running the new implementation. A pre-5F binary does not perform these checks. Deployment must replace/drain those old servers; no publish or production server restart was performed here. Pre-existing 5D data lacking a journal remains permanent ownership; missing historical rollback deltas cannot be reconstructed retroactively.
- Final state: Play stopped, Edit. No Place save, GUI save, export or Publish. Original untracked balance report preserved and excluded from this change.
