# World1 native Play benchmark — stopped at the user's request

| Run | Policy | Last confirmed elapsed | At 60 minutes | Highest first defeat | Outcome |
|---|---|---:|---|---:|---|
| 1 | Standard unpaid progression; fixed criteria in conditions.md | 83:17.864 | Stage5 cleared; Stage10 not cleared | 6 | Incomplete; user requested termination |
| 2 | Repeat the same criteria | — | Not run | — | Not started |
| 3 | Efficiency policy informed by runs1/2 | — | Not run | — | Not started |

This is one partial Studio automation run, not three completed runs and not a general-player or public-server benchmark. It does not establish the game's minimum, typical, or percentile completion time. In particular, the measured duration contains substantial Codex investigation, input failures and idle time. No estimated human operation-time adjustment is applied.

## Target and fixed conditions

Current Y01 Studio: Universe10765181857 / Place126576845524886, baseline Git245a1e7. The current unsaved document was authoritative. No older rbxl or complete Git Source replacement was used. Preparation, fixed decision criteria and isolation are in [conditions.md](conditions.md) and [preparation.md](preparation.md).

Every preparation/main Play used a newly empty memory-store adapter. Native PlayerData loading supplied Strength0, LV1, Win0, rebirth0, capacity5, AutoON, empty owned/equipped inventories and World2 unvisited. All account pass ownership was false; payment prompts were blocked, badge ownership empty, and no real group-membership reward was claimed. Initial VIP/Win/rebirth multipliers were1; ordinary speed24. Native training/combat, purchases, natural drops, timed rewards and merge RNG remained unchanged. No StudioStartOverride progression shortcut, direct grant, internal purchase/combat/merge call, forced RNG, CFrame movement or enemy HP edit was used.

Only35 temporary DataStore/Marketplace/Badge dependency substitutions isolated real services. The gameplay formulas, Source behavior and balance were fixed throughout the partial run. Four hundred forty-six initial Sources were guarded for restoration. Ordinary automation used Humanoid:MoveTo, real Windows UI pointer input, and the game's existing Auto combat. The later Route helper only repeated ordinary movement to actual arena/Trophy positions and released movement after a return. Normal Trophy warps and temporary victory speed boosts were performed by the game, not by the harness.

Play request: 2026-10-26 14:25:44.658 UTC. First ready rendered frame/clock start:14:25:51.309 UTC. Request-to-ready loading was6.651 seconds, separate from the benchmark clock. The final exported snapshot is 2026-10-26 15:49:09.173 UTC (2026-10-27 00:49:09.173 JST), elapsed4997.864 seconds. When termination was requested the Studio was already in Edit; the time/cause of that preceding Stop was not observed. No post-snapshot training interval or exact final Stop time is reconstructed.

## First-defeat observations

Read-only native-server polling resolution was approximately0.25 seconds. Stage is taken from the FirstClears array index: the snapshot CurrentStage can already have advanced.

| Elapsed | Stage | Strength | LV | Rebirth | Win at defeat | Main equipment |
|---|---:|---:|---:|---:|---:|---|
| 01:52.213 | 1 | 193 | 5 | 0 | 0 | None |
| 17:23.743 | 2 | 1683 | 12 | 0 | 2 | NORMAL_02 +5; Common Fire Belt |
| 20:53.702 | 3 | 2949 | 15 | 0 | 5 | Same |
| 26:35.520 | 4 | 6173.5 | 19 | 0 | 12 | Same |
| 58:31.627 | 5 | 46245.5 | 31 | 0 | 37 | NORMAL_02; Pink Aura; Uncommon Ice Protein; Rare Fire Belt; Common Electric Glove |
| 75:41.632 | 6 | 145864.5 | 38 | 0 | 7 | NORMAL_02; Pink; Uncommon Ice Protein; Rare Fire Belt; Rare Fire Glove |
| — | 7 | — | — | — | — | Not defeated |
| — | 8 | — | — | — | — | Not defeated |
| — | 9 | — | — | — | — | Not defeated |
| — | 10 | — | — | — | — | Not defeated |

Runs2/3 have no Stage1–10 first-defeat observations because neither started. Win here precedes the subsequent normal Trophy payment. The full table is [stage-first-clears.csv](stage-first-clears.csv).

The actual60-minute bracket is [main-run01/sixty-minute-bracket.json](main-run01/sixty-minute-bracket.json): at3595.820 and3601.019 seconds, Strength50843.5 and51363.5, LV32, rebirth0, Win67, in the lobby after Stage5. Gear was NORMAL_02, Pink, Uncommon Ice Protein, Rare Fire Belt and Common Electric Glove. Exact Strength at3600.000 was not sampled; it is not interpolated into an alleged measurement.

Last confirmed state: highest Stage6 defeated, current lobby Stage1, Strength149052.5, LV38, rebirth0, Win7, NORMAL_03 +9 (Win purchase), Yellow Aura +30, Uncommon Ice Protein +15, Rare Fire Belt +1 tier, Epic Fire Glove +35%, Normal02 treadmill, capacity5, no Pet. World2 remained unvisited. [Full state](last-confirmed-state.json).

## Time accounting and limitations

| Raw mutually exclusive category | Seconds | Minutes |
|---|---:|---:|
| Treadmill training | 2024.597 | 33.74 |
| Wall/Boss combat | 76.648 | 1.28 |
| Physical movement | 287.324 | 4.79 |
| Annotated UI operations | 656.041 | 10.93 |
| Death/respawn | 3.348 | 0.06 |
| Codex interruption / idle | 1949.706 | 32.50 |

Buckets total4997.664 seconds, about0.200 seconds short of the final snapshot due to the telemetry polling boundary. Priority was death, combat, treadmill, movement, annotated operations, idle. Operations while training remain in the training bucket, and simultaneous growth is retained. These are raw categories, not an accurate human interaction-time decomposition: early operation annotations include focus-debugging and agent inspection; the interruption bucket includes agent delays. Death excludes subsequent movement/recovery. All such intervals remain in the83:17.864 elapsed observation. The interval cannot be used to conclude that the current game inherently requires this much time.

The final native export reported1239 available events, but only1206 had been exported when Play ended. The33 remaining event rows are unavailable; later full checkpoint snapshots and OS input records still preserve the latest state/actions. This gap is disclosed rather than reconstructed. The Win-change observer missed the initial +1 transition; final earned306 is one low. From initial0, balance7 plus spent300 gives cumulative positive Win changes307, including the ordinary10-Win sale. Raw evidence is retained unchanged except account-name redaction.

## Decisions and observed progression

- Natural Stage1 Copper Ore11pt was merged via UI to NORMAL_02 +5, using ordinary RNG (upper candidate40%). It cost no Win when funds were only2; buying that same Dumbbell cost20. This demonstrates useful early Ore forging in this specific draw, not guaranteed superiority over buying. No points/probabilities were fixed.
- Common Fire Belt raised observed Normal02 growth to15/s with NORMAL_02. Rebirth was deferred under the prewritten rule that rebuilding current Strength must take at most90 seconds. This conservative operator policy, not a game-enforced restriction, may itself slow progression; no faster rebirth route was tested.
- A Stage4 combat death occurred at25:43.990 with Strength6146.5, above its displayed6000 benchmark. It lost the two unbanked items (Rare Electric Glove and Uncommon Electric Belt). Ore persisted. The root was on the arena floor, not falling off the map. Ordinary respawn/retry reached Stage4's first defeat at26:35.520. Thus the displayed benchmark was not a survival guarantee in this observed encounter.
- Later five-Ore options totaled59pt and could improve NORMAL_02, but the Merge panel no longer opened after that death. Ore was retained; no internal merge bypass was used.
- Ordinary Daily/time rewards were claimed late. Timed rewards included Win, temporary potions, training grant and the45-minute Item×10 roll. The roll supplied the Uncommon Ice Protein and Rare Fire Belt. Upgrades sharply improved training; potion time spent during Codex/UI delays was not silently treated as productive training.
- Pink Aura +5 cost30; NORMAL_03 +9 cost50; the obsolete unequipped NORMAL_02 was sold for10. A post-compaction input-format mistake moved toward the origin through ordinary movement, then a correction route crossed a purchase pad: Win decreased20 and NORMAL_02 was equipped again. This incidental purchase/downgrade is operator overhead. Owned NORMAL_03 was re-equipped via Inventory.
- After the first Stage6 Trophy, three additional ordinary Stage6 return laps raised Win57 to207 and supplied an Epic Fire Glove. Best Equip equipped it. Yellow Aura +30 cost200, chosen for its +25 incremental gain over Pink versus weaker affordable additions. At the last snapshot the unmultiplied NormalTrainingGain was55. Its sustained final growth rate was not measured long enough to report as a new benchmark.
- Normal Trophy return banking, Auto battles and later repeated route inputs worked. No StageSkip, paid facility, Egg, Pet, Pet merge, Item merge, Ore sale or rebirth was executed. Item/Pet merge effectiveness and a better buying/rebirth policy therefore remain unmeasured. No lower-benchmark kiting route was tested.
- Capacity remained5. No full-bag discard was confirmed in exported observations; early death did lose two unbanked items. Complete loss counts cannot be guaranteed across the final event gap.
- No performance-based balance changes are proposed from this contaminated partial run. UI responsiveness/mounting and automation overhead should be resolved or independently controlled before comparing gameplay-time policies.

## Bugs and operator issues

1. **Merge unavailable after death:** ordinary exit/re-entry failed to reopen it, despite being geometrically inside the area with Inventory/Shop closed. PlayerGui.StrengthGui.MergeShopMounted remained true and the existing Merge client was enabled. A stale mount/lifecycle state is a hypothesis, not a proven root cause. It prevented further useful Ore merges/sales and impaired assessment of Item/Pet opportunities. No game fix was attempted.
2. **Input focus and movement release:** early focus handling required repair. One Trophy return was followed by an unintended ordinary Stage1 lap because movement input continued; a helper released input on Stage reset. These are harness problems and remain in elapsed time.
3. **Wrong movement argument shape:** a resumed input used named coordinates where the helper expected indexed coordinates. The ordinary route and incidental20-Win purchase are explicitly recorded in run1-status-73min.md.
4. **Measurement limitations:** missed first Win transition, incomplete final event export, raw operation-category over-attribution, and no valid retained main-run progression screenshot. The attempted Merge screenshot was occluded by a terminal and is rejected as evidence. Preparation render checks are distinguished from main-run results.

## Records and cleanup

Records include the fixed conditions, preparation/live notes,71 incremental main-run checkpoints,43 OS-input files, deduplicated [events.jsonl](events.jsonl), first-clear/time CSVs, last confirmed state, and harness Sources. The separate run01/checkpoint_0001.json is a discarded clock pilot, not main run1. Main data is in main-run01. Account display names were redacted from unpublished text records; native inventory/session IDs remain only as needed for traceability.

At termination Studio was already Edit, so a final Play read was unavailable. Cleanup compared all446 initial Sources against their expected original/temporary dependency forms before writing: zero unexpected edits. It restored exactly35 dependency substitutions, destroyed the three installed Edit helper nodes and verified all446 Sources exactly equal their original live values. Zero __Night objects remain. Camera CFrame/focus/FOV/type and StarterGui.ShowDevelopmentGui match the initial values. See [cleanup.json](cleanup.json). Runtime-only route/release helpers ended with Play. No game fix, balance change, Save/Publish, rbxl writeback/new backup/copy/migration or Studio closure occurred.

The user's existing unsaved edits remain in Studio. Manual Save/Publish is required before PC transfer or exit. The benchmark was terminated at the user's request; the three-run task is not reported complete.
