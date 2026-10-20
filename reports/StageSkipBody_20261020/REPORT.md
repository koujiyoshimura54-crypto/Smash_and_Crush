# World1 StageSkip applied-body transfer repair — 2026-10-20

Updated only `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, preserving the latest growth thresholds, Speed, spawn, Rebirth and other existing changes. Two live Sources changed:

- `game.ServerScriptService.Services.StageSkipService`
- `game.ServerScriptService.Services.LobbySpawnService` (StageSkip extensions only; original36595fe lobby/load/return functions remain exact).

## Confirmed cause

The original error was reproduced with the current Source: size13 facing sideways returned the generic not-ready error without charging. Temporary rejection markers identified the entry-dimension branch, not readiness or the ray. Its projected whole-Character depth radius was4.5494; the calculated minimum Z was-15.2506, beyond maximum Z-16.4000. It measured the CURRENT heading but subsequently rotated the character toward Wall1, so the wide arms incorrectly became the required entry depth. All nine stages share this approach geometry. Initial and maximum bodies facing forward succeeded before the fix; this is not a universal ray failure.

The actual floor is48.4×40.1 studs, anchored/collidable/queryable, Default collision group. Both Default and the character's PlayerCharacters ray hit its top atY4. Character/scale readiness and combat initialization were true. Whole-model bounds also include accessories and the equipped dumbbells, making them unsuitable as the body footprint.

## Change

Measure actual applied R15/R6 body parts relative to the root, then project them in the destination heading. Exclude accessories, tools and combat/decoration models. Use current HipHeight, root size and leg/foot bottoms for support height. Probe the center and footprint corners against current walkable geometry and check colliding body parts against obstacles using their collision groups. Search at most12 candidates in the same Stage entry, before Wall1 and its existing forward combat trigger; never alter the map or body scale.

Re-resolve after streaming. Verify the matching placement acknowledgement, living Character, World/request ownership and unchanged body/geometry before committing Win. Failures release the per-player lock and restore only this request's origin; growth during the wait raises the restored origin for the new feet height. A post-debit initialization error refunds exactly once without overwriting other Win gains. No Speed assignment or periodic repositioning was added. Prices, products, UI, stage rules and receipt journal are unchanged.

## Focused checks

Actual solo Studio Play, memory-only persistence, actual mouse clicks on the existing UI (including mouse-wheel scrolling to Stage10):

| Applied body | Selection | Stage2 Win | Stage10 Win | Settled root Y, Stage2 /10 |
|---|---|---|---|---|
|0|AUTO|10000→9999|10000→8800|6.939 /6.938|
|8|AUTO, Strength50M|10000→9999|10000→8800|9.192 /9.191|
|13|manual, Strength0|10000→9999|10000→8800|11.936 /11.934|

Size13 included the actual equipped dual dumbbell displays and five avatar accessories; its sideways request succeeded. The price labels were1 and1.2K. All tested arrivals remained about5.25 studs before the first wall, unanchored, with no defeated Bosses or clear grants. D input moved roughly7–7.6 studs laterally without sinking or a later return teleport; maximum body also walked at Stage10. The existing maximum-size HipHeight stance retains the previously recorded approximately1.2-stud sole clearance; growth/HipHeight configuration was not changed.

All Stage2–10 calculations passed for0/8/13, including stable sideways13 with equipment. A temporary obstacle at the usual point selected a different supported position on the same entry. An immediate synthetic yaw/scale fixture probe temporarily failed while joints were settling; stable probes and the subsequent real UI requests passed. No fixed production delay was added.

Actual UI:0 Win rejected without moving/spending; three rapid clicks charged1 once (5→4); natural death/respawn allowed another mouse purchase (4→3). Native Play injections, separately from normal UI operation: failed movement, missing acknowledgement, World change during streaming, and body change during acknowledgement all retained10000 Win and released the lock/anchor. A forced initialization error after debit restored10000 once and returned to the origin. A World2 request was rejected. The final0→13 cancellation-height guard was retested, followed by final-Source mouse Stage2/10 purchases at13; no behavioral changes followed.

Two real clients joined one Studio server. A Player2 size13 Skip reached Stage2 and spent1 while the observer retained its exact position, World1, Stage1,10000 Win and run identity. **This multiplayer request used the Remote directly**: multiplayer mouse automation did not activate the Win controls. It is not counted as multiplayer UI verification. Solo mouse verification above succeeded; no UI changes were made to work around the tool.

Limits: no real checkout/receipt retry, production persistence, physical device input, actual network-loss timeout, every avatar/animation, or intermediate-size UI sweep. Missing acknowledgement and concurrency/error cases used temporary native test stubs, not natural network failure. No unrelated regression suite or screenshots.

Play stopped; five memory-adapter Source substitutions and all Edit fixtures were removed. The guarded same-file writer compiles and re-decodes the result and verifies exact preservation of every other Source/property/Instance/reference/UniqueId/SharedString. No alternate rbxl, Backup, Copy or Migration, Studio Save or Publish. See FileValidation.json for hashes and final process/lock checks. The external rbxl is not Git-tracked; the commit contains these two Source mirrors, writer and scoped records.
