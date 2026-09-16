# Configurable World1 Wall UI Layout — 2026-09-16

## Audit and implementation

- Baseline Git revision: `f65f8a1ea5276d919c40ce6d6b987ea81aaf5a02`, equal to fetched `origin/main` before implementation.
- The existing `StageWallDisplayClient` owned the common normal-Wall layout. It used fixed world-space dimensions but kept the Stage-to-gauge gap as a local constant of 1 stud.
- Added `ReplicatedStorage.Config.WallDisplayConfig` with `WallUI.Scale = 0.8` and `WallUI.StageGap = 0.4`.
- `Scale` multiplies the normal Wall HP gauge width/height, StageNumber and Heading width/height, Heading gap, and all descendant UIStroke thicknesses. The HP label and fill remain children of the scaled gauge and follow its size.
- `StageGap` is applied as the world-space distance between the StageNumber lower edge and the HP gauge upper edge.
- HP gauge lower edge remains 4.32 studs above the Wall bottom. All presentation sizes and gaps are fixed stud values; Wall height is used only to convert them to SurfaceGui coordinates.
- One shared client path applies the layout to World1 Stage1–10 Wall .1–.4. No per-Stage table was added.
- `CombatClient`, `BossDisplayConfig`, and `BossDisplaySurface` were not edited.

## Play verification

- All 40 Wall surfaces reported a 56.25-stud Wall, CanvasY 562.5, gauge height 4.104 studs, StageNumber height 5.4 studs, StageGap 0.4 studs, and 0.8-scaled strokes. Stage1 .1–.4, Stage6 .1, and Stage10 .1 retained readable NumberFormat output.
- Config restart check: changing only StageGap from 0.4 to 1.4 changed the measured gap to 1.4 while gauge, Stage, widths, and strokes stayed unchanged.
- Config restart check: changing only Scale from 0.8 to 1.0 restored gauge height 5.13, Stage height 6.75, widths 0.76/0.8, and stroke 3 while StageGap stayed 0.4.
- Runtime HP update: Stage1 .1 changed from `100 / 100` to `75 / 100` with fill 0.75.
- Existing Carry snapshot: the remaining 75 HP on .1 received 100 damage; .1 cleared and .2 immediately displayed the real `100 / 125` with fill 0.8.
- Stage6 displayed `74.6K / 74.6K`; Stage10 displayed `2M / 2M` through the same path.
- Temporary Wall-height check changed one client copy from 56.25 to 80 studs. Gauge height stayed 4.104, Stage height stayed 5.4, and gap stayed 0.4; the Wall was restored to 56.25 in the same probe.
- Boss fixture remained on the independent BossDisplaySurface: Transparency 0.5, SurfaceOffset 0.5, collision/touch/query disabled, and `250 / 250`.
- The QA Script was removed. A final normal Play confirmed Scale 0.8 / StageGap 0.4 results with no Runtime Error, Warning, or Infinite Yield.

## Scope

- Added one ModuleScript: `ReplicatedStorage.Config.WallDisplayConfig`.
- Modified one LocalScript: `StarterPlayer.StarterPlayerScripts.Combat.StageWallDisplayClient`.
- Lua source inventory changed from 394 to 395; no source was removed.
- Wall height, HP, Combat, Carry, Stage progression, Boss UI, BossDisplayConfig, Map, Balance, and DataStore were not changed.

