# World2 Inventory lock investigation — 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. This is a read-only investigation of the reported live-screen regression. No missing lock implementation or confirmed code defect was identified in this saved file. The actual cause of the reported screen remains unresolved; no runtime display restoration is claimed.

## Separate evidence sources

1. **Previously exercised implementation:** `ee26fa7` and `reports/World2ArrivalLocks_20261021/`. Its retained ItemsLocked.jpg and DumbbellsLocked.jpg were inspected. That report describes ordinary real Inventory tabs in native Play, using memory-only save/badge adapters. It is historical evidence, not a current Play result.
2. **GitHub and local Sources:** GitHub `refs/heads/main` was read using `git ls-remote`, returning `658cb92f98201191e446bf4ee04fe6121963f18f`. The nine relevant Source files have no changes between ee26fa7 and that commit. Current local mirrors match them.
3. **Current saved rbxl:** SHA-256 `d46942552d9d5419611db79f750f8c881ee27dd2a57f90dda70ebc0e5e3db7b4`, matching the preceding Lobby repair writeback. All nine embedded Sources match ee26fa7 and current local Sources after line-ending normalization. Relevant ItemMaster, DumbbellItemMaster and BadgeConfig also match. The GUI is enabled, relevant LocalScripts/server controllers are enabled, and required Inventory/donor/template objects exist. No duplicate relevant Source paths were found. The relevant World2 flag readers/writers and UI layout logic remain in the expected locations; no saved memory-only fixture or competing lock painter was found.
4. **User's running Studio / Cloud:** no RobloxStudioBeta process or connected Studio was available during this investigation. The Place/file and runtime attributes of the reported screen therefore could not be observed. Cloud Source, current published version and whether it contains these changes are **unverified**. A GitHub push or local rbxl write is not evidence of Cloud publication. No Studio was launched and no Cloud operation was performed.

## Relevant Full Paths already present

- `ServerScriptService.Services.PlayerDataService`
- `ServerScriptService.Services.DumbbellService`
- `ServerScriptService.Services.ItemService`
- `ServerScriptService.Systems.Controllers.StageProgressController`
- `ReplicatedStorage.Modules.InventoryPresentation`
- `ReplicatedStorage.Modules.ResponsivePanels`
- `StarterGui.StrengthGui.InventoryPanelClient`
- `StarterGui.StrengthGui.ItemInventoryTabClient`
- `StarterGui.StrengthGui.EssentialStudShopClient`

The supplied image remains `rbxassetid://93565525595769`. The existing presentation generates WorldLockIcon only for locked runtime cards: transparent background, white tint, Fit, centered at (0.5,0.5), size (0.45,0.42). It reuses the dark secret paint and black alpha silhouette, hides the ??? label and informational controls, and is supported by the existing responsive layout. Its absence as a saved Edit-time card child is not evidence of loss: the cards and lock are created by the existing client renderer.

Both Inventory tabs retain their World2/unowned/unvisited predicate, locked click guard, selection-detail guard and World2Visited-change rerender connection. Item and dumbbell purchase services retain their central WorldNotReached rejection before debit/grant. PlayerData retains normalization, load-to-attribute mirroring, permanent true-preserving save merge and the arrival setter; normal server travel calls that setter only after successful placement.

## State-dependent alternatives remain unconfirmed

By design, `World2Visited=true` removes locks from all unowned World2 cards and shows the existing ??? presentation. Owning a specific product displays that card in normal color even without arrival. Existing arrival migration can use server CurrentWorld=2 or the IntoWorld2 badge, not ownership alone. The user's runtime World2Visited, actual saved arrival/badge history and product ownership were not read. A legitimate unlocked state is therefore possible but is **not established as the cause**. No production DataStore read/write, reset command, flag reset or inventory mutation was performed.

An optional user question was sent asking whether the reported screen came from this file's Studio Play, the published game, or another Place/file. No answer was available when this record was prepared. The reported appearance (plain-color versus ??? versus another UI) also remains unobserved.

## Result and correct comparison target

No game Source, UI object, image, arrival state or saved rbxl byte was changed. Rewriting an already matching implementation would not establish a fix, so no rbxl writeback or syntax check of changed Sources was needed. Only this investigation record and its Source-comparison JSON were committed; this commit is **not a gameplay fix**. Existing Lobby walls, Pets/Egg changes and all unrelated local/untracked work were preserved.

The user should open exactly `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` to check this implementation. In that file's actual Inventory, distinguish a never-arrived unowned World2 card (lock) from an arrived unowned card (???) and an owned card (normal color). The runtime player's World2Visited value can distinguish expected unlock from a display failure without changing production history. If checking the published game, first establish which Place/version is being used; only the user's manual Save/Publish can make the chosen local content the published source. No claim is made that publication is currently missing or that publishing alone will resolve the report.

No current Play, new screenshot, mock UI, production-save test or display verification was performed. The user's existing Studio state was not modified or closed; all file handles were released. No additional rbxl, backup or copy was created.
