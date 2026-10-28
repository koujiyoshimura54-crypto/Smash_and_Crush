# Scope changed — 2026-10-27

The user cancelled all three adaptive progression runs while preparation was still in progress. No main run was started and no completion-time benchmark is claimed. Remaining scope is the death/respawn Merge bug, its focused actual-input regression, cleanup, and normal Git commit/push.

Y02 started with Place126576845524886 / Universe10765181857, loaded version292 in Edit. Six Sources from Merge commit245a1e7 exactly matched the current document. Local Git safely fast-forwarded fromd1f8213 to7407fcb without touching the unrelated untracked report.35 existing storage/payment/badge dependencies were replaced temporarily with empty memory adapters; no real data or paid account privileges were used. No balance values were changed.

## Reproduced cause

The Merge controller originated under `StarterGui.StrengthUI`, a Folder that is recreated on respawn. Both `StrengthGui` and the generated `MergeShopGui` are persistent ScreenGuis (`ResetOnSpawn=false`). An ordinary Escape/R/Enter character reset destroyed the original controller while leaving the same GUI objects and `MergeShopMounted=true`. The respawn controller exited at that flag. An open panel became inert; the earlier closed-panel report follows the same loss of proximity/input execution.

An initial runtime-only reparent into StrengthGui was tested and failed: Roblox still removed that original StarterGui-generated Script on reset. That attempt is not counted as a passing fix. The final fix moves the existing controller **template** to `StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New`. It then lives with PlayerScripts across respawns, with one existing view and its handlers. The old GUI branch remains; there is no second controller template. Transaction, proximity, UI, selection and gameplay code are retained, with one explanatory comment.

After the final move, the same controller, StrengthGui and MergeShopGui survived ordinary reset, the panel hid after death and reopened on an ordinary walk back to the facility. The remaining verification is actual material consumption/output through the panel; its outcome is recorded in the final report.

All preparation data is temporary. Preparation elapsed values in these files are not a benchmark run and must not be merged with the prior83-minute attempt.
