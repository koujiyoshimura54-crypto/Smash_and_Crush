# World1 Run Inventory Phase 5B — 2026-09-30

## Scope and implementation
Studio Place 101572058398926. Server-only provisional World1 boss loot; no HUD counter, Return button, banking, capacity purchase, schema migration or World2 inventory redesign.

Changed sources:
- ServerScriptService.Services.RunInventoryService (new ModuleScript)
- ServerScriptService.Services.EnemyDropGachaService
- ServerScriptService.World.EnemyManager (lifecycle/drop context hooks only)
- StarterPlayer.StarterPlayerScripts.UI.EnemyDropGachaClient (stale-run presentation guard and full text)

RunInventoryService owns Player-keyed tables containing RunId, WorldId=1, Capacity, Items[ItemId]=quantity, Count, Active and ProcessedDrops. GetSnapshot returns a copy. GetCapacity is the only default-capacity provider (DEFAULT_CAPACITY=5). No PlayerData, Backpack or Tool writes.

World1 defeat captures the current RunId before rolling. The existing roller and probabilities are unchanged. Atomic, non-yielding generation/deduplication/capacity validation precedes insertion. Full draws add nothing; the existing MISS presentation carries Reason=InventoryFull and displays RUN INVENTORY FULL rather than an ungranted reward. Accepted grants retain the existing acquisition badge notification. World2 still uses the unchanged durable grant function.

InitializePlayer/StartRun allocate new generations. Death and CharacterRemoving invalidate provisional items. PlayerRemoving releases the table without saving it. Stage advancement alone does not reset the run. World1 Deactivate suspends and Activate resumes the matching generation; an invalidated generation is replaced. Current-world and living-Humanoid validation gates acceptance.

Client attributes: RunInventoryCount, RunInventoryCapacity, RunInventoryId, RunInventoryWorldId, RunInventoryActive. These are server publications, never authority read back from a client for count/capacity. No client grant remote was introduced.

## Play evidence
Tests ran in actual server Script / client LocalScript contexts, not Studio plugin require caches. Drop tests invoked the existing OnEnemyDefeated entry point with server-owned confirmed-defeat fixtures; this was a loot/lifecycle integration test, not a full all-stage combat replay.

- Real unchanged random roller: five successful World1 acquisitions in 29 calls during final rerun. Count 0 -> 1 -> 5, including repeated ItemIds counted as individual items.
- Sixth insertion rejected with InventoryFull; count stayed 5; copied snapshot mutation could not alter server state.
- Existing permanent items and equipped slots did not consume Run capacity.
- Duplicate defeat returned AlreadyProcessed. Duplicate transaction ID added once only.
- Actual Humanoid death: count 0, empty items and changed RunId; preexisting OwnedItems and EquippedItems remained exactly equal.
- Completion held across death/respawn using the old RunId was rejected by both TryAddDrop and OnEnemyDefeated as StaleRun; new run stayed empty.
- Automatic respawn and explicit LoadCharacter preserved permanent ownership/equipment.
- Ordinary PlayerData.Save with Run count 5 succeeded. Direct read of PlayerData_v1_Studio showed identical OwnedItems and no Run fields. This exercises the same Save API used by autosave/exit; shutdown/crash fault injection was not performed.
- World2 drop path added one permanent item while World1 Run count stayed 5. The test-added quantity was removed through the normal item mutation API and exact pre-test ownership was restored.
- Client probe received five acquisition events and capacity-rejection notifications. The existing result TextLabel was observed visibly displaying RUN INVENTORY FULL; replicated count/capacity were 5/5.
- World1 Deactivate/Activate retained the matching RunId and all five items. Another normal Save again left permanent inventory unchanged.
- All 35 audited protected Inventory/Reward/Save/UI definition sources remained byte-identical to their Phase 5A snapshots.
- Production PlayerData was not used; normal Studio store mapping was verified without changing DataStoreConfig.

Console contains existing reference-model issues: TungTungSahur.Script nil Chatted and Infinite Yield in archived Tralalero / La_Grande_Combinasion controllers. These unrelated sources were not modified. No error from the changed scripts or QA assertions was observed.

## Deferred behavior and limits
No banking exists yet. Existing trophy Lobby return, StartRun/reset, death and disconnect do not deposit provisional items. A normal world switch suspends World1 loot rather than banks it. Phase 5C/later must define banking/return and UI, and purchase persistence remains deferred. Run contents intentionally never join PlayerData autosave or receipts.

Existing non-boss reward, purchase, merge, equipment and World2 grant logic remain unchanged. Boss HP, damage, Chase, attack intervals, animations and VFX are not changed. Multi-client/device layout testing and full combat replay were not part of this server-foundation verification.

Play stopped; final Studio mode Edit. No Place save or Publish. Runtime QA Scripts existed only in Play and disappeared on Stop. Local before-source backups remain outside the Repository.
