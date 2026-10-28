# One adaptive World1 benchmark — completed, 2026-10-27

**Exactly one fresh unpaid run completed: 11014.913seconds, 3h03m34.913s, through Stage10 first defeat.** Play is stopped and Studio is inEdit. No second/third benchmark was started. The one clock includes all natural deaths, material laps, input failures, reasoning, rendering waits and concurrent training. No balance was changed to obtain this result.

Authoritative baseline: the user's current unsaved Y02 Studio, Place126576845524886 / Universe10765181857, loaded version292. Git HEAD/origin at preparation and final fetch:12b43fa925f0d61ceb633249fc67f36d483da85e. Current unsaved edits, not old Git/rbxl Sources, remained the implementation baseline. The existing death/Merge fix is at `StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New`; its old respawnedGUI copy remains absent. No gameplaySource was changed in this benchmark.

## Evidence and timing limitations

StartUTC1793077422.577; FinishUTC1793088437.490. The read-only native recorder exported2888 contiguous events with oneStart/Finished, ten first-clears and category/finish agreement within1second. See [metrics](metrics.json), [CSV](stage-first-clears.csv), [raw events](run01/events.jsonl), [final native state](run01/finished.json), [decisions](decisions.md), [conditions](conditions.md) and [cleanup](cleanup.json).

The60-minute checkpoint was **Stage3 first-cleared, Strength18226.5/LV25/R1** in the surrounding real snapshots, not an interpolated exact3600second state. See [before/after snapshots](sixty-minute-bracket.json). The run did not meet60minutes. The previous83-minute partial run was reference only and was not added to this run or counted as completion.

| Elapsed | Stage | Strength | LV | Rebirth | Win before Trophy | Main gear |
|---|---:|---:|---:|---:|---:|---|
| 01:00.667 | 1 | 101.00 | 4 | 0 | 1 | none |
| 04:54.808 | 2 | 909.00 | 9 | 0 | 3 | NORMAL_01 |
| 16:52.078 | 3 | 5,890.00 | 19 | 0 | 9 | NORMAL_01 |
| 73:24.143 | 4 | 18,267.00 | 25 | 1 | 26 | NORMAL_03 |
| 79:00.179 | 5 | 58,267.05 | 32 | 3 | 21 | NORMAL_03 / Pink / Bear |
| 90:22.753 | 6 | 256,039.20 | 41 | 3 | 81 | NORMAL_04 / Pink / Bear |
| 111:07.671 | 7 | 948,633.75 | 49 | 4 | 31 | NORMAL_05 / Yellow / Bear |
| 150:17.042 | 8 | 3,929,112.60 | 55 | 5 | 381 | NORMAL_07 / Yellow / Bear |
| 154:05.000 | 9 | 3,957,967.12 | 55 | 5 | 531 | NORMAL_07 / Yellow / Bear |
| 183:34.913 | 10 | 4,047,246.42 | 55 | 5 | 1031 | NORMAL_07 / Yellow / Bear |

FullItem equipment appears inCSV/native snapshots: Stages5/6 usedUncommonIceProtein/RareIceBelt/CommonElectricGlove;7 usedCommonIceGlove instead for theIce set;8–10 upgraded toRareIceProtein. First-clear sampling is approximately0.25seconds; exported milliseconds are not millisecond-accurate human timing. Win is the value at defeat, before thatStage'sTrophy claim.

| Native activity label | Minutes |
|---|---:|
| operations | 8.078 |
| training | 67.194 |
| combat | 10.985 |
| death | 0.169 |
| codex_interruption | 86.715 |
| movement | 10.442 |

These are mutually exclusive native activity labels, not precise causal time accounting. Training includes overlapping AI reasoning; UI/input waiting can appear inoperations orcodex_interruption. Death time is the observed dead/no-character interval, not every second spent recovering. **Do not subtract86.715minutes to manufacture a human completion time.** Pre-readiness loading was outside the requested usable-player start boundary and was not separately timed. This is one automation-heavy run, not a general-player average or fastest-time guarantee.

Native MCP mouse/capture calls stalled. Official `UserInputService:CreateVirtualInput()` subsequently activated real gameUI when the viewport rendered, without OS cursor/foreground/window manipulation. In the unavailable background state, a focused probe observed0RenderStepped, noUIS.InputBegan, noButton.InputBegan/Activated and noInventory opening. Return/ButtonA probes also failed; ordinary in-game selection focus was restored. A successful API return was never treated as a completed purchase. Rendering later resumed long enough for realtransactions, then stopped again. A request to leave theClientPlay viewport partially visible did not authorize any automatic window change, and none was made. UI quality under full desktop occlusion remains a practical limitation.

## Decisions, actual outcomes and RNG

- FirstStone5points forged guaranteedNORMAL_01 withoutWin. Coal2+Iron=23points naturally rolledNORMAL_03 (15% upper outcome); that favorable luck is separate from strategy. A mistakenNORMAL_02 UI input was rejected for insufficientWin, with no debit, rather than counted as a purchase.
- An earlyStage2 attack died. Boss damage snapshotsStrength/Glove at battle start; a later death-timeStrength value is not the damage used through that encounter. The retry succeeded normally. NoHP or damage was changed.
- Rebirth was evaluated for future growth and equipment access, with no90second recovery rule. R3 unlockedIron; R5 unlockedGold while retaining equipment, currency, materials andPet. Gold with07/Yellow/RareIceProtein/IceSet/Bear forecasts6054.72Strength per second and actual snapshots showed roughly6000/s; tick scheduling means this is not an exact observed fixed-rate claim.
- BasicEgg was bought throughUI for15Win. Bear was naturally obtained (6.5% hatch chance; independently +6% Strength), hatched and equipped. FailedUI attempts did not debitWin. NoPet or RNG was injected. RareEgg was compared with the existingBear and larger additive/set upgrades, not deferred by a fixed rule.
- Ordinary timed/Daily rewards were claimed through theirUI after real elapsed availability. Potions and laterItems helped growth. Those late rewards were partly available because agent/input delays were long, so they confound a pure fast-route comparison. No paid/group benefit was claimed.
-71point forge producedNORMAL_04;130points producedNORMAL_05 (60% lower outcome). Pink30Win and Yellow200Win were selected without buying each intermediateAura. All actualWin spending totaled245:30+200+15. NoWin dumbbell purchase occurred; drops and freeOre forge were the chosen route.
- BestEquip selectedCommonElectricGlove althoughCommonIceGlove was available alongsideIceProtein/Belt. ManualIce selection kept +5% BossDamage and activated1.5x growth. BestEquip did not maximize this particular build's growth through its equal-rank element choice. No repair was made during measurement.
- Three spareCommonGloves were actually merged intoUncommonFireGlove. The equipped lower-rankIceGlove was retained for the stronger growth set. This was a real alternative, not a benefit assumed from an unusedItem.
- OrdinaryStage7 laps returned75Win each and naturally obtainedJade75/AquaCrystal85. The255point forge rolledNORMAL_07 (+75),50% lower outcome versus08, and it was equipped. Naturally ownedRareIceProtein (+30 from currentConfig) was equipped. OldNORMAL_05 sold for125Win. R5 then completed throughUI andGold became active.
- A second100point forge for sale/GreenAura funding was proposed, but rendering stopped at theOre tab before selection/transaction. It was cancelled; noSilverStone was consumed, nosecondforge orGreen purchase occurred. That cancelled macro is not counted as an outcome. ActualTrophy increases includedStage7=75,8=150,9=500Win; old estimates were corrected from observed changes.

## Combat learning and failures retained

Stage8 first clear used4Auto hits after the planned3.9M target was genuinely reached. A proposed earlier no-UI fallback had a helper parenting error and never ran; no progression is attributed to it. The separate later3.9M goal did run. The subsequent evasion investigation therefore did not retroactively saveStage8's training time.

Stage9 first clear used19acceptedAuto hits near3.96MStrength. IncomingBoss attacks retained their real range/angle conditions. The established encounter accepted ordinaryAuto attacks while normalMoveTo stayed inside theStage. HP samples were100,75,50,25 then25 until victory. The automatic heal after a win is not evidence that every incoming hit missed. A second approach also won normally.

FirstStage10 approach stalled after three walls: the boundedMoveTo helper stopped after60seconds and theStage-only route failed to renew input. Reissuing the same normal movement immediately advanced the character. This was an automation problem, not a balance repair. Later input renewed forward movement every20seconds until actualBossInitialize, then stopped renewing so it could not override evasion. All stopped time remains measured.

The firstStage10Boss attempt lost after7acceptedhits. Its short rectangle chose a lower-left starting corner then turned along the short edge back toward the pursuer. Ordinary timed jumps changed actualrootY but did not prevent death. The next approach died inStage9 because its older controller retained that direction-dependent short-edge flaw. Both failures and the earlyStage2 loss are retained: **three natural deaths total**.

The final input used floor-relative corners inset6studs and the long edge first for either starting side on9/10. Stage10's actual floor is86x164. Normalphysics jumps were scheduled0.68seconds after an observed damage event, then at1second cadence, instead of assumingBossInitialize delivery matched the attack epoch. NoHealth, CFrame, speed, collision, attack, progress or RNG value was written. Only temporary normalMoveTo/Jump input strategy changed.

FinalStage9 approach won, then **Stage10 was genuinely defeated by59accepted normalAuto hits**. Its focused final encounter lasted51.199seconds. Forty-six position/health samples showed real movement, rootY8.52–16.38, HP100→75→50 and survival untilBossGauge0/BossResultWIN. Two actualdamage events calibrated jumping. These samples support actual physics movement and combat success, not merely a playback/input flag. They do not isolate the separate contribution of wider corners versus jump timing.

The repaired persistentMerge controller was still present after natural deaths; no new death/Merge Source repair was needed. ActualOre transactions later than the early death succeeded. The last deaths were followed by read-only controller-presence checks, not a fresh fullMergeUI regression.

## Gameplay interpretation and proposals only

Dumbbells were forged1→3→4→5→7 rather than purchased. Ore thresholds and availabledrops beat the alternatives evaluated at those times; this does not prove purchases are always inferior. Selling obsolete05 added125Win without sacrificing equipped07. Pet+6%, Item/set growth, Aura additives and treadmill unlocks offered different upgrade choices. The15% early03 outcome was favorable luck;05/07 were lower outcomes. One run cannot statistically separate RNG and route skill.

Concrete variety came from turning drops into a visibly different equipment tier, keepingIce set over a nominally strongerFireGlove, acquiring the firstPet/Aura, and changing the movement plan after defeat. These can support meaningful choices and another material lap. Long low-gain training, repeated earlyStage traversal after returns/deaths, and input stalls created repetitive/waiting intervals. Set benefit, snapshot damage and establishedAuto behavior were more readily understood fromSource than from visibleUI. No claim is made that theAI experienced human enjoyment.

Evasion materially changed the plan: finalStage10 succeeded near4.05M versus its50M five-hit reference. This is a combat/balance finding to review, not a broken unlock assertion; RequiredStrength is a reference, not an enforced attack count. Whether outgoingAuto attacks should remain effective at those distances deserves explicit design review. No new range restriction or combat rule was implemented.

Proposals, **not executed**: evaluate earlier evasion before longtraining; compare a targetedWin purchase with saving for a largerOre threshold; inspectBestEquip equal-rank element-set ties; explain sets and battle-start damage more clearly; review outgoingAuto distance during pursuit. No additional benchmark, auto-restart, balance/UI/combat/save repair followed completion.

## Isolation, cleanup and saving

Fresh empty in-memory stores supplied native normal defaults. All paid ownership wasfalse; realpayments and badges were isolated. StudioStartOverride wasfalse. No grants, teststrengthening, forcedwins, forcedRNG, simulated waiting or direct purchase/merge/reward service calls were used. Trophy's own normal return warp is distinct from a prohibited testCFrame transfer. Raw exportedUserId keys are masked asbenchmark-player.

After finalevent export, Play was stopped. Restored35 dependency substitutions, removedfourEditfixtures, verified exact equality of439 guarded originalSources and zero__One leftovers. CameraCFrame/Focus/FOV/type and developmentGUI match their originals. The Merge fix and live104/160/210 attack angles were retained. No map/model/UI property was edited for this benchmark. The pre-existing unrelated untrackedreport was not staged or removed.

Studio remains open inEdit with existing unsaved edits. NoStudioSave/Publish, rbxlwrite, additionalPlace/backup/copy/migration orStudioexit was performed. TemporaryPlay data were discarded. Git contains this record and temporaryharness source, **no gameplaySource delta and no bulk export of unrelated user edits**. This is not aCloud saved/published update. ManualSave/Publish remains the user's task.

Checks performed: real in-game UI selection/equipment/merge/hatch/sale with actual state effects; real movement/Auto/physics combat; read-only telemetry integrity and focused cleanup checks. Not performed: full pixel/device/mobile comparison, productionDataStore/publicserver checks, or two-client regression. Cancelled/failedharness files are retained asattempt evidence; their presence alone does not prove they executed. No screenshots were retained. OS cursor, window placement, focus andStudio panel/device settings were not manipulated.

The final truncated console history contained asset access/approval warnings and expected mocked-Badge failures, plus documented input/helper guard errors. It was not a clean or complete run-scoped log; no zero-error claim is made. See [focused console review](CONSOLE_REVIEW.md). The offline analyzer in`harness/Analyze.py` reproduces timing/encounter checks from exported data without connecting toStudio or startingPlay.
