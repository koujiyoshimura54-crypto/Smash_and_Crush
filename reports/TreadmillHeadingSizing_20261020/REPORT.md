# Treadmill heading sizing — 2026-10-20

Supersedes 8384ce6. Native Edit confirmed that setting TextWrapped=false also turns TextScaled=false. The previous updater therefore left the authored14px font fixed: Japanese text bounds135x21 despite a579x155 text area. This was the direct regression cause.

Keep TextWrapped and TextScaled enabled together. Measure the actual localized ContentText with its existing Font, and extend only the treadmill title width to accommodate one line. Use the normal Egg/Dumbbell heading height7.5 studs, icon width6.8, gap1.2 and existing outline margin. Measured row widths are40.7976 studs in English and55.8672 in Japanese. Keep the existing offset(0,4,0), artwork/fonts/colors/stroke and shoe URI rbxassetid://106106287008236 with Fit/aspect preservation. ContentText/font changes invalidate each heading once; no camera polling or new frame loop. Saved English properties match the runtime calculation. No separate shadow label exists; the original stroke remains.

Changed Source: `StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient`.
Changed object scope: `Workspace.Treadmills.Billboard.BillboardGui` and `Workspace.World2Map.TrainingArea.TreadmillDisplays.Billboard.BillboardGui`, including their Name, Icon and UIListLayout properties only. Equipment geometry, machine captions, other facility UI, gameplay and data are unchanged.

## Native display verification

Used a newly opened verification Studio in Edit; no Play or data operation. Actual device preview uses1366x765 logical pixels; camera navigation used Studio's actual viewport controls. English/Japanese strings were selected temporarily with AutoLocalize disabled for a controlled font/layout comparison. This verifies those rendered strings; published localization delivery was not exercised.

| Heading | Near distance / text height | Far distance / text height |
|---|---|---|
| World1 treadmill, English and Japanese |28.66 studs /100px|82.66 studs /44.55px|
| World2 treadmill, English and Japanese |27.17 studs /100px|79.66 studs /45.44px|
| Normal Dumbbells reference, English and Japanese |31.86 studs /100px|86.61 studs /41.88px|

The far-distance size differences correspond to the small distance differences. All eight treadmill views fit one line, without clipping, and both shoe images report IsLoaded=true. Single-line rendered aspect ratios match unwrapped TextService bounds. Full measurements are in Measurements.json. Source compilation, same-file re-decode, references, SharedStrings, parents and UniqueIds pass FileValidation.json.

Images: [W1 Japanese near](W1_ja_near.jpg), [far](W1_ja_far.jpg), [English near](W1_en_near.jpg), [far](W1_en_far.jpg); [W2 Japanese near](W2_ja_near.jpg), [far](W2_ja_far.jpg), [English near](W2_en_near.jpg), [far](W2_en_far.jpg). [Previous regression](W1_ja_near_before.jpg), [normal Japanese near](Reference_Dumbbells_ja_near.jpg), [far](Reference_Dumbbells_ja_far.jpg), [normal English near](Reference_Dumbbells_en_near.jpg), [far](Reference_Dumbbells_en_far.jpg).

Temporary text, camera, selection, other ScreenGui visibility and active font watchers were restored/removed. The verification Studio remains in Edit with the final treadmill properties and Source applied in memory. No Studio Save/Publish, user-app closure, extra place or backup. Public-client gameplay/localization and other devices are untested.
