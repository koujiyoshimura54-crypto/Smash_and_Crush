# Stage01Motion focused verification

Production changes are three Sources only. These fixtures are for temporary Studio testing; do not publish or leave them installed.

## Pure frame-boundary matrix

In Studio Edit, evaluate `StateMatrix.luau` with `loadstring`, then invoke the returned function with `ReplicatedStorage.Modules.Stage01Motion.Source` and the Config table. It evaluates the exact module with fake PreAnimation/PreSimulation signals and real temporary Instances outside the DataModel. Ground raycasting is disabled for this matrix; real ground behavior is checked in isolated Play. Expected: 43 assertions. No real streaming/render claim.

## Native isolated Play

1. Verify Place126576845524886 is Edit and preserve existing Source/editor content. Never stop a user's Play. Install the existing `tests/FirstBattleTutorial/InstallIsolation.luau` only after confirming its external-service coverage; this run redirected 39 Sources.
2. Create a temporary `ReplicatedStorage.__Stage1MotionQA` Folder. Install `Native.server.luau` as `ServerScriptService.__Stage1MotionServer` and `Native.client.luau` as `StarterPlayer.StarterPlayerScripts.__Stage1MotionClient`. Both require the memory fixture and Studio. Start an owned Play; do not Save/Publish.
3. Invoke the native `__Stage1MotionQA.Server` BindableFunction: `Unlock` prepares memory LV4/Strength40 and destroys the wall through the existing path, `Battle` positions the character at the boss, `Tap` uses the accepted manual-attack path, and `Back` calls RunReturn. These are automated fixtures, not natural progress or physical input.
4. Client BindableFunction actions: `Amplitude` (1/2), `Ground` (false/true), `Side`/`Camera`, `Phase` (pause at a Walk time, Idle time0), `Run` (restore both Speed1), `HUD` (temporary visibility), `Inspect`, `Sample` (seconds). Keep the same camera for A/B. `Sample` uses PostSimulation, after the correction. Aggregate large samples inside Luau; avoid large StringValues or truncated tool responses.
5. Observe rendered poses and ground contact. Compare original1/false with final2/true at the same phase; separately use Speed1 for period/range/loop tests. Numeric amplitude comparison uses Ground=true for both1/2. Observe combat, defeat and return/reappearance; confirm exactly two tracks at Speed1. Check console.
6. Stop only the owned Play. Run `RemoveIsolation.luau`, whose exact-current-source assertions protect edits. Remove only the three named QA objects. Verify the production3 Sources/editor buffers against local files and that EnemyManager/Binding/World1BossConfig are unchanged. Confirm no QA/memory/backup objects remain. Leave unsaved Edit; no Save/Publish.

The final run passed the43-assertion matrix, native range/12-loop checks and rendered battle/reappearance. See the [report](../../reports/Stage01Motion_20261114/REPORT.md) for numeric evidence, render-stall observations and limits.
