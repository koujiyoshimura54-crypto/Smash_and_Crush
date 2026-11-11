# Back return Battle Bag repair — 2026-11-11

Target: canonical Studio Place **126576845524886**, Universe **10765181857**. Baseline: **55c2f45**. The initially connected different Place was not edited; the requested Place was confirmed before any Studio mutation.

## Cause and minimal change

Changed Full Path: **ServerScriptService.Services.RunReturnService** (repository: src/ServerScriptService/Services/RunReturnService.luau).

Back called Enemy.InitializePlayer, which created an active Bag and retained its Run ID in combat state, then immediately called Run.Invalidate, replacing that Bag with a different inactive generation. Walking out of the Lobby did not initialize another run. Normal Trophy return already preserved InitializePlayer's active Bag.

Removed this second invalidation and its unused require; added two explanatory comments. Bank.Begin still detaches and retains the accepted old Bag. No banking, Trophy, combat, death, UI, reward, configuration, or stale-request validation code changed. No manual Config/GUI adjustment is needed.

## Reproduction and verification

[Structured evidence](BackBagReturn_20261111.evidence.json) contains before/after observations and **55 passing derived assertions**. Run IDs are replaced with stable aliases.

| Check | Observed result |
| --- | --- |
| Before fix, W1 Stage2 Back then walking | Returned, but Active=false and Bag/combat IDs differed; approximately 73 studs of real Humanoid movement crossed the Lobby boundary without repairing them. Both Item/Ore additions rejected StaleRun. |
| Before fix, native Boss defeat and Trophy | Win +3, no Lobby return. Console reproduced world=1 stage=2 credited=true Bank:StaleRun. This reproduces the supplied failure mechanism; the two production players were not inspected. |
| After fix, repeated Back cycles | Two cycles each in W1 Stage2 and W2 Stage2: Back → walking → Item/Ore → native Boss defeat → actual Trophy overlap → Lobby. Active=true and matching IDs; W2 Back ID also matched. Win +3/+7000 per respective Trophy, once. |
| Old requests / repeated Trophy contact | Old Item/Ore requests rejected StaleRun in both Worlds; repeated Trophy contact added zero Win. |
| Delayed W1 save | Lobby return and another walking sortie completed while the old bank write was blocked. Injected precommit failure and acknowledgement loss were consumed. Retry banked exactly the old Item/Ore deltas; the new two-item Bag remained separate. Its later Back banked it once. |
| Delayed W2 save and death | New unbanked Item/Ore were lost on death (Lost=2), while the previously accepted Bag survived and banked once. Respawn restored an active matching generation. |
| Confirmed-grant acknowledgement loss | One fault actually injected after the mixed Item/Ore journal reached Granted. Retry preserved exactly-once old inventory deltas and unchanged Win; the new two-item Bag stayed intact. |
| Normal / empty returns | Normal Trophy paths and empty Back succeeded. Empty Trophy succeeded in both Worlds after native Boss defeat and the existing Drop API removed its loot; no Item/Ore gain. W1 death also discarded exactly two unbanked items. |
| Memory save | Final persisted fixture Win=28009 and Item/Ore counts matched the accepted receipts; no production datastore was used. |

## Scope, fixture corrections, and limits

Native Studio Play used a real Player/character and the game's service instances. Walking used Humanoid.MoveTo; Trophy used physical overlap and the normal collection loop. Back was invoked through its server service. Strength, earlier-stage progression, walls, initial Item/Ore, World selection, and Boss/Trophy positioning were prepared programmatically. Actual Boss attacks and additional random Boss drops ran normally. This is controlled runtime verification, not a full manual progression playthrough or mouse/button interaction test.

Persistence, payment, badge, messaging, and policy dependencies were temporarily redirected in 39 Sources to memory stubs. Save faults are simulated, not real Roblox outages. Public servers, production persistence, simultaneous multiple players, rendered UI acceptance, and full physical gate travel were not tested.

Fixture issues were retained as failures: initial preparation raced a placement callback (Back/walking reproduction still ran); the first grant-fault hook targeted the legacy journal and did not fire; one later harness cleanup tried writing to a frozen roller table. The harness was corrected without changing production code. The mixed-journal fault subsequently fired once, and both normal/empty native attack paths passed. No post-fix Trophy StaleRun or related production runtime error appeared. Existing asset permission/missing-image warnings remain outside this fix.

## Cleanup and delivery

All 39 temporary substitutions were restored; no helper Instances or helper Source references remained. The four other audited service Sources matched their original live versions; RunReturnService matched the minimal patch. Play stopped with Edit focused. Existing unsaved edits and this fix were retained. No OS input, foregrounding, Save/Publish, rbxl writeback, or Studio close occurred.

Regression assets: tests/BackBagReturn.server.luau and tests/BackBagReturn.Memory.luau. They are temporary Studio-only helpers, outside shipped src. Use only with the described memory redirections; remove them and restore exact Sources after stopping Play.

**The user must manually Save/Publish to deploy this fix to the public game.**
