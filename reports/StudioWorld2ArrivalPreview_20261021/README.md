# Developer Studio preview of first World2 arrival — 2026-10-21

The user clarified that the affected display was CurrentCloud.rbxl's Studio Play, that all unowned World2 cards showed black silhouettes plus ???, and that the account had already visited World2. That appearance is the existing permanent-unlock presentation, not evidence of a missing lock renderer. The user requested a developer setting to start each Play with the arrival check cleared.

## Implementation

- `ServerScriptService.Config.DataStoreConfig`: added `ResetWorld2ArrivalOnStudioPlay=true`. Set it to false to resume normal saved-arrival behavior in Studio. Existing production and `_Studio` store names are unchanged. The file already existed in the place; its Source mirror is now tracked.
- `ServerScriptService.Services.PlayerDataService`: when both RunService:IsStudio() and that setting are true, effective World2 access starts false in each new player session. A private, unsaved `World2VisitedThisPlay` session field becomes true only through the existing successful-arrival setter.
- Load mirroring, save-completion mirroring and HasReachedWorld2 all use that same effective session value. Existing badge/history migration is skipped only in this preview mode. A persisted true flag or autosave therefore cannot immediately remove the preview locks.
- The normal validated World2 gate transfer calls MarkWorld2Reached and unlocks the open Inventory for the rest of that Play, including return/death/respawn. The next Play creates a new session and starts locked again.
- Saved World2Visited remains in the existing record and is never forced false. No owner history or inventory is cleared. Owned Item/dumbbell cards keep their normal color/equipment exception. In published servers IsStudio() is false, so the original permanent arrival, legacy migration and purchase behavior remain effective even if this setting is true.

No Inventory Source, UI object, lock asset, position, layout or size was changed. Existing UI uses the replicated effective World2Visited attribute; existing ItemService/DumbbellService use HasReachedWorld2. They therefore share the preview state without bypassing server purchase restrictions. Lock asset remains `rbxassetid://93565525595769`.

## Writeback and limits

Only the two existing Source rows above were written to `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. The current baseline matched the preceding Lobby repair. Both changed Sources compiled; the same file was read back and both Sources matched the mirrors. All other Sources, instance properties, parent links and UniqueIds were preserved, including the Lobby repair and Pets/Egg changes. See `Writeback.json` for hashes.

No Studio/client launch, Play, mock test, screenshot, DataStore access/reset or badge call was performed. Runtime/visual confirmation remains with the user. No Save/Publish, extra rbxl/backup/copy or user-Studio operation was performed. File handles were released. Open the exact CurrentCloud.rbxl above for the next user test; a previously running Play would retain its previous session until stopped.
