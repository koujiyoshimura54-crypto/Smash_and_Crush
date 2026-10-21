# Repair Lobby perimeter barriers — 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. The current file hash differed from the preceding writeback; all 75 earlier panels still matched their recorded positions and dimensions. The user explicitly authorized keeping the current file and proceeding. No previous place file was restored.

## Read findings

- World1 Lobby floor: X=156..393, Z=-64..85, Y=-4..4. Existing Lobby panels began at Y=35.875 or 36.875.
- World2 Lobby floor: X=-103.880..133.120, Z=1850.980..2019.980, Y=0..2. Existing Lobby panels began at Y=20.875 or 33.875.
- Earlier broad panels followed combined wall-cap envelopes. They did not follow each actual floor/structural-wall edge. For example, World2's east floor edge was X=133.120 while its east barrier's contact face was X=161.025. This is a geometric separation, not a claim that every point in that interval lacks an existing structural wall. The lower-height omissions and the coarse envelopes were both addressed; the reported gameplay symptom was not diagnosed by a Play test.
- Existing panels were anchored, fully transparent, collidable and in Default. The current SlapController assigns PlayerCharacters to players and disables only PlayerCharacters-to-PlayerCharacters collisions; it does not disable collisions with Default. The barrier group remains Default; no global collision configuration was changed.

## Applied change

Only Lobby perimeter panels under `Workspace.GeneratedMap.WallTopExtensions` and `Workspace.World2Map.WallTopExtensions` changed. The perimeter is traced from the actual Lobby floor rectangle and individual collidable structural BlockRectangle/BlockSquare Bottom/Upper Part faces. All those structural faces are axis aligned in the current file. Trees, ornament bounds and whole-decoration bounding boxes are not used. Both outside edges and void-edge loops between the floor and structural walls receive vertical barriers, so a coarse outside rectangle does not leave the intervening floor-edge gaps open.

- World1: 63 perimeter Parts, reusing 3 existing panels and adding 60 missing segments. Bottom Y=-6 (2 studs below the floor underside); top Y=160.
- World2: 108 perimeter Parts, reusing 6 existing panels and adding 102 missing segments. Bottom Y=-2 (2 studs below the floor underside); top Y=160.
- Collinear adjoining edges are merged. Parts are 1 stud thick, with their thickness projected outward and only 0.05 stud of inward contact with the existing surface. Ends overlap by 0.1 stud. This follows individual structural faces and keeps their top footprints usable instead of filling them with broad transparent slabs.
- The normal entrance bands remain open below the existing upper panels: World1 X=263.6..312 from Z=85 onward; World2 X=-17.08..72.92 from Z=2019.980 onward. The existing World1 Lobby front upper panel and World2 Lobby-to-Stage01 upper-opening panel are unchanged. Their original opening heights remain intact.
- All new/reused perimeter panels use Anchored=true, Transparency=1, CanCollide=true, CanTouch=false, CanQuery=true, CastShadow=false and Default collision group.

No BattleCorridor outer panel or Stage-opening panel was changed. Existing visible architecture, floors, equipment, Gate/return/spawn objects, destructible walls, Sources, progression and numerical settings were preserved. No ceiling, floor, platform, detector or forced-return behavior was added.

## Writeback and scope

The same rbxl was written in place and its written bytes read back. Existing rows were compared so only the approved Lobby Part properties changed; all other existing properties, Sources, parents and UniqueIds were preserved. Added Parts have new UniqueIds and valid references. `Writeback.json` contains exact paths, before/after dimensions, edge coordinates, hashes and file-edit integrity results. All file handles were released.

No Studio/client launch, Play, screenshot, visual confirmation, mock test or regression test was performed. **Runtime and visual verification will be performed by the user.** No additional rbxl, backup, copy, Save or Publish was made. The user's Studio and unrelated local changes/untracked files were left untouched.

The stored Workspace CollisionGroupData contains Default with mask 0xffffffff. The current CollisionServer also changes only same-group character collisions. No stored or runtime Source rule disables Default-to-player collision. Gate trigger centers remain inside their original Lobby floor footprints (World1: 237.600,14,76.100; World2 return: -22.280,12,2011.080); Gate and spawn objects were untouched. These are file-read facts, not Play results.
