# World2 approved HP and 55 authored walls — 2026-10-31

Implemented in the user's open unsaved Studio document, PlaceId126576845524886, loaded version303. Final live Edit verification passed:446 original Sources accounted for,8 deliberately changed,55 World2 wall models present and connected,35 temporary dependency substitutions restored,3 QA fixtures removed, and9,804 unrelated Stage geometry records unchanged. No Studio Save/Publish, rbxl write/reload, OS mouse/keyboard, window switching/rearrangement or user Studio closure was performed. Manual saving remains the user's responsibility.

The latest GitHub main4c47f77 was fetched and fast-forwarded before implementation. Its approved World1 balance and preceding Merge/respawn work were retained. The only pre-existing local untracked report, Visual_Templates_Secret_VIP_Green_20260917.md, was left outside this commit. The current live Source was the starting point: all eight touched Sources matched the latest corresponding Git files before applying narrowly guarded deltas. No full Source set or old place was imported into Studio. The local recovery snapshot is text/JSON only and stays outside Git.

## Exact implementation

The approved table is in [BALANCE_SPEC](../../docs/BALANCE_SPEC.md); exact integer readback is in [final-edit-verification.json](final-edit-verification.json). Boss HP by Stage is15M/30M/75M/150M/500M/1B/5B/15B/45B/150B. Stages1–5 have five walls at40/50/60/70/80% of Boss HP; Stages6–10 add the90% sixth wall. RequiredStrength follows HP/5 as a reference only. No entry gate, enforced five-hit fight, balance recommendation or test-driven numerical adjustment was introduced.

Changed Source Full Paths:

- ReplicatedStorage.Config.World2GameplayConfig — approved HP/wall arrays and balance version only; all workbook rewards/equipment/shop/Pet/Treadmill values retained.
- ReplicatedStorage.Config.World2Config — per-Stage WallCount and multiplier views; maximum multiplier list extended to the sixth wall. GetWallCount/GetWallHitMultipliers read the Stage rows. World2BossConfig itself is unchanged and follows this authority.
- ServerScriptService.World.Stage1WallManager — current target, initialization/skips, damage/carry, unlock and snapshots use each Stage's wall count; snapshots also include WallCount.
- ServerScriptService.World.EnemyManager — next-wall notifications, complete-wall sweep and final-wall recognition/intros use the count. Final surplus remains discarded. The World2 Boss-section reference uses its new unambiguous name.
- StarterPlayer.StarterPlayerScripts.Combat.CombatClient — all wall rendering/reset/update loops, final-wall references, Boss display/collider eligibility and streamed wall-name matching use the relevant count. It retains the owner/revision/message guards and existing HP formatting.
- ServerScriptService.World.BossVisualPlacement — World2 Boss-section lookup and the arena's final-wall boundary follow the layout.
- ServerScriptService.World.BossChaseService — World2's arena entrance uses the actual final wall; speed/turn/animation parameters are unchanged.
- ServerScriptService.Services.TrophyRewardService — World2 Boss-section lookup follows the rename; pickup, rewards and return behavior are otherwise unchanged.

No World1 HP/reward/shop/size/movement/animation/drop/equipment/Rebirth/Treadmill/save schema or inventory values changed. Shared consumers still resolve World1's four walls from its existing authority. Animation modules, clips, rates, sequence and attack predicates were not edited. SCP-096 and SCP-049 intros now begin on wall5 rather than wall4; Stage6–10 unlock on wall6.

## Authored model changes and placement

All changes exist in Edit, independent of Play. [ApplyWallLayout.luau](ApplyWallLayout.luau) records the scoped migration; [layout-manifest.json](layout-manifest.json) records every wall Full Path, clone origin, HP, before/after pivot, body CFrame/dimensions and Boss rename. This is the Git record for non-Source additions/moves.

For each Stage, Workspace.World2Map.BattleCorridor.StageNN contains StageN.1 through StageN.5/6. The original physical wall1 and wall4 models remain at the original first/last endpoints. Wall4 is renamed to the final number; the complete same-Stage wall3 subtree supplies the15 additional models. Each includes Wall, its six texture faces and SurfaceGui hierarchy, CombatZone and Floor. WallIndex/SubStageIndex attributes, stage labels, HP text and HPConfig references were updated. No Source was added inside a wall.

Every original endpoint span is30 studs. Five walls use7.5-stud center spacing and six use6; body dimensions stay98.34×27×1.2. Visible face gaps are6.3/4.8 studs. The invisible noncolliding CombatZone volumes can overlap at the six-wall spacing; only the current wall is eligible for attack. Current-wall-only HP presentation prevents overlapping gauges. Boss sections are renamed StageN.5 → StageN.Boss and assigned SubStageIndex=count+1 without moving contents. Boss/Trophy markers, floors/lengths, decorations and perimeter geometry were compared with the original live snapshot. No map extension was necessary.

The native Edit capture of Stage6 showed distinct wall bodies with no visible intersections. It is a limited side/overhead structural view, not a full visual review of all10 Stages. No screenshots are committed. The capture tool altered camera/focus state despite its temporary-view description; both were explicitly restored to the initial values, and final CFrame/focus/FOV/type/development-GUI checks passed.

## Actual Play evidence

Tests used StudioTestService through the existing Studio connection and its current unsaved document. No OS input or window manipulation was used. All persistence, badge and payment dependencies were temporarily routed through the same isolated in-memory QA service used by the preceding approved work.35 dependency substitutions were audited before restoration. Real account stores, badges and purchase prompts were disconnected. Prepared Strength, selected size, positions and starting Stages were explicit fixtures. Native Humanoid walking, normal travel requests, accepted combat API hits, client production rendering/state events and normal Trophy overlap/return paths supplied the observations. This was not natural progression, a production-account test or a clear-time benchmark.

- [native-result.json](native-result.json): all10 Boss HP and55 wall HP/count/order values matched. Every wall took a half-HP hit with the existing formatted label, then a second accepted hit; cleared walls became hidden/noncolliding for the owner. No intermediate wall unlocked the Boss; the final wall did. Every Stage's owner was recognized and pursued, and final snapshots resynchronized correctly. Stage1/5 intro timestamps were absent before their last wall and present afterward.
- Stage5/6/10 single-hit carry reached the added final walls and discarded excess at the Boss boundary. Boss gauge stayed full immediately afterward.
- The same run used two real native test clients on Stage5 and6. One player's partial-final-wall death, Boss-combat death, accepted defeat, actual Trophy pickup/return and retry did not change the peer's wall HP/current index, actor identity/generation or remaining wall collision. Added walls reset correctly. These checks had already completed before the user's later instruction that one player was sufficient; no further multiplayer test was started after that instruction.
- World1 Stage1 retained its four individual wall clears, HP375 Boss and final-only unlock.
- [mobility-result.json](mobility-result.json): maximum authored selected size13 walked through cleared Stage5 and6 using native Humanoid movement/physics. Actual position crossed the last wall; sampled body bounds and start/end coordinates are recorded.
- The same follow-up made real World2→World1→World2 travel requests, returned to Stage6, and observed wall5 hidden/noncolliding and wall6 visible/colliding at450M/900M after streaming back, without a manual resync masking the streamed-restoration check. Peer state stayed intact.
- Stage10's accepted150B Boss defeat set WorldComplete, spawned the original Trophy, awarded the unchanged3,500,000 Win in the isolated session and returned/reset the run, including its sixth wall.

## Failures retained and corrections

[attempt1.json](attempt1.json) is the rejected first test: the QA expectation inserted spaces around the slash while the existing purchased HP format is `%s/%s`. Only the assertion was corrected.

[mobility-attempt1.json](mobility-attempt1.json) passed both maximum-body walks, then indexed a distant wall before it streamed back after Lobby travel. The harness was corrected to request/await the Stage. [mobility-attempt2.json](mobility-attempt2.json) then failed restored collision/visibility. The narrow production audit found the remaining streamed-name regex `[1-4]`; it was changed to numeric parsing bounded by the Stage's wall count. The final follow-up passed that restoration and Stage10 completion. The all55-wall main run precedes this last streaming-only fix; the subsequent follow-up and final compile/readback validate the final Source.

All eight production Sources and QA/migration/verification scripts compiled. Native reports contain no test exceptions on the final passes. Native logs were also reviewed for relevant runtime errors/infinite yields; they contain existing inaccessible/moderated asset and sound warnings. The game as a whole is not certified warning-free. A local guard rejected an initial attempt to apply the final regex patch because the local file used CRLF; no Source was changed by either rejected guard. Applying only the two expected text deltas after newline normalization succeeded.

Unverified: published-server behavior, real account persistence, physical mouse/keyboard/touch interaction, full rendered HP/decor acceptance from every Stage/camera/device, and natural progression duration. No approximately-three-hour claim follows from these prepared tests. The final tests had ended and only the original Edit Studio remained connected when the user requested the return from the server environment.

## Final state

[VerifyEdit.luau](VerifyEdit.luau), [final-edit-verification.json](final-edit-verification.json) and [source-integrity.json](source-integrity.json) record final live Source hashes, exact integer HP/counts,55 Edit models, spacing and9,804 unchanged non-wall geometry records. All446 original Sources are present,438 byte-identical,8 deliberate changes.35 temporary substitutions and all3 fixtures were removed. HttpEnabled was restored to its original false value. Camera/focus/FOV/type and ShowDevelopmentGui match the initial state. Native Play ended; the original user's Studio is open in Edit with the implementation retained and unsaved. No save/publish or place-file write was performed.
