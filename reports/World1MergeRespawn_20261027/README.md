# World1 Merge survives death — 2026-10-27

The user cancelled the proposed three progression runs during preparation. **No main benchmark run started.** This delivery is only the reproduced death/respawn Merge fix and focused verification. Earlier83-minute results are not counted as a run here.

Current Y02 Studio was the authority: Universe10765181857, Place126576845524886, loaded version292. All six Sources in Merge commit245a1e7 matched the current document. Local Git was safely fast-forwarded to7407fcb; unrelated manual edits and the pre-existing untracked report were retained.

## Cause and final change

`StarterGui.StrengthUI` is a respawned Folder, but `StrengthGui` and generated `MergeShopGui` have `ResetOnSpawn=false`. On ordinary character-reset death the original Merge LocalScript was removed. The same UI and `MergeShopMounted=true` survived, so the new respawn Script returned immediately without proximity/input handlers. The failure was reproduced with live object-identity observations, not inferred solely from the previous report. An open panel became inert, the counterpart of the previously reported closed panel never reopening.

Moved the **existing controller template**, keeping its Source behavior, from:

`StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New`

to:

`StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New`

The original LocalScript instance is retained and reparented in Edit; its old GUI branch remains. The Source differs only by an explanatory comment. PlayerScripts retains the running controller across death; there is one live controller and one Merge host. The existing singleton guard, transaction callbacks, polling, eligibility, UI assets, layout and gameplay remain unchanged. The repository path moves accordingly and must be applied as a **move**, never a second controller copy.

An initial runtime-only reparent into StrengthGui was insufficient: Roblox still removed the original StarterGui-generated instance on reset. That attempt failed and was replaced before acceptance. See `runtime-reparent-failed.json`; it is not recorded as a passed fix.

## Actual Play verification

- Temporary empty memory stores and false account pass ownership isolated real data/payments; no grants, CFrame transfers, HP edits, fixed RNG or internal purchase/merge calls were used.
- Escape/R/Enter performed a normal Roblox character-reset death. After respawn, the same final controller, StrengthGui and MergeShopGui remained. The panel hid after death and opened on ordinary Humanoid movement back into the facility. This verifies reset-death lifecycle, not a separately repeated enemy-caused death.
- Ordinary training, movement and Auto combat defeated Stage1 and naturally dropped one Stone. Walking onto the ordinary Trophy pad returned to the lobby and paid1Win. The improved movement helper stopped after that return.
- Walked back into Merge, clicked Ore, clicked the Stone card, and observed Selected1/5,5points and NORMAL_01 at100%. An actual mouse click on Merge consumed the single Stone and granted exactly one NORMAL_01. Win stayed1. The rendered completion screen was inspected. No screenshot is retained because this narrowed request did not ask to keep images.
- Final UI inspection counted exactly **one controller and one Merge host**. Native server state confirmed the material/output result and request journal; all87 final preparation events were exported.
- Source syntax compiled. Final Edit Source matched the repository. All439 guarded Sources matched their expected values; exactly35 temporary service replacements were restored and all three Edit helper nodes removed. No temporary helper remains. The approved controller relocation is retained.

Evidence: [before lifecycle](merge-before-lifecycle.json), [after lifecycle/UI](merge-after-verification.json), [transaction result](merge-result.json), [cleanup](cleanup.json). `harness/` and preparation snapshots are the temporary, unseeded reproduction/measurement adapters; they are not production Scripts or benchmark results. The `SCOPE.md` preparation note predates the final successful merge.

Not performed: three complete runs (cancelled), broad gameplay regression, World2 travel regression, public-server test, production persistence or real payment. No numeric balance changes.

## End state

Studio remains open in **Edit**, with the controller relocation **unsaved**. Camera CFrame/Focus/FOV/type and ShowDevelopmentGui match their recorded pre-test values. Editor layout/device preview were not changed. No Studio Save/Publish, rbxl writeback, new rbxl/backup/copy, or user-Studio closure was performed. **The user must manually Save/Publish.**
