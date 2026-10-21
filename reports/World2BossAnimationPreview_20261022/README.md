# World2 existing-animation inspection panel — 2026-10-22

## Use

Open the updated `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` and start Studio Play. Click **Boss Anim Preview (Studio)** at the upper right. Select a Stage/Boss, select an existing candidate on the left, then Play. The list scrolls when needed. Use 0.5x / 1x / 1.5x and Front / Side / Back. Stop reconstructs the original template pose. Close deletes the preview and returns to the ordinary game view; the game camera is never replaced.

This is an inspection tool, not a decision about animation quality or suitability. It does not connect animations to live Boss combat.

## Current-file audit

Read AGENTS and the requested SCP source-script audit, parity and Battle records. The current file's starting SHA256 was `5d0d6407bc505f79436d697682f4f8f02c47d698cba44b853c6d52f923823433` (after e54fdcc). The user-owned Edit Studio was inspected read-only; that Studio subsequently disconnected and exited during an installation update. It was not closed by this task. The saved target hash remained unchanged.

The historical `ServerStorage.World2SCPAssets.SourceModels` archive is **absent** from the current saved file and the initially connected Edit data model. All six actual display templates have zero executable Scripts. No MainAnimation, Animate child override, R6Animate/R15Animate, or Stunned was recovered from an older place or substituted with standard Roblox animation IDs. The old report is historical evidence, not the current asset inventory.

Template prefix: `ServerStorage.EnemyTemplates.World2SCPDisplays`.

| Stage | Boss/template suffix | Current actual rig | Existing animation content / result |
|---|---|---|---|
| 1 | SCP-096 / SCP096_Display | R6 Humanoid; 6 connected Motor6Ds plus one unused Motor6D | No Animation, KeyframeSequence or MainAnimation script. Model previews; no animation candidate. |
| 3 | SCP-035 / SCP035_Display | R15 Zombie/Animator inside the unnamed child Model; 15 motors | Animate and child Animations absent. No candidate. |
| 5 | SCP-049 / SCP049_Display | R15 Humanoid/Animator; 15 motors | Two Animation objects and four KeyframeSequences, detailed below. |
| 6 | SCP-173 / SCP173_Display | Static welded model; no Humanoid/Animator/Motor6D | No existing animation. No new rig is created. |
| 8 | SCP-106 / SCP106_Display | R6 Humanoid; 6 motors | No Animation, KeyframeSequence or joint-motion script. No candidate. |
| 10 | SCP-323 / SCP323_Display | R15 Humanoid; outer and nested Wendigo motor sets, 30 motors total | Animate/Stunned and animation objects absent. No candidate. |

### SCP-049 candidates

| Exact existing name | Original ID or source suffix | Observed result |
|---|---|---|
| Animation | `rbxassetid://774242142` | Asset failed to load in local Studio (PlaceId 0), Length 0 despite IsPlaying=true. Purpose remains unverified; not renamed Idle/Walk. |
| ArmOut | `rbxassetid://4651534593` | Same local asset-load failure. The current object and historical AI reference establish its name, not successful playback. |
| Automatic Save | `SCP049_Display.AnimSaves.Automatic Save` | Existing single-frame left-arm pose applied to the real preview rig. Explicitly labeled a saved pose, not timed motion. |
| Idle | `SCP049_Display.AnimSaves.Idle` | Actual three-second looping clip played. Visible head/neck movement confirmed in images and relative **part CFrames**, not just track state. |
| Idleed | `SCP049_Display.AnimSaves.Idleed` | Two identical weighted-pose frames. Applied and labeled a static saved pose; speed has no timed effect. |
| Imported Animation Clip | `SCP049_Display.AnimSaves.Imported Animation Clip` | Existing single-frame left-arm pose applied; explicitly labeled a saved pose. |

The asset errors name the assetdelivery URL with serverplaceid=0 and report “Animation failed to load.” Permissions versus asset availability was not conclusively distinguished. The panel shows load/permission failures and loading timeout; ownership in the published Experience was not tested or changed. Both failed candidates remain available for the user to retry in an appropriately authorized Studio context. No replacement asset was uploaded or authored.

## Implementation / Full Paths

- `ServerScriptService.StudioBossAnimationPreview` (new Script): Return immediately outside IsStudio, before creating any remotes or clones. Use an explicit six-Stage allowlist. On selection, clone the current Boss template into one temporary per-player replicated container; strip executable sources, sounds and interactions. Enumerate real Animation objects and saved KeyframeSequences. Deduplicate equal asset IDs, preserve actual names/paths, and identify identical/single-frame saved poses. Close/leave removes that player's model. Monotonic request epochs retire old selection/close requests.
- `StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview` (new LocalScript): Return immediately outside IsStudio, before UI/input creation. Show exactly one clone in a ViewportFrame/WorldModel. Keep the template's visible appearance and joints; normalize only preview anchoring/collision and Humanoid state evaluation. Use the existing Animator or add an Animator only to the preview Humanoid. Register existing local KeyframeSequences for playback; apply static saved poses without inventing motion. Rebuild on candidate change, Play and Stop. Viewport cameras provide front/side/back and fit visible bounds. Dispose tracks, render/log listeners and WorldModel on replacement/close. The ordinary Workspace camera is not changed.

Studio inset-dependent synthetic activation was unreliable during setup. The final panel uses actual pointer/touch input with PlayerGui hit testing, dispatching only hits on its own registered buttons. It neither dispatches underlying game UI nor consumes unrelated clicks. Press feedback is panel-local. Earlier missed-coordinate/activation attempts were not counted as successful switches. Final real-click verification ran without any input-probe Source.

WorldModel and local sequence registration follow the official [WorldModel reference](https://create.roblox.com/docs/reference/engine/classes/WorldModel) and [KeyframeSequenceProvider reference](https://create.roblox.com/docs/reference/engine/classes/KeyframeSequenceProvider). No Workspace preview arena was necessary.

## Actual Play verification and limits

Used an owned local Studio. For isolated preview verification, 94 other game BaseScripts were disabled **only in unsaved Edit memory**, so game persistence, purchases and combat could not execute. No data, ownership, Win or progression fixture was supplied. The real models, animation loader, WorldModel, GUI/input and cleanup ran in actual Play. All original Disabled flags were restored before closing, and no such changes are in the place writeback.

- Actual UI launch and all six Boss switches passed in the final panel. Each switch left exactly one displayed preview model. Missing content is shown explicitly for the five models without candidates.
- All six SCP-049 candidates were selected through the UI during development. The two failed assets displayed an error; they were never called successful based on IsPlaying. Both single-frame poses applied visibly. The final static-pose implementation was separately confirmed with Idleed.
- Idle visibly moved the head. A 0.7-second part-space sample measured 6.87 degrees in the initial 1x check, and another final 0.5x sample measured 42.40 degrees across the clip phase/loop boundary. These are observations of this existing clip, not a naturalness rating or frame-rate claim.
- Actual UI speed changes produced track.Speed 0.5 and 1.5; default 1x was also exercised. Front, Side and Back views were operated. Full-body images for SCP-096 and SCP-049 were inspected temporarily.
- Stop reconstructed the original template and left zero playing tracks. Close hid the panel, restored its launcher, removed the client WorldModel and all server-side preview Models. The game camera still targeted the player's Humanoid.
- Final scoped client log inspection found no preview-script runtime errors. Generic failed-asset messages are the failed candidate results above.

The final Play was stopped. This was not a full-game combat/DataStore regression, published-server test or authorization test for the animation asset IDs. The published-server exclusion is checked from the two leading IsStudio guards. The tool does not start any imported AI, damage, respawn, jumpscare or Animate script. User assessment of naturalness and adoption remains open.

## Preservation and completion

`tools/write_boss_animation_preview.py` checks the unchanged current input hash, compiles the two Sources, adds only their two script instances and validates all existing Source/property/parent rows unchanged. No Boss rig, animation content, HP, movement, scale, map, UI, data or prior feature Source is replaced. Unrelated dirty documentation, BossChaseService and untracked files remain outside the commit. The same rbxl is written and re-decoded; no additional rbxl/backup/copy/migration or Studio Save/Publish is used.

`Writeback.json` records saved Source hashes and preservation checks; `Verification.json` records actual final UI observations. Completion/native reload and lock release are recorded in `Completion.json`. Temporary screenshots and input probes are not retained in the place or repository. A future specification update can link this Studio-only developer tool; existing dirty gameplay specifications were preserved.
