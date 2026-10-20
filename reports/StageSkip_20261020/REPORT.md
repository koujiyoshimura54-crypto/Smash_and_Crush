# World1 StageSkip repair - 2026-10-20

Updated only `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Final SHA256: `262460fa3466aa0fa88203dd257e66db2778274e9279fdda3625f6703c3a5589`.

The current binary already had `StageSkipConfig.IsSupportedWorld(player)` with the correct Player argument and World1-only meaning. The repository mirror lacked that existing function; the mirror is synchronized, without changing the saved Config. This candidate was not the runtime cause. Current prices are1/5/15/50/75/150/300/750/1200 Win for stages2..10; the older BALANCE_SPEC table was stale. Prices, IDs and conditions were retained from the current binary.

Confirmed cause: `StageSkipService.GetStartCFrame` required `StageN.1.Floor` and `StageN.1.CombatZone`, which no longer exist. Current `StageN.1` contains only Wall; the approach floor is `StageNN.WalkableGeometry.Floor`. All nine destinations returned nil. A real Remote request was rejected with `Character or Stage not ready`, without spending Win. The old clamp also used the boss-area Floor, which starts beyond Wall1.

The new resolver uses the actual walkable floor and first wall, keeps the body inside the floor and outside the existing forward combat trigger, and probes the collidable surface for root height. StageSkip now uses added entrypoints in LobbySpawnService for streaming, request-generation validation and the existing matching client pose/floor acknowledgement. **Every original36595fe function body is unchanged**; the writer verifies that removing the appended StageSkip extension reproduces the original Source exactly. Existing join/death/Lobby/Trophy transfer code and LobbySpawnClient are retained.

Win requests keep the per-player lock across streaming, then revalidate World, Lobby, combat, Character, loaded session and balance. The authoritative PlayerData setter debits once; placement rejection refunds it, and an unexpected initialization error also refunds/restores the origin. Skipped stages are marked without defeated Bosses, clear rewards or WorldComplete. Client requests have correlated responses, a bounded pending-state timeout and death/World-change cleanup. The existing Robux prompt/receipt route, product mapping, cooldown and visual design remain.

Changed live Full Paths:

- `game.ServerScriptService.Services.StageSkipService`
- `game.ServerScriptService.Services.LobbySpawnService` (appended entrypoints only)
- `game.StarterPlayer.StarterPlayerScripts.UI.StageSkipClient`

## Focused verification

Actual Studio server with two real clients; Player2 performed the actions while Player1 remained unchanged at2000 Win, World1/Stage1 and the same position/run identity. Persistence was a temporary memory-only adapter. No production DataStore write, receipt test, Robux prompt or real payment was performed.

- Actual UI: selected the existing Win GuiButtons and pressed Return. Stage2:2000->1999 Win, CurrentStage2, position approximately(287.8,6.94,207.8). Stage10 after a test-fixture lobby return:1999->799 Win, CurrentStage10, position approximately(287.8,6.94,1476.97). Both settled above floor Y4, unanchored, ahead of Wall1. Defeated remained empty and WorldComplete false; earlier stages alone became Skipped.
- Natural death restored the existing lobby/Stage1 path. UI remained usable. At0 Win, Stage10 returned `Not enough Win`, with no move or charge. A test top-up to5 followed by three rapid UI confirmations consumed only1 Win and started Stage2 once.
- A direct World2 Remote request was rejected without charge or movement;4 Win and the observer's state were retained.
- All stages2..10 returned valid positions inside their actual walkable floors, ahead of Wall1, with collidable support at Y4 and correct price/product round trips. No StageSkip-related runtime Error/Warning/Infinite Yield was observed.

Limits: mouse automation did not activate the Win controls; the successful UI tests used keyboard selection/Return, not direct handler calls. Physical mouse/touch input, Robux checkout/receipt retries, live save/rejoin, large-body variants, delayed-response timeout and injected engine failures remain unverified. The final surface-ray and initialization-error refund guards were added after loading the tested Play code; compilation/file checks passed, and native support probes at every tested destination matched Y4. No broad regression suite was run. [Detailed observations](Verification.json) distinguish the unsuccessful mouse diagnostic and corrected walkable-floor checks.

Same-file write passed compilation, re-decode/references and exact preservation of all other Sources/properties/parents/UniqueIds/SharedStrings. No new Instance or authored alternate rbxl/Backup/Copy/Migration was created. Treadmill ba1186f,36595fe, unrelated Boss changes and untracked files are retained. All Play sessions ended; Studio is in Edit, final Sources restored, and temporary adapter/scripts removed. No Studio Save/Publish or user Studio closure. As before, the external rbxl is not Git-tracked; the commit records Source mirrors, the guarded same-file writer and English evidence.
