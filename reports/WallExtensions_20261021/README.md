# Saved vertical wall extensions — 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, based on the exact `c553583` file hash. Added only fixed transparent Parts. No game Source, visible building, decoration, floor, equipment, spawn, destructible wall, progression condition, player size, jump or speed was changed. Previous UI and gameplay work is preserved.

## Placement

- `Workspace.GeneratedMap.WallTopExtensions`: 54 Parts covering the World1 Lobby perimeter, the existing stepped corridor sides, the Stage10 end wall and nine upper Stage-opening spans.
- `Workspace.World2Map.WallTopExtensions`: 21 Parts covering the World2 Lobby perimeter, corridor sides and end, nine upper Stage-opening spans, the Lobby exit upper span and three corner connections over existing wall caps.
- All panels are vertical. Their common top is world Y=160; there is no roof or horizontal map cover. Exact centers, sizes, bottom/top heights and source-wall references are in `Placement.json`; measured structural caps and current floors are in `MeasuredWallRegions.json`.
- Straight World2 perimeter sections are combined, including the continuous Stage01-10 left/right walls. World1's changing corridor width retains the existing individual straight sections. Small decorative pieces are not individually extended.
- The bottom of each main span overlaps the lowest structural cap by 0.5 stud. Higher stepped caps remain inside the same span. Longitudinal seams overlap by 0.1 stud. The three corner connections use the corresponding existing BlockSquare cap footprints and 0.5-stud vertical overlap.
- Opening spans start at Y=35.875 in World1 and Y=33.875 in World2. Both leave 31.875 studs above their respective Y=4 and Y=2 floors. The World1 48.4-stud walking corridor and World2 90-stud floor widths remain unchanged. Permanent parts are outside the destructible-wall models and their reset/damage ownership.
- Current collidable wall/decor tops measured at Y=76.15 in World1 and Y=82.38 in World2. The existing maximum height scale is 3.55; the test rig's measured body was approximately 9.12 by 14.56 by 4.10 studs. JumpHeight remains 7.2. The Y=160 top provides substantial clearance above those existing launch surfaces plus body height and jump reach.

All added Parts use Anchored=true, Transparency=1, CanCollide=true, CanTouch=false, CastShadow=false and CollisionGroup=Default. The running PlayerCharacters group was confirmed collidable with Default. CanQuery is deliberately true: collision-aware placement/StageSkip queries must see a real obstacle. No claim is made that CanQuery alone prevents camera or ray interference. Existing StageSkip support rays include only WalkableGeometry; its body overlap includes collidable obstacles. Tutorial floor rays use their existing floor whitelist and their blocker cache considers physical boxes regardless of query flags. The new spans remain above those floor routes. Existing wall/Boss attacks use their existing explicit encounter targets; no attack code was modified.

## Completed observations and limits

The user explicitly stopped further verification. No additional physical test was run after that instruction. An already queued additional movement test was rejected by automatic approval review for conflicting with the stop instruction and was not retried.

Before that instruction, actual Play used a memory-only DataStore/badge adapter. A maximum-size character moving from temporary starting positions above the original walls was physically stopped by representative World1/World2 outer and upper-opening panels. These are real collision observations with fixture positioning, not a claim that every natural climbing route was exercised. Maximum-size ground movement crossed the representative Stage1-to-Stage2 opening in both Worlds; the World1 final Z was about 211.90, beyond the new span at 204.15, and World2 reached about 2161.56, beyond the span at 2154.63. Accepted observations are retained in `PlayObservations.json`; premature/incorrectly sized fixture attempts are not counted as passes.

Unverified: normal-size climb/jump coverage, natural climb routes, representative destruction/progression, successful StageSkip transfer, Gate/return passage, camera occlusion and attack behavior. The test runtime reported StageNotReady for StageSkip, so it is not counted as a pass; no unrelated initialization fix was attempted. No production persistence, real payment or live-server test was performed.

Blue and fully transparent overview images were retained as requested: `World1_Blue.jpg`, `World2_Blue.jpg`, `World1_Transparent.jpg`, `World2_Transparent.jpg`. These are placement records from the verification Studio, not evidence that all gameplay checks passed.

Play was stopped. All memory-only Source replacements were restored, the test adapter and temporary Edit panels were removed, temporary UI/camera settings were restored, and only the owned Studio was closed without saving. The user's Studio was left open. No Studio Save/Publish or old map generator was run; no alternate rbxl, backup, copy or migration file was created.

The guarded writer adds the two folders and 75 Parts directly to the same rbxl. It re-decodes the written bytes and validates saved positions, dimensions, transparency/collision properties, dense references and UniqueIds while comparing every existing property/parent and preserving every existing Source. `FileValidation.json` records the result. A further native Studio reopen was omitted after the user's stop instruction. The writer is a no-op on a matching already-applied file and refuses unexpected or partial local state, preventing duplicate panels.

Final written SHA-256: `885da7ec604d93e56af033221827166880b30e06488c115d729a4cc2e8782f9a`. The target lock file is absent. The external rbxl is not Git-tracked; this commit contains the exact placement manifest, guarded writer and English records.

## 2026-10-21 follow-up — move panels to outside edges

The same 75 Parts were subsequently repositioned to preserve playable wall-top space. Perimeter contact faces now meet the outside edges; Stage-opening planes move toward the next Stage (+Z). Only positions and connecting horizontal lengths changed; heights, thicknesses and all flags remain unchanged. See [edge relocation record](../WallExtensionEdges_20261021/README.md) and its exact before/after manifest. The images and Play observations above describe the earlier placement, not this follow-up. No Studio or Play verification was performed for the follow-up; the user will verify it.

## 2026-10-21 follow-up — Lobby floor-to-top perimeter repair

Lobby perimeter panels were repaired using the current floor and individual structural wall faces. Their lower limits are now Y=-6 in World1 and Y=-2 in World2, with Y=160 tops. Missing straight/void-edge segments were added while retaining the entrance upper panels and all BattleCorridor/Stage panels. See [Lobby repair record](../LobbyPerimeterRepair_20261021/README.md). This follow-up was written to the user-approved current file; runtime/visual verification remains with the user.
