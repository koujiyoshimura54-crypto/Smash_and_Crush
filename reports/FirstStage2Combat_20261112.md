# First World1 Stage2 combat funnel — 2026-11-12

Applied to the current unsaved canonical Studio: **Place126576845524886 / Universe10765181857**, loaded PlaceVersion559. This task changes instrumentation only. No Play start/stop, Save, Publish, save GUI, OS input, title change, player-data mutation or real analytics submission was performed.

## Scope and provenance

The checkout was behind the already-published main branch; it was fast-forwarded to **736f02b** for the existing FirstPlayAnalytics implementation. That Git operation did not write any Source into Studio. PR #1 was inspected read-only and remained open/draft/unmerged. Its candidate balance code was not merged, cherry-picked, or copied into main. Live manual edits remain authoritative.

**Only production Full Path changed:** `ServerScriptService.Services.FirstPlayAnalyticsService`.

Existing `ServerScriptService.World.EnemyManager` already passes world and stage on physical presence, successful wall destruction, HP decrease and confirmed defeat. The previous analytics service ignored stage2; it now routes those existing calls into the fourth funnel. No gameplay hook, HP calculation, Strength grant, reward, TimeReward, AutoTap, persistence, UI or tutorial Source was changed. OreViewOpened guidance remains a separate future task.

The Roblox Studio [rbx-instrument-analytics skill](https://create.roblox.com/docs/production/analytics/event-types#instrument-events-with-studio-mcp) was used for API, deduplication and limits guidance. The user's explicit five-event plan and no-Play/no-publish constraints take precedence over its generic repeat-approval and Play workflow.

## Funnel specification

Name: **MTF_FirstStage2Combat_v1**. Session ID: existing server-join GUID. Cohort: the same confirmed newly created first-session profile as FirstCombat. It starts at actual World1 Stage2 entry, independently of FirstCombat completion, readiness acknowledgement, Ore eligibility or Merge completion.

| Step | Name | Server observation |
|---:|---|---|
| 1 | EnteredStage2 | Living, unanchored current character root inside an actual Stage02 Floor footprint |
| 2 | ClearedFirstWall | index1 appears in the authoritative destroyed-wall list |
| 3 | ClearedStage2Walls | wallCount appears in that destroyed-wall list |
| 4 | DamagedStage2Boss | Accepted Boss attack actually decreased HP |
| 5 | DefeatedStage2Boss | Defeated[2] set true by the server |

The entry check uses current Stage02 Floor CFrames/sizes, not a fabricated region or CurrentStage attribute. Stage1's original physical predicate is retained through a shared floor lookup. There are three relevant Floor instances in the current Stage02 model; all were tested without moving or changing them.

Each normal reach also uses existing **MTF_FirstActionSeconds_v1**, with `CustomField03="Stage2:<step name>"`. Value is nonnegative **os.clock() minus the existing server join-observation clock**. It is NOT time since Stage2 entry, return, respawn, or Merge. Existing fields remain PlaceVersion / NewFirstSession / fixed category; no new event-name-per-player or dynamic-ID fields.

Death, return and retry do not reset progress; repeated notifications cannot duplicate a step. Leaving ends observation; a later Existing join does not resume it. World2 Stage2, other stages, Existing/Unknown/unloaded/reset cohorts and replaced profile data are excluded.

The existing successful StageSkip policy suppresses further normal Stage2 advancement for this join; already observed prefixes remain. Unexpected later observations emit `Stage2OutOfOrder` once and `Observed:Stage2:<step name>` once per actual exceptional reach. Earlier steps are never fabricated, and later entry does not reopen a broken normal sequence. A completed normal reach is not counted again after a later skip.

Original Entry / FirstCombat / FirstOreMerge names, denominators and step numbers are unchanged. [Complete shared measurement specification](../docs/FIRST_PLAY_ANALYTICS.md).

## Verification actually performed

All execution here was **native Luau in Edit with copied Sources, injected player/data/remote/clock/API dependencies**. No real player was controlled. The only live world inputs were read-only Floor geometry and pure Ore/Merge/count definitions.

- **68 Stage2/state assertions passed.** Normal five-step order; no Merge/readiness dependency; exact join-relative seconds; same-GUID death/respawn/retry and return/re-entry; repeated notifications; skipped routes at four prefixes; missing steps1–4; World2/other-stage exclusion; Existing/Unknown/unloaded/reset/reload/departure; no Stage2 client-remote gateway; dead/anchored/foreign root rejection; actual Stage02 geometry; Stage01 physical-predicate parity.
- The existing **38-assertion StateMatrix passed against both baseline and changed service**. Their original three-funnel and auxiliary event streams matched exactly after removing only generated GUIDs. New code did not change those cases' event counts, names, step numbers, values or fields.
- **52 transport assertions passed** against the unchanged transport Source with a fake API/clock/scheduler. Verified deferred enqueue, normal46-row burst,64-row cap, overflow fencing, thrown API failure without retry, later Stage2-send suppression, independent other-funnel delivery, bounded saturation and disabled instrumentation.
- A normal full service trace increased from36 to46 events: five new funnel rows plus five existing-name elapsed rows. Queue capacity remains64. The stress fixture uses instantaneous bursts intentionally, not a claim that players naturally finish the whole route simultaneously.
- Stress at20 simulated CCU: baseline720 queued requests →380 sent/340 dropped; extended920 →380 sent/540 dropped, both bounded at approximately30 seconds. Peak per-session queue was36/46. This exposes the best-effort global-budget limitation instead of claiming lossless delivery.
- Native compilation passed. Applied Source, editor buffer and tested candidate matched exactly. Final snapshot: **498 Sources, one changed,497 unchanged, zero added/missing Sources, zero Enabled changes**. No test instances, module copies, redirects or helper scripts were installed in the DataModel.

The first fixture attempt incorrectly fired a Signal instead of its BindableEvent; it was corrected in test code, and the complete final matrix passed. No production change was made for that fixture error.

[Machine-readable results](FirstStage2Combat_20261112.evidence.json). Reproducible fixtures: [Stage2Matrix](../tests/FirstPlayAnalytics/Stage2Matrix.luau), [Stage2Transport](../tests/FirstPlayAnalytics/Stage2Transport.luau), [running notes](../tests/FirstPlayAnalytics/README.md).

## Limits and outstanding verification

No actual Stage2 walking/combat, physical death/return, real client/network route or published Creator Hub receipt was tested in this task, because the user's Studio Play must not be started or stopped. The outcomes above are service/transport simulations plus current geometry checks and authoritative hook inspection; they are not a new live combat acceptance run. Existing FirstCombat live evidence is historical and is not presented as this task's Play verification.

The fourth funnel and two custom event names remain below the official limits. The unchanged shared pacing rule is120+20×CCU requests/minute. The queue is bounded and does not block gameplay; failures are best effort, with no durable analytics retry. Silent platform drops remain undetectable. Local detected gaps fence later sends for that funnel, but cannot guarantee that the platform never backfills after silent loss. [Official limits](https://create.roblox.com/docs/production/analytics/event-types), [funnel behavior](https://create.roblox.com/docs/production/analytics/funnel-events).

After the owner's manual Save/Publish, verify the five rows and their elapsed companions in Creator Hub View Events, including a fresh qualifying profile and StageSkip path. Do not use a returning profile as the new-session denominator.

## Delivery

Scoped Source, specification, test fixtures and evidence are committed on main and delivered by normal push to origin/main. The unrelated pre-existing visual-template report remains untracked and excluded. PR #1 is unchanged.

Studio remained in **Edit** throughout this task; no Play command was issued. **Canonical Studio is unsaved. Save/Publish remain the owner's manual actions.**
