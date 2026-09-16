# Treadmill Strength Reward Colors — 2026-09-16

## Audit

- Baseline Git revision: `494d6aec23319c48c86e51d939ffab9b07e256b2`, equal to fetched `origin/main`.
- `ReplicatedStorage.Config.TreadmillConfig.Types` is the authoritative source: `Rebirth3.Multiplier=3` maps to Tredmill04–05 and `Rebirth7.Multiplier=5` maps to Tredmill02–03.
- `TrainingManager` passes that same Multiplier into the existing Strength formula. Legacy model attributes `StrengthPerTick=1` and `TickInterval=1` are not runtime inputs.
- Existing signs display `×3 Strength` / `×5 Strength` plus the Rebirth requirement.
- The authored models use unnamed Parts. Each target has a black 8×0.98×18 belt, a black SmoothPlastic 4×0.1×2.8 console accent, and two gray approximately 10×0.98×1.2 frame crossbars.

## Implementation

- Added `TreadmillConfig.StrengthColors`: Multiplier 3 = RGB(55,145,255) blue; Multiplier 5 = RGB(70,200,110) green.
- `TrainingManager.Initialize` looks up each machine's existing authoritative config and applies its mapped color to the belt, console accent, and two frame accents.
- The remaining gray frame, invisible TrainingZone, UI display surface, Premium machine, and Normal machines retain their authored appearance.
- Only `Color` and a presentation role attribute are changed. Size, CFrame, Material, Transparency, CanCollide, CanTouch, and CanQuery are not changed.
- Existing labels and all Training access/reward logic remain unchanged.

## Play verification

- Tredmill04–05 rendered blue and retained `×3 Strength`; Tredmill02–03 rendered green and retained `×5 Strength`.
- Each machine had four colored parts: Belt, ConsoleAccent, and two FrameAccent parts. Collision/touch/query values matched the baseline.
- Changing only the Multiplier 3 Config color to RGB(255,140,0) and restarting changed all three visual roles to orange while the Multiplier 5 machine stayed green. The final Config was restored to blue.
- In an isolated Studio store, Tredmill04 accepted a Rebirth 3 player and Tredmill02 accepted a Rebirth 5 player. `IsTraining=true` was observed inside the zone and the normal loop committed gains.
- The unchanged formula produced 7.5 and 17.5 at the minimum eligible Rebirth counts because the existing Rebirth multipliers 2.5 and 3.5 still apply to machine Multipliers 3 and 5. No reward, interval, eligibility, equipment, Potion, VIP, or Rebirth value was changed.
- The isolated store switch and QA Script were removed. Final normal Play had Runtime Error 0, Warning 0, Infinite Yield 0.

## Scope

- Modified `ReplicatedStorage.Config.TreadmillConfig`.
- Modified `ServerScriptService.Services.TrainingManager`.
- Lua source inventory stayed at 395; no source was added or removed.

