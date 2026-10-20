# Egg and Merge initialization recovery — 2026-10-20

The final user scope is **Egg and Item Merge only**. Boss individualization,
StageSkip and spawn changes were explicitly withdrawn. Runtime verification was
delegated to the user to shorten delivery. None of those withdrawn changes were
written. No map, balance, image, ownership or saved-data changes were made.

## Evidence and repairs

The current binary place was the Source baseline, not an older Git export.
The existing Studio log `0.743.0.7431133_20261020T015923Z_Studio_E8D3B_last.log`
records a DataStore acquisition error in `PlayerDataService` line 19 at
01:59:39.806 UTC. This was an **unpublished local session** (PlaceId 0 at the
failure); the log later records the user's target PlaceId 126576845524886.
It is not evidence that this same error occurs in the published experience.
The failure propagates through `ItemService` to `ItemMergeController`, and through
`PlayerDataController` before its Egg startup. The same log records indefinite
client waits for `ItemMergeState` and `PetRequest` at 01:59:48.

- `ServerScriptService.Services.PlayerDataService`: defer acquisition of the
  real configured and explicitly authorized production DataStore handles until
  an existing protected read/write operation. Requiring the module no longer
  fails merely because the file is unpublished. Store names, keys, ownership
  fencing, atomic transactions, load rejection, save exclusions and reset
  authorization remain unchanged. An unavailable DataStore still fails loading;
  no fabricated data, substitute store, permission bypass or offline purchase
  path was added. Successful real DataStore loading remains required to transact.
- `ServerScriptService.Services.EggServer`: fix inner `Info`/`InfoShadow` loop
  variable shadowing the Egg ID. Register the validated PetRequest handler before
  world-label initialization; mark startup complete afterwards. Existing World
  and distance checks, 1/3/8 counts, prices, odds, IDs and transaction deduplication
  remain unchanged. The label defect alone did not explain failed purchases.
- `StarterPlayer.StarterPlayerScripts.Services.PetClient`: report hatch
  presentation exceptions with a traceback while still releasing the request
  lock after a server-confirmed purchase. The accepted state and request identity
  remain intact; no second debit or reroll is issued to recover a visual error.
- `StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New`: publish
  MergeShopMounted only after state, result and proximity listeners have been
  installed. Keep the purchased UI, existing Item recipes, material consumption,
  server result authority and save transaction. Pet Merge remains disabled.

## Validation and delivery

All four affected Sources compile with the local Luau compiler. The same target
`C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` was written in place, re-read and
re-decoded using the repaired referent tooling. All non-Source property chunks,
Instance rows, parent links, SharedStrings and UniqueIds are unchanged. There
are 182,118 Instances, no out-of-range references and no duplicate UniqueIds.
See [FileValidation.json](FileValidation.json) for hashes and validation details.

No Play, two-client session, purchase, reset, data grant, Studio reopen, Studio
Save or Publish was performed. Therefore **successful Egg hatching, Merge
transactions and published loading remain unverified**. An unpublished local
file still cannot transact without accessible real player data; this repair does
not remove that restriction. Gameplay Paused and general startup time remain
unresolved and were not measured in this reduced scope.

User verification: in the intended published/Studio environment with valid data,
approach the World1 Egg and perform 1/3/8 hatches; verify Win debits, results,
inventory and equip. Approach Merge, submit owned Item materials and verify both
consumption and result. No preexisting unrelated working-tree changes are part
of this commit. Previous Lobby/UI/arrow changes are preserved.
