# SCP096 editable body clips — partial delivery, 2026-10-23

Status: clips were added to the user's current, unsaved Studio Edit document. **The requested complete visual acceptance is not finished.** The user instructed us to stop GUI interaction; all further Studio clicks, Command Bar actions and layout changes stopped. Only local evidence review and Git recording continued.

## Baseline and artifacts

- Git was safely fast-forwarded to `8c23dcf`; unrelated untracked files were retained.
- The baseline was the live `Workspace.SCP 096`, not an older rbxl or Git Source replacement. Studio PID6368 was the user's open local document, PlaceId0.
- `CurrentStudioAudit.json` is the **initial live read**, before conversion: 19 source KeyframeSequences, the already existing Walk_BodyBones, 11 Animation references / 9 unique IDs, 73 Bones, 15 Motor6Ds, 19 BaseParts, ObjectValue save links and imported Script text. It is not a final readback or a complete model export.
- `BuildBodyClips.luau` is the final v2 converter, syntax-compiled with Luau. Together with the initial clip/rig data and the preceding `SCP096BoneWalk_20261023` artifacts it records how the outputs were made. No final JSON export of the 18 generated clips was obtained after the user stopped GUI work.
- `Walk_BodyBones` **was already present in the current Studio**. It was neither restored nor replaced by the converter. Eighteen other Bone clips were added. A later read counted 19 objects in the output slot.

## Conversion

The source animations address the transparent Motor6D carrier. The visible mesh is `Workspace.SCP 096.FBXImportGeneric.Body.LP`. Conversion uses the preceding Walk's anatomical upper/lower limb frames, fixed Bone bind CFrames, transported bend normals, relative wrist orientation and foot alignment. It also transfers pelvis displacement and jaw motion. It does not replace different actions with Walk or apply a uniform amplitude multiplier.

V1 incorrectly treated sparse, zero-weight identity parent containers as authored keys, producing pelvis jumps. V2 ignores those containers and interpolates active source channels. Only our eighteen V1 outputs were replaced; the original nineteen saves and pre-existing Walk were retained by that operation. Generated tracks include the full 73-Bone hierarchy to reset unused channels between clips. Linear/Constant easing, direction, source key times/names, loop, priority and markers are copied where applicable. This is an anatomical approximation, not proof of exact source motion parity. Attack1's negative source key times are retained; native negative-time scrubbing was not verified. No source markers were found.

The builder skips existing outputs and asserts their SourceClip identity; it does not overwrite user-edited output saves on rerun. It is an Edit-time conversion artifact, not a production Script. Do not run it blindly on a different rig or treat it as a verified recovery script for every possible Studio state.

## Saved candidate inventory

All source paths below are under `Workspace.SCP 096.AnimSaves`; `ExportAnim.Test` is a real nested KeyframeSequence, not an inference from its parent's name.

All output paths have the exact prefix `ServerStorage.RBX_ANIMSAVES.SCP096_VisibleBody.` followed by the name in the final column.

`F2` = final v2 clip actually loaded, played and scrubbed in native Clip Editor from the front, with visible mesh movement at different times. This does **not** certify full motion quality, side view, every frame, or final post-undo integrity.

`F1` = front review of the first conversion existed; final v2 individual acceptance is pending. Idle/standing/sitting clips have small authored movements and were not deliberately replaced with invented motion or declared static merely because movement was subtle.

| Source | Keys / last time (s) | Loop | Classification / verification | Output name |
|---|---:|---|---|---|
| Attack1 | 46 / 5 | no | converted; F2; negative-time review pending | Attack1_BodyBones |
| AttackRun | 7 / 0.6000000238 | yes | converted; F1 | AttackRun_BodyBones |
| AttackRunStart | 7 / 0.6000000238 | no | converted; F1 | AttackRunStart_BodyBones |
| Automatic Save | 33 / 2 | yes | converted; F2; large middle-pose rotation needs source/side comparison | Automatic Save_BodyBones |
| ExportAnim.Test | 15 / 3 | no | converted; F2 | ExportAnim_Test_BodyBones |
| GetUp_Panic | 16 / 3 | no | converted; F2; includes Constant easing | GetUp_Panic_BodyBones |
| GetUp_Walk | 13 / 3 | no | converted; F2 | GetUp_Walk_BodyBones |
| Idle | 3 / 3 | yes | converted; F1; subtle motion | Idle_BodyBones |
| Panic | 7 / 2 | yes | converted; F1 | Panic_BodyBones |
| PanicEnd | 9 / 1 | no | converted; F1 | PanicEnd_BodyBones |
| Panicking | 7 / 2 | yes | converted; F1 | Panicking_BodyBones |
| Running | 7 / 0.6000000238 | yes | converted; F1 | Running_BodyBones |
| Sit1 | 3 / 4 | yes | converted; F1; subtle motion | Sit1_BodyBones |
| Sit1ToSit2 | 9 / 4 | no | converted; F2 | Sit1ToSit2_BodyBones |
| Sit2 | 3 / 4 | yes | converted; F1; subtle motion | Sit2_BodyBones |
| SitBack | 11 / 3 | no | converted; F2; later editor-state caveat below | SitBack_BodyBones |
| StandIdle | 3 / 5 | yes | converted; F1; subtle motion | StandIdle_BodyBones |
| StandToPanic | 6 / 2 | no | converted; F1 | StandToPanic_BodyBones |
| Walk | 11 / 2 | yes | existing Bone version retained; front review | Walk_BodyBones |

### External references: unresolved, not silently substituted

All nine unique references failed the initial `GetKeyframeSequenceAsync` request. A subsequent request returned empty, zero-key sequences. Although that diagnostic printed `ASSET_OK` on a successful API return, **zero keys are not usable animation data and are not counted as success**. No such empty clip was attached as a finished output. The opaque hashes are not verified published IDs. The seven numeric assets also emitted load/authorization errors; their contents and motion remain unknown in this document.

| Actual object path | Reference | Result |
|---|---|---|
| Workspace.SCP 096.AnimSaves.TestAnim | e2cb107e5c9f6b85051c2e303ba8332e | unresolved; no saved child found |
| Workspace.SCP 096.AnimSaves.ExportAnim | 92f90eb70ee7246cc5c87954e392c391 | external reference unresolved; its separate saved Test child was converted |
| Workspace.SCP 096.Angry | rbxassetid://7448261978 | unresolved |
| Workspace.SCP 096.FinalGetup | rbxassetid://7450707800 | unresolved |
| Workspace.SCP 096.GettingUp; Workspace.SCP 096.Standing | rbxassetid://7448259790 | unresolved aliases |
| Workspace.SCP 096.Kill | rbxassetid://7451240343 | unresolved |
| Workspace.SCP 096.Run; Workspace.SCP 096.Run2 | rbxassetid://7448257611 | unresolved aliases |
| Workspace.SCP 096.Sit | rbxassetid://7448267902 | unresolved |
| Workspace.SCP 096.Walking | rbxassetid://7448255829 | unresolved; no identity with saved Walk assumed |

## Native review limitations and GUI incident

The front v2 captures visibly show the correct native clip names, changing timeline times and mesh poses for the seven F2 rows. The first side-review attempt mis-targeted the UI after the Command Bar changed height. Three VideoFrames named `Bloxy Cola` with asset5608321996 were accidentally inserted beneath `Workspace.Leaderboards`. This was an automation error. Undo was restricted to the matching `Before/After insert asset 5608321996` history entries; the observed count returned from3 to0. No imported AI Script was intentionally enabled or executed.

Undo emitted an Animator-parent-locked warning. A subsequent read still counted19 saved output clips and found `BoneWalkController`, but did not list an Animator. Native editor playback subsequently worked, but a final controller/rig/source integrity audit was **not completed**. No claim of complete post-incident restoration is made.

The second side batch also failed to select its intended clips: the actual native clip header remained `SitBack_Body...` while helper labels said Walk/Attack/Automatic Save. These five labeled captures are invalid evidence for those intended clips. They show SitBack movement only. The editor's displayed duration also changed from3 to4 during the failed scrub sequence; persistence of that editor-only change to the saved clip was not checked. Full side-view, reopen, pose-reset and final generated-data acceptance remain pending.

After the user's instruction not to touch the GUI, no further camera, editor, Command Bar, layout or restore operation was attempted. Temporary view changes consequently remain un-restored: development GUI hidden (`StarterGui.ShowDevelopmentGui=false`), camera moved, device preview changed to a phone, Toolbox/Asset Manager closed and Command Bar resized. Original camera/focus and ShowDevelopmentGui values were retained in the session-only `_G.SCP096EditorView`. This is not an instruction to run a restoration command without the user's consent. The user Studio remains open with unsaved edits.

Temporary screenshots were inspected and removed under AGENTS.md; none are committed. Native animation-editor playback is distinct from game Play. No local/server game Play, production Boss connection, Studio Save/Publish, animation publication, rbxl writeback or Cloud write was performed for this task. No full-game or two-client regression was run.

## User-controlled opening steps

These are instructions only; automation has stopped.

1. Select the exact model `Workspace.SCP 096.FBXImportGeneric` (not the outer transparent carrier `Workspace.SCP 096`).
2. Open Studio's Animation/Clip Editor for that model.
3. Use the editor's `...` > Load menu and choose the desired `*_BodyBones` entry from the table. Verify the actual editor title before playing or scrubbing. `ExportAnim_Test_BodyBones` represents the saved Test child.
4. The native save-link objects connect this model to `ServerStorage.RBX_ANIMSAVES.SCP096_VisibleBody`; the originals remain in the outer model's AnimSaves hierarchy.

Current Studio edits are unsaved. Git contains the initial audit and converter, not a final verified Studio snapshot. The rbxl and Cloud were not manually saved. Before moving PCs or closing Studio, the user must manually save any desired current edits; this report does not certify that all clips or temporary view settings are ready for acceptance.
