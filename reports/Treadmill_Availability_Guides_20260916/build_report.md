# Treadmill availability guides — 2026-09-16

## Audit and scope

- GitHub main / local HEAD started at `c1b905f03dfd640ac69173b3d306430e1764c2e0`; origin fetched, working tree clean. AGENTS and current GAME / BALANCE / UI / DEV_STATUS reviewed. Studio PlaceId: 101572058398926.
- Viewed the supplied `Treadmill_guide.png` reference; no reference image asset was imported. Inspected all ten authored machines, belt orientation, existing TutorialGuideClient Chevron geometry and current TrainingManager / GamePassService.
- Before: no availability guide. Both multiplier billboards were hidden by any IsTraining=true. Current Studio MaxDistance was 75, while main and the explicit request specify 100; this change sets 100. Original Studio snapshots are under before/.
- Canonical permission remains TrainingManager.CanUseTreadmill, unchanged. Existing server Zone scan refreshes per-player availability attributes only when the result changes. Accepted sessions mirror the model name into TrainingTreadmill; stopping clears it. These attributes neither grant permission nor persist to DataStore.

## Implementation

- New TreadmillGuideClient creates one local nonphysical guide surface per authored belt. Belt identification reuses the existing visual role or the audited 8 x 0.98 x 18 dimensions. Surface follows the belt dimensions and orientation, 0.04stud above the top; GUI-down follows belt LookVector, matching the authored travel direction.
- Twin rotated Frame arms reuse the existing tutorial Chevron construction. A clipped fixed strip is animated with a linear repeating Tween: no per-frame creation/destruction or Lua distance loop. Unavailable guides have SurfaceGui.Enabled=false and paused Tween; available guides flow even while unoccupied.
- TreadmillConfig.Guide: Enabled=true, Speed=4stud/s, Transparency=0.15, Size=Vector2(4,1.6), Spacing=4stud, Thickness=0.25stud. Normal RGB(235,245,255), Blue (205,240,255), Green (215,255,225), Premium (255,220,185). Studio Config edits apply on next Play initialization.
- All guides belong to the local PlayerGui/local Workspace. Guide surfaces are anchored with CanCollide/CanTouch/CanQuery=false. Existing belt/frame/mat objects are untouched. Streaming changes create/remove the affected guide only.
- Billboard visibility uses the accepted model's actual Config.Multiplier: 3 hides only x3, 5 hides only x5, other/no session enables both subject to MaxDistance=100. Existing size 24 x 15stud, height offset12, text styling, colors and midpoint placement remain unchanged.

## Play verification

| Case | Result |
|---|---|
| Normal, not riding | All five normal guides visible and moving |
| Rebirth2 | Both +3 and both +5 guides hidden |
| Rebirth3 / 4 | Both +3 guides moving; both +5 hidden |
| Rebirth5 | Both +3 and both +5 guides moving |
| Normal accepted session | Both billboards enabled |
| Blue accepted session | x3 disabled, x5 enabled |
| Green accepted session | x3 enabled, x5 disabled |
| Exit | Both enabled, subject to distance |
| Premium denied / effects disabled | Guide completely hidden |
| Premium owned + effects enabled fixture | Guide moving; accepted Premium session leaves both billboards enabled |
| Distance >100 | Both large billboards absent in visual capture |
| Final regular Play | Normal guides moving, locked tiers hidden; ten local guide GUIs; no QA object |

Evidence: [play_evidence.json](verification/play_evidence.json), [temporary server probe](verification/server_probe.luau), [client inspection](verification/client_probe.luau). Screenshots were inspected in the Studio tool: chevrons sit on blue/green belts, and original Strength / Rebirth signs remain visible. Two time-separated samples confirm movement on every available belt, including Premium fixture.

Premium PassId remains0 and Studio effects remain disabled in the real configuration. Premium allowed/denied tests temporarily stubbed GamePassService ownership/effects responses in the isolated Play server; no production bypass was added. The Premium session was held in the existing zone with a temporarily anchored QA character for a stable client visibility sample. This is not a real Marketplace purchase test.

QA used a separate Studio DataStore name suffix. The temporary probe was removed and DataStoreConfig restored byte-for-byte before final ordinary Play. Server had no local guide surfaces or billboard anchors. Multiple simultaneous clients were not available; per-player ownership was verified structurally and with one client's replicated states, not claimed as a multi-client Play test.

Isolated QA emitted one `Player ranking mirror save failed` warning from the existing ranking persistence path; no guide error or Infinite Yield was observed. Final ordinary Play console was empty (Error / Warning / Infinite Yield: none observed). This task does not fix ranking persistence.

## Regression and delivery

Whole-Studio source fingerprints show exactly four new/changed sources: TreadmillConfig, TrainingManager, TreadmillMultiplierBillboardClient, TreadmillGuideClient. No source deleted. Existing mat properties match the before snapshot. CanUseTreadmill and the reward loop are unchanged except the display-only accepted-session notification adjacent to startup. Strength formula, Rebirth requirements, Premium predicate, interval, colors, existing signs, collision and DataStore schema are unchanged. No new live multiplier/reward test is claimed beyond actual session acceptance; unchanged reward code is the regression evidence.

Updated GAME_SPEC, UI_SPEC, DEV_STATUS and CHANGELOG. The sources/ files are the current Studio implementation snapshots, not an automatic sync directory. Historical reports remain intact. Commit message: `Add availability guides to Treadmills`. No Publish was performed.
