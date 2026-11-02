# Isolated World1 presentation checks

These are temporary native Studio fixtures, not shipped game scripts.

1. Use the currently open canonical Edit model. Capture exact Sources and instance/property baselines before installing anything. Never import an older place or replace current edits with the repository.
2. Install Memory.luau as ReplicatedStorage.__PresentationMemory. Temporarily redirect existing DataStoreService, MarketplaceService and BadgeService acquisition to that module's matching fields, preserving exact originals. The adapter has no persistent store, real checkout or badge-award capability.
3. Install Driver.luau as ServerScriptService.__PresentationDriver, Server.server.luau as ServerScriptService.__PresentationServer, and Client.client.luau as StarterPlayer.StarterPlayerScripts.__PresentationClient. Set the server fixture's Mode attribute to Solo or Multiplayer.
4. Solo Play exposes native BindableFunctions __PresentationServer and __PresentationClient in ReplicatedStorage. Use these to reach the live Script VM's cached service state; requiring services in an external tool VM is not equivalent. Driver prepares combat, native attacks, pad contact, explicit death and gate proximity. Client samples actual root-relative Bone/MeshPart motion and equipment properties.
5. With Mode=Multiplayer, call StudioTestService:ExecuteMultiplayerTestAsync(2,{}) from Edit. Its server fixture returns the report with EndTest. It creates two real clients from the current Edit model. Purchase completion is mocked; production data and payment are untouched.
6. Inspect runtime errors and the returned checks. A playing Track alone does not establish body movement. Property-based visibility does not establish screenshot appearance; capture limitations must remain explicit.
7. Stop tests. Guard temporary Sources against unexpected edits before restoring originals, delete only the four named fixtures, and compare the full recorded baseline. Preserve production changes and current unsaved user edits. Do not Save/Publish or write an rbxl.

The health refill loop is inspection-only; Health=0 still exercises real death/respawn. Driver's strength/wall setup is prepared progression, not a normal gameplay or balance-duration test. The focused results, late-child probes and capture limits are recorded in reports/World1Presentation_20261102.
