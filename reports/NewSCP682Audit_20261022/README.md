# Newly imported Workspace.SCP-682: source audit and isolated preview

## Conclusion

**No malicious loader/backdoor was found within the fully inspected 14 Sources and their local dependency graph. Unapproved gameplay interference was confirmed:** enabled scripts can pursue/damage other characters, copy modules outside the model, mutate a global pathfinding setting, and destroy their NPC after death. These are readable NPC behaviors, not evidence by themselves of malicious intent. They are unsuitable for automatic execution in this game and are now disabled.

**This imported model does not currently have independently animated visible animal legs.** The real newly imported object's visible animal is a single rigid SpecialMesh. Its animated R6 carrier limbs are transparent. One original animation loaded and moved the hidden carrier; the other failed authorization. This conclusion comes from the new model's own Sources, native structure and actual Play, not a reused result for the old Stage9 template.

## Baseline and preservation

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Input SHA256: `7e948d203176ccd6bd827a7182982388bd471c0489daeac4b7497af0508e7fc3`. Read AGENTS, current specifications, the animation-preview/approved-walk/remaining-animation/four-boss records and fetched GitHub main. Latest remote baseline was `22c1618`; both current preview Sources exactly matched it. The imported model and the owner's declared newer edits form the current-file baseline.

The original working checkout remained at f499141 with unrelated dirty documentation/BossChaseService and untracked work. A separate source-only Git worktree based on origin/main was used to avoid mixing or discarding those edits. No additional rbxl, backup, copy or migration was created. No historical place or map generator was applied.

The user's connected Studio was already in Play on the Cloud place when inspected read-only; its server did not contain Workspace.SCP-682. It subsequently disconnected without this task stopping or closing it. Separate owned Studios 14004 and 24528 opened the actual local target in Edit. Imported scripts were never executed in either test session.

## Complete imported source inventory

The inner model's name is **one ASCII space**, not a dot or an empty string. In the table, prefix **P** means the exact path `Workspace.SCP-682. `, equivalently `Workspace["SCP-682"][" "]`. Full Paths, original Enabled/Disabled state, untouched full Sources, source hashes and saved instance references are in [OriginalScripts.json](OriginalScripts.json). All eight Scripts originally had Disabled=false. No LocalScript exists. Six ModuleScripts have no Disabled property.

| Full Path (P expanded as above) | Type / original state | Entire-source finding and dependency/impact |
|---|---|---|
| P.SCP049AnimationScript | Script / enabled | Loads this model's WalkAnim189040478, plays/stops on Humanoid.Running. No external code. The misleading 049 variable/name does not establish visible 682 rig compatibility. |
| P.SCP049HeadSoundScript | Script / enabled | Random local head sound selection, loop and four-second cooldown. Unused numeric sound-ID list is data, not a module loader. |
| P.SCP049AttackScript | Script / enabled | Scans Workspace models with Torso/Humanoid, selects a target within5 studs, applies70 damage, plays local attack sound and ArmOutAnim189040829, waits0.5s. Modifies other characters' health. |
| P.SCP049TargetScript | Script / enabled | Scans Workspace targets over a very large range, creates/removes its ForceField, heals itself, waits5s, unanchors root, MoveTo pursuit/jump recovery. Death branch disables sibling scripts and schedules destruction of its model. No hidden account/command condition. |
| P.Weld | Script / enabled | Chains direct child Parts with rigid Welds and unanchors later parts; trailing3s wait. Would constrain the carrier's moving limbs. Not needed/executed for preview. |
| P.Weld Script | Script / enabled | Another direct-child rigid weld chain. Model-local, but conflicts with joint articulation. Not executed. |
| P.Script | Script / enabled | Copies six ModuleScripts into ServerStorage only when a same-name instance is absent, then requires ROBLOX_ZombieAI and ROBLOX_DestroyService there. Starts AI, adds death cleanup and repeatedly loads Arms183294396 every2s. Existing same-name global modules could change resolution; the current file has none. |
| P.Animate | Script / enabled | Full legacy R6 animation dispatcher, child Animation overrides, local random-weight choices, tool StringValue consumption, Humanoid state events and0.1s loop. Direct DesiredAngle changes are seated/death/fall states, not a separate quadruped walk. No chat listener/UserId command. Running selects walk; run.RunAnim is an unused same-ID alias. |
| P.ModuleScripts.ROBLOX_AIUtilities | ModuleScript | Workspace ray/region queries, visible target selection, random nearby positions and repulsion-vector math. No external module or code request. |
| P.ModuleScripts.ROBLOX_DestroyService | ModuleScript | Starts a yielding cleanup coroutine on require; fades/destroys objects submitted by caller. In this graph the caller submits the NPC subtree. |
| P.ModuleScripts.ROBLOX_HumanoidList | ModuleScript | Starts a Workspace-wide Humanoid scan every3s on require. Read-only scan, but global work. |
| P.ModuleScripts.ROBLOX_StateMachine | ModuleScript | Local state/condition closures and yielding coroutine transitions. No global admin behavior. |
| P.ModuleScripts.ROBLOX_ZombieAI | ModuleScript | Requires four local modules through ServerStorage; random roaming, target pursuit, attack clip180416148, arm Touched damage, repulsion force/debug label updates and ongoing loops. No remote asset module. |
| P.ModuleScripts.ROBLOX_PathfindingLibrary | ModuleScript | Local PathfindingService calls and Humanoid.MoveTo/Jump; sets global PathfindingService.EmptyCutoff=.3 at require. Commented Workspace.Points deletion/creation is inactive. |

Dependency graph: P.Script exports all six modules, then requires ZombieAI and DestroyService. ZombieAI requires HumanoidList, AIUtilities, StateMachine and PathfindingLibrary. Every referenced module's Source was available and read completely. There is no numeric/external require, loadstring, HTTP request, InsertService/GetObjects asset insertion, encoded/obfuscated code reconstruction, privileged account test, chat command, DataStore, purchase/receipt, Teleport or administrative grant in these Sources. Animation/sound/mesh URLs are asset data, not fetched executable code. Delays, loops, death conditions and child-animation callbacks are recorded above; none was enabled for this audit. Source comments were treated as untrusted text, not instructions.

All eight imported BaseScripts now have Disabled=true, including both launchers and both weld scripts. All14 original Sources remain unchanged in the rbxl. Current game Sources have no caller for these imported modules outside their disabled entrypoint graph, and no ROBLOX_* module exists at ServerStorage's root. Preview removes every imported LuaSourceContainer before replication and never requires an imported module. Thus the existing invocation/export paths are blocked without deleting the original source or animation data. Manually re-enabling a launcher later would invalidate this containment; this is not a blanket guarantee about future edits.

## New model's actual geometry and animation inventory

[NativeStructure.json](NativeStructure.json) was exported from this newly imported Workspace model before Play. There are17 Parts,6 Motor6Ds,4 Welds,1 R6 Humanoid,5 CharacterMeshes,1 SpecialMesh,12 Animations,11 Sounds,62 Decals and no Animator, AnimationController, MeshPart, Bone or KeyframeSequence.

- `P.Torso.Mesh` is FileMesh **957757849**, texture **957760563**, scale approximately(0.984055,0.984055,0.984055), offset(0,5.904329,39.362202). The visible torso, four animal legs, head and tail belong to this one rigid rendered mesh. There are no skin weights/bones connecting its vertices to carrier limbs.
- Six connected R6 motors link HumanoidRootPart to Torso and Torso to Head/Left Arm/Right Arm/Left Leg/Right Leg. All five non-torso body parts are Transparency1. The root is anchored; the carrier body/limbs are unanchored. CharacterMeshes decorate those avatar parts; they do not split or skin the reptile mesh.
- Ten separate small neon Parts with eye decals are anchored and have no anatomical limb connection. Four HeadWelds have Part0=Head and no Part1. These are not leg joints.
- In preview only, the existing root remains anchored, connected carrier parts remain movable, loose eye decorations keep their existing anchors and Humanoid state evaluation/collisions are disabled. No whole-body weld chain is generated. Existing model geometry, scale, joint offsets, texture and colors are preserved.

Two reviewed walking IDs are exposed, using actual child objects rather than assumed default Animate IDs:

| Preview candidate | Exact data/source | Actual local Play result |
|---|---|---|
| WalkAnim (SCP049AnimationScript) | P.WalkAnim, `http://www.roblox.com/asset/?id=189040478`; referenced by P.SCP049AnimationScript | **Load failure:** Output explicitly says User is not authorized to access Asset. Length0/Time0 despite IsPlaying=true; no playback success claim. |
| Animate.walk / run | P.Animate.walk.WalkAnim and P.Animate.run.RunAnim, both `http://www.roblox.com/asset/?id=125749145` | **Loaded:** Length0.666667s. Actual hidden arm/leg Part CFrames changed. Visible animal legs did not articulate; only small rigid whole-body root motion is possible. |

Other retained animation data: ArmOutAnim189040829, climb125750800, fall125750759, idle125750544/125750618, jump125750702, toolnone125750867, Attack180416148 and Arms183294396. These were not executed or exposed as walking. The inspected Animate child overrides take precedence over its fallback table; its default run.xml is not the actual run child. No new animation was authored/uploaded, and no old682 clip was substituted.

Native front/side images show the whole visible animal with fixed feet relative to its body, without independent limb swing or body deformation. There is no stepping cycle whose contact/naturalness can be approved. At0.5x, a0.96s relative-Part sample measured hidden hip excursions about114.8degrees while the visible torso moved as one rigid unit (root rotation about2.12degrees). Those values prove carrier movement, not walking legs. Amplifying those carrier angles cannot create missing mesh articulation, so no misleading large-swing variant was added.

Before a production replacement, recover an editable mesh with appropriate rights and split the visible anatomical limbs or rig/skin the mesh with bones/weights, then create/retarget and validate a quadruped gait. Only after that should it be integrated into personal Stage9 actors with ground/pivot/attack/UI alignment and lifecycle checks. Simply attaching the present AnimationId is insufficient. None of that production work was performed.

## User procedure and changed Full Paths

Open the updated same CurrentCloud.rbxl, start Studio Play, then **Boss Anim Preview (Studio) → NEW SCP-682 (Workspace) → Animate.walk / run → Play**. Use Front/Side/Back and0.5x/1x/1.5x. The new selector is below the ten existing Stage buttons; **Stage9 / SCP-682** still means the old production template. Select **WalkAnim (SCP049AnimationScript)** to inspect its explicit load-error result. Stop restores the original pose; Close removes preview models and returns to the ordinary view.

Changed game Sources only:

- `ServerScriptService.StudioBossAnimationPreview`: separate string-key allowlist entry resolving Workspace.SCP-682; copy only two reviewed walking Animation data objects before stripping imported code; skip all production rig preparation and manually added generic Walk candidates for this new model. Reject changed expected source IDs instead of silently substituting them.
- `StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview`: separate new selector, per-view fitting for the long imported mesh, preserve preview-only loose eye anchors and explicitly distinguish loaded carrier animation from visible articulated walking. Existing Stage behavior/candidates are retained.
- The eight P Scripts listed above: Disabled only. ModuleScript Sources, imported hierarchy and all production Boss/map/gameplay/data properties are unchanged.

Both preview Sources return immediately outside RunService:IsStudio(), before creating UI/remotes/models/input. No new public-server preview or gameplay hook was added. No production Stage9 replacement or HP/reward/speed/size change occurred; the other nine walking Bosses,049 black thighs, HUD, death camera and160/210 attack settings are preserved by the property comparison.

## Verification and completion

[Verification.json](Verification.json) separates actual native UI/animation observations from static containment checks. Two isolated local Play sessions used the real Preview/model/Animator and actual UI clicks. Ninety-five other BaseScripts were disabled only in unsaved test Edit sessions to prevent game persistence, purchases and combat from running; their exact flags were restored afterwards. Imported scripts remained disabled throughout. No imported AI/module was run, no paid action occurred and no test data was supplied.

Verified launch, new/old682 switching, both candidates, success-vs-failure feedback, visible front/side views, speed controls, Stop (zero tracks), Close (zero client/server preview models), ordinary Humanoid camera and no Preview runtime errors. Final saved Sources were checked before the second Play, which reran both candidates and controls. Temporary full-window screenshots were inspected and removed; no screenshot evidence is committed. Public asset authorization, full-game regression and independent quadruped footfall are unverified/not applicable to the current rigid mesh.

The same file was written and re-decoded; native Studio reopened it and matched both Sources, all14 unchanged imported Sources and all8 disabled flags. [Writeback.json](Writeback.json) records4,919,551 checked property values, identical original parents, no new/deleted instances and zero changes outside the two Sources/eight Disabled flags. The native file has192,713 instances with valid dense references and no duplicate UniqueIds. No test adapter, fixture, captured image, new rig or runtime preview model was written. Owned Play was stopped and temporary settings removed. Studio Save/Publish was not used. Final lock/source/hash verification is in Completion.json.
