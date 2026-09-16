# Treadmill frame color refinement — 2026-09-16

Baseline: origin/main `60db0444ec8c435b12e40813c3935752bc5389ec`

## Result

The existing bright belt colors remain unchanged. `TreadmillConfig.StrengthColors` now provides independent `BeltColor` and `FrameColor` fields keyed by the real training `Multiplier`.

| Strength reward | BeltColor | FrameColor | Models |
|---|---|---|---|
| +3 | RGB(55,145,255) | RGB(20,65,150) | Tredmill04, Tredmill05 |
| +5 | RGB(70,200,110) | RGB(20,100,55) | Tredmill02, Tredmill03 |

`Belt` consumes `BeltColor`. `ConsoleAccent` and both `FrameAccent` parts consume `FrameColor`. Gray/metal structural parts retain their authored colors. Tredmill01 (Premium ×20) and Tredmill06 (Normal) are outside the keyed colors and remain unchanged.

## Scope

Studio fingerprint comparison found only these two intended source changes among 396 LuaSourceContainers:

- `ReplicatedStorage.Config.TreadmillConfig`
- `ServerScriptService.Services.TrainingManager`

Training reward calculation, Multiplier values, TrainingInterval, eligibility, Rebirth requirements, collision, World balance and DataStore were not changed.

## Play verification

- Final Play observed the exact belt/frame pairs on all four +3/+5 machines.
- Existing labels remained `×3 Strength`, `×5 Strength`, and Premium `×20 Strength`.
- A temporary +3 `FrameColor=RGB(90,20,150)` check changed only Console/Frame accents; Belt stayed RGB(55,145,255). The final value was restored to RGB(20,65,150).
- Selected parts retained Material, CanCollide, CanTouch and CanQuery.
- Runtime Error: 0; Warning: 0; Infinite Yield: 0.
