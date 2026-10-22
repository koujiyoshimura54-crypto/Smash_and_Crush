# World2 four-boss production walking — 2026-10-22

## Scope and approved baseline

The owner approved the current file, including additional HUD/Strength/Win, death-camera and attack-angle 160/210 edits. Input: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, SHA-256 `f4850f737eddeb0ecf6aae87e3b0be396daf35f06a3eb2ca3f89d6654023165f`, 192,558 instances. Git HEAD and fetched origin/main were `a1c8285`. The place was not replaced with a historical copy or with the Git source tree.

Only the seven Sources listed below, the approved anatomical joint changes and a preparation-version attribute on the four templates were written. Existing 096 corrections, 035/106/323 walking, 049 intro/black thighs, combat, speed/turn tuning, equipment, UI, map, manual edits and player data were preserved. 682 remains outside this implementation.

## Implemented motion

| Stage / Boss | Production definition | Joint work | Cycle at reference speed / amplitude |
|---|---|---|---|
| 2 / SCP-023 | Recovered large aligned gait refined into diagonal stance/swing pairs | Existing four shoulder/hip anchors aligned to limb tops and torso axes; six motors retained | 1.00 s at 19 studs/s; ±0.70 radians; stance 60% |
| 4 / SCP-058 | Four visible two-segment legs, two-bone IK with alternating lift/advance | Eight anatomical hip/knee motors plus root/body motor; nine conflicting ManualWelds removed; fixed decorations retained | 0.75 s at 21; stride ±1.05 × model scale, lift 0.55 × scale; stance 62% |
| 6 / SCP-173 | Opposed arm/leg swing on existing composite limb groups | Five motors for torso and four limbs; 48 existing welds retargeted inside groups; five obsolete root welds removed | 0.80 s at 23; legs ±0.70, arms ±0.95 radians; stance 60% |
| 7 / SCP-939 | Existing `AnimSaves.939walk`, sampled directly with rotational swing ×1.35 | Thirteen original motors and saved clip retained | 1.00 s at 24; original clip timing normalized to the configured cycle |

All definitions include bounded ground correction, movement-dependent cadence, and fade to the authored rest pose. Every authored part CFrame, size, color and transparency was asserted unchanged during rig construction. Model sizes, collision/attack geometry, HP, damage, rewards and Stage speeds/turn responses were not changed.

Production has no Studio Preview dependency and does not need a newly uploaded animation asset. Each personal actor has one cached gait record; visible joints have one writer, with no Animator tracks for these four. A single existing client update connection uses the server's measured `BossMotionSpeed`, including return travel. Contact/home stops fade to rest. Removing an actor or changing World releases its state; new generations receive fresh phases and bindings. No imported AI/attack/death scripts were enabled.

## Changed Full Paths

- `ReplicatedStorage.Config.World2BossAnimationConfig`
- `ReplicatedStorage.Modules.World2BossRig`
- `ReplicatedStorage.Modules.World2BossGaitRig` (new)
- `ReplicatedStorage.Modules.World2BossGait` (new)
- `StarterPlayer.StarterPlayerScripts.World2BossAnimationClient`
- `ServerScriptService.StudioBossAnimationPreview`
- `StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview`
- `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP023_Display.Torso` — existing hip/shoulder C0/C1 only.
- `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP058_Display.Targeter.HumanoidRootPart` — new `GaitBody` and eight `Gait_*Hip/Knee` motors; only conflicting joints inside `SCP058_Display` removed.
- `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP173_Display.DisplayRoot` — new `GaitBody`, `Gait_LeftArm`, `Gait_RightArm`, `Gait_LeftLeg`, `Gait_RightLeg`; existing part weld endpoints updated.
- The four `SCP023/058/173/939_Display` models — `GaitRigVersion=1`. 939 geometry/joints/clip are unchanged.

The complete engine-exported part identities and original/new joint endpoints/frames are in [RigRecipe.json](RigRecipe.json). The writer matches actual existing part geometry and original joint endpoints before applying a delta; no guessed deletion or whole-place replacement is used.

## Native verification and limits

Tests use Roblox Studio's actual server and two native clients, with temporary in-memory DataStore/Marketplace/Badge substitutes. The real personal Boss generation, movement, combat damage, death/respawn and animation clients run. Server-positioned targets and QA callbacks provide repeatable input; these are **not physical mouse/keyboard tests** and are **not published Cloud tests**.

- All four passed same-Stage two-client visible-limb movement, contact stop, restart, home return/settle, real owner death/respawn, three fresh retries, World exit, accepted combat defeat and actual client departure. Peer actor identity, run/generation and HP were unchanged; peer visible limbs continued moving. See [NativeLifecycleFirst.json](NativeLifecycleFirst.json) for 023/173, and [NativeSavedFull.json](NativeSavedFull.json) for 058/939 from the written file.
- Motion was measured from visible part CFrames relative to the moving actor, not `Track.IsPlaying`. Maximum joint endpoint gap was 0.000245 studs. Lowest transient visible-part bounding-box clearance was -0.209 studs; resting clearance was approximately 0.1 studs. Bounds are a numerical diagnostic, not a substitute for inspecting mesh contact.
- Native diagnostic record counts remained 0 outside the World and 1 for an active personal actor; pending mounts were 0 in sampled lifecycle states. Three retries retained motor counts 6/13/5/13 and zero animation tracks for the new gaits.
- Time-separated native front/side/third-person views are retained at the owner's request. Front/side observations show moving visible legs on 058, independent arms/legs on 173, diagonal motion on 023 and the amplified saved gait on 939. Third-person QA framing aims at the encounter; no saved gameplay camera or HUD was changed.
- The first 058 test exposed original ManualWelds pinning the visible rods. Only those connections were replaced and native tests then passed. [NativeInitialFixedWeldFailure.json](NativeInitialFixedWeldFailure.json) retains the failure.
- A lifecycle fixture originally expected changing only the `CurrentWorld` attribute to delete the server actor. The established system may retain a dormant actor; the corrected test verifies animation-record cleanup and rest pose instead. [NativeLifecycleFixtureCorrection.json](NativeLifecycleFixtureCorrection.json) is not counted as a pass. Empty native runner results are also not counted as passes; affected stages were rerun and returned full passing reports.
- Public-server asset authorization, actual production persistence/payments and physical input are unverified. Existing unrelated asset permission warnings were not repaired as part of this change.

## Preview instructions

In Studio Play, open **Boss Anim Preview (Studio)**, choose **Stage 2 / 4 / 6 / 7**, select **Approved Walk (production)**, then **Play**. Front/Side/Back and speed controls remain available. This candidate uses the exact production gait module and settings; historical candidates, including the owner's manually added IDs, remain in the list. Stop restores the authored pose.

## File integrity and delivery

Same-file output SHA-256: `0f67af139808fdc301cb8dd23292aa556d1ea524440df31885fd9cb8ee5203bb`; 192,560 instances, dense refs 0–192,559, no dangling refs/cycles, UniqueId duplicates 0. Net change: two new modules, fourteen new motors and fourteen obsolete joints removed. Seven Sources compiled. The delta validator checked 88,992 property rows in touched columns, preserved all original parent identities, and retained untouched columns/chunks. Canonical INST/PROP.Ref/PRNT repair is part of the established writer. Details: [Writeback.json](Writeback.json).

Roblox Studio independently reopened the written file, matched all seven Sources, confirmed saved gait preparation and ran the saved-file two-client tests. Decode success is not used as a substitute for native opening. No additional rbxl/backup was created. No Studio Save/Publish was used.

## Final saved-file regression and cleanup

- The saved-file matrix verified both native clients on all nine animated World2 stages.096 and023 completed in [NativeRegressionFirst.json](NativeRegressionFirst.json); its later035 sample had a **QA root-replication race**, so that run is not claimed as an overall pass. The fixture now waits for the actor root and visual. Stage3/4/5/6/7/8/10 then all completed the front/side/third-person matrix in [NativeSavedRegressionMatrix.json](NativeSavedRegressionMatrix.json).
- The matrix recorded049's existing3.0-second Idle finishing after **3.000641 seconds**, followed by real moving limbs. Both upper-leg colors and SurfaceAppearance tints remained black; the native image pairs also show black thighs during stride.
- The final Preview test initially assumed the shared candidate was first.939's existing name-sorted list placed it later. The test now selects `Kind=ProductionGait`, retaining the existing list ordering. That failure is preserved in the matrix report. [NativeSavedRegressionFocused.json](NativeSavedRegressionFocused.json) then passed all four Preview callbacks (visible changing joints:023=5,058=9,173=5,939=5),049 death during intro and fresh retry, and representative World1 movement (24.03 studs, unchanged speed16/turn4).
- These fixture failures were not gameplay regressions and did not lead to changes in combat, HUD or camera Sources. Saved Source equality was asserted before test-only memory adapters, diagnostics and QA scripts were injected into the unsaved test session.
- [Evidence.html](Evidence.html) contains68 time-separated native client images, with UTC capture times in [EvidenceManifest.json](EvidenceManifest.json). Captures use `PrintWindow` on explicitly owned client windows, not desktop capture. Early unsuccessful captures were discarded. No videos or synthetic animation mockups are claimed.
- All owned native tests returned to Edit, and the verification Studio/server/client processes exited. No user Studio was stopped. Final exclusive read-open succeeded and no target `.lock` existed. The file hash remained exactly the post-write hash after every native test. See [FinalFileVerification.json](FinalFileVerification.json).

Published Cloud execution, physical mouse/keyboard input, production data persistence and Marketplace transactions remain unverified. Studio Save/Publish was not performed.
