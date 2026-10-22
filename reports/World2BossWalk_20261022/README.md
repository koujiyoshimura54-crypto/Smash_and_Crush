# World2 approved boss animation connection ? 2026-10-22

The current downloaded CurrentCloud file is the authorized implementation baseline. Git main was fast-forwarded from 7d4698c to f499141; existing untracked work was preserved. No older source tree was bulk-applied to the place. Manual Preview candidates were recorded separately in d408dc0.

## Adopted animations

| Stage | Boss | Walk | Application / cadence at configured chase speed |
|---|---|---|---|
| 1 | SCP-096 | rbxassetid://507777826 | Existing R6: sample the approved R15 clip onto six existing motors; limbs 50%, torso/head 25%; approximately 1.00x |
| 3 | SCP-035 | rbxassetid://507777826 | Existing R15 Animator, approximately 0.496x |
| 5 | SCP-049 | rbxassetid://507777826 | Existing R15 Animator, approximately 0.533x |
| 8 | SCP-106 | rbxassetid://125749145 | Existing R6 Animator, approximately 0.521x |
| 10 | SCP-323 | rbxassetid://507777826 | Existing R15 Animator, approximately 1.136x |

Cadence follows actual travel speed and existing scaled leg length; it never changes chase speed or turn response. Stage6 and other unlisted animation stages remain unchanged. R15 reuse requires connected motors with the existing standard parent/child body names; SCP096's R6 adapter is explicitly configured, not automatically applied to unrelated models.

The exact intro is `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP049_Display.AnimSaves.Idle`: nine saved keyframes, final time **3.0 seconds**, normal speed, once per actor/challenge. Native measured transition was **3.000132 seconds** in the complete run. No substitute Idle asset, guessed fixed wait, upload, or temporary animation ID is used. The saved clip is sampled on existing motors using synchronized server time; the server derives completion from that clip's duration and enforces bounded validation. Missing/invalid clips warn and release pursuit. Owner death, actor removal, reset, World exit and defeat invalidate the old actor state.

## Rig corrections

`ReplicatedStorage.Modules.World2BossRig` runs only on fresh production/Preview clones after placement and collider sizing. Saved model templates and authored geometry were not changed.

- 096: reversed shoulders connected arms to torso and crossed their anchors. Reoriented all six connected R6 motors to consistent torso axes while preserving rest part transforms; hip anchors now use existing leg tops. No knees/new mesh were fabricated. Reduced swing on the long rigid R6 limbs and compensated cadence after the user's gait feedback. A client replication race originally compiled before motors arrived; bounded actor mounting and clip compilation retries now wait for connected motors. Both native clients subsequently moved arms/legs/head/torso. Its long rigid R6 legs remain a stylistic limitation; final user acceptance of the adjusted gait is not claimed.
- 049: both upper legs and all fifteen R15 motors already existed. Upper legs were transparent beneath a single coat mesh. Reveal those existing parts, tint them dark cloth, and remove only their previously hidden pale avatar texture; boots, coat and authored visible mesh textures remain unchanged.
- Connected limbs are unanchored while roots/disconnected decorations remain secured. Imported AI/Animate scripts stay disabled. No full-body root welds were added.

## Runtime paths changed

- `ReplicatedStorage.Config.World2BossAnimationConfig`
- `ReplicatedStorage.Modules.World2BossRig`
- `ReplicatedStorage.Modules.World2BossClip`
- `ServerScriptService.World.World2BossAnimationService`
- `ServerScriptService.World.BossChaseService`
- `ServerScriptService.World.BossVisualPlacement`
- `ServerScriptService.World.EnemyManager`
- `StarterPlayer.StarterPlayerScripts.World2BossAnimationClient`
- `ServerScriptService.StudioBossAnimationPreview`
- `StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview`

Production has no dependency on Studio Preview. Per-actor client records own one walk track/compiled clip, clean up on removal/World exit, and never LoadAnimation each frame. Contact stop, moving again and returning home use actual translation rather than chase intent. Combat damage/attack gates, HP, rewards, owner isolation, stage speeds18?27/turn4.5?7.2, World1, all map/template properties and other source scripts are preserved.

## Verification boundaries

**Native engine Play, isolated two-client fixture:** `NativePlay.json` contains the accepted complete run against saved d3cd2787... Sources. All five stages moved real joint transforms AND limb CFrames on both clients. Front/side temporary captures of all five were inspected, then removed. Intro changed the neck while root travel stayed zero, and duplicate activation did not restart it. Real EnemyManager manual attacks destroyed049's walls through existing carry handling. Death during intro, fresh retry, reset, five fresh clones (15 motors and scale2.700000047 each), World exit cancellation, contact stop (zero playing tracks), resumed movement, return/settle, real combat defeat, peer independence and actual client departure passed. World1 representative actor moved24.238 studs with existing16/4 movement. The final cosmetic-only texture correction receives a separate focused saved-file native retest.

**Fixture limitations:** avatars were server-positioned/anchored; no physical keyboard/mouse traversal or production gate UI interaction is claimed. DataStore, Marketplace and Badge calls were routed to temporary in-memory mocks in unsaved test sessions. A keep-alive fixture replenished living avatars for long tests; explicit death still used Health0. No production data, payments or real persistence were exercised. Earlier fixture attempts exposed insufficient health, wrong arena contact side and a RenderStepped timeout while rendering was suppressed; those are not counted as passed runs. The actual replication race was fixed in production code.

**Static / serialization:** all ten sources compile; saved Sources equal repository text. Initial write adds only five script/module instances (192533?192538), leaving161 classes. Final references are dense0..192537,81074 PROP.Ref values, no missing/out-of-range referents and UniqueId duplicates0. All original parents and non-approved properties remain equal; successive write reports preserve each hash transition. Native Studio opened the same saved file, completed Play, returned Edit and exited without Save/Publish. Re-Decode is additional evidence, not a replacement for native load.

**Not verified:** public-server asset authorization, published-server behavior, real production persistence/payment, physical user input, long-duration memory profiling, and the user's final visual approval of096. The Cloud place was not published or re-downloaded. No claim of Cloud synchronization is made.

## Writeback

Same file: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Reports: `Writeback.json`, `GaitRefinement.json`, `Refinement.json`. No extra place/backup/copy was created. Test instrumentation and memory stores exist only in unsaved native sessions. Temporary screenshots are not retained or committed.

## Final focused retest and remaining visual issue

The final68aed1f6... file was opened natively and Stage5 retested with two clients (`NativeFinalStage5.json`): saved Sources matched all ten repository files, Idle lasted3.000343s, and walk joint/limb motion passed. Server thigh colors and removed texture were correct. **However, front/side captures still show a pale exposed carrier segment on049 during stride. The visual clothing match is unresolved; it is not reported as visually complete.** No new mesh or broad rig rebuild was attempted.096 final adjusted gait is visible and both clients moved it in the full run; no later change touches096 logic. All test sessions returned Edit and exited without Save/Publish. Screenshots were inspected and deleted.
