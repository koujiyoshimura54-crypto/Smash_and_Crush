# Restore the original walking condition — 2026-11-03

Correction to ad907b3. The agent incorrectly interpreted automatic continuation as permission to grant ordinary training Strength while stationary. The user did not authorize removing the existing walking requirement. This correction restores it without reverting manual input while Auto is enabled or the shared success clock.

Changed production Full Path: **ServerScriptService.Services.AutoTapService**.

The automatic ordinary-training fallback now uses the exact former TrainingController predicate: Humanoid Running or RunningNoPhysics, plus MoveDirection magnitude >0.05 or horizontal assembly velocity >0.5. The check runs after existing combat routing and only for automatic ordinary training. Stationary manual taps and wall/Boss attacks are unaffected. Returning NotWalking does not record success or move the next-auto deadline; missed idle time is not awarded in a batch.

PlayerActionTiming, AutoTapConfig, EnemyManager, input LocalScript, training/treadmill loop and all gain/damage formulas remain unchanged from the preceding fix. The0.2s shared minimum and0.3/0.5s rescheduling remain. The previous Dumbbell Lobby correction and other unsaved work are retained.

## Native isolated Play

Used the existing two-client test harness, exercising one avatar in both Worlds while the peer stayed idle. Persistence, payment, badge, policy and messaging dependencies were redirected to memory/stubs. Movement used real Humanoid input/physics; manual tests used the ordinary AutoTapRequest Remote. No OS input, production data changes or real purchases.

| Case | W1 actual Strength delta | W2 actual Strength delta |
|---|---:|---:|
| Stationary, Auto ON,1.1s | 0 | 0 |
| Stationary manual, Auto ON | 1 | 1 |
| Remain stationary after manual,.7s | 0 | 0 |
| Actually walk, Auto ON,1.3s plus settling | 3 | 3 |
| Stop after walking,.7s | 0 | 0 |
| Actually walk, Auto OFF | 0 | 0 |
| Stationary manual, Auto OFF | 1 | 1 |

Both Worlds also dealt two real stationary automatic wall hits over1.25s, proving that the movement gate does not suppress already-routed combat. Wall test Strength was prepared separately; it is not evidence of a training award.

18 targeted checks passed. Boss contacts, all previous cadence permutations, physical mouse/touch operation and production saves were not rerun: their code did not change. The earlier AutoManualCadence record retains its historical measurements with a prominent correction; its stationary-training fixture assumptions are superseded by tests/AutoWalkingGate.server.luau and .client.luau.

## Cleanup

Removed all helpers and memory patches.476 pre-test Sources/Enabled states and74 SoundIds matched the post-correction baseline. The edited Source compiles and matches Git; PlayerActionTiming is unchanged. Canonical Place126576845524886 is stopped in Edit with unsaved changes. No Save, Publish, rbxl write, user Studio shutdown, camera/device-preview change or OS GUI input. The user must manually Save/Publish.
