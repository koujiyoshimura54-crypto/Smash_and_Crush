# Trophy normal / Double Win choices - 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`.
Baseline: `c63a393`. Current disk Sources matched the related baseline. No connected or running Studio was found. No Studio was started, closed, saved, or published.

## Saved equipment

Added 20 Double Win buttons and persisted the 20 previously runtime-generated normal buttons, one pair per World1/World2 Stage01-Stage10. The current yellow TrophyRewardTemplate Handle (8 x 0.3 x 5) is reused. Entry-to-Boss direction is +Z: normal is -X (right), Double is +X (left), mirrored about each actual Stage .5 floor center. Normal positions retain the existing floor-relative formula. Stage10 uses its actual floor center and dimensions. Button acceptance uses each saved Handle footprint with the existing shallow vertical allowance; the two footprints are separate. No wall, transparent wall, corridor, Boss, or existing object property was changed.

Full Paths (StageNN ranges from Stage01 through Stage10):
- `Workspace.GeneratedMap.BattleCorridor.StageNN.TrophyNormalButton`
- `Workspace.GeneratedMap.BattleCorridor.StageNN.TrophyDoubleButton`
- `Workspace.World2Map.BattleCorridor.StageNN.TrophyNormalButton`
- `Workspace.World2Map.BattleCorridor.StageNN.TrophyDoubleButton`

Each has a saved Handle and TrophyRewardBillboard. Billboard styling follows the existing normal Trophy presentation (yellow panel, trophy icon, FredokaOne, stroke, size and offset). The left caption is `?2 Wins`, with Roblox AutoLocalize enabled, matching the existing automatic localization route. Equipment is not generated on each run. The client suppresses the old cloned Trophy visual for static-button messages.

## Source changes

- `ServerScriptService.Services.TrophyRewardService`
- `ServerScriptService.Services.GamePassService`
- `StarterPlayer.StarterPlayerScripts.Combat.CombatClient`

## Purchase and credit

Uses the existing Game Pass ID 1970515086 from WorldPassConfig and the existing server PromptGamePassPurchaseFinished handler, ownership cache, UserOwnsGamePassAsync checks and ownership recovery. Config, prices, receipt handler and save schema are unchanged. Both Worlds use that same requested Double Win entitlement for this button route. Other Shop and generic reward routes retain their existing scope.

The normal button omits Double Win regardless of ownership. The left button applies Double exactly once. The separate existing Triple Win entitlement remains an independent World1 correction: without Triple, normal/left are base/2*base; with Triple and its existing effect gate enabled, normal/left are 3*base/6*base. World2 retains its prior base correction of 1. Double ownership is not inferred from a failed network request or a client success claim.

Only a Trophy-originated prompt carries the server callback. Its closure binds the exact player, World, Stage, receipt object and Character. Purchase success is associated by the existing server prompt lock and delivered immediately when Double ownership is confirmed, before the unrelated Triple query or any saving/streaming. A Shop purchase alone cannot create a Trophy callback. Unknown ownership retains verified cache entries. Cancellation and prompt failure leave the receipt available. Entry latching prevents repeated prompts while standing on the pad, and shared per-player purchase locks prevent duplicate prompts.

Both buttons consume one receipt. A right-side claim during purchase invalidates the later callback through the Collected guard. Character removal, death, World changes, progress resets and leaving invalidate the original receipt; late callbacks cannot apply to a new run. Different players have independent records and locks. Successful return clears receipt state for the next legitimate run.

The c63a393 SetWin -> Collected -> owner notification -> bank/stream/return order is preserved, including credited-receipt retry, Banked retention and exception cleanup. Initial reward acceptance has no added fixed wait. Existing ownership recovery waits apply only when verification is unavailable; existing return retry backoff applies only after credit. Network time is not claimed eliminated.

## Validation and limits

Compiled only the three changed Luau Sources. Wrote the same rbxl and reread it, confirming exact Source bytes, all 40 saved button positions/sizes and the left caption. Existing rows, hierarchy, unrelated Sources and identifiers were preserved. Input/output hashes and placements are in Writeback.json. No additional rbxl, Backup, or Copy was created. File handles are closed.

No Play, multiple clients, real payment, screenshot or visual inspection was performed. Runtime behavior, payment and appearance remain for the user's verification. Existing unrelated working-tree changes and untracked files were left intact and excluded from the commit.
