# Single-owner automatic Player combat — 2026-11-04

## Result

Implemented in the current unsaved Y02 Studio, PlaceId **126576845524886**, UniverseId10765181857. The pre-task Studio Sources matched repository commit d8742fc for all eight scoped files. Existing unsaved edits, the Belt repair and Hover.Volume0.15 were preserved. This is the newly authorized combat/cadence change; it does not reinterpret the earlier unreproduced0.2s report as a proven defect.

Only three production Full Paths changed:

| Full Path | Change |
|---|---|
| ReplicatedStorage.Config.AutoTapConfig | CombatAutoInterval0.8, AfterManualDelay0.5, ordinary AutoInterval0.5; shared MinimumInterval0.2 and manual animation speed2 retained. |
| ServerScriptService.Services.PlayerActionTiming | Retains one per-Player successful-action clock and next-auto deadline. Records combat Auto +0.8, walking Auto +0.5, manual success +0.5. Removes the delayed ticket scheduler/cancel callbacks. Run/context resets rearm the deadline without clearing the shared minimum clock. |
| ServerScriptService.World.EnemyManager | Heartbeat-routed Auto is immediate when due. Its0.1s monitor invokes contact/session maintenance with an explicit observation-only request and cannot start an attack. Removes windup reservations/Pending bookkeeping; validates target/contact/life/session/generation at execution, commits damage, then sends one punch notification per success. |

## Structure before and after

Before: TrainingController.Heartbeat → AutoTapService → EnemyManager, and EnemyManager's0.1s monitor → the same automatic dispatch. Both could request one shared delayed ticket. CombatAttack/animation was announced when the ticket was reserved, even if a manual action later canceled that ticket.

After: **TrainingController.Heartbeat → AutoTapService.TryAutomatic is the sole automatic update owner.** It checks the shared deadline, routes to one eligible current target or ordinary walking Strength, and returns. EnemyManager's0.1s loop still maintains contact, challenge state, pursuit-related transitions and Boss combat/session initialization, but performs no Player attack. There is no task.delay, queued hit closure or catch-up loop in PlayerActionTiming.

Manual input continues through AutoTapClient's original tap closure → AutoTapRequest → AutoTapService.HandleTap while Auto is ON or OFF. Both manual and automatic success require the previous success to be at least0.2s ago. Rejections do not record success or move the deadline. The currently successful action supplies the new deadline from the current time; missed periods are discarded.

Wall and Boss damage routines retain their existing arithmetic, contact volumes, owner/run/spawn validation and progression. Automatic damage is committed synchronously after validation. CombatAttack is emitted only after successful HP reduction and before result/clear notifications. The client renderer, punch assets, speed/priority calculation and punch SoundId were not modified. Walking retains its existing grounded/Running movement predicate; treadmill and Boss-to-Player code is unchanged.

## Actual solo measurements

Fixture: ordinary Studio solo Play, prepared memory-only Stage1 wall/Boss encounters in each World. Four OFF/ON cycles use the original Toggle closure/Remote. Four manual taps use the original input closure; rapid additional Remote taps intentionally test server refusal. After manual input stops, the avatar remains in contact. Values below are actual successful HP reductions, not animation intervals.

| World / target | Fresh Auto gap | Manual → first Auto | Next Auto | Following Auto | Router pause/resume → next gap | HP successes / notifications / Track plays / punch sound plays |
|---|---:|---:|---:|---:|---:|---:|
| W1 wall |0.810386|0.502197|0.815545|0.800109|0.816739|13 /13 /13 /13|
| W1 Boss |0.817422|0.516599|0.800566|0.800344|0.816786|13 /13 /13 /13|
| W2 wall |0.800092|0.500477|0.817086|0.815861|0.815679|13 /13 /13 /13|
| W2 Boss |0.816511|0.500985|0.816717|0.800263|0.816455|13 /13 /13 /13|

The small positive overhead is Studio frame scheduling. Success snapshots set the next deadline by exactly the configured offset.

A final boundary audit removed the legacy deadline rewrite on Auto permission changes: OFF/ON preserves the deadline set by the last success. Lifecycle/run rearming uses the later of the existing deadline and the normal context-start time. [ToggleBoundary.json](ToggleBoundary.json) passed8 focused assertions over both Worlds' wall/Boss cases on this final version. Measured toggle gaps were0.832393/0.807980/0.917706/0.866132s; none shortened the0.8s deadline. Higher transient delay includes frame/Remote scheduling. An earlier boundary fixture incorrectly sampled only after its toggle helper returned and imposed an upper bound across OFF/network wait; it reported1.0415/1.1446s. The corrected fixture marks before toggling and checks the committed deadline and first actual success.

The main cadence/playback matrix was measured before this final permission/deadline-only correction; the final targeted run covers that correction. Ordinary successful-action interval selection, contact/damage logic and presentation code did not change between those runs.

The earlier d8742fc baseline measured approximately0.500–0.518s automatic combat and0.301–0.317s manual-to-auto. Those historical before measurements are in reports/AutoBelt_20261104; they were not rerun as a separate baseline Play in this task.

Other measured checks:
- Automatic routing was paused for1.85s while the0.1s monitor continued. No HP reduction or clock advancement occurred. Resuming produced one hit, no catch-up burst, then the normal0.8s gap.
- OFF and separated contact produced no delayed attacks. Boss-arena separation retained the encounter but rejected taps without moving either clock.
- Rapid requests approximately0.013–0.067s after a success were refused with Cooldown and unchanged Last/NextAuto. Successful manual bursts remained available at approximately0.2s spacing.
- Both Worlds passed death → respawn → new fight, lethal ordinary manual hit → defeat → retry. No old encounter hit appeared after death/defeat.
- Each World produced six actual walking awards of1 Strength with gaps **W1:0.500805–0.517786s**, **W2:0.500357–0.517114s**. Stationary Auto, stationary time after manual, stopped movement and walking with Auto OFF awarded zero. Stationary manual and successive manual Strength requests retained the0.2s minimum.

## Observation and test corrections

[Attempt1.json](Attempt1.json) contains the first solo run. Boss cadence/notification counts and both Worlds' death/defeat/retry passed. Four fixture assertions failed, and this run is **not labeled a complete pass**:
1. The wall separation fixture tapped after leaving combat. That is a valid ordinary manual Strength input under the retained game rules, not an invalid wall attack. The corrected fixture measures automatic no-contact behavior without inventing a prohibition on normal manual training.
2. Client Humanoid.Move changed MoveDirection but produced no physical displacement in this solo network-ownership state. The corrected fixture used server-owned Humanoid movement through the normal physics controller. A diagnostic move displaced22.228 studs in1.2s; no Strength function was directly invoked.

[CorrectedSolo.json](CorrectedSolo.json) reran only the previously failed wall/walking cases in both Worlds, passing all96 checks. The first run had114 passing and4 failed assertions; the final validated case coverage combines its successful Boss/retry cases with the corrected wall/walking cases. There were **210 passing assertions across those runs**, not210 independent scenarios. [Summary.json](Summary.json) holds the accepted measurement table.

Actual AnimationTrack.Play and Sound.Play calls were observed in both World renderer mounts, with Track speed/length/playing state and Sound.IsPlaying recorded separately from server HP time. The four accepted combat samples each matched13 successful HP changes,13 notifications,13 Track starts and13 sound plays. No speculative windup-only notification remained. This verifies calls/runtime playback state; actual human listening is unverified.

One actual existing-viewport capture was inspected during server-controlled walking. It shows the avatar/HUD in solo Play, but is not video proof of attack intervals. Screens were temporary/in-memory and are not committed. Physical mouse/keyboard/touch input, public-server latency, every other Stage, production saves/rejoin and human audio listening were not tested. There was no OS input or camera/window/device-preview manipulation.

## Isolation, reproducibility and cleanup

Persistence, Marketplace, badges, policy and messaging references were redirected to the existing temporary memory/stub provider before Play. No production data access/write or real payment. Target strength, avatar positioning, high test health, wall clearing to prepare Boss contact, and one-hit Boss HP were isolated fixture setup; actual measurements use normal action Remotes and game damage/gain functions.

Test Sources: tests/CombatAutoSingleOwner.server.luau and .client.luau. They require temporary read-only timing/contact probes and BindableFunctions invoking the original client tap/toggle closures. CombatClient probes observe each World mount's actual selected Track.Play and punch Sound.Play. The RecordSuccess observer forwards the combat-kind argument unchanged. The router pause wraps only AutoTapService.TryAutomatic, so the unmodified monitor remains live. These helpers are not shipped in the Studio Edit document.

Removed three authored test fixtures and restored43 temporary Source substitutions. Verified all486 baseline LuaSourceContainers against starting unsaved Source plus the three intentional patches, all recorded Script Enabled values, no extra Sources, unchanged Edit camera CFrame/Focus and HTTP setting, unchanged Belt HUD Source and Hover.Volume0.15. Treadmill, Boss-to-Player and client renderer Sources match their exact pre-task versions. Existing imported-asset warnings remain outside this change; no game runtime error was found in the completed cases.

Final state: **Play stopped; focused Edit; Studio unsaved.** No Save/Publish, rbxl writeback, Studio close or test-mode/window setting change. The user must manually Save/Publish.
