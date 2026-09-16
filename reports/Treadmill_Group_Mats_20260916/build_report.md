# Treadmill colors and group mats — 2026-09-16

Baseline: fetched origin/main and HEAD both 93982fc958f8373c3eebc3d008089f6efb94e068.
Studio PlaceId: 101572058398926.

## Implementation

- TreadmillConfig.StrengthColors uses the existing actual Multiplier as its key. BeltColor / FrameColor remain unchanged; MatColor is added.
- +3: Belt RGB(55,145,255), Frame RGB(20,65,150), Mat RGB(8,25,65).
- +5: Belt RGB(70,200,110), Frame RGB(20,100,55), Mat RGB(8,40,22).
- Each target has one Belt, one ConsoleAccent and eight Frame Parts. All side rails, uprights, top beams and console surrounds now receive FrameColor. Invisible TrainingZone and UI surfaces are excluded.
- TrainingManager derives the mat group from the existing treadmill assignments. The two authored TrainingSpace mats provide the local lateral bounds; one new TreadmillGroupMat_3 or TreadmillGroupMat_5 Part spans each pair.
- Each visible group mat is 28 x 0.2 x 24 studs in local coordinates. Front/back length, height and thickness remain as authored.
- The four original mats remain hidden in place at runtime, retaining their collision/touch/query properties. This is one visible Part per group, not two adjacent visible mats. New group mats have CanCollide / CanTouch / CanQuery false and no training responsibility.
- Edit-time Map objects are unchanged. Runtime-generated mats are recreated on the next Play. Premium and Normal machines are excluded by their absence from StrengthColors.

## Verification

- Play screenshots confirmed bright belts, darker complete frames and darkest shared mats for both pairs.
- All four target machines: same colors within each tier, one belt, one console accent, eight frame Parts.
- Two group mats observed with exact sizes and colors. Original four mats invisible; their collision flags retained.
- Part Size and CanCollide on all four machines matched the audit. Premium Tredmill01's 13 Part colors, Size and CanCollide matched the audit; Premium source and authored mat untouched. Flame effects were not edited.
- In a separate Studio test store, the actual Training loop committed 7.5 for multiplier 3 at Rebirth 3 and 17.5 for multiplier 5 at Rebirth 5. These match the prior implementation, including existing Rebirth multipliers 2.5 and 3.5. The machine's +3/+5 designation is its multiplier, not a promise that all equipped/rebirthed players receive exactly 3/5 per tick.
- RequiredRebirth stays 3/5. Training reward/interval/access code is byte-for-byte unchanged; only appearance helpers and initialization are modified.
- Temporary QA script removed; original DataStoreConfig restored exactly.
- Source fingerprint comparison: 388 sources before/after excluding plugin GUI copies; only TreadmillConfig and TrainingManager changed. Authored mat snapshots match.
- Isolated Play console empty. Final normal Play: Error 0, Infinite Yield 0; one warning from existing ranking mirror save. Ranking/DataStore implementation was not changed. Warning text is recorded without the player's name.
- Config values are read during TrainingManager initialization; restart Play after editing colors in Studio.

See play_evidence.json for measured values and scope checks. Sources are snapshots for this change, consistent with the repository's current Studio workflow; this repository does not automatically sync Studio.
