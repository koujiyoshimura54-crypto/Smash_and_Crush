# Loot, return and owned-Item sales — 2026-11-06–07

Canonical Studio: PlaceId **126576845524886**, starting place version **463**. Work began from the live Edit sources and the preceding `ReturnUX_20261106` report, with Git at `ba8aa4b`. Scoped live sources matched that checkout apart from terminal whitespace. Changes were applied to Studio first and exported with baseline guards. The unrelated untracked Visual_Templates report was excluded.

## Behavior and changed Full Paths

| Full Path | Cause and change |
|---|---|
| ServerScriptService.Services.TrophyRewardService | Banking still blocked movement after Win credit. Accepts an immutable return receipt, then travels using the existing streaming/placement path. Existing collection identity prevents repeated Win credit. Starts lobby prefetch when the Trophy is spawned. |
| ServerScriptService.Services.LobbySpawnService | Reuses a recent character/world-specific prefetch. Keeps server floor checks and client pose/floor acknowledgement before release. Requests streaming again if the placed character still lacks acknowledgement after one second. |
| ServerScriptService.Services.RunInventoryService | Accepted receipts now live independently of the active run and character. Both Worlds track provisional Items/Ores. Each acquisition has a server-only identity; Drop removes exactly that latest displayed acquisition. Shown/Close/Drop requests validate run, identity and expiry. |
| ServerScriptService.Services.RunItemBankService | A per-player worker retains accepted snapshots through retries, reset of the active run, death and departure. Existing transaction resolution confirms ownership. Notification state remains filtered until both commitment and lobby arrival. Departure flushes the queue before releasing the data session. |
| ServerScriptService.Services.RunReturnPersistence | Adds an Accepted marker to the existing two-phase journal. Accepted Pending records recover to Granted once; legacy unaccepted records still cancel. The prepare write includes the credited Win snapshot. Terminal transaction identity/sequence checks remain. |
| ServerScriptService.Services.PlayerDataService | Supplies accepted-return metadata to the journal, captures owned/equipped Item snapshots for Forge sales, and reuses the extracted existing Win normalization. No offline reward calculation/configuration change. |
| ServerScriptService.Systems.Controllers.PlayerDataController | Flushes accepted returns before departure saves/session release and during shutdown. A pending return retains its data session instead of losing its in-memory target. |
| ServerScriptService.Services.RunReturnService | Back uses the same retained receipt path in both Worlds. Preserves World2 stage/unlock eligibility and ends the active bag after return. No Trophy/Win credit on Back. |
| ServerScriptService.World.EnemyManager | Both Worlds initialize the shared provisional bag. World2's existing return identity mirrors its bag identity. Combat cadence/damage logic is unchanged. |
| ServerScriptService.Services.EnemyDropGachaService | Removes World2 direct owned-Item grants. Both categories use provisional acquisition records. A new Boss result invalidates the preceding display target even for a miss/full bag. |
| StarterPlayer.StarterPlayerScripts.UI.EnemyDropGachaClient | Replaces the old World2 wheel/queue and two-second cue with one latest acquisition cue in both Worlds. Image loading and timers are generation-fenced. Five seconds starts after rendering. Drop uses the current acquisition only; timeout/replacement never removes loot. Handles run-attribute/result replication order. |
| ReplicatedStorage.Modules.HUDLayout | Places Back and its adjacent Drop button as one occupied group, excluding each other from obstruction checks. |
| ReplicatedStorage.Modules.ItemSale | Derives sale eligibility and half-price from ItemMaster. Robux-only and missing Win prices are rejected. Equipped last copies are excluded from sellable quantities. No price table was introduced. |
| ReplicatedStorage.Modules.WinAmount | Extracts the existing `max(0, floor(value))` SetWin normalization so quoted unit amounts and actual Win accounting share the existing integer rule. |
| ReplicatedStorage.Modules.ForgeInventory | Adds the pure SellItem quantity transaction; checks quoted count/price, stock and equipped last copy. Existing Ore/Dumbbell operations remain. |
| ServerScriptService.Services.ForgeService | Exposes owned/equipped Items in Forge state and routes SellItem through existing session token, generation, sequence, request identity and pending-operation checks. |
| ServerScriptService.Services.ForgePersistence | Persists the Item quantity change and Win delta with the same replay journal. Reconciles owned Items only for an Item sale. |
| ReplicatedStorage.Modules.DumbbellInventoryView | Extracts the existing sale popup construction for reuse. Existing Dumbbell sale appearance/behavior continues to use it. |
| StarterGui.StrengthGui.ItemInventoryTabClient | Adds Sell beside Equip, reuses the Dumbbell popup/button artwork, and supports one/all sellable copies. Uses existing quantity labels. Refreshes after Forge acknowledgement and banked loot. |
| ReplicatedStorage.Modules.ResponsivePanels | Splits the existing owned-Item action row between Equip and Sell and refits the existing button art. |
| ReplicatedStorage.Modules.MergeShopView | Only Item result/candidate cards now use the existing image-star renderer: ranks 1–5 use stars; rank 6+ uses star × rank. Materials, inputs, totals, Pet/Ore presentation and merge arithmetic are unchanged. |

Runtime-only production remote added: `ReplicatedStorage.Remotes.RunDrop` (RemoteFunction). Acquisition identities are not rendered in UI.

## Prices and authority

Win is already an integer currency: loaded values, SetWin and ordinary saves truncate fractions. The existing SetWin operation was extracted unchanged and shared with the unit-price quote. Thus **75 / 2 → 37 Win per copy**; two copies sell for 74 and five for 185. UI and server use the same unit, with no additional aggregate rounding. Purchase prices remain unchanged.

| World | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---|
| 1 sale unit |37|100|300|2,250|Robux-only: rejected|
| 2 sale unit |2,500|7,500|22,500|67,500|No Win purchase price: rejected|

All **nine World2 Legendary definitions** lack WinPrice: `W2_{PROTEIN,GLOVE,TRAININGBELT}_LEGENDARY_{FIRE,ICE,ELECTRIC}`. They are not sold for zero or a guessed value. World1 Legendary is excluded by its definition regardless of acquisition route. Ore unit prices are unchanged: ORE_001 has 5 merge points but sells for 1 Win, so selling two grants 2 Win total. An initial regression assertion confused merge points with the sale unit; the fixture was corrected from the unchanged OreConfig, without changing production prices.

Native isolated sales passed in both Worlds: one copy, remaining surplus, last equipped copy refusal, stale count refusal, negative/fractional quantity refusal, Robux-only refusal and replay without additional Win. Common W1: 5 owned/equipped, sell 1 + 3 → 1 retained and +148 Win. W2 Common: same sequence → +10,000 Win. See `Sales.json`. The existing Forge identity/sequence barrier also rejects obsolete or conflicting requests. Final Ore regression used durable isolated grants and confirmed two Stone sold for 2 Win in each World, with zero replay increment (`OreRegression.json`). A prior in-memory-only fixture lacked durable stock and correctly returned NotEnoughOres; no production correction was needed.

## Return timing

All times below are seconds from positioning the character into the real Trophy pad. The production touch/overlap handler and prepared server-owned defeated state perform collection. Qualification columns in raw JSON bracket the reward/pass lookup after initial eligibility checks; they are not a measurement of every individual predicate. Move measures MoveToLobby completion. Control measures the root being released after the actual client's pose/floor acknowledgement. These are native solo Play timings with memory persistence, not production DataStore latency or OS-input latency.

| Source / World / injected per-write delay | Win credit | Save end | Move | Control |
|---|---:|---:|---:|---:|
| Before W1 / 0 |0.08145|0.08178|0.09885|0.15219|
| After W1 / 0 |0.00048|0.00092|0.00546|0.06123|
| Before W2 / 0 |0.00029|no bank|0.05506|0.22110|
| After W2 / 0 |0.12744|0.12855|0.12812|0.18700|
| Before W1 / 0.6 s |0.00079|1.21233|1.21266|1.24351|
| After W1 / 0.6 s |0.00038|1.22157|0.08622|0.26084|
| Before W2 / 0.6 s |0.00817|no bank|0.13601|0.17878|
| After W2 / 0.6 s |0.00556|1.25578|0.00624|0.03991|

W1's matched delayed trial removes about **0.98 seconds** from control restoration. World2 now banks loot safely without putting its new persistence work on the travel path. In both delayed after trials, owned Item delta was zero at control restoration and exactly one after banking. Trophy Win deltas were 1 and 3,000 respectively. Contact recognition/streaming/acknowledgement vary; single samples are not a performance distribution.

`Before.json`, `BeforeDelayed.json` and `After.json` retain the separate qualification, reward, freeze, bank, streaming, movement and control timestamps. A later native client probe confirmed WalkSpeed 24, unanchored state and **5.78 studs of simulated Humanoid movement over 0.35 seconds** after arrival; no OS keyboard/mouse was used.

## Persistence, notifications and Drop

- Native failure test: two precommit failures plus one lost acknowledgement, accepted-return replay and death during banking produced exactly one owned Item. The death latch reported zero lost loot for that already accepted return. Accepted receipt was retired only after confirmation.
- Pure journal recovery test: repeated recovery of one Accepted Pending record changed owned count 2 → 3 once and retained the credited Win snapshot 21. This is a simulated reacquisition transition, not a second live player login.
- Native departure test: an isolated player was kicked with a delayed write/lost acknowledgement outstanding. Saved Item delta was one, journal Granted, and the session was released after completion. See `Departure.json`.
- Native Back returned both Worlds with +1 owned Item, zero Win, inactive bag and released root. See `Back.json`.
- Native server drop pipeline, using real random rolls and prepared defeat state: W1 Ore and W2 Item entered the bag while owned inventory delta stayed zero. See `DropPipeline.json`.
- Direct server adversarial Drop tests in both Worlds retained an earlier identical copy, rejected old/replayed/closed requests, changed owned inventory by zero and granted zero Win. Close left the Ore in the bag.
- Native notification snapshot test: after ownership committed but before arrival, the new Item count was **0** in notification state; after client-confirmed arrival it was **1**. Older inventory is filtered independently by the existing implementation. See `Notification.json`.
- Native cue lifetime samples were approximately **5.02–5.09 seconds**. A replacement closed the preceding cue after 1.93 seconds; the replacement survived the old timer and lasted 5.02 seconds. No deletion occurs on timeout/replacement. See `CueTiming.json`.

## Actual images versus simulated checks

Actual Play images were inspected for: W1 unit 37 / five-copy total 185; W1 unit 100 with sale acknowledgement updating its total; W2 unit 2.5K / equipped surplus total 10K; result ★3 and ★×6 with material points retained; Item/Ore overhead cue; Ore `5 pt` without ×1; and Back/Drop side by side in both Boss areas. The buttons measured 85 × 48 pixels with approximately 9.5 pixels between their rectangles in the desktop viewport.

The MCP viewport capture omitted the local BillboardGui layer, so actual native window captures were used to inspect those cues and the Back/Drop pair. Captures were temporary and are not committed. UI sale actions were dispatched through temporary local callback probes, not physical mouse clicks. A constrained-width cloned popup was also inspected, but this is **not** a device-emulator or narrow-screen end-to-end certification. No claim is made that touch hardware was exercised.

## Offline reward audit — no reward/configuration change

MaxSeconds remains **3,600**; Efficiency remains **0.05**; DecayBands remains empty. The audit used the real departure snapshot, save/checkpoint code, acquisition transition, service quote and claim persistence against isolated memory data. Only elapsed timestamps/login ownership were fixture inputs. Claims measured both before/after Strength and durable GrantedTotal/EarnedTotal deltas; the current Strength value alone was never used to infer a reward.

The reference selects the best accessible treadmill across eligible Worlds, including durable World2 visit history. Baseline selected World2 treadmill `01`, multiplier 5, yielding Rate **10**. An equipment fixture selected the same treadmill with Dumbbell +1, effective Protein +300 and effective Belt +4.5, Rebirth/VIP/Pet = 1 and no temporary potion effects. Rate was **5,738**, matching `(1 + 1 + 300) × (5 + 4.5) / 0.5`. The Fire set's existing 1.5 effect was applied to the Item inputs (200 → 300; 3 → 4.5), with no second whole-result element multiplier.

| Saved Rate | Elapsed | Capped seconds | Expected normal | Quoted / actual normal increment | Mock paid ×2 increment |
|---:|---:|---:|---:|---:|---:|
|10|600|600|300|300 / 300|600|
|10|3,600|3,600|1,800|1,800 / 1,800|3,600|
|10|7,200|3,600|1,800|1,800 / 1,800|3,600|
|5,738|600|600|172,140|172,140 / 172,140|344,280|
|5,738|3,600|3,600|1,032,840|1,032,840 / 1,032,840|2,065,680|
|5,738|7,200|3,600|1,032,840|1,032,840 / 1,032,840|2,065,680|

The actual client Amount label read **`+172K STRENGTH`** for 172,140, using the existing abbreviated formatter. Raw quotes and grants agree; abbreviation is not a reduced grant. Ordinary claims and repeated claims used the real request service. Paid ×2 used the real immutable intent/receipt state and persistence with synthetic receipt IDs, **without Marketplace checkout or a real purchase**. Replaying receipts added zero.

An old saved Rate fixture (30 instead of 10) produced 900 for 600 seconds: acquisition intentionally uses the departure snapshot, not today's equipment. Online checkpoints generated no offline reward. Reacquiring the same owner is idempotent; old free rewards are replaced on a new login, with bound paid intents retained. No mismatch was found in these cases, so no reward code or setting was changed. See `OfflineBasic.json` and `OfflineEquipped.json`.

## Preservation, limitations and completion

- The initial 486 Source containers were preserved; 19 existing sources changed and two modules were added. Unrelated sources, Egg prices, attack cadence, Belt edits, prior death UI, carpet arrows and Rebirth UI were not rewritten. These previous UI fixes were preserved by source/property scope, not re-certified visually in this task.
- No real DataStore player record, real payment or published place version was used for the fixtures. Marketplace/Badge/Policy/Messaging/DataStore calls were isolated. All shipping sources were restored after Play and compared against the intended production snapshot.
- Live production network latency, multi-client hardware input, real paid receipts, mixed-version server rollout and an abrupt process loss before any successful durable write were not exercised. A permanently unavailable backend beyond Roblox's shutdown deadline cannot be certified by the memory tests.
- Existing unrelated asset authorization/missing-asset warnings appeared. Two temporary probe mistakes (wrong Merge root and absent PlayerModule) and a frozen test roller assignment were corrected/replaced; these probes are not shipped. The final production paths compiled successfully and Git whitespace checks passed.
- Save and Git completion evidence is recorded below after the final cleanup/save operation.

## Save / Git result

After the last isolated Play, all 39 service substitutions were restored and the memory module/probes were removed. Final Edit audit: 488 Source containers, 467 unchanged original Sources, 19 intentional existing-source changes and two new modules; zero unexpected Sources, helper markers or Enabled differences. HTTP, Edit camera and focus match the initial baseline. A subsequently observed Play session was stopped before the final audit and Save; no fixtures were run against it.

The native **Save to Roblox** command (`RBXMainWindow.savePlaceToRobloxAction`) was invoked through UI Automation without mouse/keyboard input. Studio's status bar confirmed that the new changes to **マージして強さを鍛造する** were saved to Roblox. Destination is the existing canonical cloud place **126576845524886**, not a new file/place. The loaded PlaceVersion remained463; this is not claimed as a new published version. **Save succeeded. No Publish, rbxl writeback or Studio close was performed.** Play is stopped and the viewport is Edit.

All21 changed/new sources compiled; Git whitespace checks passed. The delivery commit includes these sources, this report/evidence and the five relevant specification/status documents. Normal push destination is `origin/main`; unrelated untracked material is excluded. The final response supplies the delivered commit ID and push verification.
