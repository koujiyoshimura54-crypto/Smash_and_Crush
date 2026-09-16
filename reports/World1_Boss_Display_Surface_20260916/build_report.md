# Configurable World1 Boss display surfaces — 2026-09-16

## Baseline and scope

- GitHub main was verified online at dc4e4355817e463a9da7c0980c6fa6af68f84b09; local main and origin/main matched, tracked worktree clean.
- Read AGENTS and the four current SPEC documents. Connected Studio PlaceId: 101572058398926.
- Live CombatClient and EnemyManager matched the latest main snapshots after line-ending normalization.
- This repository records Studio source snapshots and documentation; it is not an automatic Rojo synchronization tree. Applied the implementation in Studio and exported the final three sources here. No Publish.
- Existing ignored local copies, backups and past reports were preserved.

## Implementation

- CombatClient creates one local BossDisplaySurface per Stage under PersonalCombatVisuals at initialization. It reuses Parts while toggling visibility and clears/recreates them for a new Run.
- Stage1–9 reference the next Stage .1 Wall. Stage10 references Stage10BoundaryWall, using Stage10 .4's existing StageSurface styling/Face.
- Width/height come from the reference Part. Current sizes: 88×56.25×0.05stud for Stage1–9; 90×56.25×0.05stud for Stage10.
- Reference Face supplies the local normal, transformed by Wall CFrame. Surface center = Wall center + player-side normal × (Wall half-thickness + SurfaceOffset + Surface half-thickness). Orientation derives from that normal and Wall UpVector; no Stage-specific coordinates.
- BossDisplayConfig: Transparency=0.5, SurfaceOffset=0.5stud clear gap, Thickness=0.05stud, HeightRatio=0.6, VerticalOffset=0, Color=RGB(210,220,235), empty StageOverrides. The common ratio keeps Stage9's full-name area inside the surface without a per-Stage exception.
- Surface: Anchored=true; CanCollide/CanTouch/CanQuery=false; CastShadow=false; SmoothPlastic. SurfaceGui.Active=false. No Combat, Damage, Trigger, Gate, Reward or Progress registration. No new Blur/PostEffect.
- EnemyManager adds only a spawn-time visual measurement: after cosmetic scaling and floor placement, existing staticBounds measures visible BasePart corners and Bone positions of the visual Model. Outer Collider/CombatZone are excluded. Attributes BossDisplayHeight and BossDisplayBaseY record the bounds.
- HP bar world center Y = BossDisplayBaseY + BossDisplayHeight × HeightRatio + VerticalOffset. Existing bar height, name/Stage spacing, fonts, full names, colors, NumberFormat and CombatState handlers remain.
- Bounds are not sampled each frame. Respawn recomputes them; existing 0.5-second client maintenance refreshes placement from cached attributes and retries streamed references.
- A normal-start test exposed delayed display initialization under Streaming. gauge now caches Current/Max before looking up the root, allowing the existing retry loop to create the display once ready.
- Boss unlock shows Surface and UI before contact. Boss result/defeat hides them per client; next Wall immediately displays authoritative Current/Max. Hidden Parts remain non-collidable, non-touchable and non-queryable.

## Play verification

### Actual Stage1 → Stage2 Combat

An isolated Studio test namespace was used for the physical combat fixture; production and normal Studio records were not given test Strength values.

- Existing Debug API set test Strength57. Character was placed at actual Wall contact regions; the unmodified EnemyManager monitor, Wall service and Boss service performed attacks and progression.
- Wall .4 clear: Stage2 .1 reference Surface appears with Transparency0.5. IsFighting=false; Ballerina Cappuccina / STAGE 1 / 250 / 250 visible before Boss contact.
- Boss contact applies existing pending Carry52: 198 / 250, followed by damage updates 141,84,27,0. Client label matched each packet.
- Defeat: no visible Boss surfaces; Stage2 .1 normal StageSurface/HPBar enabled, 300 / 300, Wall LocalTransparencyModifier0.
- Screenshot inspected: translucent surface lies just in front of the real wall, with its stud texture visible through the tint. No floating plane above the wall.

### All Stages and settings

- Real Play client received existing server wall snapshots and BossRecommendation for each Stage1–10. Every case showed exactly one active Surface, correct Stage/name/HP, and correct reference dimensions. These are UI fixtures, not ten complete physical combat runs.
- Config tests: VerticalOffset+2 moves UI center exactly2stud without changing either Part CFrame; HeightRatio .6→.7 moves by BossHeight×.1; SurfaceOffset .5→1 moves only the display plane forward .5stud; Transparency .5→.6 changes plane opacity.
- Stage1-only override VerticalOffset3 moves that UI3stud. All settings restored afterward.
- Raising reference Wall height56.25→76.25 and center by10stud leaves Boss UI world center unchanged. Runtime geometry restored; Edit Map stayed unchanged.
- Raycast including both Surface and Wall hits the real Wall. CanCollide/CanTouch/CanQuery=false asserted on all ten Parts.
- Server has zero BossDisplaySurface Parts; clients own their visuals. Multi-client simultaneous A/B progression was not executed.
- Runtime Stage1 template scale×1.25: next genuine enemy respawn changed measured height23.934675→29.918343 (ratio1.25). UI center changed to19.951006 and stayed stable during animation. Template restored and Play stopped.
- Stage10 uses SurfaceGui on the boundary-derived Part, not a Boss-following Billboard. Full Stage10 physical combat/WorldComplete and Gate travel were not replayed; their code is unchanged.

### Final normal Play and logs

- Removed both temporary QA Scripts and restored DataStoreConfig before final verification.
- Final normal Play at145.36seconds: ten local surfaces, ten gauges, zero visible Boss surfaces during Stage1 Wall1, normal Wall UI100 / 100; server surfaces0; temporary QA script absent.
- Final normal Play console: Runtime Error0 / Warning0 / Infinite Yield0 during observation. Studio returned to Edit afterward.
- Earlier isolated fixture emitted one ranking-mirror-save Warning. This occurred under the temporary test namespace; its exact storage failure cause was not established. It is not counted as a clean fixture console.
- Direct Assistant attempts to require EnemyManager/fire CombatState were capability-rejected. They were not game-code errors; verification used ordinary temporary Scripts instead.
- An initial edit replacement hit a declaration instead of its invocation; corrected before Play. No broken version was exported as final.

## Scope audit

- All395 final LuaSourceContainers compared to394 before: two changed, one added, none deleted.
- Changed: CombatClient; EnemyManager (ten presentation-only lines).
- Added: ReplicatedStorage.Config.BossDisplayConfig.
- StageWallDisplayClient, BossCombatService, Stage1WallManager, StageManager, World1BossConfig, all World2 Configs, DataStoreConfig/PlayerDataService, reward, strength/level and Carry code retain their original fingerprints.
- Reference Wall CFrame/Size equals before; no BossDisplaySurface exists in Edit. Map edits were not required.
- GAME_SPEC, UI_SPEC, DEV_STATUS, CHANGELOG updated. Historical CHANGELOG entries and earlier reports preserved.
- Commit message: Add configurable Boss display surfaces.

## Evidence

- before/ and sources/: starting/final snapshots.
- fingerprints_before.json / fingerprints_after.json / scope_comparison.json: complete source scope audit.
- map_before.json / map_after.json: reference geometry and no permanent display Parts.
- stage1_before_contact.json / stage1_after_combat.json: live HP and visibility transitions.
- all_stages_play.json / config_play.json / size_follow_play.json: Stage coverage, configuration and respawn tests.
- normal_play.json: final normal Client/Server and empty console evidence.
- verification/: temporary probes retained as history only, removed from Studio.
