# Stage02 leg motion verification

These fixtures are temporary Studio-only helpers, not game scripts to publish.

1. Confirm canonical Place126576845524886 is Edit and preserve Source/editor content. Do not stop a user's Play. Use the existing FirstBattleTutorial InstallIsolation/RemoveIsolation scripts with their exact-source guards; this run redirected39 Sources and never used production data/payments.
2. Install a temporary ReplicatedStorage.__Stage2MotionQA Folder, Native.server as ServerScriptService.__Stage2MotionServer and Native.client as StarterPlayerScripts.__Stage2MotionClient. Start an owned Play. Server `Unlock` prepares memory LV8/Strength360 and uses StartRun(2)/wall destruction; `Battle`, `Tap`, `Back` use existing combat/return paths.
3. Client `Amplitude` switches the native config between1 and1.5. `Phase` pauses the Walk at a given time and Idle at0; `Run` restores Speed1. `Side`/`Camera` fix the camera, `HUD` hides/shows screen UI. `FloatHold(true)` holds the current visual-weld value for same-position frozen A/B images ONLY. Release it with false before any normal-play/float measurement. Product code never writes that weld.
4. Run Measure.luau in Client: compares non-leg poses, restoration to1.0, and two193-sample native ranges with floating enabled. Run Loops.luau:21 seconds Speed1, compare exact CFrame components at the same phase. It reports self-comparison angle error separately to avoid mistaking floating-point matrix error for drift.
5. Install Lifecycle.client temporarily in PlayerScripts. Invoke its native Lifecycle BindableFunction for HideShow, Partial, Remember and Previous. Partial detaches/re-attaches one foot Bone: a replication simulation, not natural streaming. Previous checks stopped old tracks as well as current count; destroyed Animator GetPlayingAnimationTracks can still return stale stopped entries.
6. Exercise real Battle/Tap to victory, Back/Unlock to reappearance, inspect rendered movement and console. Fixture setup is not natural progression or physical-device input.
7. Stop only the owned Play, run RemoveIsolation, remove the three Edit QA objects, and verify no QA/memory/backup remains. Do not Save/Publish. Product3 Sources stay in unsaved Edit.

StateMatrix.luau returns a function accepting the exact module Source and Config table. Run in Edit with loadstring; it uses fake frame signals and temporary real Instances outside the DataModel. Expected64 assertions; no rendering/real streaming claim.

[Report, measurements and limitations](../../reports/Stage02LegMotion_20261114/REPORT.md).
