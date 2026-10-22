# Remaining World2 boss animation investigation — 2026-10-22

| Stage / Boss | Current joint structure | Candidate / source | Actual native replay | Classification | Work required before production |
|---|---|---|---|---|---|
| 2 / SCP-023 | 9 parts; 6 R6 Motor6Ds; four visible limb meshes; Humanoid; no Bones | PreMerge `SourceModels.SCP-023.Animate` joint equations; Preview `Recovered 023 gait (large, aligned)` | Original DesiredAngle version stayed still. Adapted Transform version visibly moved all four limbs, front and side; final relative limb rotation reached 1.589 rad | **B**: recovered gait plus joint-axis/amplitude adaptation | Refine stance/contact and front/back phase: current motion is a conspicuous bound rather than a finished natural walk |
| 4 / SCP-058 | 48 visible Body parts; five hidden Targeter parts; four motors only in Targeter; Humanoid; no Bones | No recovered gait; existing manual R6 candidate `125749145` used as a diagnostic | Asset loaded, 0.667 s; hidden motors moved but **visible body/legs did not** | **D**: add anatomical joints | Group existing leg segments, add leg-root motors and internal welds, author gait. Possible in Studio without replacing meshes |
| 6 / SCP-173 | 54 parts, including transparent DisplayRoot; 53 rigid root WeldConstraints; no Motor6D, Bone or Humanoid | No recovered Animation, saved clip or gait equations | R6 diagnostic could not run: no compatible Humanoid; no limb motion | **D**: add anatomical joints | Group existing torso/head/arms/legs, replace only crossing root-to-limb welds with shoulder/hip motors, add controller/Animator and author large swing. Current separate blocks can be handled in Studio |
| 7 / SCP-939 | 14 parts; 13 custom Motor6Ds; Humanoid/Animator; no Bones | `SCP939_Display.AnimSaves.939walk`, `Automatic Save`, `ExportAnim.Test`; Preview `939walk (large 1.35x)` | Three saved clips played at 1.0 s, actual four-limb motion. Large variant reached 1.846 rad visible relative rotation. Archived asset `4607522177` failed to load | **B** for requested large gait; **A** for original saved-clip replay | Retain saved clip; refine enlarged gait's ground contact and limb phase before battle adoption |
| 9 / SCP-682 | Hidden R6 carrier with 6 motors; main animal is one rigid SpecialMesh; no Bones/weights | Existing `WalkAnim` **189040478**, referenced by old `SCP049AnimationScript` | Asset remained length 0, no motion. A moving R6 carrier would still not articulate the animal's mesh limbs | **D**: mesh/rig work | Recover/edit source mesh in an external tool such as Blender; split anatomical limbs or add skeleton/weights, then author gait. Tiny visible marker parts are not animal limbs |

A = use existing animation; B = existing animation with joint/amplitude adjustments; C = new animation/procedural gait on existing joints; D = model/joint work first. None of these five has been connected to production combat or permanently rerigged in this change.

## Baseline and historical evidence

Repository HEAD and fetched `origin/main` were both `4ffb30652d8459fa8c6790581160f97a55104a9d`. The input CurrentCloud SHA-256 matched the preceding work: `68aed1f64f92cae7fa621f606661d301caee5b04c45772eed3cc1c62649ae8b0`. Existing untracked `reports/Visual_Templates_Secret_VIP_Green_20260917.md` was preserved and excluded from this commit.

Compared current `ServerStorage.EnemyTemplates.World2SCPDisplays` against read-only `C:\Users\kouji\Smash_and_Crush_PreMerge_20261003.rbxl`, specifically `ServerStorage.World2SCPAssets.SourceModels`. Consulted the previous purchased-model/script audit, animation-preview record, and [approved Walk/096 correction record](../World2BossWalk_20261022/README.md). [AssetAudit.json](AssetAudit.json) retains relevant object/joint/clip metadata and animation-related script excerpts, not runnable imported AI.

- **023:** the archived Animate script drives DesiredAngle (running amplitude 1 rad, angular frequency 9 rad/s, MaxVelocity 0.1). Recovering just those equations did not move this current Preview rig. The separate large candidate applies Motor6D.Transform around the torso's lateral axis at amplitude 0.8 rad and angular frequency 6 rad/s (approximately 1.047 s per cycle). Hip and shoulder pairs have opposite signs. This is a Preview-only adaptation; model parts, saved joints and production speed remain untouched. Manual R6 `125749145` also loaded and moved limbs, but its biped pattern is not a suitable quadruped recommendation.
- **058:** old `Targeter.Script` contains pursuit and victim ragdoll/damage code. Its C0/C1 edits operate on victims, not an anatomical 058 walking rig. It was not enabled. The hidden helper motors are insufficient for moving the visible 48-part body. Preview now measures visible connected geometry rather than treating hidden helper motion as a successful gait.
- **173:** no gait was found in the archived source or current template. This is not an exclusion from the task: the independent Parts permit a Studio joint-building solution. Preserve each limb group's internal welds, replace cross-group rigid welds and keep a stable root before adding a large swing clip. No such permanent modification was made here.
- **939:** full saved paths are `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP939_Display.AnimSaves.939walk`, `.AnimSaves.Automatic Save`, and `.ExportAnim.Test`. All three yielded approximately the same measured motion; byte identity is not claimed. The old source `SCP-939.Animate.walk.RunAnim` supplies `rbxassetid://4607522177`, now exposed as `Archived 939 Walk` but locally unavailable. An old GUID content string (`13e51a0709edd67223a6ac3c174415a4`) is not numeric asset 13; candidate parsing now rejects that false ID. The large Preview variant samples the existing saved clip through World2BossClip and scales joint rotation by 1.35, retaining its 1-second period.
- **682:** principal mesh `957757849`, texture `957760563`, is under the carrier's Torso.Mesh; the inner model name is `.`. The old misnamed `SCP049AnimationScript` references WalkAnim `189040478`; ArmOut `189040829` is an attack candidate, not classified as walking. The animal's actual legs are part of one FileMesh. Adding motors to invisible carrier limbs alone cannot deform it. Preview framing now uses existing FileMeshSizes so the creature is not cropped by the carrier's smaller bounds.

Load failure (939 archived/682), missing controller (173), hidden-joint mismatch (058), and legacy procedural no-motion (023 original) are distinct results. An IsPlaying flag with Length 0 was never counted as a successful replay. Asset access failures may depend on ownership/authorization; no public-server availability claim is made.

## How to review candidates in Studio

Open the updated **same CurrentCloud.rbxl** and start a Studio test when desired. Use **Boss Anim Preview (Studio)** at the top right. Select a Stage, select the candidate, press **Play**, then **Front / Side / Back**. Existing Stop, Close and 0.5x / 1x / 1.5x controls remain; speed controls change the Preview cycle only, not Boss chase settings.

1. **Stage 2 / SCP-023 → Recovered 023 gait (large, aligned)**: main large-motion candidate. `Recovered 023 gait (original)` intentionally exposes the unsuccessful original DesiredAngle method for comparison.
2. **Stage 7 / SCP-939 → 939walk**: original saved gait. Select **939walk (large 1.35x)** for the enlarged version. `Automatic Save` and `Test` remain available; `Archived 939 Walk` documents the unavailable old asset.
3. **Stage 4 / SCP-058 → Walk候補 R6**: diagnostic only; helper joints can move while visible legs stay fixed. No usable existing anatomical gait was found.
4. **Stage 6 / SCP-173**: inspect the static model; existing manual candidates remain visible but cannot produce limb motion without joints/controller.
5. **Stage 9 / SCP-682 → WalkAnim**: retained historical candidate, failed in this test; mesh processing is required for independently moving limbs regardless of carrier playback.

All ten Boss selectors are available in two columns. Existing manually added `507777826` / `125749145` candidates, existing controls, and the corrected SCP096 retarget implementation are preserved. Imported AI, attack, death and regeneration scripts are stripped from Preview clones as before. Production does not depend on the Preview.

## SCP-049 black thighs — implemented

The pale exposed pieces are the **existing LeftUpperLeg and RightUpperLeg MeshParts**. Native comparison showed that black Part.Color plus an empty TextureID still rendered pale. A black `SurfaceAppearance.Color` on only these two parts rendered black. A BodyColors alternative was inspected in unsaved memory but was not adopted because it would affect other regions.

`ReplicatedStorage.Modules.World2BossRig` now gives each existing thigh one `SurfaceAppearance` named **SCP049BlackThigh**, Color `(0,0,0)`. No texture asset, geometry, dimensions, joints, swing, foot, coat or other white body part is replaced. The existing clone preparation path applies this on fresh personal Boss actors and on Preview clones; its idempotent version guard prevents accumulating children. Saved template parts are unchanged. Runtime paths are:

`Workspace.World2Enemies.Owner_<UserId>.Stage05_Enemy.SCP-049.LeftUpperLeg.SCP049BlackThigh`

`Workspace.World2Enemies.Owner_<UserId>.Stage05_Enemy.SCP-049.RightUpperLeg.SCP049BlackThigh`

Actual native Play front/side sequences show both thighs black during strides. The original `SCP049_Display.AnimSaves.Idle` remains a 3.0-second clip, triggered after the owner's actual Wall4 destruction; the first final-file test measured 3.016 seconds until completion, followed by real moving-limb Walk. No intro/chase/attack code was changed.

## Verification and limits

- **Static/writeback:** three Sources compiled, same-file decode passed, all Sources matched, 192,538 instances / 161 classes, dense refs 0–192,537, 81,074 PROP.Ref values, no missing/out-of-range refs and **0 duplicate UniqueIds**. All 4,915,517 original property rows were checked, permitting only the three Source replacements; template geometry, hierarchy, properties and other Sources were preserved. See [Writeback.json](Writeback.json).
- **Native Preview:** one real Studio client, all five remaining bosses and recovered candidates replayed; visible limb CFrame changes were measured independently of Track state. Front and side time-separated images were inspected. Final 023/939 large variants were replayed from the written file. No disconnected parts or extreme joint reversal were observed in those sequences. Contact is **not production-ready**: bounds proxies dipped 0.052 and 0.175 studs below the guide respectively, and 023's paired gait has an airborne phase. These are part-bounds measurements, not exact mesh/skin collision proof. See [NativeInvestigation.json](NativeInvestigation.json) and [NativePreviewFinal.json](NativePreviewFinal.json).
- **Native actual 049 battle:** two real clients, real combat/animation services, actual server wall-attack path, memory-only stores and Marketplace/Badge fixtures. Server-positioned targets and temporary QA callbacks supplied inputs; **no physical mouse-click validation is claimed**. Both clients showed real joint/limb movement. Front/side black-thigh captures are from this actual battle, not only a ViewportFrame.
- The first final-file session completed black appearance/intro/walk checks, then its extra retry fixture failed because the still-running test target mover displaced the player during a new wall attack. [Native049FirstAttempt.json](Native049FirstAttempt.json) retains that failure; its outer `Success=true` means StudioTestService returned, not that all assertions passed. The retry fixture alone was corrected to stop the target mover before new wall attacks. The focused rerun passed with no assertion errors, two fresh actors retaining both black surfaces, and a measured 3.017-second intro: [Native049Final.json](Native049Final.json). The server's Transparency=1 in that diagnostic is the existing owner-only presentation mechanism; actual owner-client frames establish visible black thighs, rather than assuming server properties prove appearance.
- Existing unrelated restricted asset warnings occurred during the full game startup; the two historical candidate load failures above are relevant and explicitly reported. They were not silently substituted.
- **Not verified:** public-server asset permission/playback, Cloud publication, physical mouse/touch interaction, narrow-device Preview layout, final natural gait/ground contact for 023/939, production walking for these five, or unrelated game features. This task does not claim those five are ready for combat deployment.

## Retained visual evidence

[Open the sequence gallery](Evidence.html). Each Front/Side pair consists of distinct capture times; timestamps, file sizes and SHA-256 values are in [FrameManifest.json](FrameManifest.json). Original frames are retained at the user's explicit request. The gallery starts with saved-file large candidates and live 049, then includes the historical/failed/control comparisons. A single still is not used as proof of movement.

## Changed Full Paths and delivery

- `ReplicatedStorage.Modules.World2BossRig`
- `ServerScriptService.StudioBossAnimationPreview`
- `StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview`
- Repository mirrors under `src/`, scoped writer `tools/write_remaining_boss_preview.py`, this English report/evidence and corresponding specification/status/changelog entries.

Written to `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, SHA-256 `5b4cc9194de35f3853714cac59ad68363c5e2f19e78afc42311f78bcbae08619`. The actual saved file was reopened natively; saved Sources were compared before Play. No other rbxl, backup or migration was created; PreMerge was read-only. Studio Save/Publish was not used. Final process/lock and Git delivery checks are recorded in Completion.json.
