# World2 paid facilities — 2026-10-21

## Status and current-file authority

Premium Treadmill and Premium Aura are implemented and validated. Limited Egg 02 remains disabled pending the user's explicit quantity/button confirmation. This is a partial delivery, not completion of all three products.

Started from the actual `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, SHA256 `cc7aa254b4654ea0faf0e514e72aa842677522f58d6b14c71185abf182a6f0cb`, including `ae7c5d0`, `2ee20a4`, `c63a393`, and the player's individual Boss structure. No older place or generated map was imported. Only nine existing Source values are written; every other Source, property, parent, model, wall and Trophy button is preserved by the writer's binary comparison.

Target Experience: UniverseId **10765181857**, PlaceId **126576845524886**. Validation used an unpublished local copy in Studio memory (PlaceId 0), without creating another rbxl, Save, or Publish.

## Products and benefits

| Product | Kind / ID | Base Robux | Read-only Marketplace result | Connection / benefit |
| --- | --- | ---: | ---: | --- |
| World 2 Premium Treadmill | Game Pass `2044250678` | 399 | 360 | Existing old tier 04, one machine at `Workspace.World2Map.TrainingArea.TreadmillDisplays.07`; existing Training multiplier **35** |
| World 2 Premium Aura | Game Pass `2045204630` | 299 | 270 | `W2_AURA_06` in the existing Aura Inventory; **+1500 Strength only while equipped** |
| Limited Egg 02 | Developer Product `3720640383` | 279 | 252 | Existing `W2_Limited` at `Workspace.World2Map.TrainingArea.FacilityDisplays.LimitedEggDisplay.PetMesh`; **not connected yet** |

Marketplace returned the requested names/types, positive sale prices and base prices. The developer product also returned the specified UniverseId. The displayed prices above include the account's current Roblox Plus discount; they are observations, not fixed configured sale prices. The two implemented client displays use the existing `ReplicatedStorage.Modules.MarketplacePrice.Get` path. Missing/invalid World2 prices display `...`; Aura purchase is disabled until a positive price is available. Treadmill may still open Roblox's own priced prompt. A lookup failure never becomes a free offer.

## Implemented behavior

- Treadmill entitlements are cached per player and pass ID. World1 retains `1982996954` and its existing x20 tier; World2 uses its separate x35 tier. Existing occupancy, gain, departure and character checks remain authoritative. A per-player prompt lock and the existing per-entry latch prevent duplicate prompts and re-prompting while continuously standing after cancellation. A stale occupancy check cannot open a prompt after departure. Server purchase completion triggers ownership verification immediately; the existing heartbeat starts training after confirmation. Retry waits occur only after unsuccessful verification, with no added success delay.
- Aura ownership verification now addresses the configured Aura ID rather than hardcoding Red. World1 Red retains `1975173075`, +500 and its prior completion/save behavior. World2 purchase success updates verified ownership and Inventory without waiting for a data save or auto-equipping. Selection remains the existing explicit Inventory equip operation. Existing equipped colors, visual template, cross-world effect rules and saved equipment remain in use.
- Ownership API errors neither grant unknown rights nor erase rights already verified in the session. Saved Aura flags alone do not authorize a Game Pass effect. The server's existing purchase callback is extended, not replaced; client completion never grants rights.
- No World2 Egg count is inferred from 279 Robux. Current `World2GameplayConfig.PaidOffers.LimitedEgg` has no product/count mapping, and Open 1/3/8 are all disabled. `reports/World2Gameplay_20261020.md` and the later Pet candidate record contain no confirmed World2 paid quantity. World1's `LimitedEggConfig.Count=1` refers only to Product `3717610547`. The user was asked which quantity/button the new ID represents; no response had arrived when this partial delivery was recorded. No Egg grant, odds, effect, model, PolicyService check or ProcessReceipt was changed.

## Changed Full Paths

1. `ReplicatedStorage.Config.World2GameplayConfig`
2. `ReplicatedStorage.Config.TreadmillConfig`
3. `ReplicatedStorage.Config.AuraConfig`
4. `ServerScriptService.Services.GamePassService`
5. `ServerScriptService.Services.TrainingManager`
6. `ServerScriptService.Services.AuraService`
7. `ServerScriptService.Systems.Controllers.AuraController`
8. `StarterGui.StrengthGui.AuraInventoryClient`
9. `StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient`

The existing AuraController had no repository mirror; its current actual Source was extracted before the scoped modifications and is now tracked. No production test adapter was added. World1 Win x2/x3, Trophy award/return logic, all Boss Sources, normal prices and balance tables are untouched.

## Validation and its limits

Actual local server with **two real Studio clients**, using temporary in-memory DataStores and simulated Marketplace ownership/completion events. No Robux purchase was attempted and no production player record was loaded or modified. Existing Studio `GamePassEffectsEnabled=false` was temporarily enabled for these checks and restored before writeback. Production creator-effect preferences were preserved.

| Check | Result / evidence |
| --- | --- |
| Both clients enter World2 premium treadmill unowned | Both denied; exactly one tier-04 prompt request each; neither trained |
| Repeat request while open / cancel while remaining in zone | Repeat returned `Pending`; cancellation awarded no access or Strength and did not re-prompt while standing |
| Buyer succeeds while still on the machine | Verified buyer began training without rejoining; first existing tick awarded **35**; other player remained unowned at 0 |
| Leave training zone | `IsTraining=false`; no continued treadmill session |
| Ownership API outage | Unknown player: `false, OwnershipUnavailable`; previously verified player retained `true`; no false prompt/grant |
| Prompt throws, then retry | `PromptUnavailable` released the lock; subsequent explicit entry/request could prompt |
| Aura real Inventory button clicks | Correct pass ID requested; cancellation returned to BUY; simulated server-confirmed success immediately changed to Equip |
| Aura owned vs equipped | Ownership alone bonus **0**; actual Inventory equip click selected `W2_AURA_06`, changed equipped style, attached existing visual and bonus **1500** |
| Existing Strength arithmetic | Baseline one-tick x35: **35**; equipped World2 Aura: `(1+1500)*35 = 52535`; World1 Red/x20: `(1+500)*20 = 10020` |
| Other player and World1 isolation | World2 Aura purchase did not affect Player2. World1 treadmill ownership did not authorize Player1's World2 treadmill. World1 Red remained independently selectable at +500 |
| Display | Real client labels showed **270** for Aura, **360 Robux** for unowned treadmill, and **Owned** for its owner. Screenshot inspected; identified and fixed inherited Win currency icon on the World2 paid Aura card using the existing Red card's Robux icon |
| Persistence / rejoin simulation | Real PlayerData Save/Release/Load against the isolated store preserved selection. A fresh service cache denied saved Aura flags until mocked ownership confirmation, then restored selected +1500; fresh treadmill cache recognized mocked pass ownership |
| Source / saved-place validation | All nine changed Sources compiled; writer rereads exact Source bytes and proves every non-target value unchanged; details in `Writeback.json` |

The rejoin check is a **simulation of data reload and fresh server caches**, not an actual paid account leaving/rejoining production. Purchase success/cancellation/errors were **simulated Marketplace events**, not real payment confirmations. Runtime mechanics, UI clicks, two-player separation and client state were exercised in real Play. Existing unauthorized sound/image asset messages and Roblox CoreGui warnings appeared; no changed-production-script error or infinite yield was observed. One temporary assistant-only probe used the wrong module cache and failed; it was replaced by a runtime-script probe before reporting the successful fresh-cache result.

Limited Egg quantity, Receipt recovery/deduplication, purchase UI, and its repeated grants remain **unimplemented/unverified** pending the requested count. Full unrelated Boss/Stage/Trophy regressions were deliberately not repeated.

## Cleanup and delivery

Play stopped. Temporary fixture Script, adapter ModuleScript, RemoteEvent and altered test ownership/data settings were removed from Edit state. Runtime-only probes disappeared with Play. The same original rbxl is patched directly and reread, without an additional rbxl/backup/copy/migration, Studio Save or Publish. Validation Studio is closed without saving after disk verification; no user Studio was open at the start. Existing unrelated documentation edits, BossChaseService local tuning and untracked files are excluded from the commit.
