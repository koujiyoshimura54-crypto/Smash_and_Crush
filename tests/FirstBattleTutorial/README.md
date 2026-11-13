# Phase 2 isolated verification fixtures

These are source fixtures, not production scripts. No test helper remains installed in the final Studio.

Run `python tests/run_first_battle.py` for the 82 progression and 53 prompt assertions and Luau syntax checks. The runner uses the existing Luau binaries under `C:/Users/kouji/stage_skip_work/luau`; it does not install tools.

Native Play requires an operator-owned isolated session. Do not stop someone else's Play, reset public data, Save, or Publish a helper installation. `InstallIsolation.luau` must run in the specified canonical Edit before Play. It backs up exact Sources, redirects external services to memory, and refuses a second installation. Confirm every redirect before starting Play.

Create a temporary ReplicatedStorage `__FirstBattleQA` Folder with `Report` RemoteEvent and `State` RemoteFunction. Install Observe, SaveChecks and CombatChecks as temporary server Scripts, and Route as a temporary StarterPlayerScripts LocalScript. Their native BindableFunctions provide live-service access; requiring a server module from an MCP command is not equivalent to its native running-script cache.

The natural Route fixture uses a test-only export of the existing `pressed` callback in HatchClient: append `HatchClient.__FirstBattlePress=pressed` immediately before `return HatchClient`. Back up this additional Source change as another Target/Before/After entry in `__FirstBattleBackup`, so cleanup validates and restores it. Do not ship the export. Set QA's `NaturalMode` to `LossFirst`, `WinFirst`, or `EarlyMerge` before fresh Play. The route asserts fresh LV1/Strength0/Stone2/Auto OFF; it earns all progression and never forces the result. Prepared CombatChecks actions must not be used during a natural timing run.

Invoke server QA.SaveChecks once to run 14 cases / 120 assertions against exact services with memory fault injection. SaveChecks restores its original isolated profile. Read SaveChecksDone/SaveChecksFatal and SaveChecksResult. Inspect returns native events/analytics; remove account names, IDs, session tokens and operation GUIDs before retaining any evidence. Disconnect tests model Release/Load and write yielding, not real cloud networking.

Phase 1 prompt fixtures can be reused from `tests/Stage1WallPromptPlay.*.luau` with the temporary QA prefix adapted and prepared Strength set to 5. Test real tool input on the visible finger separately from direct test Remote calls. Client detach/reparent only models streaming.

Restore simulator defaults, stop only the owned Play, and run RemoveIsolation in Edit. It validates every After Source before restoring all exact Before Sources. Remove the QA Folder and installed temporary scripts by their explicit names. Confirm Source and ScriptEditor equality, no helper references/objects, and unchanged retained geometry. No Save/Publish. See the Phase 2 report for executed cases and limitations.
