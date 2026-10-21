# World2 arrival locks — 2026-10-21

Implemented against the current `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, preserving commit `41c9e66` and all existing local edits. This was an additive change to nine Source rows. No place copy, backup, migration place, Studio Save, or Publish was used.

## Behavior and unlock authority

- Unowned World2 Item and dumbbell cards remain in their existing lists. Before arrival they use the existing dark secret paint and transparent black silhouette, with only the supplied white padlock over the image. Names, effects, prices, stars, purchase buttons and `???` are hidden. Card selection and purchase callbacks stop before sending a request.
- After arrival, unowned cards return to the existing `???` presentation with effects, stars, prices and eligible purchase buttons. Legendary direct purchase remains unavailable. Owned cards stay in color and remain equipable regardless of arrival history.
- `PlayerData.World2Visited` is a boolean in the existing PlayerData store and key. It is mirrored as the player attribute of the same name. Server purchase checks read the loaded session data, not the client attribute.
- `StageProgressController` marks arrival only after the existing validated gate route successfully calls `LobbySpawnService.MoveToLobby` and sets the server CurrentWorld to 2. Gate eligibility (`HighestUnlockedWorld`), Stage10 completion, client claims and arbitrary coordinates do not mark arrival.
- Legacy proof uses the existing server CurrentWorld=2 state or the existing IntoWorld2 badge (3295862437341420), which the normal travel controller awards after successful arrival. Inventory ownership alone never unlocks other products. There is no existing durable per-World2 stage field to reuse in this PlayerData schema.
- Missing flags default to false. Badge lookup failures fail closed and retry; an unavailable proof service cannot clear an established flag. Save merges preserve true in both stored and live data, including a concurrent arrival. Marking arrival schedules the existing save path with retries; normal autosave remains available.
- Central ItemService and DumbbellService checks reject unarrived World2 purchases before debit or grant. Inventory, Shop and equipment controllers share these services. World2 Robux Item purchasing was already excluded by the existing product definitions/validator. Paid receipt, drop and Merge grant paths were not repurposed as purchases.

## Changed Full Paths

- `ServerScriptService.Services.PlayerDataService`
- `ServerScriptService.Services.DumbbellService`
- `ServerScriptService.Services.ItemService`
- `ServerScriptService.Systems.Controllers.StageProgressController`
- `ReplicatedStorage.Modules.InventoryPresentation`
- `ReplicatedStorage.Modules.ResponsivePanels`
- `StarterGui.StrengthGui.InventoryPanelClient`
- `StarterGui.StrengthGui.ItemInventoryTabClient`
- `StarterGui.StrengthGui.EssentialStudShopClient`

No Master, price, effect, product ID, model, facility or map property changed. Existing World1 transparent IDs and 2D displays, World2 equipment, Inventory secrets, fonts and equipped colors were preserved. The lossless editor checked 4,724,966 properties and all parents, changing only the nine intended Source rows.

## Supplied lock asset

- Original: `Downloads/透明背景の白い南京錠アイコン.png`.
- Registered through the available Roblox Studio image upload tool.
- Used ID: `rbxassetid://93565525595769`.
- Original SHA-256: `31c8c109c61577412e4cc64df5acc2157f035eb4d0c07fa4cd88505f5675a260`.
- RGBA 1254 × 1254, alpha range 0–255. The UI uses a transparent background and Fit scaling.
- Native preload succeeded both before Play and after reopening the written file.

## Focused native Play verification

All DataStore and badge service calls were redirected to temporary in-memory adapters in the verification Studio only. Production saves and badge awards were not made. Real Inventory tabs were opened using ordinary mouse input; these were not mock cards.

| Check | Result |
| --- | --- |
| Gate eligible, never arrived | HighestUnlockedWorld=2, World2Visited=false; World2 remained locked |
| Legacy owned products without arrival | Item and dumbbell kept color and equipped successfully; other products stayed locked |
| Locked clicks and direct requests | Card clicks sent no purchase request; direct Item/dumbbell requests returned WorldNotReached; Win stayed 1,000,000 |
| First normal gate transfer | Test character positioned at real trigger; existing normal remote, server validation and MoveToLobby completed; open Inventory immediately unlocked |
| Purchase and equip | Normal buttons purchased W2_NORMAL_02 for 6,000 and W2_PROTEIN_COMMON_ICE for 5,000; final Win 989,000; both colored and equipped |
| Legendary | All nine World2 Legendary cards had secrets/stars and no purchase button |
| Return/death/respawn | Unlock persisted |
| Rebirth data reset | Existing strength reset and rebirth setter preserved unlock |
| Save/read | Existing Save, Release and Load against memory store preserved true |
| Legacy inference | Missing flag + ownership only stayed false; arrival badge or server CurrentWorld=2 restored true |
| Before load | Both server purchase services returned DataNotLoaded |
| Reopen/scroll/state changes | No duplicate lock/secret labels or accumulated darkening |

Requested screenshots: [Items](ItemsLocked.jpg), [Dumbbells](DumbbellsLocked.jpg). The retained images intentionally include legacy owned products alongside still-locked unowned products.

Limits: production persistence and a real reconnect were not exercised; save/reload and legacy badge responses were simulated in memory. Rebirth was checked through its existing data operations, not the entire Rebirth UI. Unchanged World1 displays/assets and a full device matrix were not retested. Existing unrelated asset permission warnings appeared; corrected diagnostic-command errors did not originate in the nine changed production Sources.

## Writeback and cleanup

- Input SHA-256: `9222a7f50906cdd0c582862929586a96dfc99088a60f66d5675cb6ade1140bc6`.
- Written SHA-256: `0d48d36f210b9562dcf61accf62da1ce9d637ccf0ac585da5dc9fd4aa8b525ed`.
- Nine Sources compiled. Binary decode, referent bounds, canonical encoding and unchanged-property checks passed.
- Reopened the same written rbxl in native Studio: all nine Sources exactly matched the tested implementation; lock preload succeeded; no test instances remained.
- Play stopped and memory adapters/fixtures were removed. Only the two verification Studios started for this task were closed, without Save/Publish. The separate user Studio was left untouched.
- See [FileValidation.json](FileValidation.json), [NativeVerification.json](NativeVerification.json) and [FinalState.json](FinalState.json).
