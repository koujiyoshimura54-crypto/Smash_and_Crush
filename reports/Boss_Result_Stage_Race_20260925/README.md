# BossResult stage identity / suppression — 2026-09-25

## Scope and authority

- PlaceId 101572058398926. Current Studio source is authoritative.
- origin/main verified at e77ecaba566ba099c7fda02957bfdb247c60af99.
- Existing working copy stays on backup branch sync/DESKTOP-CNFVEH2-20260924-2203 at 0188223. Its Trophy styling, expanded source archive and untracked World1 audit report are untouched.
- A separate worktree C:/Users/kouji/Smash_and_Crush/boss-result-stage-fix-20260925 and branch fix/boss-result-stage-20260925 start at origin/main. Only this fix and its documentation are committed. No merging/rebasing/resetting/pushing main.
- AGENTS and required SPECs reviewed; mandatory SPECs matched the already fully reviewed backup-task versions.

## Root cause: what is and is not confirmed

The normal pre-fix Play did NOT reproduce complete next-boss disappearance. Stage1 and Stage2 cosmetic parts remained LTM=0 until their own defeat. The actual natural Stage1 client sequence was:

| Server-time seconds | Client observation |
|---:|---|
| 1790262560.144199 | BossResult WIN arrival, Stage absent, currentStage=1, CurrentStage=1 |
| 1790262560.146146 | suppression keys become [1] |
| 1790262560.315651 | EnemyDefeated Stage=1 |
| 1790262560.317956 | defeated=[1], currentStage=2; Stage2 visible |
| 1790262560.391390 | CurrentStage Attribute=2 |
| 1790262560.446953 | StageCleared Stage=1, CurrentStage=2 |
| 1790262580.011431 | Stage2 unlock: model visible, HP gauge enabled, personal collider present |
| 1790262580.020635 | Stage2 BossInitialize: model/gauge remain visible |

A separate controlled runtime scheduling test delayed only BossResult handler processing by 0.5 seconds. This is NOT claimed as a naturally reproduced network-order bug. It used actual server combat victories; other events/Attribute updates proceeded normally.

- Stage1 result arrived at 1790262661.671701, with currentStage=1.
- EnemyDefeated(1) advanced the local stage; Attribute became 2 at 1790262661.721719.
- Result processing resumed at 1790262662.174438 with currentStage=2 and no event Stage.
- At 1790262662.175914 the old code wrote bossSuppressed[2]=true.
- Stage2 unlock and BossInitialize left this entry intact; HP gauge stayed disabled while its collider remained active.
- Stage2 victory subsequently caused the same error for Stage3.
- Stage2 visual mesh LTM remained 0 even under this failure. Therefore this patch fixes an experimentally confirmed wrong-stage **HP/display-state suppression** race. It does NOT establish the cause of the reported full-model disappearance; that symptom remains unconfirmed.

The server's two BossResult sends had no Stage; the client indexed mutable currentStage. bossSuppressed feeds bossDisplayEnabled (gauge/surface), while cosmetic hiding is driven by defeated and setBossVisualVisible. These are not interchangeable.

## Minimal production changes

1. EnemyManager: WIN and LOSE include Stage=n and the current boss SpawnGeneration.
2. CombatClient, within each mount(worldId):
   - Validate the result Stage as an integer from 1 through 10; reject invalid values with a warning. No currentStage fallback.
   - Reject stale generations using the existing acceptance helper.
   - Suppress only the explicit result Stage.
   - BossInitialize validates Stage/generation, ignores defeated stages, clears only that stage's old suppression and restores its visual.
   - Stage1BossUnlocked requires its explicit valid MajorStage and an undefeated stage; clears only its suppression before showing it.
3. EnemyDefeated already hides only d.Stage and remains unchanged.
4. World1/World2 transports, stage Attribute names, tables and colliders remain isolated in mount.

No HP, required Strength, economy, reward/drop rate, model, pivot, collider dimension, map, training/treadmill, save schema, World2 placement or Trophy/UI styling changes. Studio keeps its existing Trophy styling; the Git fix deliberately excludes that unrelated diff.

## Runtime QA method

Single actual Studio Play client/server. Temporary contact helper seeded only QA-player Strength and moved its real Character to the existing wall/CombatZone reference positions. Ordinary auto-combat performed damage, four-wall progression, Boss.Begin/Attack, result events and defeats; no direct stage clearing was used to advance the test. The explicit ClearStage(10) negative probe at Stage1 returned false / out of order.

QA used temporary DataStoreConfig Studio suffix _BS0925, avoiding normal player stores. This suffix, diagnostics and helpers were restored/removed before the final fresh normal Play. Rewards/drop algorithms were not changed. This is accelerated fixture-assisted Play, not a manually walked unmodified player journey.

The initial debugger logpoints could not access uncaptured upvalues; they were removed and replaced by temporary non-yielding in-script snapshots. Their diagnostic-tool errors are not counted as a clean runtime test. The intentional 0.5-second delay existed only in the clearly marked before/after scheduling comparison.

## Results

- Delayed before/after comparison: after the fix, Stage1 result still processed with currentStage=2 but suppressed Stage1 only; Stage2/3 visuals and gauges worked.
- One Play/player advanced World1 Stage1–10, keeping all ten shared Instances and SpawnGeneration=1. This ten-stage pass preceded final synchronization of the additional unlock guard; final production source was then re-tested through Stage1–3 in another fresh Play.
- Final World1 Stage1–3: all walls processed, boss unlock/initialization visible, current-stage collider and HP gauge present, own defeat alone hidden. Next-stage parts stay LTM=0. No wrong next-stage suppression.
- LOSE: real Stage1 fight at Strength=0 produced LOTTERY_MISS then LOSE, suppression [1], not [2]. Actual Character respawn restored Stage1, empty cleared/suppressed state, full 375 HP, visible Stage1/2 models, unchanged shared Instances/generations. Replayed Stage1 successfully afterwards.
- Final synthetic recovery probes (explicitly not gameplay victories): valid result suppression at undefeated Stage4 was cleared independently by Unlock and Initialize. Delayed Stage1 Initialize/Unlock after Stage1 defeat did not change currentStage=4, defeated keys, or hidden Stage1. Older-generation result probe did not suppress Stage7.
- Final World2 Stage1 and Stage2 actual victories: next stage visible; World1 stayed at Stage4 with only [1,2,3] defeated. World2CombatState and World2CurrentStage were used, not World1 transport/state.
- Both worlds' shared Instances stayed identical and generation 1 throughout the measured progress.
- Two-client test NOT performed; no mock is presented as a two-client rendering test.
- Complete visual-disappearance symptom remains unconfirmed. Physical-device rendering and production network timing are not verified.

## Final cleanup and saving

Final fresh normal Play after removing all diagnostic/QA code and restoring normal DataStore naming ran for 264 seconds with empty console output, as recorded in final_runtime.json. It is separate from fixture-assisted combat passes. Studio was returned to Edit and its final sources were verified. Ctrl+S was dispatched to the verified Studio window (process 4164), as explicitly requested by this task, and was the only final GUI action. Publish was not performed. The MCP interface cannot acknowledge durable Studio save completion; dispatch is verified but durable save remains unconfirmed.

Evidence files contain event/stage/visual state only, not player names, UserIds, inventory/save data or credentials.
