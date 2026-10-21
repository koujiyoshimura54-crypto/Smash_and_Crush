# Trophy receipt ordering and recovery - 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`.
Changed Full Path: `ServerScriptService.Services.TrophyRewardService` (both World contexts).

## Findings

- Current rbxl Sources matched the related local Sources after decoding. The place hash matched the last completed wall writeback, including manual map edits. No running Studio was found; no Studio was launched or closed.
- EnemyManager uses `state(player).Defeated[stage]`, with owner-specific Trophy records and overlap filtering. No legacy shared Boss qualification or button-global lock was found in this path. Clear/reset removes the player's session receipts; these receipts are not persisted as claimed flags.
- Before credit, collection called `Placement.StreamLobby`, which yields on `RequestStreamAroundAsync`, and World1 then called durable `Bank.Commit`. Streaming failure, stale placement or failed banking rejected the Win receipt. A successful bank retires the run; a subsequent credit failure previously left no bankable run for a retry. Exceptions after setting `Claiming` had no guaranteed cleanup.
- The shared 0.1-second overlap scan called the yielding collector inline, so one player's save/stream work could suspend that scan for other players. Touched also invokes collection, so the scan was not the only route.
- The yellow template Handle and server hitbox use the same 8x5 footprint, with a shallow added vertical overlap volume. Client Trophy visuals use the supplied CFrame without a separate scale. Static reading did not establish a maximum-body contact defect. Physical contact still requires user verification.
- No evidence establishes the unknown report's exact World, Stage, data state or persistent failure cause. A report persisting across rejoin is not proof of corrupt saved data. No production data was read or modified.

## Changes

After server owner/World/defeat/alive/physical-overlap/load validation, collection serializes the player's receipt. The existing server multiplier is calculated; eligibility and the current balance are rechecked if a cold ownership lookup yielded. Successful `PlayerData.SetWin` and the Collected flag have no intervening yield. The owner event follows credit, before durable item banking and Lobby streaming.

The existing loaded-session dirty/save mechanism remains enabled. World1 durable item banking still must succeed before run reset. Streaming and banking waits were moved out of the Win receipt's critical path, not removed from their required persistence/travel operations. No fixed pickup delay was found or arbitrarily deleted. The 0.3-second defeat-to-visual scheduling and 0.1-second overlap fallback remain; Touched still provides event-driven acceptance.

A credited receipt retains its result and successful Banked state if return fails. Further overlap can retry the return without recalculating or granting Win again or re-banking a retired run. A one-second backoff applies only to retries after credit, never initial reward acceptance. Other Trophy records for that player's same return cannot grant concurrently. Clear/reset releases this per-player state for the next run.

Collection workers are separate from the shared overlap loop. An xpcall cleanup always releases transient processing flags, including on errors; only a successfully credited receipt retains its same-return exclusivity. Other players have independent receipts/workers. Existing death/return/leave resets remain authoritative. A failed travel does not clear the receipt or reset progression before placement succeeds.

Failure diagnostics are emitted once per receipt/reason for invalid reward/balance, rejected credit, bank failure, stream failure, return failure or exception. They include World, Stage, receipt id and whether Win was already credited. There is no per-frame logging or new monitoring subsystem.

## Completion and limits

Only the changed Luau Source was syntax-compiled. Wrote to the same rbxl, reread and decoded it, and confirmed exact target Source equality. All other Sources, property chunks, hierarchy and identifiers were preserved; see `Writeback.json`. No extra rbxl/copy/backup was created and file handles were closed.

No Play, client launch, post-change screen inspection or simulated reward tests were performed. No elapsed-time improvement was measured. The unexplained inability report is not claimed reproduced or resolved. Final behavior, maximum-body contact and concurrent-player operation are for user verification.
