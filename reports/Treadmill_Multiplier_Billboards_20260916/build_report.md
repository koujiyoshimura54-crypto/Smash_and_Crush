# Treadmill multiplier billboards — 2026-09-16

Baseline: fetched main = HEAD = 464e341033d8989e8dd2caadfacb4a928d8818e8.
PlaceId: 101572058398926.
Reference image inspected: C:/Users/kouji/Downloads/Treamill_GUI.png.

## Implementation

- TreadmillConfig.MultiplierBillboard: MaxDistance=100, StudsOffset=Vector3.new(0,12,0), Size=Vector2.new(16,10), TextScale=1.5. Final billboard canvas is 24×15 studs; TextScaled fits the glyphs.
- TreadmillMultiplierBillboardClient groups the existing Config assignments by actual Multiplier, only for tiers in StrengthColors.
- One ×3 for Tredmill04/05; one ×5 for Tredmill02/03. Anchors are the midpoint of each pair's existing TreadmillUIDisplay positions. No fixed Map coordinates in implementation.
- Current base anchors: ×3=(-52.677,14.477,-92); ×5=(-52.677,14.477,-124). World-space offset puts billboard centers at Y=26.477.
- Text uses BeltColor, outline uses MatColor; GothamBlack font and UIStroke. No Strength suffix, extra effects or poles.
- PlayerGui holds two local BillboardGuis. Local invisible anchors have no collision/touch/query. No server BillboardGui Enabled changes.
- LocalPlayer.IsTraining event disables both billboards for every treadmill tier; exit re-enables them, while Roblox MaxDistance still performs camera-distance culling.
- Roblox handles camera facing and MaxDistance without per-frame Lua distance calculations. Streamed model/display arrival/removal schedules a deferred rebuild, requiring both pair members before displaying. Character respawn refreshes the local view.
- Edit Config and restart Play to adjust size, height and range.

## Play

- Near camera at ~51.18 studs: exactly one ×3 and one ×5 rendered. Angled closer camera: text faces the camera.
- Far camera at ~124.35 studs: neither rendered, despite Enabled=true. This is native distance culling, independent of training.
- Actual Normal Tredmill06 entry: IsTraining=true and both billboards Enabled=false. Exit: IsTraining=false and both Enabled=true within range.
- Existing ×3 Strength / 3 Rebirth Required and ×5 Strength / 5 Rebirth Required labels remained unchanged on all four machines.
- Server inspection found zero multiplier billboard/anchor objects. Multi-client simultaneous testing was not performed; player isolation is additionally established by local generation and LocalPlayer-only state.
- Config-only tuning from 16×10 / offset8 to 24×15 / offset12 was reflected on restart.
- TrainingManager and existing TreadmillUIClient source fingerprints are unchanged. Authored mat snapshots match; no colors, mats, reward, requirements, interval, DataStore or Premium source was changed by this task.
- Final normal Play console: Error 0 / Warning 0 / Infinite Yield 0.

## Concurrent edits

During one restart AuraConfig had a temporary syntax error, causing existing module loads to fail and downstream Infinite Yield warnings. Its current Edit source was subsequently valid without any agent edit; the subsequent normal Play passed. TrophyRewardConfig and AuraConfig fingerprints changed during work and are outside this task; neither is included in this commit. This task adds only the billboard LocalScript and the display Config section.

See play_evidence.json and source snapshots. Existing reports remain historical snapshots; no automatic Studio synchronization is configured.
