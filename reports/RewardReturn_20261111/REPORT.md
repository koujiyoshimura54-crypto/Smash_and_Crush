# Offline claim and return UI repair — 2026-11-11

Applied to the open canonical Studio: PlaceId **126576845524886**, UniverseId **10765181857**. Baseline: **dd3531e**. Existing unsaved edits and the Back-return fix were retained. The cancelled Stage1 collision investigation is not resumed or represented as fixed by this change.

## Phase 1.1 — offline reward claim

Reproduced before modification: a successful View immediately followed by Claim returned `Busy`; Strength remained unchanged. Both requests shared the same 0.25-second admission timestamp. The client discarded Claim's returned View and immediately requested another throttled View.

Changes:
- Independent read/mutation admission timestamps. Existing mutation lock remains.
- A Claim reuses its operation ID for the same reward, session object and Forge session token, including uncertain-save retries. The client sends that token; stale tokens are rejected.
- One button callback owns a bounded retry loop: 0.5/1/2-second backoff, at most ten requests and a 45-second overall deadline, with a ten-second response wait. Temporary Busy/DataSaving/InventorySavePending/transport failures do not require repeated clicks. Exhaustion or terminal failure restores input.
- The existing button title shows `Claiming...`. A successful confirmed response applies its View immediately. View request revisions discard older responses. Reset/session-token change and script destruction invalidate the old client operation.

Native isolated Play passed **13 scenarios**: View then one activation, eight simultaneous activations, another save in progress, delayed save, pre-write failure, write committed with lost acknowledgement, lost Claim response, older delayed View, terminal rejection, reset during retry, a response delayed beyond ten seconds, another pending inventory mutation, and retry exhaustion. Successful fixtures granted exactly **123** Strength, with durable Paid=123 and a closed panel; replay did not grant again. During uncertain persistence, live Strength stayed zero until confirmation. Eight activations produced one Claim request. Permanent Busy stopped after ten requests (~18.47 seconds) and restored input.

Eleven pure-state assertions additionally covered DoubleOffline, free/paid races, duplicate receipts, delayed receipts after login/cancellation and mismatched intents. No actual checkout or production receipt was used. Calculation, cap, current-login reward replacement, price and receipt code are unchanged.

## Phase 1.2 — measured return delay / stutter

Identified a measured client cause, separate from persistence latency:
1. Each RunLootBanked snapshot iterated every owned Item through acquired(), which rendered notification state each time.
2. acquired() set already-seen Items to unseen before render cleared them. Each attribute change rebuilt the entire Item page.
3. The same bank event refreshed both ItemInventoryState and Forge, which both rebuilt that page.

The notification handler now batches ownership updates and renders once; acquired no longer forces seen Items back to unseen. The renderer derives the flags from existing seen history. The Item page coalesces notification-attribute updates and uses the existing confirmed Forge snapshot for bank-event refresh. RunItemBankService, RunReturnPersistence, arrival rules and save barriers are unchanged.

Local Studio samples, inventory panel closed, seeded valid Item IDs, native Back return and native client rendering:

| Bag / owned types | Notification renders before → after | Item rebuilds before → after | Item render CPU ms before → after |
|---|---:|---:|---:|
| Empty / 1 | 0 → 0 | 0 → 0 | 0 → 0 |
| Item / 1 | 1 → 1 | 6 → 1 | 128.79 → 21.63 |
| Ore / 1 | 1 → 1 | 7 → 2 | 134.06 → 40.31 |
| Mixed / 1 | 1 → 1 | 7 → 2 | 142.37 → 43.98 |
| Item / 90 | 90 → 1 | at least 360 → 1 | 9206.20 → 25.84 |
| Mixed / 90, 0.6s/write + one failure | 90 → 1 | at least 360 → 2 | 9016.98 → 53.01 |

The delayed-save case took **1.949s before / 1.933s after** to resolve the save operation. After repair, Lobby arrival was **53ms**, anchor release **54ms**, and confirmed inventory presentation **2.131s** after return initiation. Thus the saved-item delay remains tied to confirmation; movement is not blocked on that save.

Frame sampling distinguished the long synchronous renderer stall from save wait. An initial 90-type baseline captured 363 rebuilds, 9285.68ms render CPU and a 13505.93ms frame. Matrix baseline snapshots could precede the trailing stalled RenderStepped event, so their frame maxima are not valid proof of smoothness. Post-fix capture waited two render ticks: the 90-type Item case had a 97.86ms maximum; delayed mixed had 108.84ms maximum / 69.81ms p95. Even the empty baseline was ~81ms; these are loaded local Studio measurements, not a target frame-rate or production-latency guarantee.

Additional native tests:
- Held all writes, returned and traversed **3.17 studs using Humanoid MoveTo** while saving; character was unanchored. ItemInventoryState exposed no unconfirmed Items.
- Re-entered immediately with a separate Bag, accepted a second return, then injected a committed-write acknowledgement loss. Both Items and both Ores were granted once, with exactly two bank notifications. Old Run acquisition and return requests were rejected as StaleRun; combat and active Bag IDs matched.
- Fresh Play: three new Item types set their three unseen flags and inventory badge. Marking them seen cleared the flags; returning with those Items again emitted **zero** true unseen-attribute writes and did not restore the badge.

## Changed Studio Full Paths

1. `ServerScriptService.Services.StrengthRewardService`
2. `StarterGui.StrengthGui.StrengthRewardClient`
3. `StarterGui.StrengthGui.InventoryNotificationClient`
4. `StarterGui.StrengthGui.ItemInventoryTabClient`

These are the only production changes. No GUI property, layout, reward amount or tuning Config was changed. Claim processing text lives in StrengthRewardClient; the existing OfflineRewards.Claim.Title is reused. Full sanitized measurements: [evidence.json](evidence.json).

## Verification limits and final state

The native server/client code, actual GUI properties, RemoteFunction responses, Humanoid movement and in-memory durable records were exercised in solo Studio Play. Fixture inventories/rewards, delayed/failing stores, response loss and scripted callback activation are simulations. Physical mouse/touch activation, live DataStore/network performance, actual purchases, public servers, two-client load, and a new raster/UI-layout comparison were not tested. No claim is made that all frame-time spikes or all possible return delays are eliminated. Test setup errors were corrected before the reported assertions; an unavailable Play loadstring attempt is not counted as a passed existing test suite.

Latest Play console contained an existing asset-approval warning for `rbxassetid://139190015780830`; no scoped production script error was observed. The asset was not changed.

All three instrumented Sources were restored, all **39** external-service substitutions were restored, and all temporary helpers were removed. The four final Sources compile and match the Git exports. EnemyManager, CombatClient, World1BossPresentation, Stage01AppearanceClient and RunReturnService match the pre-task Sources exactly, including dd3531e.

Studio is stopped in **Edit**, with changes **unsaved**. No OS input, foregrounding, Save/Publish, rbxl writeback or Studio closure occurred. **The user must manually Save/Publish to update the public game.**

Delivery: this change is committed on top of dd3531e and pushed normally to origin/main; the commit identifier is supplied in the completion message. No force push.
