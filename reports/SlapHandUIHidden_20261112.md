# Slap Hand purchase UI hidden — 2026-11-12

Canonical PlaceId: 126576845524886. Current unsaved Edit Source was the baseline; both target editor buffers matched Source, and the Git service mirror matched the live baseline after newline normalization. No folders were created.

## Change

- `ReplicatedStorage.Config.SlapPassConfig`: add `PurchasePromptEnabled = false`. This is the single manual setting for restoring the purchase UI.
- `ServerScriptService.Services.GamePassService`: `PromptSlapPass` returns `false, "Hidden"` before calling MarketplaceService while the flag is false.

The UI is Roblox's purchase prompt, triggered by `ServerScriptService.Systems.Controllers.SlapController` when another living player is within eight studs. No separate Slap screen/button or Slap text label was found in the canonical place. The existing proximity scan remains, but its prompt request cannot open the UI. Existing paid ownership, tool granting/use, collision rules, other purchases, analytics and game balance are unchanged. This does not remove an existing owner's Tool from the Backpack.

## Verification

Performed in Edit without changing Play state:

- Both modified Sources compiled, and both editor buffers matched Source.
- The exact modified prompt function was executed with isolated ownership and MarketplaceService stubs: 100 repeated hidden/unowned calls and one hidden/owned call produced zero purchase API calls.
- Restoring the flag in an isolated Config copy retained `AlreadyOwned` for owners and made exactly one stub purchase call for an unowned player.
- No production module was required for the test, no real purchase API was called, and no helper Instances or player data were created/modified.

Actual Play, two-player proximity behavior and displayed purchase-dialog screenshots were not exercised. The user forbids starting/stopping Play. Source-level suppression is verified; a live visual check remains unconfirmed. Save/Publish, OS input and Studio shutdown were not performed. Studio remains unsaved Edit; the user must Save and Publish when ready for the change to reach published servers. PR #1 was not merged. Existing unrelated worktree content is excluded from the commit.
