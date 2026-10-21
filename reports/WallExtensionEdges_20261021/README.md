# Move existing transparent walls to boundary edges — 2026-10-21

Edited only the 75 Parts introduced by `6e44ae8` in the existing `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`:

- `Workspace.GeneratedMap.WallTopExtensions`: 54 existing Parts.
- `Workspace.World2Map.WallTopExtensions`: 21 existing Parts.

Perimeter panels now place their Map-facing contact surface at the outside edge of the recorded existing wall-cap envelope, with only 0.05 stud of inward overlap. Their original thickness projects outward instead of occupying the standing surface. Left/right edges use the corresponding negative/positive X side; rear/end edges use the appropriate negative/positive Z side.

Stage-opening panels move toward the next Stage, which is +Z in both current corridors. Their near face is placed at the downstream edge of the existing boundary strip with the same 0.05-stud overlap. The World2 Lobby upper-opening panel is aligned with the adjoining exit-wall contact plane. Panel endpoints, corner connections and connecting lengths are adjusted to meet the relocated perimeter. The three existing World2 junction Parts are retained at their corresponding outer corners. No instance was added, removed or reparented.

Only CFrame positions and necessary horizontal span lengths changed. Rotation, panel thickness, Y center, Y size, Y=160 tops, opening-bottom heights and all visibility/collision/query settings remain as before. Existing visible walls, floors, decoration, equipment, destructible walls, Sources and gameplay are untouched. Children can use the existing wall tops up to the boundary contact surface; gameplay confirmation remains the user's task.

The input file exactly matched the previous writeback hash. The writer changed only the Part CFrame and size chunks; every other chunk remained byte-identical, including Sources, parents and UniqueIds. The same file was written in place, then read back to confirm the written bytes. All file handles were closed. Full per-Part paths and before/after positions/sizes are recorded in `Writeback.json`.

No Studio launch, Play, client launch, screenshot, visual review or additional test was performed. The user will perform runtime and visual verification. No additional rbxl, backup or copy was created. No Studio Save/Publish or user-Studio operation was performed. Existing unrelated working changes and untracked files were preserved.
