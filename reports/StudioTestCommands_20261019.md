# Restore the missing Studio /test entrypoints — 2026-10-19

## Confirmed cause in the actual file

Input/output is the same `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`.
Input SHA-256: `e25dc9e34a46a4021bded4ceec8405ba042c77a5c47a2791534860e52e94e650`.
Final SHA-256: `7ece6d8e887ea248dca746535529977bed45c3dc3c1b4c394777992b9b6f2b8b`.

The actual binary hierarchy had **no** `ServerScriptService.Systems.Debug.StudioStartController`
and **no** `StarterPlayer.StarterPlayerScripts.StudioTestCommandClient`, despite their
Sources existing in Git. Therefore the /test registration and result listener never
started. This is a separate path from the working StudioDebugController/Service/Client.
No repeat input confirmation or /resetdata execution was needed.

`ServerScriptService.Config.StudioDebugConfig` exists as a ModuleScript. Its actual
Start settings already have Enabled=true, ChatCommandsEnabled=true and
AutoApplyOnPlay=false. These settings remain byte-identical. The required current
PlayerData override functions, LevelProgression/LevelRequirements modules and
EnemyManager.ForWorld APIs also exist. Their Sources were not replaced from Git.
No runtime require failure is claimed as the cause: the missing entrypoint could
not execute any require in the first place.

The two runtime-created objects were absent in Edit, as expected when there is
no controller: `TextChatService.StudioTestCommand` and
`ReplicatedStorage.Remotes.StudioTestCommandResult`. They remain runtime-created;
neither a dormant saved command nor a new permanent Remote was added.

## Changed instances and behavior

| Full path | Class / execution | Source mirror |
|---|---|---|
| `ServerScriptService.Systems.Debug.StudioStartController` | Script, Disabled=false, Legacy context under ServerScriptService | `src/ServerScriptService/Systems/Debug/StudioStartController.server.luau` |
| `StarterPlayer.StarterPlayerScripts.StudioTestCommandClient` | LocalScript, Disabled=false, Legacy context under StarterPlayerScripts | `src/StarterPlayer/StarterPlayerScripts/StudioTestCommandClient.client.luau` |

Restore these two missing instances using existing inert script schemas, fresh
UniqueIds/ScriptGuids and the existing /test implementation reconciled with the
actual dependencies. No original Instance, parent or property is modified.

- Register one named TextChatCommand with PrimaryAlias=/test and one Triggered
  handler before gameplay requires. Replace stale objects with the same command
  name, without changing the separate working Debug aliases.
- help/status work while gameplay dependencies initialize or fail. Status includes
  dependency readiness/failure; initialization errors and slow initialization name
  the dependency in Output. Configuration failure is also reported in Output.
- Preserve help, status, level, start, reset, world, stage, default and the existing
  numeric start shorthand. Invalid arguments and unexpected execution errors reply
  through the result Remote and Output.
- Level uses the actual PlayerDataService.ApplyStudioStartLevel and the unchanged
  progression curve, updating authoritative Level/Strength/LevelProgress and their
  replicated attributes. Level-only never calls EnemyManager or PivotTo, including
  its reset/respawn path. No Strength-to-Level change is made to /setstrength.
- start/world/stage/default keep the existing EnemyManager.ForWorld Deactivate,
  InitializePlayer(player, stage), Activate and lobby placement path. Check IsReady
  before changing worlds. Reset restores the existing PlayerData snapshot and the
  original World/Stage when the command had requested movement; it does not claim
  to restore an exact pre-command CFrame or all combat state.
- Keep partial level overrides resettable if later placement fails; release Busy
  after reset exceptions and report respawn-placement errors.
- The Client binds an existing or later-created result Remote once. It waits for
  RBXGeneral when needed, displays system messages and retains the result in Client
  Output if the channel is unavailable. No new screen GUI or client-to-server input.
- Both entrypoints retain RunService:IsStudio guards; Triggered/execution paths
  also guard Studio. AutoApplyOnPlay remains false. No production command enablement.

## Existing persistence and gameplay preserved

PlayerDataService.ApplyStudioStartLevel refuses unloaded/saving data, takes the
existing StudioStartOverride snapshot and sets LevelProgress=0. RestoreStudioStartOverride
restores its fields. The existing Save guard returns StudioRuntimeOverride while
that override is active. These actual functions and guard were used in the memory
test without running PlayerDataService's DataStore initialization. No fabricated
fallback data, DataStore constraint bypass, real session load or real save.

All 417 original Sources and 4,714,862 original property values are preserved.
All original parents remain unchanged. This includes working Debug, PlayerData,
Pet/Egg/Dumbbell code, World1 and the b047204 World2 lobby geometry: 237x169 floor,
seven treadmills, moved Dumbbells and Eggs, BattleCorridor and Stages. No lobby
generator was run. Existing unrelated tracked/untracked edits and stash remain.

## Verification and limits

- **Static/binary:** exactly two added instances; 182,085 final instances across
  162 classes; dense IDs 0..182084, zero invalid/missing references or duplicate
  UniqueIds. INST, 78,372 PROP.Ref values, PRNT and 362 SharedStrings / 208,405
  indexes validate. Fresh Decode and byte-idempotent canonicalization pass.
  The two decoded Sources match the current mirrors. Luau compiler passes both.
- **Memory simulation:** `tests/StudioTestCommandsOffline.py <luau.exe> --place
  <CurrentCloud.rbxl>` passes **158 assertions** using actual saved entrypoints,
  actual Config/requirements/progression, extracted current PlayerData functions
  and the actual HUD update/signals with memory-only adapters. Covers one command/
  reply, pre-init help/status, level 45 and HUD attributes, no level-only movement,
  Save exclusion, start/reset/world/stage/default, invalid/unloaded/not-ready/error
  paths, Remote-to-Client/system-message dispatch and non-Studio exclusion.
  EnemyManager effects, TextChatCommand triggering, replication and chat rendering
  are simulated, not real engine gameplay or typed chat.
- **Native Studio Edit:** reopened the exact written file in owned Studio
  `bf82447f-ed9d-47ba-bd42-53f33100f219` (PID27660), mode Edit, running=false,
  PlaceId/UniverseId=0. Both script classes, parent paths, Disabled=false and Legacy
  context confirmed; native loadstring compilation succeeds for both Sources
  without executing them. Runtime command/Remote absence in Edit is expected.
- **Not verified:** real chat input, runtime command registration/require completion,
  real replicated HUD response, live World/Stage travel, real restoration/save and
  production behavior. No local Play, /resetdata, real DataStore operation, Studio
  Save or Publish was performed.
- Only the owned verification Studio was closed normally without saving. User
  Studio `1395d9d1-323d-4792-84dc-5194c5a58099` is untouched. Final hash is unchanged
  after native inspection and the target lock is absent. No extra rbxl, backup,
  copy or migration file.

[Binary/preservation manifest](StudioTestCommands_20261019.json).
Implementation: `tools/restore_studio_test_commands.py` is a guarded, dry-run-by-default
same-file restoration. It refuses changed inputs and never replaces original Sources.
