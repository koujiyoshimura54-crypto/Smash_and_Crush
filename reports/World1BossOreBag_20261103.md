# World1 Boss Ore now uses Battle Bag — 2026-11-03

## Corrected behavior and cause

The user clarified that Boss Ore belongs in Battle Bag. The previous implementation routed normal Ore directly through Forge.GrantOre and the first Stage1 Stone through a durable Forge grant, while RunInventoryCount counted only provisional Items. A correctly updating Item counter therefore did not satisfy the intended Ore behavior. This change supersedes the direct-Boss-Ore behavior documented in the preceding Stone/Stage1 reports.

Applied to the latest unsaved canonical Edit document, PlaceId126576845524886 / UniverseId10765181857.

Changed Full Paths:
- `ServerScriptService.Services.RunInventoryService`
- `ServerScriptService.Services.RunItemBankService`
- `ServerScriptService.Services.RunReturnPersistence`
- `ServerScriptService.Services.EnemyDropGachaService`
- `ServerScriptService.Services.PlayerDataService`
- `ReplicatedStorage.Modules.FirstStage1RewardState`
- `ReplicatedStorage.Modules.ForgeInventory`

World1 Boss Items and Ores now share one provisional run inventory, one capacity and one processed-Drop-ID set. Acquisition increases the actual combined count; it does not increase OwnedOres yet. Back/Trophy's shared bank freezes both categories and commits them in the same existing two-phase, session-fenced return journal. Death/run invalidation loses unbanked contents. Already committed returns remain terminal, including lost-response retries.

First Stage1 defeat still consumes lifetime eligibility durably. New first awards use Delivery=BattleBag and BagEligible; the legacy OreGranted field continues to describe old direct awards. The queue adds its Stone only to the original live run, after consuming eligibility, and the shared Drop-ID set prevents a second addition. Full/stale runs receive no Stone. Death does not restore eligibility. Legacy consumed records and previously owned Ore remain intact.

Ore-containing returns use RunOreReturnJournal; Item-only returns keep the legacy RunReturnJournal. The shared sequence/owner checks cover both, and new ownership cancels abandoned Pending entries in either field. This avoids putting an Ore-only record into a field that older Item-only readers reject. Final native checks repeated Ore-only lost-ack recovery, mixed return, subsequent Item-only return and memory reload after this compatibility change.

TimeReward Stone remains a direct inventory reward. UI layout/font, drop odds/candidates, Win, Limited Egg, production setwin, merge rules and tutorials are unchanged. OwnedOres refreshes through the existing ForgeInventoryRevision signal after bank confirmation.

## Verification

All persistence, badges and payment dependencies were temporarily memory-isolated. No production/player account data was changed. Used actual EnemyManager combat, defeat notification, normal RunReturnService return, character death/respawn and the existing /resetdata command. Only RNG inputs were controlled for deterministic Item/Stone/Coal outcomes; the drop service was not cloned.

| Check | Result |
|---|---|
| TimeReward + first Boss | TimeReward gave Owned Stone1 / bag0. Actual first Boss gave bag Stone1 / visible1/5 while Owned Stone stayed1. Return changed Owned Stone to2 / bag0. |
| Normal Coal after reload | Bag Coal1 / visible1/5; Owned Coal remained0 before return. First guarantee stayed consumed. |
| Mixed capacity | Coal2 + Stone1 + Item2 occupied5/5; actual pixels inspected. Both further Item and Ore additions refused. Reusing an Ore Drop ID as an Item also refused. |
| Atomic mixed return | Owned Item2, Stone3, Coal2 confirmed together; old run replay rejected. |
| Lost Grant response | Durable Stone advanced3→4 once while live confirmation remained pending. Normal return retry reconciled to4 and cleared the bag, with no duplicate. |
| Unbanked death | New Coal in bag disappeared on actual death; banked Stone4 / Coal2 remained. Memory reload preserved those counts and consumed first flag. |
| Actual /resetdata path | Fresh first flag and empty inventory restored in isolated stores. Actual first defeat produced Stone in bag only; actual1/5 pixels inspected. Death lost it, and save/reload did not revive eligibility. Next native defeat followed normal Item selection and returned Item1, Ore0. |
| Notifications/dedup | Server grant snapshots, client notifications, overhead icons/points and bag text correlated by Drop ID. Every repeated defeat notification returned AlreadyProcessed. |
| Pure transaction checks | 20 focused checks: mixed/Ore-only/legacy returns, pending recovery, cancellation, terminal grants, delta mismatch, overflow atomicity, first-delivery normalization/full bag/legacy migration. |
| Existing Item-return regression | All18 existing RunReturnPhase5F cases passed with the current modules, including ownership transfer and ambiguous writes. |

Representative IDs: first bag Stone `3615dd64-441c-4f44-8957-fa740e05cceb`; normal Coal `5b488034-d1ad-48af-b07a-c108e2a0d556`; post-reset first Stone `19878c5e-b8dd-45b1-a7eb-1dd8042b3b82`; post-death normal Item `88dd314f-c177-43bb-8375-ae10adf1e0f4`.

Fixtures: tests/BattleBagOre.server.luau and .client.luau (temporary __OBQA memory adapters/instrumentation), plus BattleBagOre.spec.luau (pure modules); existing RunReturnPhase5F.spec.luau retained unchanged.

## Limits and final state

Not tested: live production datastore/rejoin, actual network disconnect during return, real two-client simultaneous play, or a complete Trophy-stage run. Trophy reuses the modified bank; its connection was inspected, while native travel verification used Back. Reloads and failure injection above were memory tests, not production persistence.

Expected badge-stub warnings only; no remaining task-related runtime errors. Temporary captures inspected and not committed per AGENTS.md. No OS input, window/camera/device changes, real payment, Save/Publish, rbxl writes or Studio exit.

Stopped Play and removed all __OBQA helpers/dependency substitutions. Verified475 Source/Enabled baselines and74 SoundIds, preserving the new seven Sources and prior edits. Canonical Studio is **unsaved Edit**; user manual Save/Publish is required.
