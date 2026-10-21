# Marked World1 stage wall faces - 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`.

The current saved file contains the user's marker at `Workspace.GeneratedMap.BattleCorridor.Stage01.Boundaries.Environment_RightSide.Cliff01.BorderPattern.BlockSquareX`. Its SHA differs from the prior work as expected from the explicitly reported manual edits. This current file, including the rename and manually shortened neighboring Upper strip, was used directly. No old place, map generator or previous batch fixer was applied. No Studio process or connected Studio was found during inspection.

## Cause and edit

In each World1 Stage01-10, the corresponding `Boundaries.Environment_RightSide.Cliff01.BorderPattern` has three overlapping Bottom block Parts at the same positive-Z vertical end plane. That plane also coincides with the green Upper end faces. The actual axis-aligned block faces overlap in X/Y; this is not an inference from MeshPart bounds. The marked middle tier is at Y=14, with adjacent bottom tiers at Y=1 and Y=22.5. Their relative X offsets are 4 and 7 studs. The repeated parent hierarchy, geometry and relative positions identify the counterparts despite duplicate Model names.

For each Stage, recessed only those three competing positive-Z Bottom faces by 0.02, 0.04 and 0.06 studs respectively, keeping their opposite ends fixed. Each center moves by half that amount and only the corresponding local size component is reduced. This provides separation for deliberately overlapping stepped blocks without deleting their overlapping structure. Upper Parts, green overhangs, heights, X dimensions, rotation, materials, colors, Texture objects and all other properties remain unchanged. There is no blanket wall scaling, replacement cover or added floor gap. The opposite-Z overlap is behind the adjacent wall geometry and was not changed.

All ten Stages received 3 Part edits, 30 total. Each Stage's measured positions and dimensions were used independently; Stage01 dimensions were not copied. No Stage was deferred. World2 and all other map structures were untouched.

`Writeback.json` lists each changed Full Path, serialized instance reference (to distinguish duplicate names), before/after position and size, and competing Part references. Stage01 has 11 positive-Z competing face pairs; each other Stage has 9.

## Completion and limits

Wrote directly to the same rbxl and reread byte-for-byte. Decoded output properties match the intended edits; all other property rows/chunks, hierarchy, identifiers, Sources and user edits are preserved. No additional rbxl, backup or copy was created. File handles were closed. No Studio was opened or closed, and no Studio Save/Publish occurred.

No Play, screenshots, post-change visual inspection or runtime tests were performed. Final appearance and gameplay verification belong to the user; geometric separation is not a claim of visually verified flicker removal.
