# World1 progression rebalance — 2026-09-16

## Scope

Updated the live Roblox Studio configuration for the approved Lv1–50 progression curve and World1 Stage6–10 late-stage balance. World1 Stage1–5, World2, gain rates, combat rules, UI, DataStore, and monetization were not changed.

## Runtime sources

- `ReplicatedStorage.Config.LevelRequirements` — Lv1–50 requirements; Lv51–200 and Lv201+ values retained.
- `ReplicatedStorage.Config.World1LateStageConfig` — Stage6–10 RequiredStrength, wall multipliers, and Boss HP consumed by `BossCombatService` and `Stage1WallManager.GetStageConfig`.
- `ReplicatedStorage.Modules.NumberFormat` — existing formatter retained.

## Verification

- Cumulative totals: Lv8 460, Lv10 865, Lv15 2,700, Lv20 7,025, Lv25 17,025, Lv30 37,025, Lv35 81,525, Lv40 196,525, Lv45 462,525, Lv50 1,017,525.
- Level boundary values: Lv29→30 5,000; Lv30→31 6,000; Lv39→40 33,000; Lv40→41 40,000; Lv44→45 69,000; Lv45→46 80,000; Lv49→50 150,000; Lv50→51 200,000; Lv51 remains 319,000.
- Studio Play was started and stopped successfully; console output contained no Error or Warning.
- `execute_luau` direct module evaluation was unavailable because the inspection tool lacks the required Roblox module capabilities; this did not modify the project.
