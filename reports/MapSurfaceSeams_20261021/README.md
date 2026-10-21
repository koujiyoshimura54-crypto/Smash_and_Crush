# Map coplanar surface seams — 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Edited the current file in place; no historical map generator or place copy was used. The baseline matched the completed Studio arrival-preview writeback.

## Changes

World1: **3 Parts / 3 seams**.

- Two `Workspace.GeneratedMap.TrainingArea.EntranceCarpets.Path.Upper` Parts (west and east branches) overlapped the central `EntranceCarpets.Upper` top face. Their touching ends were trimmed to the central pad's edge, retaining the other endpoints, Y, thickness and carpet colors. The hierarchy contains two same-named Path branches; exact instance refs and before/after transforms in `Writeback.json` disambiguate them.
- `Workspace.Ramp.Stand.Part`: trimmed a small adjoining-block overlap at a visible side seam. The removed slab is covered by the neighboring stand block, preserving the outer geometry.

World2: **19 Parts / 19 seams**.

- `Workspace.World2Map.TrainingArea.PathToRun.WestBranch.Upper` and `.EastBranch.Upper`: the equivalent two central-pad carpet seams.
- `Workspace.World2Map.TrainingArea.DumbbellDisplays.Ramp.Stand.Part`: the equivalent stand-block seam.
- Four Parts in each of `Workspace.World2Map.TrainingArea.TreadmillDisplays.01`, `.02`, `.03` and `.04`, all named `Smooth Block Model`: neighboring rectangular frame-strip top faces overlapped slightly. Each affected strip was shortened only at its touching edge. These are actual block Parts, not MeshPart bounding boxes or Parts containing SpecialMesh geometry. Exact instance refs distinguish repeated names.

Every approved trim removes a slab whose other two dimensions are covered by the adjoining Part. This preserves the occupied volume/outer silhouette to the stored face precision, without opening a floor gap, raising floors or globally offsetting geometry. Existing carpet upper faces differ by only about 0.000096 stud; their shared footprint is now disjoint. Names, hierarchy, tags, attributes, references, textures/materials and all collision settings were left unchanged. No duplicate Part was removed and no covering plate was added.

## Identification and limits

Identification used the actual planes of opaque, axis-aligned block Part faces with positive overlapping surface area, rather than mere intersecting bounding boxes. Changes were limited to small, shape-preserving seam trims with a geometric line of sight from representative ground-level positions. This is mathematical edit-time evidence, **not a screen/render confirmation**. Opaque blocks were checked as occluders; uncertain Mesh/Union/custom-mesh bounds were conservatively treated as potential occlusion rather than as real competing surfaces.

The map search included both Lobbies, normal corridor and Stage01-10 fixed geometry. No sufficiently proved, small, shape-preserving repair was selected in the Stage sections. Large or ambiguous wall-pattern intersections were left unchanged. Examples requiring actual surface/normal-view evidence before any further edit:

- `Workspace.GeneratedMap.BattleCorridor.Stage04.Boundaries.BossArea_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` and adjoining BlockSquare pieces: large overlaps cannot be shortened with the approved small seam rule without additional appearance evidence.
- `Workspace.World2Map.BattleCorridor.Stage01.LevelWall.LeftWall.BorderPattern.BlockSquare.*` against `Workspace.World2Map.TrainingArea.Borders.ExitLeft.BlockSquare.*`: corner intersections have unequal footprints; a simple whole-Part trim could alter the shape. High wall-cap tops were excluded from the ground-view repair.
- MeshPart, UnionOperation, rotated/custom-mesh decoration: their bounding boxes do not establish actual overlapping rendered faces, so they were not changed.

Carpet lower-layer overlaps hidden beneath the upper carpet were excluded. Deferred counts in `Writeback.json` describe candidate rejection, including hidden/intended intersections; they are not counts of confirmed remaining Z-fighting defects.

The changed Parts are authored static frame/carpet pieces. TreadmillVisualService regenerates separately named effect/template models, not these frame strips. No destructible wall, Boss template, dynamic wall definition, gameplay Source, transparent barrier, spawn/transfer, purchase/save path or UI was changed.

## Completion

Only approved Part CFrame/size rows were written. The same file was read back; all other existing properties, Sources, parents and UniqueIds matched the input. Reference bounds and canonical re-decode passed as file-edit integrity checks. Exact Full Paths, instance refs, counterpart Parts, overlap amounts and before/after positions/sizes are in `Writeback.json`.

No Studio was opened, so no task-owned Studio process or Studio file lock was created. File handles were closed. No extra rbxl, Backup or Copy, Studio Save or Publish was made. Unrelated changes and untracked files were preserved.

**Post-edit appearance and gameplay verification will be performed by the user.** No Play, client launch, screen tour, new screenshot, image comparison or mock/regression test was performed. Z-fighting resolution has not been visually confirmed by the agent.
