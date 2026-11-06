# Return, loot notification and presentation fixes — 2026-11-06

Applied to the **current unsaved canonical Studio**, PlaceId **126576845524886**, place version457. The initial state was Edit;487 LuaSourceContainers were captured before any change. Scoped source exports matched the checkout apart from terminal whitespace. Existing combat cadence, Belt/HUD, user tuning and Egg prices were retained. The unrelated untracked Visual_Templates_Secret_VIP_Green_20260917.md was excluded.

## Changed Full Paths and causes

| Full Path | Cause and final change |
|---|---|
| ServerScriptService.Services.TrophyRewardService | Durable banking and lobby streaming ran serially. Starts the existing StreamLobby request while banking runs; awaits both before movement/reset. Keeps the existing collected receipt, Banked flag, current-character validation and retry cooldown. Reuses a valid finished stream on retry. Exceptions cannot strand an unfinished stream job. |
| ServerScriptService.Services.LobbySpawnService | Exposes Arrived only after the existing client pose/floor acknowledgement is validated and the root is released. Marks only MoveToLobby requests as Lobby arrivals; StageSkip acknowledgement cannot release loot notifications. Existing floor checks, streaming, placement and respawn timing remain. |
| ServerScriptService.Services.RunItemBankService | Tracks each return's notification separately from ownership, including its reset token. Filters only confirmed-but-not-arrived additions from the notification snapshot; older owned items remain eligible. Releases after Arrived. A terminal journal callback also covers an ambiguous write later resolved through death. |
| ServerScriptService.Services.RunReturnPersistence | Invokes the optional return-context OnResolved callback after terminal resolution, ownership synchronization and unlocking. Pending→Granted writes, ownership fencing, journal IDs/sequences and idempotence are unchanged. |
| ServerScriptService.Services.RunInventoryService | DiscardOnDeath latches the bag before invalidation on the dying character. Pending writes settle through the existing resolver before publishing BattleBagLostCount; already Granted loot reports zero loss. A character latch prevents repeated death handling. |
| ServerScriptService.World.EnemyManager | The existing death observer calls DiscardOnDeath instead of clearing the bag without preserving the result. No combat/cadence/damage change. |
| StarterGui.StrengthGui.InventoryNotificationClient | EnemyDropGachaResult previously called acquired for unbanked World1 Items. Excludes provisional results; uses the filtered server snapshot and arrival event. Confirmed ownership is merged idempotently; existing seen history and purchase/direct World2 notification paths remain. |
| StarterPlayer.StarterPlayerScripts.World.SpawnFacingCameraClient | Existing death presentation reads the dying character's server loss result, including late replication. Shows LootLoss only for a positive actual loss. Camera latch, respawn conditions and display duration are unchanged. |
| StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient | Yellow Lower surfaces were already registered, but the whole-chevron flatness test allowed only0.08 stud. Red top4.400014 versus yellow top4.212015 differs by0.188 stud; outer samples can also cross to the structural floor. Only explicitly registered carpets may bridge a step up to0.45 stud to another approved walking surface. Raises the whole chevron above its highest support sample. Equipment/wall obstruction tests remain. |
| StarterGui.StrengthGui.RebirthMenuClient | Replaces the duplicated requirement/current-level sentence with Required Level: N. MAX and all card/gauge/button conditions remain. |
| StarterGui.StrengthGui.RebirthPanel.RebirthProgress | FredokaOne; text size32, scaled with18–32 constraint; size0.9×0.09 of the panel. Original position retained. Added RequiredLevelTextSize constraint. |
| StarterGui.DeathGui.Overlay.LootLoss | One authored clone of the existing Message style: You lost your loot. Hidden by default, at position(0.5,0.63), size(0.75,0.04),16–26 text constraint. Existing Message remains YOU DIED. |

Runtime-only service outputs: ReplicatedStorage.Remotes.RunLootBanked (RemoteEvent) and BankedItemNotificationState (RemoteFunction); character BattleBagDeathPending/BattleBagDeathResolved/BattleBagLostCount attributes. They are recreated by production code, not QA fixtures.

**Ore scope:** the current standalone acquisition-exclamation renderer handles Items, not Ores. ORE results already cannot enter acquired. No new Ore exclamation category was invented and no completed Ore/tutorial highlight was changed. Mixed Item+Ore bags were tested for bank/loss; owned Ore and its existing Forge revision path remain server-confirmed. World2 retains its existing direct inventory grants; it has no World1 provisional bag.

## Timing evidence

[Measurements.json](Measurements.json) contains all raw accepted timestamps. Contact denotes fixture positioning into the real pad followed by its actual overlap/touch handler. Credit, Bank, Stream and Move instrument the original service calls; Controllable observes the server root after the actual client placement acknowledgement. These are native solo Play measurements with memory persistence, not production DataStore timings or physical input latency.

Representative matched-source matrix, seconds after contact setup:

| Source / World / latency | Win credit end | Bank start→end | Stream start→end | Move complete | Controllable |
|---|---:|---|---|---:|---:|
| Before W1 / memory |0.367277|0.367308→0.367552|0.367554→0.371128|0.371410|0.422247|
| After W1 / memory |0.000285|0.000387→0.000559|0.000304→0.005728|0.007574|0.155484|
| Before W2 / memory |1.365341|not applicable|1.365358→1.409424|1.409960|1.468522|
| After W2 / memory |0.096325|not applicable|0.096331→0.133757|0.135593|0.444436|
| Before W1 / injected wait |0.053258|0.053286→0.459506|0.459509→0.820346|0.820746|0.871435|
| After W1 / injected wait |0.001522|0.001548→0.413690|0.001544→0.412830|0.413960|0.533050|
| Before W2 / injected wait |1.174877|not applicable|1.174891→1.495522|1.495982|1.545472|
| After W2 / injected wait |0.073094|not applicable|0.073107→0.416077|0.417360|0.709132|

The injected test waits0.4s at banking and0.3s at streaming while still executing the real functions; it does not model measured production latency. W1 credit→movement improved0.767488→0.412438s, demonstrating overlap without removing either persistence confirmation. W2 has no bank to overlap. Contact recognition, streaming and client acknowledgement vary substantially; these single samples are not a population speed benchmark. The first pre-change run also measured W1 total0.036708s and W2 total0.440157s in the warm memory fixture.

The timing matrix uses isolated before/after Trophy module instances with controlled defeated qualification. A subsequent test used the **normally initialized production Trophy service**, normal pad collection and server-owned prepared defeated state:

| World/case | Win delta | Item delta | Bag after | Contact→controllable |
|---|---:|---:|---:|---:|
| W1, mixed bag |1|1|0|0.087357s|
| W2, existing direct-grant design |3000|0|0|0.301267s|
| W1, first banking response lost |1|1|0|1.154341s|

The failure case made two bank attempts, retained the single Win credit and awarded the Item once. Its roughly1s additional delay is the preserved retry cooldown.

## Native Play assertions and actual images

- Provisional Item+Stone bag:2 units, owned Item0, no Item badge attributes. After durable banking: bag0, owned Item1, still no badge. After validated Lobby arrival/root release: unseen Item and menu badge true.
- Resending the confirmed snapshot twice kept one keyed badge state. Previously unseen banked Items remained when a subsequent bag was lost; a separately confirmed direct Item grant also remained visible.
- Lost response after Prepare: owned0/bag2, no notification. Normal retry succeeded with owned1/bag0; another Commit returned StaleRun with owned still1. No notification until arrival.
- Lost response after Grant followed by death: terminal journal resolution recovered ownership; actual lost count0 and no loot-loss subtitle. The recovered Item became unseen after respawn's Lobby acknowledgement.
- Lost response after Prepare followed by death: actual loss2; subtitle visible; the lost Item was absent from notification attributes. Earlier unseen Items remained.
- Mixed bag death: server loss2, bag0; actual image shows YOU DIED and You lost your loot. Empty bag death: loss0; actual image shows only YOU DIED. World2 empty death was also captured.
- An additional live World1 BossAttack encounter, prepared with one Stone and test health1, killed the avatar through the original attack loop. Server loss1 and normal death/respawn completed. This is native combat/state evidence; its exact death frame was not separately captured.
- Red/yellow ray samples at x293.9,294.25,294.5,294.8,295.1,295.7 all passed on the actual PathToRun. A temporary tall collidable obstacle over the same yellow point failed support, preserving obstruction. Actual image shows continuous chevrons along the yellow edge and across the red/yellow boundary.
- Actual normal Rebirth image: Required Level: 10, FredokaOne; native label474.858×31.440, text227×31, TextFits true. Actual350px panel fixture: label315×20.856, text149×20, TextFits true. Additional25/10000 string fit checks passed. MAX retained full gauge and inactive button under a client-only cap fixture.
- The narrow screenshot uses a cloned in-game panel at350px width, **not** Studio device emulation or a real phone. Pixel captures were inspected transiently and are not committed.

Test preparation changed only isolated runtime state: world selection, prepared defeats, bag contents, position, test health and memory-store failures. It did not complete natural progression or test real payments, production saves, public-server network latency, physical input, all Stages or actual mobile devices. Initial tutorial start/completion, guide targets and completed highlight/notification renderers were not modified.

Fixture corrections are not counted as production failures: the initial timing fixture used nonexistent ItemMaster.GetSorted; it was corrected to GetAll. An initial mixed before/production-instance timing run timed out after lifecycle changes cleared its prepared record; matched module fixtures were used for timing, followed by the successful normally initialized production-service tests above. Two immediate World setup calls lost their placement request during lifecycle/world transitions; subsequent normal Trophy collection in each World passed. No error is omitted from a claimed all-pass count; no aggregate assertion count is claimed.

## Reproduction and cleanup

QA files: tests/ReturnUXTiming.server.luau, ReturnUXCommands.server.luau, ReturnUXNativeTrophy.server.luau and ReturnUXBossDeath.server.luau. Install only in an isolated Play; they are not part of the authored Studio. Timing needs memory/stub service substitutions, __BeforeTrophy from the pre-change source and __AfterTrophy from the current source. The command fixture supports prepared bag/bank/arrival/death, response-loss and replay checks. [ApplyReturnUXProperties.luau](../../tools/ApplyReturnUXProperties.luau) records only the authored GUI changes.

Before each Play, DataStore/Marketplace/Badge/Policy/Messaging references were redirected to temporary memory/stub dependencies. No production persistence or payments were used. The final console contained the expected injected InventorySavePending diagnostic and existing imported asset permission warnings; no new production runtime exception was observed in completed cases.

Removed authored QA modules, restored40 temporary source substitutions/probes, and verified487 Sources with exactly the10 intentional changes above. No unexpected source remained; original Script Enabled values, Edit camera CFrame/Focus and HTTP=false matched the baseline. All **477 unchanged Sources** remained identical, including combat cadence, Belt, Egg configuration and existing tutorial/renderers outside the scoped guide. The10 production Sources and four test fixtures compile; git diff --check passes.

Final Studio state: **Play stopped; viewport focused Edit; unsaved changes retained.** No Save, Publish, rbxl writeback, Studio closure or OS mouse/keyboard input occurred. Saving and publishing remain the user's manual responsibility.
