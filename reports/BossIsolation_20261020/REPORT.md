# Personal Boss actors in both Worlds — 2026-10-20

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Started from current binary/HEAD cc534cd after fetching GitHub. Preserved047775e,99772a8,bedf633, spawn and all later existing content. Only five existing Source rows changed; no authored Instance, model, animation, VFX, geometry, balance, reward, save schema or price changed.

## Cause and retained implementation

Reproduced with two real clients before editing: both World1 Stage1 encounters had375 personal HP, but both screens/server sessions referenced one Boss at the same position. Its ChaseTargetUserId was-2, so only one participant determined the shared pose and attack geometry. BossCombatService's HP, attacks, lottery/result snapshots; EnemyManager's sessions, defeated guard; walls, Trophy ownership, item rolls and stage progress were already per Player. Historical596a76b removed shared respawn and isolated HP, but did not isolate the physical actor. BossChaseService still selected one candidate from all eligible players for that Stage.

Reuse those logical encounters and builders. Each living player now has at most one authoritative actor for their current Stage in their active World, with owner, World, run revision and personal generation. World1's existing chase accepts only that owner. Its actual16 studs/s and turn response4 are retained. World2's existing stationary/lottery combat is retained; it did not previously run World1 chase or Boss-to-Player damage, and those were not added. World1 damage25/1s, manual/auto cadence, World2 attack cap and lottery formulas remain unchanged.

Actors are noncolliding and invisible/muted on the server. Only the owner restores the existing appearance/effects locally; existing personal colliders block only the owner's local view. Other players remain visible. Attack bounds use authored visibility metadata, preserving the original volumes despite default invisibility. Reset, death, departure and World deactivation destroy/deregister only that owner's actor. Removed the shared generation rebind path and broad per-frame Boss descendant scans. Client notifications validate owner/World/run/sequence; delayed server hits retain existing session/Character/instance identity guards.

The current purchased World2 walls no longer have World2StageSurface. Its Boss GUI had correct internal HP but nil Adornee; both old screens showed stale wall0/0 labels instead. The same existing personal overhead renderer now supplies the missing Boss donor. Cleared wall decals/UI obey existing personal clear state so they do not obscure the Boss. No general wall-HP/UI redesign or map edit.

## Changed Full Paths

- `game.ServerScriptService.World.EnemyManager`
- `game.ServerScriptService.World.BossChaseService` — explicit unregister only.
- `game.ServerScriptService.World.BossAttackService` — original visibility for bounds only.
- `game.StarterPlayer.StarterPlayerScripts.Combat.CombatClient`
- `game.StarterPlayer.StarterPlayerScripts.Combat.Stage03AttackVisual` — own actor lookup; original attack track observed playing, length0.5.

BossCombatService, StageManager, damage/lottery Configs, reward/drop/Trophy/return/gate services, StageSkip and spawn/Speed/growth/Rebirth Sources remain exact. The pre-existing dirty mirror Chase speed20 and HEAD28 differ from actual16; the writer applies only unregister to the current actual Source, and the commit excludes the dirty speed line.

## Actual multiplayer Play

Two real clients on one server, both screens visually inspected. Temporary progress/Strength/manual size and an in-memory persistence adapter were used. Four walls were prepared through the existing server wall state before approach, rather than replaying unrelated wall grinding. Boss contact, attacks, damage, defeat and Trophy collection then used real client movement/mouse input and production paths. Test-only health top-ups kept long World1 observations alive; actual25-damage hits about1s apart were recorded. No production save or real purchase.

- **World1 same Stage:**75/150 Strength produced375→300 and375→225 HP independently. The stronger player's subsequent win left the other's300 HP, pose/target and combat unchanged; the survivor completed its own remaining hits. Only each client's own actor was visible (3 visible parts versus0), with0 server/visual colliders; other Characters remained visible. Natural chase brought each actor to its owner.
- **World2 same Stage, final Source:**70M/140M Strength against current350M HP. Actual navigation/contact/mouse attacks produced separate HP/attack counts. When one won, the other retained140M after3 hits and then won with its own remaining2 hits. Both screens showed the correct personal Boss and350M gauge donor. The real stronger player's Trophy pickup credited3000 Win and returned/reset only that player; observer retained10000 Win/Stage2.
- **Death/Back/retry:**one player's forced test-state death in each World left the other's encounter running at the same HP; existing respawn/retry worked. Real Back GUI selection/Return reset only the requesting player's run in both Worlds. Mouse automation did not activate Back reliably; it is not claimed as mouse verification.
- **Different Worlds/Stages:**World1 Stage3 and World2 Stage2 fought simultaneously with real mouse hits (12500→10000/7500 and700M→560M). HP, targets, notifications and Worlds stayed separate. Stage3's original attack animation was observed on its owner's actor.
- **Latest StageSkip:**manual size13 used the actual Stage2 Skip UI (mouse open, keyboard purchase), spent1 Win, and walked until its own Boss collider stopped it and combat began. Navigation reported Path Blocked at this intended collider, not a transfer failure. Back, another paid Skip and3 accepted750-damage mouse attacks completed its2250 HP Boss. Observer's Stage3 HP7500 stayed unchanged. Skip Source is byte-identical to cc534cd.
- **Stage10:**prepared current Stage10 through existing InitializePlayer(10) plus wall state; no completion/reward before victory. Actual2-hit wins at125M Strength (World1 HP250M) and1.75T (World2 HP3.5T) set only the winner's respective WorldComplete. Actual Trophy walking credited1000 /3500000 Win. World1's HighestUnlockedWorld became2 only on its Trophy pickup; observer stayed1. World2 did not unlock World3. Existing return reset timing was retained.
- **Departure/join:**actual LeaveTest removed one client in each World. World2 survivor stayed at280M/1 attack, World1 survivor at300/1 attack, fighting its own target. Departed actor count became0; survivor count stayed1. A replacement real client joined without resetting the existing World2 encounter.
- **Cleanup/load:**five short reset cycles left0 prior actors parented and one current actor per living active player (two total across Worlds). Server colliding actor parts=0, enabled clone scripts=0. Source confirms one existing chase connection, explicit deregistration and destruction of per-actor event owners; global loops/watchers are reused. No maximum-player or long-duration performance claim.

## Mock checks and limits

Injected old-run, duplicate-WIN sequence and foreign-owner notifications left the live7.5K/12.5K gauge enabled and unchanged. Forged victory/damage and an extra-target Tap request did not change either player's state or rewards. Repeated real reward entry returned AlreadyProcessed; a foreign run returned InvalidOwner (World2) / StaleRun (World1). These are injected/native mock checks, not natural packet loss. Some initial automated clicks were processed by UI and did not attack; only observed accepted server hits count above.

Unverified: maximum player count, prolonged stress, real persistence/checkout/receipts, every Boss asset/animation rendered, all World2 lottery outcomes and every item grant. Both Worlds' ten Bosses share the verified factory/combat paths; Stage3's changed adapter and both Stage10 paths received extra actual checks. Existing unrelated asset-permission warnings remained; no new scoped Boss runtime error was observed. Temporary screenshots were inspected in tool memory; no image artifact was saved or committed.

Play ended, fixtures/adapters removed, and final Edit Sources matched tested code. The same-file writer compiles, re-decodes and verifies all other Sources/properties/parents/references/UniqueIds/SharedStrings unchanged. No post-test behavioral edits, extra rbxl/Backup/Copy/Migration, Save or Publish. Owned Studio/client process and lock checks are recorded in FileValidation.json. External rbxl is not Git-tracked; the commit records scoped mirrors, writer and English evidence.
