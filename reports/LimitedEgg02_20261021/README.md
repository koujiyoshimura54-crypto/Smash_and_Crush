# Limited Egg 02 — 2026-10-21

## Confirmed scope and result

The user confirmed **Open 1**, then requested a **dedicated UI containing only Open 1**, and prioritized speed with narrow validation. Developer Product **3720640383** now grants **one Pet per purchase**, repeatable, at the existing World2 Limited Egg. Base price is **279 Robux**. Current read-only Marketplace information returned **252 Robux** with the account discount; UI uses the existing Limited Egg client `GetProductInfoAsync` path and server price/association validation, never a free fallback.

This completes the pending third product after `e83fa54` connected Premium Aura **2045204630** (+1500 only while equipped, base 299) and Premium Treadmill **2044250678** (existing x35, base 399). Those connections, `ae7c5d0` Boss work, Trophy logic, map geometry and manual changes are retained.

Input is the current `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, SHA256 `8afea7a24a37d00aa360f36d73fb02cf2aa3f8593d375498ff69892c87d94703`. Seven current Sources were patched; no old rbxl or map-generation script was used. Target Experience remains UniverseId **10765181857**, PlaceId **126576845524886**.

## Connection and durable grant

- Facility: `Workspace.World2Map.TrainingArea.FacilityDisplays.LimitedEggDisplay.PetMesh`. A local View Pets interaction opens the existing dedicated Limited Egg sheet; no facility geometry is created or moved. The old generic World2 Limited sheet is excluded, so Open 3/8 do not appear.
- UI: `Players.LocalPlayer.PlayerGui.LimitedEgg02Gui.Background.Opens.Open1`. Reuses World1's existing single Robux purchase control and seven-model probability display. World1's Limited Egg also contains only Open 1; generic normal Eggs retain their separate Open 1/3/8 controls.
- The catalog keeps World1 Product **3717610547** unchanged, adds World2 by ProductId, and fixes Count=1. No client quantity argument can change the grant. Candidate names use the existing World2 species keys, retaining current models, multipliers and equipment behavior.
- Existing remotes: `ReplicatedStorage.Remotes.GameRemotes.LimitedEggPurchase` and `LimitedEggCommitted`. Requests carry the selected ProductId; server validates the exact World, physical entrance, active character/session, PolicyService restriction, positive sale price and Experience association before prompting.
- The sole existing `ReceiptService.ProcessReceipt` dispatch now recognizes both Limited Egg products. It reserves an immutable outcome in the existing DeveloperProductReceipts journal, atomically saves Pet + PurchaseId marker through the existing fenced PlayerData path, and completes the journal. Replays reuse the original Pet UUID/outcome. A purchase-finished event only releases the prompt lock; it never grants. Already-paid receipts remain fulfillable through a later policy or price outage.
- Client Hatch and inventory refresh occur only after the server's saved receipt notice. No added fixed success delay, new DataStore, schema migration, product, or competing ProcessReceipt callback.

| Existing World2 candidate | Probability | Existing multiplier |
| --- | ---: | ---: |
| W2 Pet_042 | 25% | 2.9 |
| W2 Pet_064 | 25% | 2.9 |
| W2 Pet_081 | 25% | 2.9 |
| W2 Pet_086 | 15% | 3.2 |
| W2 Pet_094 | 6.5% | 3.6 |
| W2 Pet_024 | 3% | 4.0 |
| W2 Pet_135 | 0.5% | 4.5 |

## Changed Full Paths

1. `ReplicatedStorage.Config.LimitedEggConfig`
2. `ReplicatedStorage.Config.World2GameplayConfig`
3. `ServerScriptService.Systems.Purchases.ReceiptService`
4. `ServerScriptService.Services.PlayerDataService` (only product/receipt validation; existing atomic persistence retained)
5. `StarterPlayer.StarterPlayerScripts.Services.StandClient`
6. `StarterPlayer.StarterPlayerScripts.Services.EggClient`
7. `StarterPlayer.StarterPlayerScripts.Services.HatchClient`

## Focused validation

Actual local Play with one client, temporary in-memory persistence and mocked Marketplace completion/prompt calls. No real Robux, live receipt or production player data was used. The user's later speed preference superseded broad repeat testing; the previous two-client/pass tests were not repeated.

- Actual E interaction opened the dedicated World2 UI. Inspected screenshot and runtime children: seven current candidates with 25/25/25/15/6.5/3/0.5% labels, Open 1 present, Open 3/8 absent, and no generic W2_Limited sheet. Marketplace price showed **252**. An actual button click requested **3720640383** through the real server remote/eligibility flow with a mocked platform prompt.
- Simulated cancel: zero Pets, UI returned to purchase-ready. Policy-restricted, Policy API error and price API error returned `PaidRandomRestricted`, `PolicyUnavailable`, and `PriceUnavailable`; valid offer reported Count=1.
- First simulated World2 Receipt granted one Pet. Exact duplicate returned PurchaseGranted without another Pet. Journal-finalization failure after Pet save returned NotProcessedYet; retry returned PurchaseGranted with the same single Pet. Ambiguous PlayerData write response likewise retried without duplication.
- Three distinct World2 receipts and one World1 receipt produced exactly four Pets. Existing World1 product selected its original unprefixed candidate; World2 used its own prefixed candidates. Every saved marker passed product-specific result validation.
- Actual PlayerData Save/Release/Load against the memory store, followed by a fresh ReceiptService cache and receipt replay, still contained exactly four Pets. This is **simulated rejoin/recovery**, not real production rejoin.
- Client received saved inventory revision 4, `PetSavePending=false`, closed the purchase sheet, and displayed the existing Hatch UI. No changed-production-script runtime errors were observed; injected persistence failures were expected. A first fixture run correctly refused the unpublished local context before its temporary context adapter was corrected; no Receipt grant was attempted in that rejected run.
- All seven modified Sources compiled. Same-file writeback rereads exact Source bytes and compares every other Source/property/parent/UniqueId unchanged; see `Writeback.json`.

Unverified: actual billing, real Roblox receipt redelivery, production persistence/rejoin, additional device layouts and a new two-client run. No broad unrelated tests were performed.

## Cleanup

Play stopped; temporary Script, adapter, RemoteEvent and test-only context/ownership/data replacements removed. Production restrictions are restored. Only the same rbxl is rewritten; no extra rbxl, backup, copy, migration, Studio Save or Publish. The Codex-launched Studio is closed without saving, and an exclusive file open checks lock release. Prior unrelated dirty Source/docs and untracked files are preserved and excluded from the commit.
