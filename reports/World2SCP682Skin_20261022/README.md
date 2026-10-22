# World2 Stage9: skinned SCP-682

Current-file baseline: `db08f1f7a0dff736033f88dd5d4cf555b15b1c147da94cbd033a30046c0b5371`.
Fetched Git main: `82e8981`. AGENTS and current related animation records were consulted. All eight existing target Sources matched that Git version; the current place's other edits were retained. This is the newly imported visible MeshPart **10775394100**, texture **957760563**, with **32 Bones**, no executable Sources and 120 reference-pose CFrameValues. It is not either previously inspected rigid carrier model.

## Weight gate and gait

In an isolated native Studio clone, right and left fore/hind roots were rotated about 0.35 radians; middle/end joints were also exercised at 0.25/0.15 radians. The visible legs deformed, including the lower limbs/feet. Inspected side views did not show detached limbs, unrelated stretched surfaces or major twisting. Transform offsets were reset to identity afterwards. This is a practical movement-range check, not an exhaustive vertex-weight audit.

`World2SCP682Gait` uses four cached two-link IK chains (UpperArm/Forearm/Hand and Thigh/Calf/Foot), diagonal phase pairs, a planted rearward stroke and raised forward return. Ankles counter-rotate to retain their authored contact orientation. Tail motion is small. At 26 studs/s the cycle is 0.32 s; unscaled stride amplitude is 2.7 studs, lift 1.1 and stance fraction 0.58. Cadence follows the existing measured BossMotionSpeed; stopping fades to rest in 0.16 s. No uploaded AnimationId, imported AI, per-frame hierarchy scan or animation Remote is needed. Reach is clamped to existing limb lengths; foot sliding is reduced, not claimed to be physically eliminated at every speed/turn.

Existing owner-only animation records cache each actor's gait independently, reset on removal/World exit and rebuild for new actors. Bone.CFrame, original skin, texture and reference-pose data are unchanged; offsets are recomputed from rest, never accumulated. Production and Studio Preview call the same module.

## Placement and retained combat

| Visible dimensions, width / height / length (studs) | Value |
|---|---|
| Former production 682 | 12.8380 / 9.4075 / 38.8989 |
| New authored mesh | 17.3689 / 12.5352 / 51.8320 |
| New production, 0.75 of authored scale | 13.0267 / 9.4014 / 38.8740 |

The new template stays at authored scale 1; each spawned copy uses 0.75. The previous VisualScale=1.4 is not reused. Forward is the mesh's -Z; existing floor fitting and HP display bounds use its actual MeshPart size. The previous fixed collider is retained at **10.9123 / 9.4075 / 21.3944** studs with the matching center offset. Deforming skin never resizes that collider or the cached chase footprint. Speed **26**, turn response **6.9**, HP **900B**, rewards, attacks, progression and all other stages' tuning are unchanged.

The actual imported model was moved from `Workspace.SCP-682` to `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP682_Skinned_Display`; it is not duplicated in the live map. The old `SCP682_Display` template remains intact. Other candidates were not deleted.

## Changed Full Paths

- `ReplicatedStorage.Modules.World2SCP682Gait` (new).
- `ReplicatedStorage.Config.World2BossAnimationConfig`, `ReplicatedStorage.Config.World2BossVisualConfig` (Stage9 only).
- `ReplicatedStorage.Modules.World2BossGait`, `ReplicatedStorage.Modules.World2BossRig` (explicit skin branch).
- `StarterPlayer.StarterPlayerScripts.World2BossAnimationClient` (Stage9 visual lookup).
- `ServerScriptService.World.BossVisualPlacement` (optional fixed collider dimensions/offset; other stages retain their existing calculation).
- `ServerScriptService.StudioBossAnimationPreview`, `StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview` (Stage9 production gait; retire the obsolete Workspace-import selector).
- The moved model's Name/Parent/PrimaryPart and its MeshPart.Anchored. All 32 original bones and other model properties are retained.

Preview: Studio Play → **Boss Anim Preview (Studio)** → **Stage9 / SCP-682** → **Approved Walk (production)** → Play. Front/Side/Back, Stop and speed controls remain available.

## Native evidence and verification boundaries

Two native clients ran the real personal actor generation, chase, turn, combat and animation code. Test-only in-memory service adapters protected persistence/receipts; positions, strength and lifecycle inputs were driven by the fixture, not physical gameplay input. Front/side/ordinary-view sampling observed movement in both owners' 12 limb bones and zero visible foreign Boss parts. Actual skin deformation was assessed separately in native images, not inferred from bone coordinates alone.

Four time-separated native screenshots are retained: [front 1](walk_1.png), [front 2](walk_2.png), [side 1](walk_3.png), [side 2](walk_4.png). Only the game viewport is retained; cropping does not alter its pixels. There was no image synthesis.

Early native attempts are recorded honestly in NativeFirst/NativeSecond/NativeStreamingFailure/NativeVisuals.json. Fixture failures were: a peer reaching its own target; a return completing before the sample ended; a floor not yet replicated; and a peer target placed outside the post-wall chase region. They are not counted as complete lifecycle passes. The corrected fixture uses in-bounds targets, waits for replication and accepts a return that walks then settles. Combat logic was not changed to satisfy these checks.

The initial broad service-replacement test action was rejected by automatic approval review before execution. The actual fixture uses an explicit allowlist of eight external-service boundaries in a Codex-owned Studio, restores original Sources after the test and removes its three temporary instances. No real payment, production profile write, free product grant or paid receipt fulfillment was performed.

Same-file write and reread: [Writeback.json](Writeback.json). Nine production Sources compiled, all 32 bones and original skin data were preserved, and 4,917,525 unrelated property values were checked. Native Studio reopened the saved file and matched nine Sources, template scale 1, mesh ID and bone count before any test adapter was injected. No extra rbxl, backup or migration was created; Studio Save/Publish was not used.

Published-server behavior, real payments/persistence, every possible vertex deformation and long-session gameplay outside this Stage9 task remain unverified. The screenshots and scripted native inputs do not claim physical mouse/keyboard testing.

## Saved-file completion

[NativeSavedLifecycle.json](NativeSavedLifecycle.json) passed with no reported errors: contact stop, restart, return/home settle, real character death/respawn, two fresh retries, World exit (active animation records 0), accepted combat defeat, actual client departure, and continued peer movement with unchanged identity/HP/run/generation. Stage9 Preview exercised the shared production callback and 15 changing bones. Existing Stage4 retained its 13-motor gait and visible limb movement. The saved-file native runner took 61.8 seconds including native test startup. Inputs were scripted; death used Humanoid.Health=0, defeat used the existing accepted attack path, and departure used StudioTestService.LeaveTest.

Static MeshPart bounds remained about 0.1 studs above the main floor; that diagnostic does not measure deformed vertex clearance. Native skin images supplied the visual grounding/shape check. No gameplay failure was found requiring combat/rule changes.

[Completion.json](Completion.json): Play stopped, test Sources restored and fixtures removed; both owned verification Studios exited without Save/Publish. Exclusive file read succeeded, the task-owned stale lock was removed only after its recorded PID exited, and the saved hash remained unchanged after native tests. The user's original dirty checkout and untracked files were untouched.
