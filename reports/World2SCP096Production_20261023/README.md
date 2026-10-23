# Current-session SCP-096 production connection — 2026-10-23

Implemented in the user's existing unsaved `MergeToForge_CurrentCloud.rbxl` Studio document, starting from Git `405a15b`. The current ten relevant Sources matched Git before editing; the current imported model and approved body clips, rather than an older place file, supplied the new template. This delivery changes only World2 Stage1's presentation and its explicitly requested intro gate.

## Connection and preservation

The already configured Roblox Studio MCP stdio proxy successfully connected to the existing document. No plugin installation, GUI input, window activation/repositioning, device-preview change or development-GUI change was needed. The previous report's inability to connect was an incomplete connection investigation, not proof that Studio lacked a non-GUI interface. No user connection action is currently required.

The original `Workspace["SCP 096"]` mesh, Bones, imported scripts' Source and all original editor animations remain. The three imported AI scripts `SCP-096Main`, `RunToTheSCP`, and `Respawn` are retained but now disabled, preventing imported AI/attacks/respawn from running. `ServerStorage.RBX_ANIMSAVES.SCP096_VisibleBody` still has all19 clips, including the prior Walk and the18 additional body variants; their recorded properties remain identical. This task did not reconvert or visually re-review the whole candidate collection.

The existing11 display templates, including `SCP096_Display`, remain byte-for-byte equivalent in the scoped property audit. A12th template was added:

`ServerStorage.EnemyTemplates.World2SCPDisplays.SCP096_BodyBones_Display`

It contains the current `Workspace.SCP 096.FBXImportGeneric.Body.LP` mesh with73 Bones and five exact approved saved clips. It contains no imported AI, transparent carrier rig, Animator, or editor-save reference. The original mesh asset6805365701, appearance and Bone bind hierarchy are preserved. Template scale is0.6819049715995789; the existing spawn factor2.25 produces a15.75-stud rest bounding height, matching the prior boss. The previous collider dimensions6.8849787712 ×15.75 ×2.5559258461 are explicitly retained. Current floor placement/orientation and HP presentation continue through the existing BossVisualPlacement logic. Animated contact/visual orientation still require the visual check described below.

## Approved clips and editable rates

Production prefix: `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP096_BodyBones_Display.BodyClips.`

Editor prefix: `ServerStorage.RBX_ANIMSAVES.SCP096_VisibleBody.`

| Exact suffix at both locations | Stored length | Runtime speed | Runtime behavior |
|---|---:|---:|---|
| GetUp_Panic_BodyBones |3.0s|2×|Once per challenge;1.5s|
| Panic_BodyBones |2.0s|2×|Once after GetUp;1.0s, despite saved Loop=true|
| Running_BodyBones |0.600000024s|1×|Loop during actual pursuit/return travel; freeze when stopped|
| AttackRunStart_BodyBones |0.600000024s|1×|Once each time the existing attack predicate becomes true|
| AttackRun_BodyBones |0.600000024s|1×|Loop while that same predicate remains true|

Edit the individual `Speed` fields in `ReplicatedStorage.Config.World2SCP096Config` (Git mirror: `src/ReplicatedStorage/Config/World2SCP096Config.luau`). Begin a fresh Play session after editing Config; required ModuleScripts are cached within an existing session. The saved clip keys/times remain unchanged.

The server enters GetUp only from the owner's real Stage1 Wall4-clear hook. Actual stored durations divided by the individual rates determine the boundaries; there are no guessed fixed waits or delayed completion callbacks. Intro blocks both pursuit and boss attacks, then enters Running. Attack eligibility uses the existing valid combat session and unchanged distance/angle/height predicate. Entry starts AttackRunStart, completion enters AttackRun, exit interrupts either attack phase and restores Running, and re-entry starts AttackRunStart again. Damage remains25 on the existing1-second absolute cadence; attack animation never waits/gates damage. Blocked intro deadlines are discarded, not banked into a burst.

The client samples the saved body Bone poses directly, with authored timing/easing and per-clone model scale. Root planar displacement is removed in the Bone bind basis to avoid adding clip translation to existing PivotTo movement; vertical crouching and rotations remain. No animation asset upload, temporary registration ID, Animator track, new attack event or amplitude modification is used. Records are per owner/actor; cancellation retires the timeline with no callback able to restart a later challenge.

## Changed live Full Paths

- `ReplicatedStorage.Config.World2BossAnimationConfig`
- `ReplicatedStorage.Config.World2BossVisualConfig`
- `ReplicatedStorage.Config.World2SCP096Config` (new)
- `ReplicatedStorage.Modules.World2BossRig`
- `ReplicatedStorage.Modules.World2SCP096State` (new)
- `ReplicatedStorage.Modules.World2SCP096Clip` (new)
- `ServerScriptService.World.World2BossAnimationService`
- `ServerScriptService.World.BossAttackService`
- `ServerScriptService.World.EnemyManager`
- `StarterPlayer.StarterPlayerScripts.World2BossAnimationClient`
- The new template and its five `BodyClips` listed above.
- Enabled=false only on the three retained imported scripts listed above.

No balance Config, World1 setting, other boss definition, HP/reward/speed/turn value, saved-player schema, Map, equipment or UI Source changed. In particular, the existing attack-angle rules and death-camera/HUD edits remain. The shared service edits branch only for the new World2 Stage1 body; the049 intro path is unchanged.

## Verification and limits

**Static / native Edit checks:** All10 production Sources, the fixtures and recovery helpers compiled with Luau. Native Edit preflight passed114 checks: per-clip rates/durations, intro boundaries, repeated entry/interruption/cancel/actor isolation,73 Bone bindings, changed sampled poses for all five clips, stopped locomotion and unchanged actor pivot. These are not rendered visual acceptance. `EditPreflight.json` contains the actual result.

**Actual local native server plus two real clients:** `StudioTestService:ExecuteMultiplayerTestAsync(2,{})` ran the current unsaved document with in-memory stores and mocked Marketplace/Badge calls. The fixture used real wall destruction and accepted combat APIs, with programmatically positioned isolated test avatars, not mouse/keyboard input. Final run passed:

- Both owners: Wall4 → GetUp → Panic → Running → AttackRunStart → AttackRun, with73 body Bones bound and actual changed Bone transforms sampled on both clients.
- Exact server intro duration2.5s, with the first boundary at1.5s; pursuit was stationary and boss damage absent during the opening.
- Both actors actually pursued; AttackRunStart interruption, condition re-entry and AttackRun looping worked.
- Damage25 occurred0.149436s after AttackRunStart entry, before its0.6s completion; existing cadence remained1s.
- Death during intro and attack, reset during intro, World return, retries and a real accepted defeat retired the affected actor without resetting the peer.
- Actual departure of one test client preserved the other's actor.
- Other-owner visible parts0; animation tracks0. Final retired-owner animation records0/pending0; continuing owner1record/73bindings/pending0.

See `NativeFinal.json`. `Visible=true` in that data means the mesh's transparency flags allowed rendering; it is **not** a screenshot/visibility judgment. Toe Bone heights are diagnostic joint positions, not measured skinned sole contact.

The final server/client log review found no production-animation error. It did find early asynchronous test-observer errors when Stage01.Floor had not replicated yet; subsequent samples and all assertions succeeded. The repository observer now guards this optional diagnostic lookup; that final fixture-only guard was syntax-checked, not followed by another full combat run. Existing unrelated sound/archived-asset failures and native close-already-in-progress messages are not counted as a clean whole-game log. See `RuntimeLogReview.json`.

**Not verified:** rendered front/side appearance, visible skinned deformation in a captured frame sequence, final ground contact/twist/orientation quality, physical input and published-server behavior. Read-only MCP screen captures of the native clients did not return images; no GUI/camera/window manipulation was used to force a view. Bone movement and phase flags are deliberately not substituted for visual acceptance. The user had approved the original five clips, but that does not establish the new scaled battle presentation's appearance. No Cloud/public test or Publish occurred.

**Retained failed attempts:** First native run reached attack/re-entry checks but its defeat fixture incorrectly changed Strength after the existing encounter snapshot. Second run passed lifecycle/defeat but its RenderStepped observer produced no observations in the nonrendering test client. Only test preparation/sampling was corrected: lethal Strength before encounter start and Heartbeat pose observation. Production combat was not changed to satisfy either fixture. `NativeInitial.json` and `NativeSecond.json` retain those failures. An early read-only recursive integrity serializer also exhausted memory; it made no DataModel edits and was replaced by bounded flat serialization. The final audit initially lacked a count of readable UniqueIds; that omission was corrected, revealing the capability restriction below.

## Final restoration and save state

Test-only substitutions in36 Sources were restored to their exact prior production text; the three owned fixture Instances were removed. All10 final Sources match the Git files. The new five template clips match the current saved editor clips. Original model/19 editor clips/11 existing templates passed the final scoped property comparison. Camera CFrame, Focus and StarterGui.ShowDevelopmentGui match the initial current-session values. No display setting was restored to a guessed default. The test server/clients ended; both pre-existing user Studio instances remain, and the target is in Edit.

The live DataModel contains219,367 descendants at the final audit. Direct UniqueId reads were denied for all of them (`lacking capability RobloxScript`), so duplicate UniqueIds are **unverified**, not reported as zero. No binary serializer or rbxl write was used; INST/PROP/PRNT/redecode verification is therefore not claimed for this unsaved live-only delivery.

`FinalIntegrity.json` and `TestRestoration.json` record the checks and limitations. `ModelSnapshot.json`, `BuildTemplate.luau`, five exact `BodyClips/*.json`, `ClipManifest.json`, and `RestoreClip.luau` preserve the model/clip delta in recoverable form. BuildTemplate clones the retained current source only and refuses to overwrite an existing template; RestoreClip likewise refuses duplicate clip replacement. These recovery helpers are not installed as runtime scripts.

**Studio:** implementation remains in the current unsaved Edit session. **Local rbxl:** not written/reloaded. **Cloud:** not saved/published; unchanged by this task. The user must manually save before closing Studio or moving PCs. The Git commit records the Source/model/clip delta and evidence, not a complete place file or every unrelated unsaved user edit.
