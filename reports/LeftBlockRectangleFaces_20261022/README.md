# World1 left BlockRectangle face separation ? 2026-10-22

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`.

The current saved place was used directly. AGENTS.md and the previous right-side repair record/implementation from commit `8f44947` were read first. The saved file had no `BlockRectanglex` marker. The user explicitly directed proceeding without waiting for that rename. Every existing name is preserved; no guessed rename was introduced.

Each Stage contains several identically named rectangle models. Matching used the full left-side Cliff01/BorderPattern hierarchy, paired direct Bottom/Upper block Parts, their relative tier height/dimensions, and measured coincident vertical end faces. Only one rectangle per Stage has the reported conflict. Its Bottom/Upper overlap is 0.375 studs high and 17 studs across at the same end plane. The adjacent larger rectangle does not have that coincident face and was excluded.

For each independently measured Stage, recessed only the competing Bottom end by 0.02 studs along its own local face normal. Reduced that local size component by 0.02 and moved the center inward by 0.01, keeping the opposite end fixed to serialized float precision. All ten measured local normals happen to point toward world +Z; the code derives them from each actual part rotation rather than applying a blanket world-space displacement. Stage01 has a different longitudinal length and retains it.

Upper geometry, green overhangs, heights, transverse dimensions, rotations, model pivots, colors, materials, Texture objects and tiling settings remain unchanged. The existing 0.375-stud vertical seam overlap is retained, avoiding an open gap. No cover, transparency change, whole-model movement or rebuilt wall was used.

## Per-Stage edits

Position and size are serialized XYZ studs. Each Full Path names the changed Bottom; instance references disambiguate duplicate model names. The corresponding Upper is listed in Writeback.json and is unchanged.

| Stage | Full Path | Part ref | Position before ? after | Size before ? after |
|---|---|---:|---|---|
| 1 | `Workspace.GeneratedMap.BattleCorridor.Stage01.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 82608 | (243.037491, 20.000000, 120.800003) ? (243.037491, 20.000000, 120.790001) | (13.600000, 26.000000, 17.000000) ? (13.580000, 26.000000, 17.000000) |
| 2 | `Workspace.GeneratedMap.BattleCorridor.Stage02.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 78926 | (243.037491, 20.000000, 238.699997) ? (243.037491, 20.000000, 238.690002) | (11.100006, 26.000000, 17.000000) ? (11.080006, 26.000000, 17.000000) |
| 3 | `Workspace.GeneratedMap.BattleCorridor.Stage03.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 70013 | (243.037491, 20.000000, 358.019989) ? (243.037491, 20.000000, 358.009979) | (11.099998, 26.000000, 17.000000) ? (11.079998, 26.000000, 17.000000) |
| 4 | `Workspace.GeneratedMap.BattleCorridor.Stage04.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 70775 | (243.037491, 20.000000, 480.220001) ? (243.037491, 20.000000, 480.209991) | (11.099987, 26.000000, 17.000000) ? (11.079987, 26.000000, 17.000000) |
| 5 | `Workspace.GeneratedMap.BattleCorridor.Stage05.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 79680 | (243.037491, 20.000000, 606.169983) ? (243.037491, 20.000000, 606.159973) | (11.100005, 26.000000, 17.000000) ? (11.080005, 26.000000, 17.000000) |
| 6 | `Workspace.GeneratedMap.BattleCorridor.Stage06.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 77898 | (243.037491, 20.000000, 735.870056) ? (243.037491, 20.000000, 735.860046) | (11.099932, 26.000000, 17.000000) ? (11.079931, 26.000000, 17.000000) |
| 7 | `Workspace.GeneratedMap.BattleCorridor.Stage07.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 75877 | (243.037491, 20.000000, 946.869995) ? (243.037491, 20.000000, 946.859985) | (11.100054, 26.000000, 17.000000) ? (11.080053, 26.000000, 17.000000) |
| 8 | `Workspace.GeneratedMap.BattleCorridor.Stage08.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 74356 | (243.037491, 20.000000, 1181.869995) ? (243.037491, 20.000000, 1181.859985) | (11.100054, 26.000000, 17.000000) ? (11.080053, 26.000000, 17.000000) |
| 9 | `Workspace.GeneratedMap.BattleCorridor.Stage09.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 81362 | (243.037491, 20.000000, 1362.869995) ? (243.037491, 20.000000, 1362.859985) | (11.099932, 26.000000, 17.000000) ? (11.079931, 26.000000, 17.000000) |
| 10 | `Workspace.GeneratedMap.BattleCorridor.Stage10.Boundaries.Environment_LeftSide.Cliff01.BorderPattern.BlockRectangle.Bottom` | 72011 | (243.037491, 20.000000, 1507.869995) ? (243.037491, 20.000000, 1507.859985) | (11.099932, 26.000000, 17.000000) ? (11.079931, 26.000000, 17.000000) |

## Saved result and verification

Changed 10 Bottom Parts across World1 Stages01?10. The saved file was reread byte-for-byte and the intended property rows were decoded and compared. Every other property row/chunk, hierarchy, identifier, name and Source was verified unchanged, including the previous right-side fix, World2, transparent boundaries, destructible walls, facilities and manual edits. Input/output hashes and exact unrounded dimensions are in Writeback.json.

No Studio was launched, stopped or closed; no Play, screenshot, Save or Publish was performed. No additional rbxl, backup, copy or migration was created. File handles were closed. Geometry separation and persistence are verified; actual appearance and behavior remain unverified and will be checked by the user.
