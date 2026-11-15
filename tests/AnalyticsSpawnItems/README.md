# AnalyticsSpawnItems verification

These files are test material, **not shipping Scripts**. Never synchronize this directory into the live place. Results and limitations: [2026-11-15 report](../../reports/AnalyticsSpawnItems_20261115/REPORT.md).

## Deterministic matrices (Edit, no production services)

Read the test file as text and evaluate its returned function using Studio MCP's Edit Luau execution / loadstring. Keep test text outside the DataModel. Obtain current production Source from the duplicate Studio; compare it with the repository before running.

```lua
-- Each *TestText is the corresponding local file's text, passed by the test runner.
-- Each Source argument is text, not a required live server ModuleScript.
local transportResult = assert(loadstring(transportTestText))()(transportSource)
local spawnResult = assert(loadstring(spawnTestText))()(spawnSource)
local analyticsResult = assert(loadstring(analyticsTestText))()({
    Service = analyticsSource,
    Transport = transportSource,
    Before = baselineAnalyticsSource,
}, {
    Ore = require(game.ReplicatedStorage.Config.OreConfig),
    Merge = require(game.ReplicatedStorage.Modules.OreMerge),
    Counts = require(game.ReplicatedStorage.Modules.InventoryCounts),
})
local stressResult = assert(loadstring(stage2TransportTestText))()(transportSource)
```

Baseline Analytics source is from commit 4b0560b526b20fa5a157f5e942edc607ffaa36dc at src/ServerScriptService/Services/FirstPlayAnalyticsService.luau. stage2TransportTestText is the existing tests/FirstPlayAnalytics/Stage2Transport.luau.

Expected results at this revision: Analytics 1,631 assertions, Transport 26, Spawn 34, existing stress 52 checks. The matrices substitute Players, time/scheduler, API calls and geometry; they are not Play, network departure or Creator Hub verification. Analytics uses the real state-machine source with geometry functions replaced by fixture predicates. Item property/mapping checks and native observations are recorded separately in evidence.json.

## Isolated native Play fixtures

Use only the duplicate PlaceId 126576845524886 / UniverseId 10765181857. Check both IDs and Edit mode before edits. Do not save, publish or use production DataStores/payments.

1. Snapshot current Source AND ScriptEditorService:GetEditorSource for every source to be changed; assert no unexplained divergence before writing. Preserve all unrelated edits.
2. Adapt the existing tests/FirstBattleTutorial/InstallIsolation.luau: replace __FirstBattleBackup / __FirstBattleMemory with __ThreeFixBackup / __ThreeFixMemory. Use ScriptEditorService:UpdateSourceAsync with a current-source guard. This fixture redirects DataStoreService, MarketplaceService, BadgeService, MessagingService and PolicyService to in-memory adapters. In this run it redirected 39 sources. Re-audit service access before any future Play; do not assume future source versions use the same access spelling. Payment prompts must remain blocked.
3. Create a temporary ReplicatedStorage Folder __ThreeFixQA, Script ServerScriptService.__ThreeFixServer from Native.server.luau and LocalScript StarterPlayer.StarterPlayerScripts.__ThreeFixClient from Native.client.luau.
4. Start Play. Invoke __ThreeFixQA.Server from Server context and __ThreeFixQA.Client from Client context. Bindable calls run in the native Script VM so they share the production ModuleScript cache. Do not require a second service instance from a separate MCP VM and treat it as the running service.
5. Server actions: Inspect; SeedItems (four of each item, fixture Win and World unlock); Die; World(1 or 2). Client actions: Inspect; Gallery("Fire"/"Ice"/"Electric"), Gallery(nil) to remove it; Inventory; Close; MoveShop. Use real UI clicks/drags for equipment, sale, selection and purchase checks. Read actual positions for the current viewport.
6. NativeExtras.server.luau is optional isolated test code providing Extra("Purchase") / Extra("Drop"). Purchase uses game Win only. Drop explicitly injects a result; it does not verify natural random drop probability or a natural kill.
7. NativeDeparture.server.luau / KickDuringLoad **disconnect the isolated test player**. They are opt-in tests, not normal startup code. Record whether the engine load was actually still running before the kick. Our attempt returned from load first, so in-flight native departure remains unverified.
8. Switch to the actual client viewport and require RenderStepped progress / nonzero viewport before interpreting screenshots. Native.client preloads ImageLabel instances; raw URI callbacks returned false negatives in this environment. Offscreen IsLoaded=false is not evidence of a broken asset. Inspect screenshots then discard them.
9. Stop Play. For each __ThreeFixBackup entry, require both current Source/editor to equal After, then restore Before. If another edit appeared, preserve it and resolve the diff; never blindly restore. Destroy only owned fixtures, backup/memory modules and any owned gallery. Restore original camera/device settings. Confirm original source inventory, expected production diffs and no __ThreeFix / __PostOre remnants. End unsaved Edit.

The Ore native routes used the prepared first-battle fixture from tests/PostBattleOre (adapt its memory-module reference to __ThreeFixMemory), then actual server outcome paths, rendered client guide/view observations and real Ore UI merge. See the report for the exact scope; it was not a naturally earned end-to-end account progression test.

No real user profile, screenshots, session GUIDs or player identity are required in published evidence.
