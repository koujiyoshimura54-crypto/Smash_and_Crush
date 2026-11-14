# Post-first-battle Ore analytics verification

These fixtures are not deployed under `src`. Never install them in a published server.

`StateMatrix.luau` returns a function taking `{Service, Before, Transport}` source strings and `{Ore, Merge, Counts}` modules. `Before` is the service at `d0b5f24`; the other sources are the current checkout. Invoke with `loadstring` in an isolated Studio Edit command. Dependencies, clock, delivery API and physical geometry are injected; the exact production cohort, sequencing, validation and transport code runs. The final regression compares all 18 rows of the other five funnels against that baseline.

`ClientMatrix.luau` returns a function taking the current `FirstPlayAnalyticsClient` source. Its frame events, GUI geometry, controls, HUD and remotes are mocks. It cannot prove actual screen visibility.

Native Play uses the existing `tests/FirstBattleTutorial/InstallIsolation.luau` memory service redirects, with exact Before/After restoration by `RemoveIsolation.luau`. Assert PlaceId 126576845524886 and Edit mode, preserve the existing sources, install the memory redirects, then create:

- `ReplicatedStorage.__PostOreQA` (Folder)
- `ServerScriptService.__PostOreServer` from `Native.server.luau`
- `StarterPlayer.StarterPlayerScripts.__PostOreClient` from `Native.client.luau`
- Optionally `ServerScriptService.__PostOreHybrid` from `Hybrid.server.luau`.

Only start/stop a test Play owned by this task. `Server:Invoke('PrepareBoss')` prepares a memory-only LV4/Strength40 wall-cleared fixture and anchors its character. It is not natural progression. Existing Boss attacks produce Death; six spaced `Tap` actions use the existing accepted manual-attack path for Victory. Call `ReleaseFixtureAnchor` before `Back` or after Victory; otherwise the fixture anchor can correctly prevent readiness. The ordinary return can also temporarily anchor during placement: wait for its acknowledgement.

Use `Client:Invoke('MoveShop')` for ordinary Humanoid movement. Use Studio input tools to click the actual Item/Pet/Ore tabs, the Stone material twice, then Merge. `Fault('Fail')` and `Fault('Hold')` affect only memory writes; always call `Fault('Off')` before stopping. Inspect server records through the native bindable (MCP server command `require` can have a different module cache).

`Hybrid:Invoke('Prefix')` explicitly fabricates the display observations for a server/persistence integration test. Never label that path as actual rendered UI. The final report distinguishes it from the later native client-observed runs.

After Play, restore the exact isolation backup and remove the four named QA objects. Verify production Source and ScriptEditorService editor text against the checkout, including unchanged authority/config modules. Do not Save/Publish. Do not leave these fixtures, fault switches or the memory service in Studio.

Evidence and limitations: [report](../../reports/PostFirstBattleOre_20261114/REPORT.md).
