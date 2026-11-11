# Early-game balance candidate checks

These tests exercise Luau code with service adapters. They do not launch Roblox Studio, access DataStores, publish, click UI, or measure player retention.

From the repository root:

```sh
npm install --prefix tests/EarlyGameBalance
node tests/EarlyGameBalance/run.mjs
```

For a runtime installed elsewhere, set `LUAU_WEB_MODULE` to its absolute `luau-web/src/index.js` path. Dependency version1.4.0 is pinned.

The default progression fixture is the repository's September15 archived module, NOT a current Studio export. Before application, export the live `ReplicatedStorage.Modules.LevelProgression` and use:

```sh
LEVEL_PROGRESSION_SOURCE=/absolute/path/to/live-LevelProgression.luau node tests/EarlyGameBalance/run.mjs
```

`fixtures/LevelRequirementsBefore.luau` and `World1BossConfigBefore.luau` come from main `dd3531ebd99131cbb9481227b23fd99ab9393751`. The progression fixture comes from `reports/Level_Progress_20260915/after/ReplicatedStorage.Modules.LevelProgression.luau` at that same repository commit. None is intended for production installation.

The suite checks requirement boundaries, all10000 levels, fresh cumulative anchors, every Rebirth threshold, legacy lookup compatibility, saved-progress carry, batching, invalid inputs, wall carry, Boss encounter resets, independent adapters and the initial guide floor. `result.json` records the authoring run. Its attack-count comparison is a fixed-Strength ideal-contact model, not full-route seconds.

Native acceptance remains mandatory; see `reports/EarlyGame15x_20261111/REPORT.md`.
