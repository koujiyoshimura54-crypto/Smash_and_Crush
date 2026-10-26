# Isolated World1 Ore checks

These are QA fixtures, not production Scripts. Never mount them in a published game or a session using production DataStores/payments.

- `Pure.luau`: native pure/config checks; no player data.
- `Memory.luau`: in-memory DataStore/receipt dependencies, metadata and injected acknowledgement/before-write failures. It does not write Roblox DataStores.
- `Seed.server.luau`: temporary owned quantities and a server-only BindableFunction for focused checks. Requires the memory dependency replacement **before** any gameplay Script initializes. Restore original Sources and remove both seed and memory module in Edit after Stop.
- `RemoteChecks.client.luau`: real remote request paths in that isolated session. Does not represent physical clicks.
- `Multiplayer.server.luau` / `Multiplayer.client.luau`: native `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)` isolation checks, then `EndTest`. Both clients use the memory store fixture. This is not a published-server test.

Before replacing temporary dependencies, retain each exact original Source and its QA replacement. Restore only if the current Source still equals the recorded replacement, so concurrent user edits cannot be overwritten. Record camera/Focus/FOV/ShowDevelopmentGui before QA and compare after Stop. Do not use Save/Publish or a copied rbxl. The current task's fixtures were removed and its 36 dependency replacements restored; see `reports/World1Ore_20261026/final-audit.json`.

Real UI actions, temporary constrained-parent testing, controlled RNG combat and limitations are documented separately in the report. These fixtures do not claim actual mouse/touch coverage by themselves.
