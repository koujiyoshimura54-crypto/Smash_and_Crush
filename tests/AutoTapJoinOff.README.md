# AutoTap join-only OFF verification

Use only canonical Place126576845524886 in isolated native Studio tests. Do not use production persistence or real payments.

The temporary memory adapter is the existing `tests/EarlyGameLive/InstallIsolation.luau` at commit f2c8cf3, with its matching guarded RemoveIsolation script. It redirects39 external-service references, retaining exact before/after Source backups. This adapter is test infrastructure from the prior verification branch, not a shipping dependency of this fix.

Before Play, seed the isolated PlayerData store with synthetic Player_-2 `{Strength=11,AutoTapEnabled=false}` and Player_-3 `{Strength=23,AutoTapEnabled=true}`; leave Player_-1 absent. Delay the first PlayerData UpdateAsync for each key by four seconds. Do not edit production defaults or reward clocks.

Create ReplicatedStorage.__AutoJoinQA with RemoteFunction `Call` and Hold=true. Install the matching server fixture as ServerScriptService.__AutoJoinQAServer and client fixture as StarterPlayer.StarterPlayerScripts.__AutoJoinQAClient. Execute StudioTestService.ExecuteMultiplayerTestAsync(3,{}). Read the Result attribute when Completed=true. Hold=false lets the native test finish; it does not close the canonical Studio.

The fixture seeds data boundaries and gate positioning. Input uses existing AutoTapRequest/WorldTravelRequest Remotes and actual Humanoid movement. Death is triggered by setting the test Humanoid's health to zero, followed by the game's ordinary respawn. No OS input or test-driven reward grant is used.

For the second independent Play, use the exact memory record saved with AutoTap ON in the first native test. Set RejoinOnly=true and SavedStrength to the saved value26. Recreate native clients; do not reuse PlayerData module state. The first run separately tests memory Save/Release/Load. An MCP evaluation's separate module environment must not be substituted for the native Script's loaded services when exporting this record.

Cleanup: finish child tests, remove the three __AutoJoinQA fixtures in canonical Edit, run the guarded isolation removal and compare all shipping Source hashes against the post-fix baseline. Keep the two intentional changes and all prior edits. No Save/Publish or rbxl writeback.
