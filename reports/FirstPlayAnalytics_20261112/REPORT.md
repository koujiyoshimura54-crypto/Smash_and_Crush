# First-play funnel instrumentation — 2026-11-12

Implemented in the current unsaved canonical Studio, **Place126576845524886 / Universe10765181857**. Instrument mode, limited to the user's Entry / FirstCombat / FirstOreMerge plan and first-action elapsed values. Five new Sources and thirteen existing Sources changed. No balance, UI, tutorial, AutoTap behavior, price, receipt or persistence-schema change.

The [English measurement specification](../../docs/FIRST_PLAY_ANALYTICS.md) contains the complete event schema, cohort/denominator definitions, all changed Full Paths, server gates, limits, manual configuration location and Creator Hub verification instructions. `rbx-instrument-analytics` was loaded from the connected Roblox Studio skill provider during final review. Its server-only, success-only, bounded-name and deduplication guidance was applied to the existing implementation; the user's explicit three-funnel plan supersedes the generic onboarding template and repeat-approval workflow. No Economy or unrelated instrumentation was added.

## Findings and implementation

The scoped Live Source audit found no existing AnalyticsService event calls in493 Sources. Existing first-profile creation, placement acknowledgement, combat outcomes and Forge journals provided the authoritative hooks. Git absence alone was not used as evidence of absence in Studio.

- Entry observes the server join before load, retains load-failure denominators, and only completes after actual client HUD/control/loading checks plus accepted server placement. Native Play exposed the current engine's `StarterPlayer.PlayerModule.ControlModule` location/API; the observer now supports it and the legacy location without modifying controls.
- Combat observes real Stage1 floor entry, successful wall destruction, decreased Boss HP and confirmed defeat. Death/rematch does not restart it. Skips and invalid observation orders are independent categories, with no fabricated earlier steps.
- Ore eligibility uses confirmed owned materials and the existing evaluator. Actual visible Ore UI and valid selection are reported through a bounded validated gateway. The normal accepted request carries a read-only current-view snapshot to handle network order. Save confirmation uses the existing exact Forge journal; delayed persistence and acknowledgement loss cannot count success early.
- A service simulation found that a repeated accepted-Merge observation could mark the pending first funnel broken. The first operation identity is now retained and duplicate observations ignored. Final skill review removed redundant normal Merge custom events; the normal step's elapsed value is sufficient, while nonsequential paths retain independent events.
- The first return token correlates acceptance, Lobby arrival and save confirmation without putting travel behind persistence. First ordinary gain route, explicit Auto ON, equipment and death are observed once. Existing Back/Bag, offline Claim and return UI behavior remains under its existing authority.

## Actual native Play

All acceptance runs used isolated memory DataStores and blocked payment/badge/messaging adapters. Native server plus three real clients were created through StudioTestService; programmatic ordinary Remotes, real Humanoid.MoveTo and actual Merge/Hatch callbacks were used. No OS input, forced draws, normal-route stat grants, reward-clock edits or test teleports.

Two successful independent normal-route launches completed **Auto, Manual and Mixed**, three routes each. These are six ordinary routes, not six independent launches. Each starts absent data at Strength0/LV1, trains, walks through all Stage1 walls, damages and defeats the Boss, takes Trophy back, claims the ordinarily ready Stone reward, opens Ore UI, selects actual owned Stone, submits normal Merge, finishes the normal chest callback and equips the confirmed result. The held early-game candidate remained in Studio throughout.

- [Before final deduplication](native-normal-before-dedupe.json): all three routes succeeded; each client recorded Entry1–3, Combat1–6 and Ore1–5 exactly once.110 recorded events.
- [After the final production-code change](native-normal-final.json): all three routes succeeded again; all nine per-player funnel-sequence assertions passed.104 recorded events after removal of the six redundant normal-Merge values. Each route had zero deaths; the intentional death check is separate.
- The event records include the actual server elapsed values, equipment, Strength/LV, reward and Bag state. Client snapshots show the actual visible Ore panel and selection. This task did not acquire viewport screenshots and does not claim a new visual-design review or physical-device test.
- Natural Trophy returns recorded accepted return, saved loot and Lobby arrival independently. In these ordinary runs saving completed before the arrival acknowledgement; the opposite ordering was tested by controlled service-state simulation.
- Final native server and all three client consoles were inspected. No new analytics runtime error or Infinite Yield was found. Existing asset permission/download warnings and intentionally rejected isolated Badge awards remain outside this change.

## Injected native runtime boundaries

[Native boundary record](native-boundaries.json): **15 assertions passed** with one actual newly created profile, one seeded existing LV1/Strength0 profile with saved Auto ON, and one injected load failure. These are controlled data/fault boundaries using the real running services and client GUI, not earned-route timings or real published-server failures.

- Newness follows creation; default-looking existing data is excluded. Failed load records only Entry step1 plus LoadFailed. Both playable clients initially remain Auto OFF.
- The player physically opened Ore UI before owning material. Two injected Battle Bag Ore did not qualify. Two ordinary durable server grants into owned Ore then produced Eligible and reobservation of the already open screen, followed by real selection.
- Thirty duplicate view notifications, a forbidden action and an invalid session did not duplicate funnel steps.
- Held writes left Merge at Requested, with no committed step and no runtime Dumbbell. The next write committed but lost acknowledgement; the existing retry confirmed the same journal. Eight request replays retained exactly one granted result and one step5.
- A second Merge with a precommit failure stayed pending and resolved normally; it produced no second first-Merge completion.
- An actual Humanoid death followed by normal respawn recorded one death and retained the same Entry/Combat session.
- Injecting an analytics-send failure did not block a successful ordinary manual Strength increment.
- Actual isolated Data.Reset excluded further new-session observations. An existing profile's actual memory Save/Release/Load remained Existing and did not start another Entry session.

This boundary launch preceded only the final removal of redundant normal-Merge custom values. The final state matrix and ordinary routes ran after that final change. Receipt/payment behavior was not altered or exercised with real payment.

## Controlled Luau simulations

- [Final state matrix](state-matrix-final.json): **38 assertions**, using a dependency-injected copy of the actual analytics service with fake players/data/location/signals and the Studio transport. Covers New/Existing/Unknown, load failure, exits after every Entry/Combat/Ore step, death/rematch, reset, early-open and request-before-notification orders, stale/invalid token/character/generation/area reports, missing-view success, skip/out-of-order protection, duplicate first actions, both return arrival/save orders and a failed first funnel send. The earlier [matrix](state-matrix.json) is retained as pre-final-review evidence. This is simulation, not38 Play sessions or actual network-disconnect tests.
- [Ownership matrix](ownership-matrix.json): **8 assertions**, real acquisition module with in-memory callback inputs. Covers confirmed fresh creation, existing zero-like records, ambiguous missing records, creation acknowledgement loss and retry, later acquisition as Existing, repeated callbacks and reset-shaped saved data. No analytics is emitted from the callback.
- Syntax compilation of all27 scoped shipping Sources passed. [Source audit](source-audit.json) matches the22 captured live originals plus the intended37 scoped patch hunks and five current new Sources. The only AnalyticsService API call site is FirstPlayAnalyticsTransport.

## Excluded attempts and limits

Two initial native readiness probes exposed the legacy-only PlayerModule assumptions and were stopped before accepting normal routes. Two injected-boundary setup attempts had temporary adapter errors (wrong insertion point; missing server-only seed guard), were corrected and rerun, and are not passing gameplay tests. The acceptance evidence above comes from the corrected attempts. A connector/agent restart interrupted result collection; completed native results were recovered from the running native server before ending that test, without rerunning or inventing outcomes.

During final cleanup, after29 of41 temporary Source replacements had been restored, the canonical instance unexpectedly switched from Edit to Play outside this agent's native-test launch sequence. Further edits were rejected by the tool. It was stopped immediately after detection, and all remaining Sources were rechecked. That session is excluded from verification. No QA route input or fixture grant was intentionally run in that session; whether the game's ordinary initialization wrote its Studio-suffixed profile store is unconfirmed. The intentional acceptance tests themselves were fully isolated.

Unconfirmed: published-server API receipt and Creator Hub charts, physical device/OS controls, real network packet loss/disconnect at every step, public DataStore/rejoin behavior, and World2 gameplay. StageSkip, arbitrary step exits and both return completion orders have simulated observation coverage; they are not claimed as actual native purchases/travel/disconnects. Treadmill classification was audited at the existing multiplier-supplying caller; this task did not perform a dedicated first-gain Treadmill route. Silent platform analytics drops and post-departure save completion can undercount; see the specification. Average elapsed values describe reachers only. Missing historical profiles cannot prove account newness.

## Cleanup, preservation and delivery

[Cleanup](cleanup.json): all39 external-service substitutions and both callback aliases restored. One SlapController trailing CRLF was normalized by the editing tool; there is no code-content change and it is not included in the Git change. Eleven exact temporary fixture objects/folders were removed; zero `__EarlyQA` / `__FirstAnalytics` instance or shipping-Source references remain. Canonical Studio is stopped in focused **Edit**, preserving the prior unsaved edits and this instrumentation. No Save/Publish, rbxl writeback, OS input/foregrounding or canonical Studio close was performed.

The worktree derives from main84331b5. Back dd3531e, offline/return fixes and AutoTap join-OFF remain. The live PlayerDataService also contains the held PR #1 zero-gain normalization; that unrelated line is retained in Studio but excluded from this main commit. No old Git Source was bulk copied into Studio. Test screenshots were not created or committed. Local `.qa` baseline/source backups are not staged.

Only the listed analytics Sources, test fixtures and English documentation/evidence are to be committed and normally pushed to origin/main. The completion response supplies the commit and push result. Public reflection requires the owner's manual Save/Publish. Use Creator Hub Funnel, Custom/Explore and View Events after publication; aggregate charts normally take about24 hours. No past behavior can be restored, and no retroactive measured events are sent.

After cleanup and final Edit verification, the user explicitly said they would start Studio/Play and instructed the agent **not to stop it**. This latest instruction supersedes the earlier final-Edit requirement for subsequent user-controlled Play. No further Studio mutation or Play-stop action is part of the remaining documentation/Git delivery.
