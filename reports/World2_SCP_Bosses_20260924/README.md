# World2 SCP Boss implementation — 2026-09-24

## Authority and scope

- Fetched origin/main; starting HEAD: 9f34bca3562dedc57a4f178cd0e398b7f2442b7d.
- Studio place: 101572058398926, +1 スマッシュ&クラッシュ[ベータ版].
- Studio was newer than the repository in the shared combat code. The existing no-shared-respawn, visual-only transparency, and external RuntimeCombatTriggers behavior was retained.
- World1BossConfig, World2Config balance values, assets outside the scoped placeholders/SCP display instances, PlayerData schema, purchases, Rebirth, lottery/drop probabilities, Localization and UI styling were not changed in Studio.
- World2Config and World2BossConfig are exported unchanged as dependencies. World2 Trophy/Win rewards were not configured: RewardStatus=Unconfigured; no World1 trophy values are borrowed.

## Exact assets and stage mapping

Source prefix: ServerStorage.World2SCPAssets.SourceModels.
Display-template prefix: ServerStorage.EnemyTemplates.World2SCPDisplays.
Live/Editor-preview prefix: Workspace.World2Enemies.

| Stage | SCP / source model | Display template | Existing Boss HP | Existing recommended Lv |
|---|---|---|---:|---:|
| 1 | SCP-096 | SCP096_Display | 15,000,000 | 60 |
| 2 | SCP-023 | SCP023_Display | 50,000,000 | 75 |
| 3 | SCP-035 | SCP035_Display | 100,000,000 | 90 |
| 4 | SCP-058 | SCP058_Display | 250,000,000 | 105 |
| 5 | SCP-049 | SCP049_Display | 500,000,000 | 120 |
| 6 | SCP-173 | SCP173_Display | 1,000,000,000 | 140 |
| 7 | SCP-939 | SCP939_Display | 2,500,000,000 | 155 |
| 8 | SCP-106 | SCP106_Display | 5,000,000,000 | 170 |
| 9 | SCP-682 | SCP682_Display | 10,000,000,000 | 185 |
| 10 | SCP-323 | SCP323_Display | 25,000,000,000 | 200 |

The config is an explicit stage/SCP/template allowlist, not a fuzzy model-name search or candidate-folder enumeration. Source SCP-131 remains untouched. Its unused display is moved intact to ServerStorage.World2SCPAssets.ReservedNPCDisplays.SCP131_Display, outside the ten boss candidates.

The ten authored EnemyPlaceholder_Stage01..10 models are moved intact into ServerStorage.World2SCPAssets.ReservedPlaceholders. No original placeholder geometry is deleted or reshaped. They otherwise obscure the smaller SCP display clones.

## Implementation

- New ReplicatedStorage.Config.World2BossVisualConfig: explicit mapping and reward status.
- New ServerScriptService.World.BossVisualPlacement: cosmetic adapter only, not a second combat/progression loop.
- Shared StageManager, Stage1WallManager, BossCombatService, EnemyManager and TrophyRewardService gain cached ForWorld contexts. Existing World1 entry points remain compatible.
- StageProgressController initializes World2 and switches the active context on the existing validated gate request.
- CombatClient mounts the same renderer for each world with isolated event/state/collider tables. World2StageSurface is its existing wall UI reference; Stage10 uses the existing NextWorldArea.FutureConnectionBounds because World2 has no Stage10BoundaryWall.
- World2CombatState is a separate transport for the shared implementation. Attributes World2CurrentStage, World2Complete and World2StageNSubStage do not overwrite World1 run state.
- Existing Studio trophy UI styling was retained in Studio; its unrelated difference from origin/main is excluded from this task's commit.

## Placement and collision

Each stage uses Workspace.World2Map.BattleCorridor.StageNN.StageN.5.EnemySpawn and Floor. The source templates are cloned; original models and templates are not edited. No guessed world coordinates are used in production.

Visible bounds exclude fully transparent helper roots. The visual is centered in X/Z on EnemySpawn, keeps its upright template orientation relative to the marker, and its visible bottom is fitted to the authored floor top (Y=2.1). All ten runtime measured bottoms were 2.0999999–2.1000002.

MiniBossCollider is a separate transparent part matching those visible bounds. CombatZone uses the same five-stud horizontal margin as the shared system. Cosmetic parts have CanCollide/CanTouch/CanQuery=false. Humanoids and their rig joints remain; EvaluateStateMachine=false plus post-parent collision normalization prevents engine torso collision restoration. The existing client PersonalBossCollider provides player-specific blocking.

No GeneratedMap, TrainingArea, treadmill, World1 spawn or World2 floor/anchor position is moved.

## External script audit

All 62 executable source-model scripts were already Disabled=true at the start and remain so. No external script was deleted or newly enabled. Counts include 60 Scripts and 2 LocalScripts; zero ModuleScripts. The existing display templates already contain zero scripts and zero Sounds. A defensive clone guard disables any newly introduced BaseScript; this does not remove originals.

| Source | Script / LocalScript | Sound | Humanoid | Animator | AnimationController |
|---|---:|---:|---:|---:|---:|
| SCP-023 | 4 / 0 | 0 | 1 | 0 | 0 |
| SCP-035 | 7 / 0 | 2 | 1 | 1 | 0 |
| SCP-049 | 10 / 0 | 32 | 1 | 1 | 0 |
| SCP-058 | 1 / 0 | 0 | 1 | 0 | 0 |
| SCP-096 | 2 / 0 | 4 | 1 | 0 | 0 |
| SCP-106 | 5 / 0 | 0 | 1 | 0 | 0 |
| SCP-131 | 6 / 0 | 10 | 0 | 0 | 0 |
| SCP-173 | 0 / 0 | 0 | 0 | 0 | 0 |
| SCP-323 | 15 / 2 | 7 | 1 | 0 | 0 |
| SCP-682 | 6 / 0 | 11 | 1 | 0 | 0 |
| SCP-939 | 4 / 0 | 0 | 1 | 1 | 0 |

Audited behaviors include AI pursuit, direct health/damage changes, respawn/clone loops, jumpscare/player-control helpers, Sound loops and animation asset loads. See external_script_audit.json for every script path, disabled state and relevant source lines. Existing display rigs/Animators/Welds/Motor6Ds are retained. No external AI or animation script is needed for the current static display templates; adding new idle animations was not part of this task.

## Play and regression evidence

1. Normal Play creates exactly ten World2 bosses and ten World1 bosses; SCP-131 never appears.
2. Isolated QA session exercised the actual shared manual wall-contact and boss-contact path through World2 Stage1–10 in order. All advanced correctly, Stage10 completed, every boss Instance and SpawnGeneration stayed unchanged.
3. Out-of-order ClearStage(10) at Stage1 was rejected with 'out of order'.
4. Separate no-carry Stage1 test reduced 15,000,000 HP to zero through the accepted manual attack path.
5. All ten client gauges showed the matching SCP name and full configured HP with a valid BossDisplaySurface Adornee. Visual screenshots inspected all ten SCP models for orientation/contact after removing overlapping placeholders.
6. After defeat, the defeated client's visible cosmetic parts=0 and gauge.Enabled=false; shared root/collider LocalTransparencyModifier remained 0. No shared boss reconstruction.
7. Two mock participant records through BossCombatService proved A's completed encounter did not change B's HP/completion or shared Instance/generation; World1 encounter state was separate.
8. Actual two-client Studio session was NOT available/performed. The mock-state test is not represented as a two-client rendering test.
9. World2 Character reload reset its run to Stage1 and placed the player at the existing World2LobbySpawn. Existing ReturnWorld1 and ToWorld2 remotes worked through their real gate checks.
10. World1 Stage1 walls/boss still progressed to Stage2; the other nine World1 bosses were present. A full World1 ten-stage replay and trophy pickup probability distribution were not retested.
11. Final fresh normal Play after QA cleanup: Error=0, Warning=0, Infinite Yield=0; active external scripts=0; colliding World2 visual parts=0. See final_runtime.json.
12. Nine changed/new implementation sources compile. Temporary QA scripts, camera controller, test clones and isolated DataStore suffix are removed/restored. Production data schema and naming are unchanged.

QA errors during development (test-only Player construction permissions, early streaming probes, and missing reference naming) were not silently counted as a clean final run. They were resolved or removed and a fresh final run was checked.

## Final state / limitations

- Edit mode restored. Ctrl+S sent to the verified +1 スマッシュ&クラッシュ[ベータ版] Studio window; the MCP interface does not expose a save-completion acknowledgement.
- No publish operation.
- World2 Trophy/Win reward amounts remain unconfigured; no invented production values.
- Two-client visual continuity still requires a real multiplayer Studio test.
- Original imported models retain their native sizes and static display poses.
- Pre-existing reports/World1_Balance_Audit_20260916 remains outside this commit.
