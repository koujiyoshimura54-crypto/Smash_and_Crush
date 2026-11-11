# AutoTap OFF on join — 2026-11-12

Implemented in current canonical Studio, Place126576845524886 / Universe10765181857. Two production Sources changed. Existing unsaved edits, Back fix dd3531e, offline Claim and return Item UI fixes are retained. The prior PR #1 candidate remains in Studio; its unrelated changes are excluded from this main commit.

## Cause and minimal change

- `ServerScriptService.Services.PlayerDataService`: normalization restored saved AutoTap ON, and IsAutoTapEnabled treated unloaded/missing sessions as enabled. Load now publishes OFF before the yielding ownership acquisition, then sets the loaded AutoTap Boolean to false before exposing Loaded. IsAutoTapEnabled requires a loaded session with explicit true.
- `StarterPlayer.StarterPlayerScripts.UI.AutoTapClient`: a missing attribute was displayed as ON (`~= false`). The existing renderer now displays ON only for `== true`, retaining its existing OFF colors and all geometry/fonts.

The loaded-session early return remains before join initialization: repeated Load, death/respawn and World travel do not reset the toggle. Saved field/schema, normalization/defaults used by other operations, reset behavior and normal Toggle/Save remain unchanged. AutoTapConfig is unchanged; it only owns timing. Manual-while-ON input, grounded walking, action deadlines, combat/treadmill routing and button callback remain unchanged.

## Actual native Play

Two independent native three-client launches used the final production code. Synthetic profiles: new/absent data; saved OFF with Strength11; saved ON with Strength23. Each initial PlayerData acquisition was delayed4s in the memory adapter. First launch passed35 assertions; second launch passed9 join assertions. These are assertion counts, not44 independent Play sessions.

- All three clients were OFF before any test input; server loading samples never enabled AutoTap. RenderStepped observations saw no initial ON text. Starting Strength stayed0/11/23.
- Each client physically walked approximately15 studs with OFF and gained0. Toggle ON synchronized authority/attribute/button text and gold gradient; stationary manual input with ON gained exactly1.
- Stationary ON gained0. Actual walking with ON gained1/2/2 in the sampled movement windows. OFF switched the button back to its existing gray-purple gradient.
- ON survived actual Humanoid death and normal respawn, then W1→W2 through the normal gate travel Remote. OFF survived another death/respawn and W2→W1. Gate positioning and unlock were isolated fixture preparation; travel used normal validation/placement.
- A repeated Data.Load within the existing session preserved ON.
- Native memory Save confirmed ON, followed by Release/Load: runtime and UI became OFF while Strength stayed unchanged.
- After the first tests, the third client toggled ON again and its native Script saved the actual record with Strength26. That exact isolated record seeded a new independent native server/clients launch. It joined OFF, retained26 Strength, and showed no initial ON or automatic gain. The fresh and saved-OFF controls also passed again.
- One actual viewport image was inspected: Lobby HUD, Strength3 and the existing Auto Tap OFF button. It was temporary and is not committed.

Inputs used the existing game Remotes and Humanoid movement, not OS input or human mouse/touch. Death was triggered by the fixture setting test Humanoid health to zero; ordinary respawn then ran. This is actual native Play with isolated persistence, not a published-server account rejoin. [First launch](native-play.json), [independent rejoin launch](native-rejoin.json).

Server and all three client logs were inspected in both launches. No new related runtime error or Infinite Yield appeared. Existing asset permission/missing-asset warnings and the deliberately stubbed World2 badge failure remain outside this change. An initial record-export probe in the MCP evaluator's separate module context returned not loaded and was excluded; the successful export ran in a native Script using the actual live service session.

## Limits, preservation and delivery

Production DataStore rejoin, real payment, physical mouse/touch and every combat/treadmill scenario were not rerun. Action timing, AutoTapService, TrainingController, EnemyManager and treadmill Sources were unchanged; this task tests only the join permission and its necessary lifecycle regressions.

All39 external-service substitutions were restored with exact Source guards, all QA fixtures removed, and all493 shipping Source hashes matched the post-fix baseline. The Back/Claim/notification and protected collision Sources are unchanged. Canonical Studio is stopped/focused Edit, with prior edits and this fix retained unsaved. [Cleanup audit](cleanup.json).

Only the two AutoTap Source patches, focused fixtures and documentation are included in the normal main commit. The live PlayerDataService additionally retains PR #1's pre-existing zero-gain progression line; that unrelated line is intentionally not copied into main. No Save/Publish, rbxl writeback, OS input, foreground operation, player-capacity change or canonical Studio close was performed. Public reflection requires the user's manual Save/Publish.
