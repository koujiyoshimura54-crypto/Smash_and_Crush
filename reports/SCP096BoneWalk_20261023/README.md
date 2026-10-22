# SCP 096 editable visible-body Walk — 2026-10-23

## Result and scope

Retargeted the imported two-second Walk onto the visible 73-Bone skin in the current Studio Edit session. This is an editable KeyframeSequence, not a runtime animation helper. Production World2 Stage1 and all gameplay Sources are unchanged. The place remains open and unsaved; no rbxl write, Studio Save, Publish, Play, or imported script execution was performed.

The user reopened Studio during this work. All changes were applied to that live Edit model, not to an older disk copy. The disk SHA256 stayed `963d740cec0a512f6aeb061ceb116720fc2bbd785259dcd018c68bb6aaec25e4`.

## Cause

`Workspace.SCP 096.AnimSaves.Walk` animates the separate invisible 15-Motor6D carrier rig. Its names/hierarchy do not target the visible mesh's 73 Bones. There is no imported bridge that transfers those carrier poses to the skin. Changing the timeline therefore moved the invisible rig without deforming the body.

The online Walking asset `7448255829` was requested once and rejected by an authorization error. No retry or substitute asset was used. The existing saved Walk supplied the motion.

## Live Edit changes

- Added `Workspace.SCP 096.FBXImportGeneric.BoneWalkController` (AnimationController) and its Animator.
- Added `Workspace.SCP 096.FBXImportGeneric.AnimSaves` (ObjectValue) linking the editor rig to its save slot.
- Added `ServerStorage.RBX_ANIMSAVES.SCP096_VisibleBody` (ObjectValue, pointing to the existing FBXImportGeneric model).
- Added **`ServerStorage.RBX_ANIMSAVES.SCP096_VisibleBody.Walk_BodyBones`**.
- Kept the original `Workspace.SCP 096.AnimSaves.Walk`, original controller, mesh, textures, weights, 73 Bone bind CFrames and all 15 Motor6D C0/C1 pairs.

The conversion reconstructs the source joint poses using its C0/C1 hierarchy. Four anatomical limb chains map upper/lower limb directions into the target bind axes; wrist motion is transferred relative to the forearm. The bend plane is transported from the reference pose to avoid a 180-degree flip at a straight knee. Foot orientation, torso and head rotation are mapped separately. Target local transforms are calculated from the desired parent orientation and unchanged bind CFrame. Unmapped Bones retain identity animation transforms.

The original 11 key times (0 to 2 seconds), loop and Movement priority are retained. Linear interpolation is retained (the easing-direction enum has no effect with Linear). Target limb lengths remain fixed; small source carrier translations are not copied as skin translations. No amplitude exaggeration or replacement walk was added.

## Native editor verification

Actual Studio Edit Clip Editor operations, not Play or IsPlaying-only checks:

- Opened Walk_BodyBones on the nested visible-body rig.
- Clicked Play and visually observed visible arms and legs deforming.
- Scrubbed the native time field between poses and observed the body changing.
- Inspected front and side views; no major limb separation or mesh collapse was observed in the inspected poses/playback.
- Stopped, closed, reopened and scrubbed to 0.8 seconds again. All 73 Bone transforms matched exactly (maximum component difference 0); no accumulated correction.
- Final integrity checks: original Walk data unchanged; all 73 Bone CFrames, 15 Motor6D C0/C1 pairs, part CFrames/sizes/anchoring/transparency, and three imported script Sources/enabled flags unchanged.
- Luau builder syntax passed.
- Temporary development-GUI visibility change restored. Verification screenshots were inspected then removed, as required by AGENTS.md.

The imported enabled scripts remain unchanged because this task never entered Play: `Workspace.SCP 096.Respawn`, `Workspace.SCP 096.RunToTheSCP`, and `Workspace.SCP 096.SCP-096Main`. Their original Sources and flags are captured in OriginalRig.json. They contain respawn, character-script insertion and chase/damage behavior and were not executed.

Unverified: the unauthorized online asset; production combat/runtime integration (out of scope); aesthetic approval of the walk. No claim of production adoption is made.

## Open and inspect

1. In Explorer select **Workspace > SCP 096 > FBXImportGeneric**, the nested model containing Body.LP. Do not select the outer invisible carrier rig.
2. Open **Avatar > Clip Editor**.
3. In the editor's ellipsis menu choose **Load > Walk_BodyBones**.
4. Click Play, or drag/scrub the timeline. Orbit the camera for front/side inspection.

The corrected clip is already in the live Edit data model. Saving the place is the user's next action; Git does not save the open place.

## Git artifacts

- BuildBoneWalk.luau: the exact Edit-only retargeting builder used; not installed as a game Script.
- Walk_BodyBones.json: corrected clip data read back from Studio, including hierarchy and all key times. Missing CFrame fields represent identity. Easing and priority are serialized enum values.
- OriginalWalk.json: unchanged source clip data.
- OriginalRig.json: original structural/pose and imported script audit.
- Verification.json: final integrity and editor reopen results.

Only this report directory is committed. Unrelated worktree files are preserved.
