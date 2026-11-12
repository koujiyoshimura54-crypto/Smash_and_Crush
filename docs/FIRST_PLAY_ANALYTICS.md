# First-play analytics v1

Canonical Place **126576845524886**, Universe **10765181857**. Instrumentation only: no changes to difficulty, rewards, tutorials, UI, AutoTap policy, receipt handling or transaction schemas. The current unsaved Studio is authoritative. The held PR #1 early-game candidate remains in Studio and is not part of this main change.

## Cohorts, session boundaries and interpretation

- **Entry** starts when the server observes each PlayerAdded, before attempting profile load. The existing-player startup loop is idempotent. A fresh GUID identifies this join; respawn does not restart it. Failed loading and departure remain incomplete entries. Connection failures before PlayerAdded are outside the denominator.
- **FirstCombat** starts at ClientPlayable only for a successfully acquired, newly created profile in this join. Death and rematch retain the same session. A later join does not resume this funnel.
- **FirstStage2Combat** uses the same confirmed New first-session cohort, but its denominator starts at actual World1 Stage2 floor entry. It does not wait for FirstCombat completion, the ClientPlayable acknowledgement, Ore eligibility or Merge completion. Death, return and re-entry retain this join's GUID and observed steps. Existing/Unknown/unloaded/reset profiles and World2 Stage2 are excluded; later joins do not resume it.
- **FirstOreMerge** starts only when that same new first-session player has enough confirmed owned Ore to pass the ordinary `OreMerge.Evaluate`. Its denominator is **merge-eligible players**, not all new players. Battle Bag material is excluded. It is independent of Combat: reward claims, combat and Merge are not forced into one sequence.
- Newness comes from `PlayerDataOwnership.Acquire`: an absent uncached read followed by confirmed creation under this attempt's owner token. A commit-acknowledgement retry retains provenance for that attempt. A nonempty prior profile is Existing even at LV1/Strength0 with incomplete tutorials. Ambiguous evidence is Unknown. Reset and Studio start overrides deactivate the new cohort. No additional persistent flag or DataStore is added.
- A returning account whose entire profile is already missing cannot be distinguished from a genuinely new account with the available data. Such an absent record can appear New; do not describe this as account-history certainty.
- Entry's first-step cohort is always `AllSessions`. Later load classification does not reclassify earlier funnel steps. Companion Entry value events can report New/Existing/Unknown at the time observed; they do not change Entry segmentation.
- These populations are not the Home/RFY recommendation population. No referral source is guessed. Device/OS segmentation uses Roblox's built-in dimensions.

## Final event schema

All funnels use `AnalyticsService:LogFunnelStepEvent` on the server, with the join GUID and the names below. Numbering is versioned; incompatible future definitions require new names. No retroactive player-history events are sent.

| Funnel | Step | Name | Authoritative trigger / Full Path |
| --- | ---: | --- | --- |
| MTF_Entry_v1 | 1 | ServerJoined | `ServerScriptService.Systems.Controllers.PlayerDataController`: PlayerAdded/startup observation before load |
| MTF_Entry_v1 | 2 | DataLoaded | `ServerScriptService.Services.PlayerDataService.Load`: accepted ownership and valid runtime data published |
| MTF_Entry_v1 | 3 | ClientPlayable | `ServerScriptService.Services.FirstPlayAnalyticsService.Playable`: accepted placement plus separately validated client readiness |
| MTF_FirstCombat_v1 | 1 | Playable | ClientPlayable, New first-session cohort only |
| MTF_FirstCombat_v1 | 2 | EnteredStage1 | `ServerScriptService.World.EnemyManager` monitor: root physically inside a World1 Stage01 floor footprint |
| MTF_FirstCombat_v1 | 3 | ClearedFirstWall | EnemyManager successful first-wall destruction callback |
| MTF_FirstCombat_v1 | 4 | ClearedStage1Walls | EnemyManager successful final Stage1 wall destruction callback |
| MTF_FirstCombat_v1 | 5 | DamagedStage1Boss | EnemyManager accepted attack actually decreased the Stage1 Boss HP |
| MTF_FirstCombat_v1 | 6 | DefeatedStage1Boss | EnemyManager sets the server-confirmed defeat state |
| MTF_FirstOreMerge_v1 | 1 | Eligible | FirstPlayAnalyticsService.CheckOre: confirmed owned counts, permanent World2 eligibility, ordinary evaluator |
| MTF_FirstOreMerge_v1 | 2 | OreViewOpened | Actual visible normal Ore view, current Forge token/generation, living character at the Merge area |
| MTF_FirstOreMerge_v1 | 3 | ValidSelection | Same current view's selection passes the authoritative evaluator against owned counts |
| MTF_FirstOreMerge_v1 | 4 | MergeRequested | PlayerDataService.MutateForge validates the ordinary operation, before starting persistence |
| MTF_FirstOreMerge_v1 | 5 | MergeCommitted | `ServerScriptService.Services.ForgePersistence.Resolve`: exact journal confirmation and runtime publication after saving |
| MTF_FirstStage2Combat_v1 | 1 | EnteredStage2 | `FirstPlayAnalyticsService.StagePresence`: living, unanchored current character root inside an actual Floor footprint under `Workspace.GeneratedMap.BattleCorridor.Stage02` |
| MTF_FirstStage2Combat_v1 | 2 | ClearedFirstWall | Existing EnemyManager callback for index1 in the server's successfully destroyed Stage2 wall list |
| MTF_FirstStage2Combat_v1 | 3 | ClearedStage2Walls | Existing EnemyManager callback for wallCount in that successful destruction list |
| MTF_FirstStage2Combat_v1 | 4 | DamagedStage2Boss | Existing EnemyManager accepted attack callback after HP actually decreases |
| MTF_FirstStage2Combat_v1 | 5 | DefeatedStage2Boss | Existing EnemyManager callback immediately after server Defeated[2]=true |

`LobbySpawnReady` proves pose/floor placement only. `ReplicatedStorage.Modules.FirstPlayAnalyticsClient` additionally waits for game loading, a living unanchored ready character, no active LoadingScreen, the current standard ControlModule's enabled controller, and visible initialized Level/Progress/Strength/Health/AutoTap HUD labels. Both legacy PlayerScripts and current StarterPlayer PlayerModule locations are supported. No control is enabled or disabled by analytics.

If the Ore screen was open before eligibility, the server asks the client to reobserve the current view. A read-only MergeShopView closure reports visibility and selection; it does not select material or change presentation. ForgeClient captures that same view with a normal Merge request, so a delayed separate RemoteEvent cannot make a valid earlier view disappear. The server validates token, generation, character, area, bounded sequence and matching materials. It never accepts a client-provided funnel step number.

Later steps are never emitted across an unobserved earlier step. StageSkip is independently recorded and stops normal Combat and Stage2 advancement for this participation, including when the successful skip happens before Stage2 entry. Previously observed prefixes remain. Other out-of-order events are recorded separately with fixed categories; no missing gameplay is invented. If a funnel send throws or its local queue drops an event, later sends for that funnel are suppressed to avoid known backfill.

Stage2 does not infer entry from CurrentStage=2, infer any wall destruction from Boss availability, or infer effective damage from defeat. Entry reuses Stage1's floor-local X/Z bounds and vertical band (floor half-height minus2 through plus35 studs), with an additional living/current/unanchored root gate. It does not move the character or change collision. The existing server hooks already include world/stage, so EnemyManager and all gameplay authorities are unchanged. Repeated completed Stage2 reaches are suppressed even after a later skip; exceptional unobserved reaches are recorded once each.

### Auxiliary values and classification

Two fixed `LogCustomEvent` names carry nonnegative **seconds since this server's join observation**:

| Name | CustomField03 categories | Cohort / purpose |
| --- | --- | --- |
| MTF_EntrySeconds_v1 | `Entry:ServerJoined`, `Entry:DataLoaded`, `Entry:ClientPlayable`, `Profile:New/Existing/Unknown`, `LoadFailed`, `EntryOutOfOrder` | All joins; cohort is what is known when the event happens |
| MTF_FirstActionSeconds_v1 | `Combat:<step name>`, `Ore:<step name>` | New first-session milestone duration |
| MTF_FirstActionSeconds_v1 | `Stage2:EnteredStage2`, `Stage2:ClearedFirstWall`, `Stage2:ClearedStage2Walls`, `Stage2:DamagedStage2Boss`, `Stage2:DefeatedStage2Boss` | Each normal Stage2 reach; seconds from the existing server join observation, NOT Stage2 entry, respawn, return or Merge |
| MTF_FirstActionSeconds_v1 | `Stage2OutOfOrder`, `Observed:Stage2:<one of the five step names>` | Once-only ordering exception and actual exceptional reach; no synthetic earlier funnel steps |
| MTF_FirstActionSeconds_v1 | `Strength:Manual/AutoWalking/Treadmill/Other`, `UserAutoOn`, `DumbbellEquipped` | First successful ordinary gain, explicit user Auto ON, first successful equipment |
| MTF_FirstActionSeconds_v1 | `ReturnAccepted`, `ReturnLobbyArrived`, `ReturnLootSaved`, `ReturnEmptyNoSave` | The first accepted return only; arrival and durable loot confirmation are independent, either order |
| MTF_FirstActionSeconds_v1 | `Death:Combat:<step>`, `Death:Ore:<step>`, `Death:Loading` | First death and latest observed progression category |
| MTF_FirstActionSeconds_v1 | `StageSkip`, `Observed:<combat step>`, `CombatOutOfOrder`, `OreOutOfOrder`, `OreViewBeforeEligible`, `OreRequestWithoutValidatedView`, `MergeRequestAccepted`, `MergeSaved`, `DebugReset` | Independent exceptional ordering / excluded-reset observations |

Normal Merge request/commit durations use the Ore step value events. `MergeRequestAccepted` and `MergeSaved` are reserved for paths outside the validated sequential funnel; they are not additional normal-success counters. Repeated callbacks, repeated attacks, button spam, save retries and respawn do not produce a second first-event observation.

Use **Count or Unique Users** for reach and **Average value** for elapsed seconds, filtered to a single milestone. The average includes **only players who reached that milestone**; it is not the average for all entrants. Do not sum elapsed seconds to get player counts, or aggregate different milestones into a meaningful duration.

All events have three fields:

1. `CustomField01`: `PlaceVersion:<published version>` — release identity.
2. `CustomField02`: `AllSessions` on Entry funnel; `NewFirstSession` on Combat/Ore/Stage2 and their auxiliary values; current known cohort on Entry auxiliary values.
3. `CustomField03`: `Normal` on funnels; one fixed category from the tables on custom values.

Version v1 is encoded in fixed event/funnel names. User IDs, GUIDs, item operation IDs and detailed seconds are never field values or event names. The GUID is used only in the required funnelSessionId argument. Studio recorder records synthetic test UserIds locally for correlation.

## Implementation Full Paths

| Path | Purpose |
| --- | --- |
| ServerScriptService.Config.FirstPlayAnalyticsConfig | Enable flag, bounded queue and Studio recorder limits |
| ServerScriptService.Services.FirstPlayAnalyticsTransport | Server API calls; ordered bounded queue; Studio recorder |
| ServerScriptService.Services.FirstPlayAnalyticsService | Session/cohort state, validation, deduplication, funnel rules |
| ReplicatedStorage.Modules.FirstPlayAnalyticsClient | Read-only HUD/control/view observations |
| StarterPlayer.StarterPlayerScripts.Telemetry.FirstPlayAnalyticsClient | Starts the client observer |
| ReplicatedStorage.Remotes.FirstPlayAnalytics | Runtime-created, allowlisted readiness/view notification gateway |
| ServerScriptService.Services.PlayerDataOwnership | Transient acquisition provenance; no analytics calls in its UpdateAsync callback |
| ServerScriptService.Systems.Controllers.PlayerDataController | Join, exhausted load failure, departure cleanup |
| ServerScriptService.Services.PlayerDataService | Loaded/reset/equip/validated Forge acceptance hooks |
| ServerScriptService.Services.ForgePersistence | Durable committed Merge hook, including asynchronous resolution |
| ServerScriptService.Services.ForgeService | Carries transient validated-view context with normal requests |
| ServerScriptService.Services.LobbySpawnService | Accepted Lobby placement observation |
| ServerScriptService.Services.RunItemBankService | Accepted immutable return token and confirmed save observation |
| ServerScriptService.Services.AutoTapService | Ordinary Manual/AutoWalking gain and explicit Toggle ON |
| ServerScriptService.Services.StrengthManager | Actual ordinary Treadmill gain |
| ServerScriptService.Services.StageSkipService | Successful skip exclusion / independent observation |
| ServerScriptService.World.EnemyManager | Actual Stage1 entry, wall destruction, Boss damage/defeat |
| ReplicatedStorage.Modules.ForgeClient | Capture read-only view context with Merge request |
| ReplicatedStorage.Modules.MergeShopView | Read-only current Ore view/selection provider |

## Safety, limits and measurement limitations

- Four named funnels, with 3/6/5/5 steps; two custom event names; three fields/event; zero Economy currencies/events added. The original three names, definitions, denominators and step numbers are unchanged. This is below the 10-funnel, 100-step, 100-custom-name and three-field limits. Entry lifecycle measurements are intentional user-requested loading diagnostics, despite the generic skill's preference for gameplay-only onboarding steps.
- Client notifications use a server token bucket (burst8, refill4/s), session/character/generation checks and idempotent server state. The client checks readiness/view every0.25s locally; it only sends changes and at most five readiness attempts spaced2s. No every-frame/attack/gain analytics sends.
- Each player session queues at most64 events. Sends are ordered, paced against `120 + 20*CCU` requests/min and wait at most30s for budget. No analytics retry loop. Queue expiry, overflow and send exceptions do not alter gameplay or save outcomes. Studio records at most2048 events and never calls the production API.
- Stage2 adds at most five normal funnel sends and five elapsed-value sends per qualifying participation. A complete normal four-funnel route with all ordinary auxiliary observations is46 events versus36 previously, below the unchanged64-row queue. This is not a guarantee against global saturation: a deterministic20-CCU instantaneous burst of20×46 rows sent380 and locally dropped540 at the existing30-second budget deadline (baseline20×36:380 sent/340 dropped). No queue, pacing, timeout or gameplay policy was changed. These are fake-clock stress measurements, not production traffic.
- Instrumentation calls are guarded; game success never depends on analytics delivery. No API call runs inside UpdateAsync callbacks. Existing receipt IDs, Forge journals, return snapshots, save retries and ownership fences are unchanged.
- Delivery is best effort, not a durable event outbox. Silent platform drops cannot be detected, and Roblox can backfill earlier funnel steps after a silently lost request. Locally detected failures stop subsequent steps; they cannot prevent every platform-side loss. Compare View Events before relying on conversion figures.
- Client HUD/visibility observations cannot be cryptographically proved by the server. Session/location/inventory/sequence gates reduce accidental and abusive reports; all combat outcomes and save commits remain server-owned.
- Departures clear first-session observation state. A save resolved after departure may be missing from analytics even though the existing transaction still safely completes. No later join repairs that measurement, and no past behavior is backfilled.
- The shipping `StudioRecords`, `StudioFailNext` and `StudioClear` transport adapter methods are guarded by IsStudio. They are bounded local validation support, not a public remote or production fault switch.

## Creator Hub verification after the owner's manual Save/Publish

1. Publish manually, then run a normal session in that published version. The agent does not Save or Publish.
2. In the experience's Analytics → **Funnel**, choose `MTF_Entry_v1`, `MTF_FirstCombat_v1`, `MTF_FirstOreMerge_v1`, and `MTF_FirstStage2Combat_v1`. Check the distinct denominators above and filter by the published PlaceVersion. Standard device/OS filters are available.
3. Use **View Events** to inspect recent event order, step names, fields and numeric seconds; refresh if necessary. Check Error Report if events do not appear. Studio recorder rows are not proof of Creator Hub receipt.
4. In **Custom / Explore**, select the two elapsed event names; filter CustomField03 to one milestone, compare reach and average value separately. Prioritize Entry loading conversion, Stage1 combat drop-off, then eligible-to-committed Ore conversion. Inspect independent StageSkip/order categories alongside the funnels.
5. Aggregated charts normally take about **24 hours** after the first published events. Review the first one to two weeks before changing the schema. Historical behavior from before this publication cannot be reconstructed or sent as measured events.

Official references: [AnalyticsService API](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService), [funnels and first-step segmentation](https://create.roblox.com/docs/production/analytics/funnel-events), [custom value events](https://create.roblox.com/docs/production/analytics/custom-events), [event validation/limits](https://create.roblox.com/docs/production/analytics/event-types), [custom fields](https://create.roblox.com/docs/production/analytics/custom-fields). Roblox Studio's `rbx-instrument-analytics` skill was loaded during final review; the user's explicit event plan and no-publish scope take precedence over its generic templates and approval workflow.
