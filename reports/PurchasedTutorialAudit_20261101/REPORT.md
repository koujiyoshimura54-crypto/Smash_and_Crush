# Purchased-map tutorial audit and Battle Bag target check — 2026-11-01

This is a **static, read-only Studio audit**, not a tutorial migration or runtime certification. The requested Battle Bag font change is pending target clarification; it was not substituted with an edit to normal Inventory or UpGrade. No game Source or GUI object was changed, no Play was started, and no purchased Script was enabled.

## Evidence and provenance

- Current local-file Studio: `MergeToForge_CurrentCloud.rbxl`; repository baseline7050c37. The separately connected Cloud Studio was not inspected or modified.
- Purchased original: `C:\Users\kouji\Downloads\Game\Game.rbxl`, SHA256 `2369cfe1ff4ef2111112bca45e853a9cc33cad0217b3074205820ce2f4bb1f5c`. Decoded read-only using the existing repository binary reader; no write/build operation was called. File bytes were checked unchanged afterward.
- Prior original-asset audit: `C:\Users\kouji\GameAsset_Full_Audit_20261001.md`, sections2/3/16 and appendices. It documents an original-map Play showing onboarding/HUD suppression; that is historical evidence, not a new test in the current game.
- Git history:396c036 introduced the Run inventory counter;7370c6f preserved the current floor-only tutorial and added walking-carpet coverage/blocker caching. The requested protections remain untouched.
- Compared original and current `ReplicatedStorage.Modules.Tutorial`, `ServerScriptService.Services.TutorialServer`, `StarterPlayer.StarterPlayerScripts.Services.TutorialClient`: the actual source text is retained unchanged. An extra terminal newline in the private export was normalized for comparison. `Config.Tutorial` also matches exactly; unrelated Config sections now include current Egg prices and World2 additions.
- `Evidence.json` records current startup flags, dependency paths, relevant call sites and completion contexts. Module/asset existence is not presented as proof that its runtime behavior is connected.

## 1. Battle Bag: target clarification remains pending

The specified local Studio contains:

| Full Path | Observed role |
|---|---|
| `StarterGui.StrengthGui.HUD.RunInventoryLabel` | Run-only item/ore count, authored `- / -`, Legacy font,24px,184×28 before runtime layout |
| `StarterGui.StrengthGui.HUD.RunInventoryIcon` | Existing purchased bag icon beside that counter |
| `StarterGui.StrengthGui.RunInventoryHUDClient` | Reads RunInventoryCount/RunInventoryCapacity, updates the existing authored counter; no detail panel or open/close behavior |
| `StarterGui.StrengthGui.RunReturnClient` | Creates HUD.RunReturnButton with Back / Saving... / Retry; battle return state and existing remote |
| `StarterGui.StrengthGui.InventoryCapacityUpgradeClient` | Separate UpGrade screen with capacity and Speed cards; not a Battle Bag item-list panel |

No Battle Bag detail panel/controller was found by current GUI text/names or client Source references to Battle/Bag/RunInventory. The current RunInventoryHUDClient differs from the Git snapshot: it uses existing authored icon/counter objects rather than recreating a TextLabel. This newer unsaved implementation must be preserved.

The shared font is already `ReplicatedStorage.Config.StrengthHUDStyle.Font = Enum.Font.FredokaOne`. No lower-HUD text-size helper is necessary for a font-only change. HUDLayout owns this counter's position and size and does not reassign its font in the relevant layout block.

The user was asked whether Battle Bag means this run counter/return UI or a separate detail panel. Until that target is identified, no alternative UI is changed. Font rendering, detail-panel opening/closing, contents updates and death/respawn verification are therefore **not performed for this request**. No confirmation images were fabricated or taken from another Studio.

## 2. Original tutorial sequence and exact completion tests

The original purchased game trains **Speed**, breaks40 client-owned wall stages, collects Wins, buys shoe multipliers and hatches/equips Pets. It has no Smash Boss/ore/banked-run/Forge tutorial. `ReplicatedStorage.Modules.Config.Tutorial.Stages` contains19 rows; the completed stage is20.

All conditions below are read from the original/current unchanged `StarterPlayer.StarterPlayerScripts.Services.TutorialClient.Answers`. The English instruction and the actual condition are deliberately distinguished.

| # / key | Original instruction and target | Actual completion condition |
|---|---|---|
|1 / wall|Break your first wall; `Workspace.Stages.1`|`StageClient.broken("1")`|
|2 / wins|Collect your first wins; `Workspace.WinButtons.1.WinButton.Press`|Legacy data `wins > 0`; not validation of that particular pad|
|3 / upgrade1|Buy first upgrade; `Workspace.ShoesModels.2`|`Multiplier.owned(playerData,2)`|
|4 / upgrade2|Buy second upgrade; `Workspace.ShoesModels.3`|`Multiplier.owned(playerData,3)`|
|5 / belt|Normal treadmill to level4; `Workspace.Treadmills.Normal`|`Math.level(SpeedClient.total()) >= 4`; does not independently require standing on Normal|
|6 / menu|Open Rebirth; `StarterGui.ScreenGui.Left.Rebirth`|`MenuClient.shown() == "Rebirth"`|
|7 / rebirth|First rebirth; `StarterGui.ScreenGui.Menus.Rebirth.Main.Rebirth`|Legacy data `rebirth > 0`|
|8 / exit|Close Rebirth; `StarterGui.ScreenGui.Menus.Rebirth.Exit`|Shown menu is no longer Rebirth|
|9 / iron|Step on Iron; `Workspace.Treadmills.Iron`|`Treadmill.beneath(character) == "Iron"`|
|10 / run|Run on Iron; same target|Standing on Iron for3 continuous seconds, accumulated in0.1-second ticks; leaving/death resets this local timer|
|11 / wall1|Break Stage1; `Workspace.Stages.1`|Client wall1 broken|
|12 / wall2|Break Stage2; `Workspace.Stages.2`|Client wall2 broken|
|13 / wall3|Break Stage3; `Workspace.Stages.3`|Client wall3 broken|
|14 / wins3|Collect Stage3 wins; `Workspace.WinButtons.3.WinButton`|A new `QuickNet.WonWins` event after entering the step; event handler does not verify Stage3|
|15 / egg|Go to Basic Egg; `Workspace.Eggs.Basic`|Runtime `PlayerGui.ScreenGui.Basic` BillboardGui exists and is enabled|
|16 / open|Open Egg; runtime `PlayerGui.ScreenGui.Basic.Opens.Open1`|`HatchClient.shown()` increases after entering the step; not restricted to a verified Basic result|
|17 / inventory|Open Inventory; `StarterGui.ScreenGui.Left.Inventory`|`MenuClient.shown() == "Inventory"`|
|18 / equip|Equip new Pet; `StarterGui.ScreenGui.Menus.Inventory.Main.Items.<pet>`|`#Pet.equipped(playerData) > 0`; any equipped Pet, not necessarily the newly hatched one|
|19 / close|Close Inventory; `StarterGui.ScreenGui.Menus.Inventory.Exit`|Shown menu is no longer Inventory|

### Guidance presentation

- `NotifyClient.pin` pins each row's English text using the yellow/orange configured colors.
- `ReplicatedStorage.Assets.Tutorial.TutorialBeam` (texture74906879757285, width4, FaceCamera) joins cloned TutorialAttachment0 on the character's torso/root to TutorialAttachment1 at the target's bounding-box center. This is an airborne character-to-target Beam, not the current floor-only chevrons.
- TutorialHighlight is a transparent rounded Frame with a white outline and a large black translucent stroke. World targets are projected into a screen rectangle; GUI targets use their bounds. The original asset audit's description of a darkened focus area is consistent with this material.
- The rectangle uses worldPadding0.012, edgeInset0.02, minSize0.05, guiGrow1.18; menu tiles use0.125-square focus. GUI transitions interpolate over0.12 seconds, world rectangles track each RenderStepped. Conditions poll every0.1 seconds.
- HUD is held/hidden through MenuClient.hold, except the Speed and configured Leave frames. The left menu is released from step6. Shop/Daily/Playtime/Free notification badges are temporarily suppressed and restored afterward.
- The Egg step switches from world guidance to a highlight attached to its active BillboardGui button. The Pet slot highlight selects the first hatched Pet name, falling back to the first owned Pet.
- Hatch animation temporarily hides focus. Completion releases held HUD, plays SoundService.UI.Winner and shows `You finished tutorial!`; after notification duration/close delay it sends the last TutorialStep.

### Start, finish, save and lifecycle

`ServerScriptService.Main` and `StarterPlayer.StarterPlayerScripts.Main` invoke `ReplicatedStorage.Modules.Loader.load` on their Services folders. Loader requires service modules, calls init and then starts start functions. The original TutorialServer waits for legacy Data and begins at stage1 only if tutorialStage is0 **and wins, rebirth and playtime are all numeric0**. A missing tutorialStage field or missing/nonzero counters does not qualify. This is an approximate new-profile test, not a separate first-join flag. A player with tutorialStage0 but nonzero playtime is not automatically restarted.

Original `ReplicatedStorage.Modules.Data` initializes tutorialStage0 in ProfileStore index `OfficialGameProduction` (`IS_TESTING=false`, dontSave=false, useMock=false). DataServiceTyped binds Value updates to profile.Data and releases the ProfileStore session on leave; tutorialStage is therefore persistent profile state. It is separate from the current game's PlayerDataService schema.

TutorialStep is a logical client-to-server QuickNet event (declared with `SetRateLimit(10,5)`), not a pre-authored RemoteEvent named TutorialStep under current Remotes. Server checks only that tutorial is running, then increments by1 up to20. It does **not** independently verify wall/upgrade/egg/Pet completion. No dedicated tutorial Skip control/handler was found. The separate loading-screen Skip is not tutorial completion.

Client start waits up to10 seconds for a running tutorial stage. Stage20 returns without starting. Rejoin continues a saved stage1–19. Client-only counters such as Iron standing time, WonWins baseline and Hatch shown baseline are reinitialized. CharacterAdded rebinds the Beam for the current world step; it does not reset saved tutorialStage. ScreenGui replacement rebinds the focus frame; the current donor ScreenGui is ResetOnSpawn=false. These are Source-derived lifecycle conclusions, not a new original-map Play.

## 3. Current connection state and reuse requirements

| Full Path / component | Current local Studio | Reuse requirement |
|---|---|---|
|`ServerScriptService.Main` / `StarterPlayer.StarterPlayerScripts.Main`|Both Enabled=false / Disabled=true; original Loader entry points do not run|Keep disabled. Do not enable all imported services to obtain tutorial behavior|
|`ReplicatedStorage.Modules.Tutorial` / `ReplicatedStorage.Modules.Config.Tutorial`|Original rules and19-row table retained|Adapt stage definitions and current data schema; original text/counter assumptions are not Smash rules|
|`ServerScriptService.Services.TutorialServer`|Original module retained; no independent current caller/start found|Use current server-confirmed progression events and existing session/save ownership, not unchecked legacy TutorialStep increments|
|`StarterPlayer.StarterPlayerScripts.Services.TutorialClient`|Original module retained; no active direct start call found|Presentation logic could be selectively adapted; current paths/events/menu state must be mapped|
|`ReplicatedStorage.Assets.Tutorial.TutorialBeam`, `TutorialAttachment0`, `TutorialAttachment1`, `TutorialHighlight`|All four templates present|Visual templates can be reused selectively; retain the current corrected floor-arrow renderer instead of replacing it with Beam guidance|
|`ReplicatedStorage.Modules.Data` / `ReplicatedStorage.Packages.DataServiceTyped`|Legacy profile/template/dependencies retained; tutorialStage has no bridge to current TutorialCompleted|Do not start a second legacy profile store for this feature; define conversion/step state in the current data system only if subsequently approved|
|`ReplicatedStorage.Packages.QuickNet` logical TutorialStep/WonWins/Hatch|Definitions/packages remain; the original TutorialServer listener is not connected through its disabled loader|Adapt notifications to authoritative current events; do not equate channel declaration with a live listener|
|`Workspace.Stages.1`, `.2`, `.3`; `Workspace.WinButtons.1.WinButton.Press`, `.3.WinButton`|Missing at these original paths|Map to current World1 wall/Boss/Trophy events and current generated geometry|
|`Workspace.ShoesModels.2`, `.3`|Missing; `Workspace.PerStepButtons.2`, `.3` still exist with current equipment use|Replace shoe ownership conditions with confirmed current Dumbbell purchase/equip data; existing DumbbellPurchaseRequest/InventoryState belong to a different schema|
|`Workspace.Treadmills.Normal`, `.Iron`|Missing under those original names|Use current Treadmill equipment, available tiers and Strength/Level rules; do not import original Speed/level4/rebirth assumptions|
|`Workspace.Eggs.Basic`|MeshPart remains|Existing current Pet/Hatch modules are adapted and used by current flows; verify their outcome events and runtime BillboardGui path before any future onboarding connection|
|`StarterGui.ScreenGui.Left.Rebirth`, `.Menus.Rebirth.Main.Rebirth`, `.Menus.Rebirth.Exit`|GUI pieces remain|Presence is insufficient: current Rebirth controller/data and MenuClient.shown state must be integrated|
|`StarterGui.ScreenGui.Left.Inventory`|Original entry missing; current normal Inventory/Pets entry layout differs|Use the approved current entry, not recreate the old button|
|`StarterGui.ScreenGui.Menus.Inventory.Main.Items`, `.Exit`|Containers remain|Resolve current per-copy Pet card paths and equipment confirmation; do not treat Battle Bag as this Pet inventory|
|`SoundService.UI.Winner`|Sound Instance remains|Asset playback/authorization not retested; optional completion cue, not a gameplay dependency|

The original source data is available; the missing items are mostly **current runtime path/semantic connections**, not an absent tutorial archive. Loader catches require/init/start failures, so enabling it wholesale could also fail silently and start unrelated imported services. No such enablement was attempted.

## 4. Difference from the current tutorial

The active current controller is `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` (Enabled=true). It is independent of the disabled original Services.TutorialClient.

- World1 only, while `TutorialCompleted == false` and the character is alive.
- Level below2 points at current `Normal01.Area`; then Stage1 walls1.1–1.4, Stage1 Boss and the owner's spawned Trophy. CombatState events drive wall/boss/Trophy targets.
- Completion is server-owned: `ServerScriptService.Services.TrophyRewardService` calls PlayerDataService.CompleteTutorial on validated World1 Stage1 Trophy pickup; `ServerScriptService.World.EnemyManager` has the documented fallback at accepted Stage2 Boss attack entry.
- `ServerScriptService.Services.PlayerDataService` persists TutorialCompleted and retries save through its existing gates. It does not use the purchased tutorialStage field.
- Death hides/releases arrow/cache state; respawn rebinds character and requests current combat state. World changes gate updates; TutorialResetSequence resets local guide state.
- Current floor arrows retain verified walking-carpet surfaces, obstruction tests including relevant CanQuery=false parts,16-stud spatial cache, lifecycle cleanup and0.2-second scheduling. No old Beam/RenderStepped logic was applied over them.

Running both systems could produce two guidance targets/messages, two incompatible completion states, hidden menus during current HUD flows and old Speed/upgrade/Stage predicates that never complete. The original has no Boss or Merge steps. Any future Boss/Forge/Item/Ore/Pet Merge onboarding needs new approved steps tied to current committed outcomes; it is not a dormant original feature ready to switch on.

## 5. Verification limits and final state

Read current Sources/properties, original purchased Sources, existing audit and Git history. Did not execute the original tutorial, test its save/rejoin path, load assets for new playback, simulate19 steps, enable imported modules, or alter the current tutorial. No production data, receipt or purchase operation was used. No Battle Bag font/display/lifecycle acceptance is claimed while its intended panel is unresolved.

No Studio/OS input, window/panel/camera/display change, locking change, Save/Publish, rbxl writeback or Studio shutdown. Current unsaved Edit remains intact; local rbxl hash remains `1951C12EB639703BD516DD925983F63A54AC3A701BB2C0EA6B4810FCCB62D97A`. Git records this investigation only. The Battle Bag change still needs the user's target clarification.
