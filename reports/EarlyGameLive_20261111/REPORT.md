# PR #1 live verification — started 2026-11-11 JST

Completed 2026-11-12 JST. **Progression/HUD repair passed; balance acceptance and main reflection remain HELD.** Auto, Manual and Mixed each completed six fresh routes before and six after:36 successful native routes, twelve independent multiplayer Play launches. The final candidate also ran a separate fresh visual route. The Mixed sample's Stage2 total is +11.57%, outside the initial ±10% comparison guide; this is not marked as a pass.

## Canonical source and scope

Canonical Studio: Place126576845524886, Universe10765181857, session c76164f6-2d12-4020-ad17-65eef698f1f3. PR head06247f33; baseline main08fb307 (including Back fixdd3531e and offline/notification fix7e42bfa). Current live Sources, not the archived progression fixture, supplied the baseline. The three PR target Sources matched main at the start; PlayerDataService matched main too. Existing unrelated unsaved edits were retained.

Production Full Paths:
- ReplicatedStorage.Config.LevelRequirements — PR early costs and stable legacy lookup.
- ReplicatedStorage.Config.World1BossConfig — PR Stage1 / Stage2 values and intro Strength floor.
- StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient — PR intro predicate.
- ReplicatedStorage.Modules.LevelProgression — live-derived normalization fix; newly tracked in Git.
- ServerScriptService.Services.PlayerDataService — publish normalized zero-gain state.

The HUD layout/source was not changed. Normalization carries excess progress before publishing saved Level/Progress, and on zero gain. It neither invents Strength nor derives a versioned Level from Strength. LevelProgressVersion remains1. Ownership, save fencing and reward operation IDs are unchanged.

## Normal-route method

Native StudioTestService multiplayer Play uses three real clients, one each Auto, Manual, Mixed, with a fresh memory store on every independent launch. All assert initial Strength0 / LV1 / progress0. External DataStore, receipt, badge and messaging dependencies are isolated; no production data, real payment, or production reset is used.

The same policy is used before/after: ordinary walking training until both LV4 and nominal four-hit Stage1 Boss damage are available (baseline94 Strength, candidate60); defeat all Stage1 walls/Boss, touch normal Trophy, merge owned Ore, equip, train to563 Strength, reclear Stage1 on foot, defeat Stage2, touch Trophy, train toLV10 and use normal Rebirth request. There are no stat/equipment grants, test-driven teleports, stage skips, time changes, or forced draws in these timing runs; the game's normal Trophy/Back return remains intact. Auto uses the normal toggle; Manual taps every0.25s; Mixed taps every0.9s plus normal Auto. Inputs are programmatic through existing game remotes and Humanoid.MoveTo, not OS input.

Ready TimeRewards are claimed through normal remotes. Stone×2 is merged when available; Iron×2 upgrades an empty/NORMAL_01 slot. Manual equips the result explicitly; Auto/Mixed use Best Equip. The unchanged normal RNG is recorded per run. The existing chest callback is temporarily exposed solely so the driver can press its actual knock/result-dismiss callback; no animation delay is skipped. All driver hooks are removed afterward.

Each event records server time, time from common start, Strength/LV/progress, equipment, rewards and bag state. Analysis subtracts each client's Operable timestamp. Loading time remains separately recorded. Stage2Phase means first Trophy return to Stage2 defeat (training, earned gear, second expedition included); Stage2Corridor means entering the Stage2 route to its Boss defeat. Travel is included, not subtracted or synthesized.

A preliminary solo run and a setup error were excluded: an early driver waited15s for a persistent hatch GUI and paused at walking turns. Accepted before/after runs use continuous normal walking and the actual hatch completion callback.

## Measured results and acceptance

[Every individual run](RUNS.md), [complete timing/state CSV](route-times.csv), [raw summary](timing-summary.json), and [equipment-matched observations](matched-gear.json) are retained. All36 timed routes completed with zero deaths; the intentional natural-death check is separate. Final after-runs4–6 were independent cold native launches after exact restoration of the candidate Sources. Module/GUI/event instances and isolated memory data were recreated; engine-managed asset caches were not manually cleared.

| Input | LV4 before → after | Stage1 defeat before → after | Stage2 total before → after | Stage2 total delta | First Rebirth before → after |
|---|---:|---:|---:|---:|---:|
| Auto | 45.87 → 30.38s | 60.91 → 43.36s | 156.69 → 151.17s | −3.52% | 200.28 → 192.31s |
| Manual | 23.67 → 15.76s | 33.85 → 24.47s | 114.63 → 110.32s | −3.76% | 141.00 → 136.81s |
| Mixed | 40.97 → 27.17s | 53.33 → 37.85s | 132.67 → 148.03s | +11.57% | 171.11 → 186.35s |

LV4 is about1.5× faster. Whole Stage1 is1.38–1.41× faster (27.7–29.0% less time), not an exact1.5× full-route result; unchanged travel/contact time is included. Stage2 phase time increased from94.64→106.80s Auto,79.78→84.84s Manual and78.23→109.12s Mixed. Stage2 corridor combat/travel increased7.69→9.31s,5.10→5.28s and5.80→7.08s respectively. Stage2 defeat→Rebirth took43.60→41.15s,26.38→26.49s and38.44→38.32s: no large later speedup was observed in these samples.

The initial three-run Auto comparison was −12.33%, so a predeclared additional cohort of three before/three after launches was performed, preserving all earlier observations. Final Mixed runs drew NORMAL_02 from the first Stone merge4/6 times before and1/6 after. Its three matched gear paths changed by−0.30%,+1.95%,−1.47%; across all modes the matched differences are−4.51% to+1.95%. This supports an RNG-sample explanation, but does not turn the unmatched +11.57% measurement into a passing result. No forced draw, hidden wait, extra Strength, or balance constant fitted to that draw imbalance was introduced. The PR balance numbers were retained because matched routes did not demonstrate a systematic Config error that justified retuning. A distribution-balanced independent comparison and acceptance of the measured whole-Stage1 pace remain outstanding before main reflection.

The formulas beyond LV7, cumulative fresh gains530 toLV8 /955 toLV10, Stage2 Boss2250, Stage3+ values, input cadence, equipment, rewards and prices remain unchanged. Studio adjustment locations are LevelRequirements.FIXED_STRENGTH[1..7], World1BossConfig.RequiredStrength[1], RecommendedLevels[1], walls[1..2], and IntroTrainingStrength. No GUI layout or font setting was changed.

## Existing-save carry

Native Play tested seeded save profiles, actual ordinary Tap gains, actual HUD labels/fill, a failed memory save, retry and memory save/reload. See boundaries.json. These are injected save boundaries using real runtime services/UI, not fresh normal-route timings or a published-server rejoin.

| Saved LV / P | Loaded LV / P | Extra remaining gain to LV8 versus old costs |
|---|---|---:|
| 1 / 9 | 2 / 2 | 0 |
| 2 / 29 | 3 / 9 | 3 |
| 3 / 49 | 4 / 16 | 13 |
| 4 / 69 | 5 / 9 | 30 |
| 5 / 0 | 5 / 0 | 40 |
| 6 / 124 | 6 / 124 | 35 |
| 7 / 154 | 7 / 154 | 15 |
| 8 / 189 | 8 / 189 | 0 |
| 10 / 15 | 10 / 15 | 0 |
| rebirthed 2 / 29 | 3 / 9 | 3 |

Strength is unchanged during load in every case; excess is conserved. Fractional rebirthed Tap gain1.5 is retained. Repeated load does not apply carry twice. Zero-gain publication was separately checked. The existing HUD rounds display numbers as before; its fill uses the exact fractional progress. No compensation or schema migration was added.

## Additional runtime and fault checks

- Strength7→8→9→10 while LV remains2: guide stays Treadmill at8/9 and changes to Wall1.1 at10. Actual HUD and floor-arrow images were inspected. One guide instance remained.
- Two client-local delayed attribute-arrival orders (Level then Strength, and Strength then Level), followed by60 frames each: correct final target and no target toggles. This is controlled arrival simulation, not a real packet-loss network test.
- Rebirth while the initial guide is active: actual server Rebirth request resets to Strength0/LV1/P0 and Treadmill guide. The starting boundary profile is explicitly seeded.
- Delayed Stone claim at134s with10 submissions: exactly2 Stone. Iron at164s with10 submissions and held writes: no inventory publication before confirmation, exactly2 Iron after release and replays. Win at196s with commit acknowledgement loss and replays: exactly3 Win in runtime and memory store. No reward clock/formula was changed.
- Actual earned post-route data: train, clear walls, Back, walk out again, take natural Boss damage to death, respawn, rematch, Trophy return. The Back-created bag is active and its ID equals the combat ID.
- Separate final fresh visual Play: Boss defeat43.56s → TrophySpawn43.87s; the guide stayed at Trophy1 for60 sampled frames with one guide instance, including delayed TimeReward arrivals. A live image showed white floor arrows terminating at the yellow return pad. Actual Trophy return then showed Lobby /73 Strength /LV4 /13 of60. The screenshot pause excludes this route from benchmark totals. Native memory save/reload and Stone-claim replay returned AlreadyClaimed with identical Strength/LV/progress/Win/Ore counts.
- Three actual clients: one player's wall clears / Boss defeat do not change the other two players' walls, defeat state, LV or Strength. Native client HUD snapshots match their own attributes.
- Native pure Luau/service-adapter checks:263738 assertions using live-derived progression/current wall/Boss Sources. This count is arithmetic/model coverage, not a Play count.
- Existing asset-access failures and intentionally blocked badge awards occur in both baseline/candidate. Expected save acknowledgement-loss diagnostics are isolated fault injection. No claim is made that these assets were fixed.

The held third after-run exceeded the connector's300s call timeout while extra checks continued. Its completed normal-route Result was read directly from the native server before stopping; all three route completions are preserved. This connector timeout is not reported as a successful tool response or hidden as a gameplay failure.

## Artifacts and limits

Per-run JSON and route-times.csv are the event evidence; timing-summary.json is only a summary. faults-and-guide.json, boundaries.json, multiclient-hud.json and back-death-owner.json distinguish injected cases from earned-data Play. Screenshots were inspected temporarily and are not committed. A Rebirth panel obscured the first extra world capture; after hiding that test-time panel, the native Stage2 wall500/500 and matching HUD were visible. That image is not claimed to show the Trophy itself.

Published-server persistence/rejoin and real-device/manual-human timing are untested. No OS mouse/keyboard, foregrounding, Save/Publish, rbxl writeback, or canonical Studio close is used. Public-game reflection requires the user's manual Save/Publish.

Local Python analysis scripts passed syntax compilation and the Git diff passed whitespace checks. Node is unavailable on the local PATH, so the updated WASM runner and its Node syntax check were not executed here; the separately recorded native Luau equivalent passed. This does not add any Play coverage.

Inspected native logs included before-run5 and after-run4 server plus all three clients, earlier route samples, and the final visual Play. No new gameplay Runtime Error or Infinite Yield was observed there. After-run6 console retrieval missed the already-closed child sessions; its successful route events are retained, but that missed console read is not classified as a clean-log pass. Existing asset authorization/download warnings and intentionally rejected badge awards remain outside this patch. Physical-device behavior, published DataStore behavior and every possible randomized/human strategy are not claimed as verified.

## Cleanup and delivery

All39 external-service substitutions were restored with exact Source guards; the temporary hatch alias and all route/boundary/baseline helpers were removed. Final inspection found0 __EarlyQA instances and0 shipping Source references. All five changed Sources match the tracked implementation after line-ending normalization. RunReturnService, EnemyManager, CombatClient, World1BossPresentation and Stage01AppearanceClient exactly match their captured protected Sources. See [final audit](final-audit.json) and [source manifest](source-manifest.json).

Canonical Studio is stopped, focused Edit, with existing edits and this candidate retained unsaved. Only the existing PR branch is to receive the scoped commit by normal push; PR remains Draft and origin/main remains08fb307. The containing commit identifies this record; the completion response records the push result. No Save/Publish was performed.
