# World2 Battle repair and extended local verification ? 2026-10-21

Final implementation prepared; additional Play was stopped at the user's request. Departure continuity remains unconfirmed.

## Authoritative input and scope

The current place was read first (SHA-256 `17ce9238d4db65dfb34d82e375768bada63b79b19651036c85f0a1c1650f108d`). Current native Sources took precedence over historical generators and repository mirrors. The saved World1 chase settings were 16 studs/s and response 4; HEAD's 28/12 and the pre-existing local mirror's 20/12 were not imported into the place. No map generator was run.

The existing Pet equipment preview, 35 Pet models, paid facilities, Trophy choices, player-owned bosses, transparency fixes, map geometry, numerical World2 balance and saved equipment/progression remain unchanged.

## Causes and changes

1. World2's current forty walls contain the same purchased `SurfaceGui`/`Amount` interface as World1. `CombatClient.wallGauge` selected that interface only in World1. World2 fell back to the retired stage surface, leaving all four labels at `0/0`. Both contexts now use the existing purchased wall health renderer and number formatting. Streamed GUI descendants trigger one deferred, coalesced render for their wall. No per-frame map search was added.
2. The basic active-world death path already reset successfully in the baseline. A specific stale-run path was reproduced: clear World2 Stage1, return to World1, die to its Boss, then return to World2. `EnemyManager.Activate` reused the old Stage2 run, including four broken walls and the defeated Stage1 Boss, despite a replacement character. `CharacterAdded` also skipped installing that World's death observer while it was inactive. Runs now retain their character identity; activation initializes a new challenge when the avatar changes, and attaches one guarded death observer for the current character. Planned-loss respawn retains its existing guard. Old-character observers are disconnected/rejected; leaving removes the observer.
3. World2 Boss HP uses the existing personal overhead design. Its bounds now come from `BossVisualBounds`, including the rendered SpecialMesh dimensions measured by the existing placement service, rather than tiny invisible mesh carrier parts. Streaming/new actor generation continues through existing ownership/revision checks.
4. World2 chase speed and facing response are fixed per Stage in a small Config. World1 retains its actual 16/4. Attack interval, reach, cone, damage, telegraph, carry, collision shell and reward paths are unchanged.

## Changed Full Paths

- `ReplicatedStorage.Config.World2BossMovementConfig` (new ModuleScript)
- `ServerScriptService.World.BossChaseService`
- `ServerScriptService.World.EnemyManager`
- `StarterPlayer.StarterPlayerScripts.Combat.CombatClient`

## Rules comparison

Both Worlds already share the same combat implementation: individual wall snapshots, Strength damage, unlimited accepted Boss attacks, no encounter time limit, existing tap cooldown/automatic hit timing, 25 HP Boss hits on the existing one-second schedule, encounter healing on exit, individual Stage progression, and Trophy-only Win credit. The World2-only legacy `Lose` branch is unreachable under the current Strength-damage service and was left alone. World1 StageSkip remains World1-only. World2 Stage10 uses its existing completion state and adds no World3.

The actual saved World1 speed is intentionally preserved. World2 retains its own HP, required Strength, reward amounts, models, sizes, floor bounds and lack of animations. No additional live combat-rule mismatch was identified beyond the lifecycle defect above.

## Fixed movement configuration

`TurnResponse` is an exponential response rate in inverse seconds: increasing it makes facing settle faster. It is not a turn duration or an adaptive player-speed setting. The existing pursuit displacement direction and attack math remain unchanged.

| Stage | Before speed | After speed | Before response | After response |
|---|---:|---:|---:|---:|
| 1 | 16 | 18 | 4 | 4.5 |
| 2 | 16 | 19 | 4 | 4.8 |
| 3 | 16 | 20 | 4 | 5.1 |
| 4 | 16 | 21 | 4 | 5.4 |
| 5 | 16 | 22 | 4 | 5.7 |
| 6 | 16 | 23 | 4 | 6.0 |
| 7 | 16 | 24 | 4 | 6.3 |
| 8 | 16 | 25 | 4 | 6.6 |
| 9 | 16 | 26 | 4 | 6.9 |
| 10 | 16 | 27 | 4 | 7.2 |

Player Speed is 24/28/32/36/40, with upgrade costs 100/200/300/400 Win, and Premium is 50 (pass 1979583273). All four upgrades total 1,000 Win, below World2 Stage1's 3,000-Win claim. There is no per-Stage Speed purchase requirement: every Stage can encounter 24?40 or Premium 50. A precise expected purchase choice per Stage cannot be inferred. These settings are separate from player Speed and remain easy to tune.

A faster player can still outrun a slower Boss along a sufficiently long straight path. Fixed speed alone cannot forbid all safe circling or skilled avoidance while retaining the value of Speed. The measured circle trials explicitly include successful avoidance; these changes do not guarantee a hit.

## Verification method

Actual local server and two standalone Studio clients were launched with `StudioTestService.ExecuteMultiplayerTestAsync`. Existing combat/reset Sources were exercised, not replaced. A temporary in-memory DataStore/ownership/badge adapter isolated all persistence and purchase rights. Statistics, body tier and Speed ownership were test preconditions. No production data, real receipt, payment, Save or Publish was used.

The all-ten traversal and repeated battles used physical Humanoid movement plus ordinary client `AutoTapRequest("Tap")` requests, including server cooldown, damage, contact, progression and defeat processing. No wall/Boss HP setters or force-Clear were used. The representative speed/turn trials used explicit Stage entrance placement as a test precondition; those placements are not counted as natural Stage traversal. Gate positioning and travel requests are identified as fixture/Remote operations. Actual mouse wall damage, keyboard character reset and native GUI return operations are reported separately.

The renderer can pause in an unfocused standalone Studio client. Native viewport focus was restored for visual/input observations; rendering stalls were not treated as game defects. A fixture-wide all-wall query initially encountered a streamed-out wall and was replaced by observations while each Stage was loaded. An early automatic navigation approach needed a physical backstep; subsequent attacks still used normal combat. Back-to-back gate requests initially hit the existing one-second travel debounce and were retried respecting it. Those fixture failures are not recorded as successful cases.

## Results

- Final local session elapsed 2,475 seconds (41m15s). This includes setup/inspection and is not claimed as 41 minutes of active movement. The separate pre-change two-client baseline lasted about 18m40s. The all-ten uninterrupted traversal took 116.13 seconds, with normal wall damage and Boss kills at every Stage (see `AllTen.json`).
- All ten Stage Bosses were defeated through the real progression path. The first pass verified no automatic Win credit on a kill and existing World2 Stage10 completion. Player2's Stage10 right-pad claim added exactly 3,500,000 Win while Double Win ownership was enabled: 1 product multiplier, not 2.
- Real Boss-hit deaths were exercised at Stage1, Stage5 and Stage9, followed by Lobby respawn and a fresh Stage1 challenge. Later repeated trials also produced ordinary damage deaths. The explicit partially damaged Boss case recorded one accepted hit (350,000,000 ? 230,999,986), then real Boss-hit death and full challenge restoration.
- Three death ? retry ? Trophy ? retry ? Back ? World-round-trip cycles completed in the same local session. Their ordinary/Double/ordinary Stage1 claims added 3,000 / 6,000 / 3,000 Win. A travel debounce retry was required in the first cycle. Subsequent balance snapshots confirmed the cumulative 12,000 increase; the original first-cycle report and later event/case observations are distinguished from a single continuous exported report.
- The exact baseline regression was re-run successfully: World2 Stage2 with Stage1 defeated ? World1 Boss death ? World2 Stage1 with all forty walls full, no defeated flags, and a new run ID. Confirmed Win was retained. See `BattleCrossWorldReport` in `Verification.json`.
- Actual mouse input reduced a wall from 140M to 21M; actual keyboard character reset restored 140M, visibility and collision. `WallPartial.png` and `WallRestored.png` show the same viewpoint. The final native Back click was observed with the same character, revision 33 ? 34, unchanged Win and all forty walls full at Lobby (`BattleNativeBackProbe2`). Its click handler stopped only the temporary navigation controller so it could not automatically walk into a new run afterward.
- Two actual clients fought at the same and at different Stages. A guarded comparison verified that one player's wall/Boss clear, Trophy return, death/respawn and different-Stage encounter left the other's run ID, revision, Stage, Boss generation, Boss HP and Win intact while its Boss continued chasing. Both owner clients reported zero visible foreign Boss parts. Mixed World1/World2 battles and return/death were also exercised.
- Departure cleanup left one owner model and one runtime trigger. However, the surviving navigation trial's own duration expired around the departure observation, so this is **not** a successful uninterrupted-combat departure test. A replacement client was opened for a clean repeat, but the user stopped further testing before that repeat. Departure continuity remains unconfirmed.
- Body tiers 1 and 13 were used through the existing size service (height scale 1.1 and 3.55; the model's `GetScale()` stays 1 because body parts are resized individually). The maximum body cleared Stages1?4 and fought Stage5, and both normal/Premium speed cases exercised Stage10 contact and HP. No persistent model scaling was applied.
- Four physical movement patterns were compared at Stage1/Speed24, Stage5/Speed32, Stage10/Speed40 and Stage10/Premium50: straight segments with reversal in the finite arena, a fixed-direction circle, alternating lateral changes, and close orbit. Each trial ran up to 11 active seconds or death. Circles survived the observation windows (100/100/75/75 HP respectively); the other scripted patterns died. These are bounded scripted paths, not proof that all skilled players must be hit or that straight-line escape is impossible. No player speed, attack interval/range/damage or ownership rule was changed.
- Authoritative motion samples gave median translational speed about 18.00 / 22.00 / 26.37 studs/s at Stages1/5/10; the last includes boundary/contact-constrained movement. There were no chase recoveries in the collected samples. Facing-response samples agreed with 4.5 / 5.7 / 7.2.
- A direct server Heartbeat stopwatch used a stationary target repositioned within the arena as an explicit test precondition. Actual settling to <=10 degrees was 0.550s from 112.27 degrees (Stage1), 0.432s from 108.95 degrees (Stage5), and 0.334s from 107.92 degrees (Stage10). This measures real actor turning; it is not a manual cutback input measurement. See `BattleTurnReport`.
- Existing wall displays were observed updating through damage and break across the traversal, including M/B/T values. Actor/HP visibility was observed during the traversals and representative screenshots. Stage10's HP presentation was not separately retained as a screenshot; detailed visual checks of every camera angle are not claimed.

## Limits, cleanup and persistence

No real payment, production DataStore write, published-server join or production rejoin was performed. Marketplace ownership and persistence in these local tests were isolated substitutes. Existing asset permission failures for some sounds/textures and Studio/Core UI warnings were observed; those assets were not replaced. The temporary streamed-wall probe error and paused-renderer input issue came from the verification setup and were not persisted.

All local server/client Play processes were stopped. The owned Edit Studio was closed without Save/Publish, discarding all temporary adapters, test scripts, remotes, mock ownership and test characters. Only the four reviewed production Source changes are written by `tools/write_world2_battle.py`. Its fail-closed input hash, Luau compilation, binary re-read and exhaustive preservation checks verify the saved result. No additional rbxl or backup was created. The user requested immediate completion, so a fresh Studio launch/reload and the final departure repeat were omitted; binary saved-Source verification remains required and is recorded in `Writeback.json`.

Pre-existing changes in CHANGELOG/DEV_STATUS/GAME_SPEC and the owner's local Chase constants were kept outside this commit. No Pet/Egg/Merge/Shop changes were made. Future documentation updates should link this report and the fixed movement Config; existing unrelated document edits were preserved.
