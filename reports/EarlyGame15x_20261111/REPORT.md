# Early World1 pacing — tested candidate, NOT applied to Studio

## Status and scope

Numeric/source baseline: `dd3531ebd99131cbb9481227b23fd99ab9393751` on `origin/main`. During this work, main advanced to `08fb3078742b7f2faf0e20e5e3db7d804823b69e` with the separate offline-claim/return-notification fixes. The three Sources changed here and the test dependencies are unaffected by those commits. The draft is based on that newer main and preserves both concurrent fixes.
This is a draft implementation for faster initial level feedback and World1 Stage1, with extra time assigned to Stage2. The requested target is approximately 1.5x speed (two-thirds elapsed time) for the opening, while preserving the intended later pace. Whole-route elapsed times are **not verified**. Do not merge or describe this as a live fix until the native checks below pass.

There is no Roblox Studio connection in the authoring environment. No Place, live player data, public game, Save/Publish, OS input or local Windows files were changed. Repository Sources and isolated Luau-WASM checks are the evidence here. The canonical target for later application is PlaceId `126576845524886`, UniverseId `10765181857`.

## Proposed numeric changes

`ReplicatedStorage.Config.LevelRequirements` changes only costs from levels1–7. The subsequent costs, high-LV formula, level cap, reward gains and Rebirth rules remain unchanged.

| Reach LV | Old cumulative gain | Candidate cumulative gain | Old cost / candidate cost |
|---|---:|---:|---:|
|2|10|7|1.429|
|3|40|27|1.481|
|4|90|60|1.500|
|5|160|120|1.333|
|6|250|215|1.163|
|7|375|360|1.042|
|8|530|530|1.000|
|9|720|720|1.000|
|10|955|955|1.000|

New per-level costs1–9: `7,20,33,60,95,145,170,190,235`.
These cumulative equalities apply to a fresh progression cycle, including after Rebirth. Equal cumulative requirements do not prove equal elapsed time when equipment and player choices differ.

`ReplicatedStorage.Config.World1BossConfig`:

| Setting | Baseline | Candidate |
|---|---|---|
|Stage1 required Strength reference|75|45|
|Stage1 Boss HP|375|225|
|Stage1 walls|100 / 125 / 150 / 200|65 / 85 / 100 / 135|
|Stage1 recommended LV label|8|4|
|Stage2 Boss HP / required Strength / recommended LV|2250 / 450 / 10|unchanged|
|Stage2 walls|300 / 325 / 350 / 425|500 / 650 / 800 / 1050|
|Stages3–10|existing values|unchanged|

Stage2 wall changes are a calibration candidate, **not a claim that the elapsed time saved in Stage1 has already been exactly recovered**. Each Stage2 wall remains weaker than the corresponding Stage3 wall. Stage2 Boss survivability is not made worse by increasing its HP or damage.

Stage1 total HP falls from950 to610. At identical Strength20/30/45/60/75/100, executing the existing WallManager carry and BossCombatService damage paths requires1.43–1.57x fewer accepted attacks. This model excludes movement, reaction, lost contact, death, frame scheduling, return, rewards and equipment. See `tests/EarlyGameBalance/result.json` for the full attack-count matrix.

At candidate LV4 (fresh cumulative Strength60, no modifiers), Stage1 needs4 Boss hits. Even allowing the first Auto hit to wait one full0.8s interval, the ideal uninterrupted-contact sequence ends by3.2s, before the unchanged fourth25-damage Boss hit at4s. This arithmetic does **not** prove survival with missed contacts or real engine scheduling. Stage1 repeated farming and first-clear drops must also be tested: lower HP applies to every Stage1 encounter, not just the first encounter.

## Tutorial integration

The existing floor guide switches from Treadmill to walls at LV2. Lowering LV2's cost from10 to7 without another check would guide a fresh player to combat at lower Strength.

The candidate adds `World1BossConfig.IntroTrainingStrength=10` and a small `NeedsIntroTraining` predicate. `TutorialGuideClient` uses it in its existing refresh loop. Early LV feedback occurs sooner, but initial wall guidance retains the prior10-Strength floor. This is presentation only; no new combat entry lock is added. Once a wall or Boss is already cleared, the added Strength floor cannot send the player back to training. The existing LV-reset rule, World/life/completion checks,0.2s presentation refresh and all Merge/Egg guidance remain.

## Saved progress and legacy lookup

No saved field, schema, LevelProgressVersion, award value or migration was changed. Current `PlayerDataService` preserves explicit saved Level/LevelProgress. The archived progression implementation confirms that overfilled saved progress is carried on the next positive gain; a zero gain does not replay it. The draft leaves that behavior intact rather than deriving live levels from Strength or adding a new persistence migration.

The old `CalculateLevel` threshold lookup is deliberately preserved for unversioned records by retaining the old first7 costs privately in LevelRequirements. New requirements must not silently change that one-time historical lookup.

**Existing low-level profiles are not promised identical remaining work.** Their exact saved LV/progress remain, and future gains use the new costs. Depending on their current early LV, the remaining gain to LV8 can be3/13/30/40/35/15 larger than before (LV2–7 respectively). No saved Strength, LV, progress, inventory or currency is deducted. Existing LV8+ profiles have identical future requirements. This is a balance consequence to evaluate in the native acceptance run, not a claim of complete backward pace equality.

The repository has no shipping `src/ReplicatedStorage/Modules/LevelProgression.luau`. The test fixture is the tracked `reports/Level_Progress_20260915/after/ReplicatedStorage.Modules.LevelProgression.luau`, consistent with the November10 report but **not freshly exported from Studio**. Before applying, compare the live module and rerun the checks with its export via `LEVEL_PROGRESSION_SOURCE`. Do not copy the archived fixture into production.

## Verification performed

Executed the actual proposed Configs, current repository WallManager/BossCombatService and the identified progression fixture in Luau-WASM1.4.0 with minimal service adapters. Both changed Configs and the changed tutorial client compile. The check count includes exhaustive boundary/property loops, not255902 distinct gameplay scenarios.

- All10000 requirements are finite, positive and increasing; every requirement fromLV8 onward is exactly unchanged.
- Fresh LV8/LV10 and every configured Rebirth cumulative requirement match the baseline.
- Exact/below/above LV boundaries, fractional gains, batching, very large finite gains and invalid values behave as expected.
- Explicit saved LV/progress are retained; positive gain conserves Strength and progression; memory reload/zero gain do not double-count. No real DataStore was used.
- Historical unversioned lookup matches the baseline over0–2000 in0.25 steps and large values.
- Actual wall carry, fresh/reset snapshots, Boss hits, Glove bonus, unfinished heal and completed-Boss non-resurrection pass with the changed values.
- Separate table-backed player adapters retain independent wall/encounter state. This is **not multiplayer Roblox Play**.
- Initial tutorial gate tests cover early LV2 at7 Strength, release at10, existing battle progress and reset.
- Auto/manual intervals, Boss behavior and all Stage3–10 values remain unchanged.

Result: `255902` assertions passed. The observed execution report is checked in at `tests/EarlyGameBalance/result.json`.

## Required native checks before acceptance

1. Read the current canonical Studio Sources and preserve newer manual edits. Compare the current LevelProgression implementation with the explicitly identified fixture; rerun offline checks against the live export. Do not replace current Sources wholesale from this draft.
2. Use isolated fresh/reset data and the same action/route policy before and after the change. Record first LV2/3/4, first wall, Stage1 Boss defeat, Trophy return, first merge/equip, Stage2 defeat and first Rebirth. Record Strength, LV/progress and equipment at each point.
3. Cover Auto-only and representative manual/mixed input using the unchanged cadence. Do not use setstrength/setlevel, injected equipment or skipped movement to claim a normal first-session time.
4. Whole Stage1 should approach two-thirds of baseline elapsed time. Stage2's own interval should increase; join-to-Stage2 completion should stay near baseline (initial comparison tolerance10%). If these targets fail, retune the candidate Stage1/2 Config values and repeat only the affected scenarios. Do not insert waits, speed multipliers, new reward times or hidden grants to force a result.
5. Preserve TimeRewards at1/2/3 minutes (Stone2, Iron2, Win3) and the existing merge/equip/Egg flow. Check claiming immediately and later, natural drops, repeated Stage1 farming and return/Back/death. Ensure the smaller early LV costs do not jump/loop the guide or the later merge presentation.
6. Check existing low-LV, overfilled progress, LV8+, Rebirth and saved/reloaded states with the live services. Confirm HUD progress/notifications and no duplicate gain or downgraded data. If the owner requires identical remaining work for existing low-LV profiles, design and review that separately rather than silently adding a save migration.
7. Confirm unchanged Stage3+ and World2 consumers, no runtime errors/infinite yields, and no newly introduced duplicate listeners/timers. This does not require re-auditing unrelated completed UI features.
8. Return to Edit, remove fixtures and keep user edits. Do not Save/Publish or use OS input. After successful native verification, integrate the reviewed changes through the established normal Git workflow. Manual Save/Publish remains the owner's step.

## Changed production Full Paths

- `ReplicatedStorage.Config.LevelRequirements`
- `ReplicatedStorage.Config.World1BossConfig`
- `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient`

Production specification updates are intentionally not represented as completed on main while this is a draft. Upon native acceptance, add the confirmed early curve/Stage values to BALANCE_SPEC, the guide floor to GAME_SPEC and the actual tested/untested scope to DEV_STATUS/CHANGELOG. Existing historical reports must remain untouched.
