# Studio Phase 2–3 Script preservation (2026-09-30)

This is a Git-only export of existing Studio implementation, not a new gameplay change or a Place backup. Studio PlaceId: 101572058398926. No Script was written back to Studio; no Play, Place save, GUI save or Publish was performed.

## Repository selection and preservation

- Official remote: github.com/koujiyoshimura54-crypto/Smash_and_Crush (existing HTTPS origin addresses the requested SSH repository).
- Main worktree: C:\Users\kouji\Smash_and_Crush, main at fc2e0d7888bd29ec84d07d678a62d9409c4c9d55.
- Backup worktree: Smash_and_Crush_backup_20260925-0915 at 9088eb86d8be2be21dd5ffe8b7a94603fed6042c (clean).
- Boss worktree: Smash_and_Crush_boss_round_work at ff625a7218042df72ee118cf82d8d7f444d287bd (clean).
- The nested Smash_and_Crush_updated_20260915 directory is not an independent Git repository.
- Freshly fetched origin/main: e77ecaba566ba099c7fda02957bfdb247c60af99. Original main was 0 ahead / 9 behind; its uncommitted Hair file overlaps a remotely changed file.
- Export uses a new linked worktree, C:\Users\kouji\Smash_and_Crush_phase23_git_save, branch save/studio-phase23-20260930, created from origin/main. Existing worktrees and their branch tips are not changed.
- Main's HisarinoHairAutoEquip.server.luau remains uncommitted and untouched (SHA256 C0BC34F178C40E7ECF252B94600EE971C276361B3CEE0B300BE94CED116F5A94).
- Main's untracked reports/Visual_Templates_Secret_VIP_Green_20260917.md remains untouched (SHA256 2D03A0239F2D336224630FC1827E0744F721ECFA213DE579CB6861B4372EB04A).
- A local-only snapshot of all 509 Studio scripts plus copies of those two preexisting files is retained at C:\Users\kouji\Studio_Phase23_Git_Backup_20260930. No original report or backup was deleted.

## Export scope

See [manifest.json](manifest.json) for all 51 source paths and normalized SHA256 hashes. Source content comes from Studio, not old audit snapshots or other worktrees. UTF-8, LF and one terminal newline are used.

Key preserved changes:
- BossChaseService: CHASE_SPEED=28, Model PivotTo, arena limits, rotation and recovery.
- EnemyManager: .4 wall recognition before formal combat, chase/attack lifecycle, death/reset/exit handling.
- BossAttackService: damage 25, one-second deadlines relative to formal combat start, size-aware area, combat-only ForceField bypass and standard regeneration suspension, full heal on living normal exit.
- CombatClient: personal overhead HP surface following the boss, existing event-stage/generation visibility fixes.
- AutoTapConfig: ManualAttackCooldown=0.5. CombatConfig: AttackInterval=0.8.
- EnemyManager retains Stage02 YOffset=2.7, Stage07 YOffset=5.0 and the currently authored Stage08 YOffset=3.0.
- SpawnFacingCameraClient retains CAMERA_DISTANCE_MULTIPLIER=0.65 and one-shot scale adjustment with manual zoom.
- Existing Stage01–10 appearance/animation/VFX controllers, current size-selection, treadmill registration/guide, spawn-camera, inventory-save and presentation changes.
- Current Studio balance/config values are preserved, not recalculated or changed by this task. Some differ from older specifications (including current Aura and early World1 RequiredStrength tables).

Of 160 production-service scripts, 52 already match origin/main; 11 differ; 97 have no src entry there. Export includes nine substantive differences and 41 missing current versions plus the unchanged CombatConfig. The other 55 absent src entries have exact historical source snapshots and are not duplicated in this preservation commit.

Explicit exclusions:
- HisarinoHairAutoEquip: Studio versus origin/main differs only in blank lines. Do not import the unrelated old main-worktree edit.
- DailyRewardsClient: Studio has mojibake replacing two bullet characters. Preserve the full source locally; do not introduce that unrelated textual regression into main or repair Studio in this task.
- Workspace/ServerStorage asset and authoring scripts are preserved in the local snapshot but not bulk-added as runtime src files.
- Models, Animation Instances/IDs stored on Instances, KeyframeSequences, Attributes, CollectionService tags, UI Instances and VFX assets are outside this Script-only export. Restoring the whole Place requires its separate Studio save; this commit is not a complete Place restoration package.

## Verification and limits

- Compared Studio against main, both existing worktrees, fetched origin/main, and relevant historical source snapshots.
- Reviewed changed production source; no merge conflict was resolved or ignored.
- Read-only compilation (loadstring without invoking returned functions) succeeded for all 160 production-service scripts in Studio.
- A multiset comparison of all 509 script paths/classes/disabled states/sources confirmed no Studio changes during export; duplicate-named Part paths were accounted for.
- Selected file hashes match the Studio export after newline normalization. Git diff/manifest checks are performed before commit.
- This task does not repeat combat Play verification. Phase 2–3 runtime results remain prior verification, not fresh test results.
- Auto-to-manual near-consecutive Hit behavior is preserved; no attack-timing bug fix, balance redesign or Phase 4 implementation is included.

## Specification follow-up

GAME_SPEC / BALANCE_SPEC / UI_SPEC / DEV_STATUS still contain historical wall-mounted gauge, manual 0.25-second and older balance descriptions. Their next scoped update should document the preserved Phase 2–3 behavior, manual 0.5 / auto 0.8, current camera/offsets and current Studio balance. This Script-save task does not rewrite historical specifications or Play evidence.
