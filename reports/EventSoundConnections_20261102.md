# Connect missing event sound effects — 2026-11-02

Applied to the current canonical Studio, PlaceId 126576845524886. Existing unsaved edits, including the completed per-Item set effects/Best Equip change (ac7b5cc), were retained. No other Studio was touched. Existing audio registration/permissions were not re-audited, changed or uploaded.

## Current-route audit and outcome

| Event | Existing active path | Retained / added | Verification |
| --- | --- | --- | --- |
| Rebirth success | Current RebirthMenuClient had no audio. Purchased RebirthClient is dormant under disabled Main. | Added UI.Winner only on server Success; RebirthCount/session dedup. | Actual isolated success once; repeated mock success silent; refusal Error. |
| Offline normal / double / Strength pack committed grant | StrengthRewardClient had click feedback but no grant audio. | Added UI.Success after committed GrantedTotal increases. Read-only View metadata; no Receipt/schema change. | Actual normal 180000 preview grant once; repeated Claim silent. Double remainder/totals and replay simulated, no payment. |
| Hover / click / tabs / material selection | ButtonClient owns ScreenGui and attached Egg buttons; HUDLayout owns purchased buttons; StrengthHUDPresentation already clicks. | Existing paths untouched except ownership markers. Add UI.Hover/Click only for missing halves; drag-to-input Click. | Existing-owner exclusions, disabled button, regenerated button callback, burst suppression tested. Physical mouse/touch events not injected. |
| Ore / Item merge | Current Forge.Completed and consumeResult had no result sound. | Added UI.Success by accepted operation ID. | Real memory-backed Ore merge; real Item merge response passed to the same audio handler. Replays silent. |
| Pet merge / hatch | PetClient invokes HatchClient for accepted LastRequestId. Click knock, Success crack, existing rare Winner already connected. | Retained; no added Pet result sound or new rarity rule. | Current Sources audited; excluded from added handler. Full hatch/camera animation not replayed. |
| Ore / Dumbbell sale | Forge.Completed had no audio. | Added UI.Cash per accepted operation, including bulk sale. | Actual sale of six Ores and one unequipped Dumbbell each once. Protected last-equipped-copy and material shortage reject with Error. |
| Item sale | No active SellItem request/UI found; Forge supports SellOre and SellDumbbell only. | No feature invented/enabled. | Static current-source audit. |
| Win purchases | Purchased buttons already hover/click; current result handlers lacked confirmed-success audio. | Added UI.Success for Item, Dumbbell, Aura, Speed upgrade and inventory capacity. | Actual isolated successes; repeat Item response silent; non-purchase Dumbbell equip excluded. |
| Time / Daily rewards | Active current controllers/UI had no result sound. Old PlaytimeClient/DailyClient dormant. | Added UI.Cash for Win; UI.Success otherwise. Observe explicit success or claimed-state transition after an established baseline. | Actual Stone/Win Time rewards, Daily Day1 Win; repeated claims silent. Non-Win Daily result simulated. |
| Operation denial | Pet/Egg failures already use NotifyClient (UI.Notification); preserve that path. Other covered operations had none. | Added UI.Error for terminal supported denials; pending/already-claimed/cancellation does not create success. | Actual insufficient Win/Ores and too-few Ores, plus protected-sale replay; prompt/cancellation mocks silent. |
| First clear / World unlock / Trophy | CombatClient already plays defeat audio at EnemyDefeated; StageManager.ClearStage marks first clear there. TrophyRewardService unlocks W2 in the existing TrophyCollected path, which TrophyRewardFeedbackClient sounds. | Retained those existing combined event sounds; no overlapping Winner. | Current call path verified; not replayed by progression attribute polling. |
| Level-up | Old LevelClient is dormant; current Strength/Level HUD had no level sound. | Added UI.Notification on level increase after authoritative View baseline; one final value per update. | Real isolated Level1 -> 74 emitted once; initial view, repeated value, death/respawn did not emit. |

## Full Paths changed

- **ReplicatedStorage.Config.UISoundConfig**: added-only sound choices, source-volume multipliers, playback-speed multipliers and minimum intervals in **Added**. CoinCollect remains exact.
- **ReplicatedStorage.Modules.UIFeedback** (new): client-only playback, input ownership checks, existing-result/state dedup and routing.
- **StarterPlayer.StarterPlayerScripts.UI.EventSoundClient** (new): one persistent startup call.
- **StarterPlayer.StarterPlayerScripts.Services.ButtonClient**: existing Hover/Click ownership flags only.
- **ReplicatedStorage.Modules.HUDLayout**: existing purchased Hover/Click ownership flags only.
- **ReplicatedStorage.Modules.StrengthHUDPresentation**: existing Click ownership flag only.
- **ReplicatedStorage.Modules.MergeShopView**: Click for drag release into the input area.
- **StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New**: audio at its existing correlated terminal Item result.
- **StarterGui.StrengthGui.StrengthRewardClient**: observe authoritative View/result totals and explicit refusals.
- **ServerScriptService.Services.StrengthRewardService**: View exposes committed GrantedTotal, Forge session token and current Level. Receipt methods, product configuration and persistence are unchanged.
- **ServerScriptService.Systems.Controllers.ItemController**: unique transient feedback ID on actual Win-purchase success.
- **ServerScriptService.Systems.Controllers.DumbbellController**: response distinguishes a new confirmed purchase from stand/equip-only actions; transient feedback ID.
- **ServerScriptService.InventoryCapacityController**: extra transient success-response ID; old response arguments retained.

IDs in purchase responses are only presentation metadata. No new stored fields, receipt routing, prices, inventory mutations, UI geometry or rewards were introduced. The client cannot authorize a grant through this module.

## Settings and verification

Added Hover volume is source *0.22 (0.165 with current source), Click *0.65 (0.4875), Denied/Level *0.8 (0.6), other added results *1 (0.75). All added playback-speed multipliers are 1. Minimum intervals: Hover 0.09s, Click 0.035s, Rebirth/Level 0.15s, results 0.12s, Error 0.3s. Original Sound properties and existing playback functions keep their original timing/volume/speed. Added local voices reuse one clone per source sound and never overlap copies of the same source. Reading current source volume respects existing mute settings.

Two focused solo Plays used memory DataStore/Badge substitutions across all seven existing persistence consumers. **22 native client assertions** passed for success/refusal/duplicate/cancellation, committed totals, purchase filtering, multi-level notification, ownership guards, disabled/regenerated button callbacks and hover throttling. A final protected-sale replay probe emitted Error once.

All seven UI source sounds preloaded successfully. Added voices reported IsLoaded=true, Playing=true and TimePosition 0.149–0.171 seconds during the probe. Success and event counts are playback-state checks, **not an auditory listening confirmation**. No real Robux transaction or production save was performed.

Actual server exercise additionally covered Rebirth, Time Stone/Win, Daily Win, all five Win purchase categories, one repeated purchase reply, actual multi-level Strength gain, Ore merge, bulk Ore sale and Dumbbell sale. Item merge used a real server transaction with the response fed into the same confirmed-result audio function; the physical Merge button was not clicked. The ordinary offline claim used the existing Studio preview path, with real claim response and committed totals; x2 payment/grant delivery was simulated.

The first raw Ore fixture was superseded by authoritative memory-store transactions, so initial Ore attempts correctly refused NotEnoughOres. Stock was then granted through the existing memory-backed Forge grant API and the success/sale cases passed. The intentional Badge stub produced a FirstRebirth warning. No new runtime error or Infinite Yield occurred.

Limitations: no physical pointer/touch interaction, no live payment/receipt network timing, no production persistence, no full Pet hatch or full Stage campaign replay. Initial authoritative View establishes a silent baseline; historical grants/progression are not announced on rejoin. Screenshot collection was unnecessary for this audio-only change.

## Cleanup

Removed all QA objects and restored every persistence substitution. Final Edit verification checked **465 production Sources / Enabled states** and **74 SoundIds** against the pre-Play manifest. Existing UI7/BGM2 replacements, healthy WallBreak and current music remain unchanged. Both old Main scripts stay disabled. No Save/Publish, rbxl write, OS input, window/camera setting change or Studio exit.

