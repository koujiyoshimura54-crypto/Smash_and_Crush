# Speed entitlement, upgrades, equipment and UI — 2026-10-20

Canonical place: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Baseline commit: `5e3d53f`. Updated the same external, untracked place; no alternate rbxl, backup, migration, Studio Save or Publish.

## Confirmed causes and changes

- Premium Speed is GamePass **1979583273**, not a developer product. A read-only official `UserOwnsGamePassAsync` query for the signed-in Studio account succeeded and returned true. No missing purchase entitlement was reproduced. The force-unowned Studio setting was false, but its obsolete executable override was removed from the Speed entitlement path. Failed ownership queries retain the last verified session entitlement and expose an unavailable status; they do not persist a negative ownership record.
- Premium ownership blocked normal upgrades in the Upgrade UI, SpeedService and PlayerDataService. Removed those three restrictions. Existing atomic Win/stage transaction, expected-stage check, pending-operation retry, cooldown, prices 100/200/300/400 and normal speeds 24/28/32/36/40 are unchanged. Legacy Speed1 owners still normalize to stage4/40.
- Inventory had no equipment selector: it displayed the highest eligible speed, while the creator/Studio benefit gate could suppress Premium's effect despite OWNED. Added mutually exclusive Normal/Premium selection, authorized on the server and saved as optional `EquippedSpeed` in the existing PlayerData record. Missing legacy selection defaults to Normal; ownership alone never selects Premium. Premium50 and normal upgrades are independent. Generic benefit gates for other passes remain intact; explicitly equipped, verified Premium Speed now applies50 for the owner too.
- The current living Character receives the selected speed through existing Speed.Apply publications. The existing return-time recalculation from bedf633 is byte-identical. No frame-by-frame WalkSpeed writer, new movement controller or restriction bypass was introduced.
- Several equipment buttons changed an invisible parent underneath purchased image/gradient artwork; others only changed text/checkmarks. Shared presentation now colors the actual visible skin/Main gradient, restores its original paint on deselection, and leaves hover/press sizing and existing actions intact. Common equipment cyan is **#00DEFF → #0094EC**; solid selected surfaces use #00DEFF. Win yellow and Robux green purchase skins remain unchanged.
- Speed ACTIVE becomes Equipped. Speed, Dumbbells, regular Items, Pets by individual ID, Aura, size1–13/AUTO, Shop Dumbbell buttons and both Worlds' Dumbbell stands share this state color. Item slots, Pet/Aura unequip, size permission/fee and selection units are unchanged. Native scoped LocalizationTable/RootLocalizationTable uses the existing CSV's Equip/Equipped wording and adds Owned/所有済み; it works without a cloud-table download in the local place.

## Full Paths changed

1. `game.ServerScriptService.Services.GamePassService`
2. `game.ServerScriptService.Services.PlayerDataService`
3. `game.ServerScriptService.Services.SpeedService`
4. `game.ServerScriptService.Systems.Controllers.SpeedController`
5. `game.ReplicatedStorage.Modules.InventoryPresentation`
6. `game.StarterGui.StrengthGui.InventoryCapacityUpgradeClient`
7. `game.StarterGui.StrengthGui.SpeedInventoryClient`
8. `game.StarterGui.StrengthGui.InventoryPanelClient`
9. `game.StarterGui.StrengthGui.ItemInventoryTabClient`
10. `game.StarterGui.StrengthGui.AuraInventoryClient`
11. `game.StarterGui.StrengthGui.EssentialStudShopClient`
12. `game.StarterPlayer.StarterPlayerScripts.Services.PetClient`
13. `game.StarterPlayer.StarterPlayerScripts.Services.DumbbellStandClient`
14. `game.StarterPlayer.StarterPlayerScripts.UI.SizeChangeClient`

Also updated `localization/GameLocalizationTable.csv` and these English records. All other422-source snapshot entries, object properties, geometry, parents, referents, UniqueIds and shared strings were preserved. Boss isolation, StageSkip, Rebirth, body-growth thresholds and RunReturn Sources are unchanged.

## Focused actual Studio Play

One desktop Play client. Native temporary memory-only DataStore adapters covered every active non-package DataStore consumer. Runtime entitlement fixtures tested owned/unowned/error states separately from the successful real account ownership query. No production data or real payment was modified. Temporary inventory/progress grants and the flat floor existed only in Play.

- Baseline real Inventory UI: Premium OWNED; normal Upgrade also OWNED and disabled; WalkSpeed24. The reported purchase blockade was reproduced.
- Actual keyboard Upgrade UI: Premium equipped50, upgrade24→28 for100 Win, 5000→4900; Premium remained equipped50. Actual Inventory mouse/keyboard toggles changed Normal/Premium/Normal and their colors. Normal upgrade28→32 cost200, 4900→4700, applied32.
- Actual W input on the same300×300 flat floor, same camera/direction and1.6-second hold. Measurements use the central interval after0.25seconds acceleration allowance, actual horizontal root displacement/time and grounded samples:

| Case | Config / Humanoid | Distance / seconds | Measured studs/s |
|---|---:|---:|---:|
| Original owned account, suppressed effect |24 /24|23.59964 /0.982848|24.0115|
| Fixed Normal stage2, selected through UI |32 /32|31.33353 /0.981781|31.9150|
| Fixed Premium, selected through UI |50 /50|49.79156 /0.999021|49.8403|

- Native death/respawn retained Premium50. Existing WorldTravel Remote handlers, with fixture positioning at the real gate triggers, completed World1→World2→World1 and retained50. Real Normal01 Area occupancy set IsTraining true, then false after leaving;50 remained. These gate/Treadmill preparations were scripted positions, not manual traversal.
- Controlled native Bank.Commit interleavings switched equipment during return, once to Normal32 and once to Premium50. Both actual return-service executions completed at the latest speed. This is a deterministic race test, not a spontaneous reproduction.
- Real UI insufficient-Win rejection retained stage2/Win0 and unlocked the button. Six rapid keyboard activations advanced only stage2→3 and charged300 once. A later activation advanced3→4 for400; MAX disabled further purchase. A direct maximum-stage request made no change. An unowned test state bought a normal upgrade through UI for100 Win; forged Premium equip requests were rejected without changing Win/selection/effective speed.
- Native PlayerData Save→Release→Load against the memory adapter retained stage2, selected Premium, Win5000 and applied50. An injected ownership-check error retained verified ownership. These are test persistence/error checks, not production rejoin or a real purchase.
- Actual representative UI switches: Dumbbells NORMAL_01→02; Protein Common Fire→Ice; Aura Pink→Purple; two distinct Pet copy IDs, then same-Pet unequip; size13→AUTO. New equipment cyan and previous equipment original paint were inspected in the real rendered UI. Size selection charged the existing500 once; AUTO cost0. Reopening/tabs restored confirmed state. Shop Dumbbell switching and stand state followed the same equipment, including the visible PurchasedButtonVisual.Main cyan gradient; an invisible parent's yellow gradient was not used as success evidence.
- Final localization/presentation changes were loaded in a fresh Play and rechecked through actual Speed/Dumbbell UI, Shop skins and stand labels. English labels were rendered. The final native label RootLocalizationTable translator returned Equip/Equipped/Owned and 装備/装備中/所有済み for en-us/ja. Japanese-locale whole-screen rendering was **simulated through that translator**, not a Japanese-account Play session.

Automation attempts with a stale GuiService selection or unsynchronized fixture Pet revision did not move/equip; they were corrected before the successful checks above. Existing inaccessible-asset/Core UI warnings and explicitly identified test-command errors occurred. No new game Speed/equipment runtime error was observed.

Unverified: actual two-player Speed/UI interaction, production persistence/rejoin, real checkout, Japanese-account automatic screen rendering, mobile/touch and every cosmetic/product. Source confirms player-keyed state/requests and no mutation of other Players. This task did not rerun unrelated Boss/StageSkip regression suites.

All14 final Sources compiled and matched Edit before the same-file write; reDecode compared all422 Sources and found exactly those14 changes. Temporary ownership/DataStore/UI test hooks were removed. Play stopped; owned Studio PID17180 closed without Save; no user Studio was closed; its matching lock was removed after process exit. Target SHA256: `c66fe71741c5affec6dcbc641c7ff3042cb051c7e6903f16928f864559df51c3`.
