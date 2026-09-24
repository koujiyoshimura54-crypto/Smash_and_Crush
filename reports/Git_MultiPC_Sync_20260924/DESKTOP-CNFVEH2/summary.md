# PC backup — 2026-09-24

- Host: DESKTOP-CNFVEH2
- Clone: C:/Users/kouji/Smash_and_Crush/Smash_and_Crush_updated_20260915
- Configured origin: https://github.com/koujiyoshimura54-crypto/Smash_and_Crush.git
- Git URL rewrite resolves HTTPS to SSH; configuration was not changed.
- Initial branch: main; initial HEAD and remote main: e77ecaba566ba099c7fda02957bfdb247c60af99.
- Backup branch: sync/DESKTOP-CNFVEH2-20260924-2203. Main integration is forbidden for this task.
- Readable C: drive scan found one matching clone; protected OS/user directories were inaccessible. Other discovered repositories had unrelated origins. One worktree, no stashes.
- Fetch found existing remote backup/world2-scp-e77eca-20260924. It was preserved, not overwritten.
- git rev-list --reflog --not --remotes returned no commits after fetch. Reflog commits 94f6fad and 0fc09e2 are already remote-reachable, not lost commits.
- Initial uncommitted CombatClient Trophy layout changes are preserved; Studio source agrees with them.
- No pull, merge, rebase, reset, restore, clean, force push, branch deletion, or untracked deletion performed during this backup task. Reflog contains historical operations, not new actions.

## Studio and backup limits

PlaceId 101572058398926, Edit. 482 LuaSourceContainers exported to src (419 new paths; all 63 prior source paths retained). ClassName, Disabled, original path components and duplicate-name mapping are in studio_script_manifest.json. This is an archival export, not a new Rojo deployment configuration: do not blindly deploy disabled/archive/third-party scripts.

GUI save-menu attempts were stopped when the user prohibited GUI work. No game source/property was intentionally edited through the GUI. No Publish or Play occurred. No GUI operations were performed after that instruction.

A complete .rbxl/.rbxlx save is NOT completed. A native .rbxm alternative preserves 84 root instances across 12 requested services, including GeneratedMap/TrainingArea, Treadmills, World2 maps, SCP source models/templates, attributes/pivots/rigs and GUI instances. Terrain, Camera, service properties and other service-level state are NOT a complete Place backup. Native restoration has not been tested. Do not treat this as a complete Place.

Local-only backup: C:/Users/kouji/RobloxBackups/Smash_and_Crush/DESKTOP-CNFVEH2/20260924_2203/

- scene-instances.rbxm: 3,471,187 bytes; SHA-256 B995010A38886556DB6817D1B6246F98B39B8E112072D3B19BCCF26DEDBF3834.
- repository-all.bundle: all original refs/history plus the backup branch at its initial HEAD.
- src-before/: pre-sync source copies; studio-sources.json: all 482 current sources and metadata.
- World1_Balance_Audit_20260916/: untouched original untracked report and CSV copies.

Full Place/model files, screenshots, GUI helper, caches and credentials are excluded from GitHub. The existing untracked World1 Balance build_report.md includes actual Player state observations and remains local, unchanged; four balance CSVs contain configuration audit data and are included.

## Integration review

Compare both PCs before merging. Focus on PlayerDataService pending-item mutation retry/metadata checks, InventoryPanelClient InventorySavePending text, ItemEffectHUDClient explicit image IDs, AuraConfig economy/templates, CombatClient Trophy layout, and the World2/shared EnemyManager/Stage01AppearanceClient/PersonalBossCollider changes already in e77ecab. DailyRewardsClient contains mojibake in Studio; preserved, not repaired. Old SPEC and historical reports are not rewritten to imply these changes were newly implemented/tested.

Push verification is recorded separately after backup commits. No runtime/gameplay regression test was requested or run for this read-only Studio backup.

