# Studio normal-Egg purchases during level tests — 2026-10-22

## Result and scope

Normal Win Eggs now work while the actual Studio level-test override remains active. The existing purchase validation, server rolls, unique copy IDs, mutation rules, hatch presentation, Inventory, equipment, follower, and Strength calculation are reused. Normal play keeps its durable mutation path. Limited Egg grants/receipts remain protected during an override; no paid purchase is acknowledged through the temporary branch.

The input was the current `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, SHA256 `4dda6dc2181bba4ef4e9b9d0a5411a80262712e9c1fa63717312ab64493e16b9`. Read AGENTS, the current relevant Sources, `StudioEggOverrideInvestigation_20261021.md`, and `PetInventory_20261021/README.md`. The file's relevant Sources matched the current mirrors before this change. The unrelated dirty documentation, BossChaseService mirror, and untracked files were left untouched.

## Cause and implementation

`PlayerDataService.MutatePets` previously allowed only temporary Equip operations under `StudioStartOverride`. Normal Egg requests passed the regular checks but Hatch was rejected with `StudioOverrideActive`.

Changed Full Paths:

- `ServerScriptService.Services.PlayerDataService`: On the first level override, retain the original profile and dirty state and deeply copy the active profile. Repeated level commands reuse this original restore source. Hatch and Equip share the normal operation validation and `Pet.ApplyOperation`; only the commit step branches. Temporary commits debit the copied Win and update the copied owned/equipped state without a persistent pending mutation or store update. Reset restores the original profile and republishes attributes/Pets. Existing Studio Save and Limited grant guards remain.
- `StarterPlayer.StarterPlayerScripts.Services.PetClient`: Retire pending requests when the Pet-view generation changes; reject late responses from retired views. Old retries cannot clear a newer request's pending flag or start a stale hatch.
- `StarterPlayer.StarterPlayerScripts.Services.HatchClient`: Cancel the active/queued normal-Egg reveals when a view is retired. Preserve committed Limited reveal handling and paid-notice deduplication.

No pricing, pool, Pet IDs/models/effects, World rules, equipment count, map, Boss, Merge, or UI-design changes. ResetWorld2ArrivalOnStudioPlay was unchanged. There is no Pet ownership-count cap in the current normal-Egg implementation: InventoryCapacity is the battle collection capacity. No new cap or balance rule was invented; the existing one-equipped-Pet limit remains.

## Actual Studio operations

Ran an owned local Studio session against the current file, with temporary in-memory DataStore/ordered-store adapters and blocked purchase/badge adapters. No live datastore, live player grant, real Robux payment, Save, or Publish was used. Only the test setup supplied Win, unlock state, and a comparison Dog; authoritative Egg purchase, mutation, equipment, follower, reset, and respawn code were not replaced. A wrapper observed the real EggServer request handler; one test held its response after commit to simulate a late network reply.

Commands were sent through `TextChannel:SendAsync`, invoking the real TextChatCommand handler: `/test level 160`, `/test level 180`, `/test world 1`, `/test world 2`, and `/test reset`. The first level command really created the private StudioStartOverride; it was not manually cleared to purchase. Repeat level commands preserved generation 1 and the original restore source.

Native mouse clicks operated the purchase buttons, four hatch knocks, reveal dismissal, Pets menu, and individual Inventory cards. Studio's device simulator was returned to the default viewport for readable interaction and reset to default at completion. Temporary viewport screenshots were inspected and removed rather than committed.

### All normal Eggs: real UI Open 1 / 3 / 8

| World | Egg ID | Unit Win price | Purchased copies | Win consumed | Result |
|---|---|---:|---:|---:|---|
| 1 | Basic | 15 | 1 + 3 + 8 | 180 | Passed |
| 1 | Rare | 100 | 1 + 3 + 8 | 1,200 | Passed |
| 1 | Legendary | 300 | 1 + 3 + 8 | 3,600 | Passed |
| 1 | Mythic | 1,000 | 1 + 3 + 8 | 12,000 | Passed |
| 2 | W2_Basic | 1,000 | 1 + 3 + 8 | 12,000 | Passed |
| 2 | W2_Rare | 5,000 | 1 + 3 + 8 | 60,000 | Passed |
| 2 | W2_Legendary | 25,000 | 1 + 3 + 8 | 300,000 | Passed |
| 2 | W2_Mythic | 100,000 | 1 + 3 + 8 | 1,200,000 | Passed |

All 24 requests produced the requested result count, unique owned copies, completed hatch presentations, and updated Inventory cards. Total 96 added copies, 97 cards including the comparison Dog; Win went from 1,000,000,000 to 998,411,020 (cost 1,588,980). Store writes stayed at 2 throughout the matrix, repeat level command, equipment changes, death, and World travel. A separate capture of the original profile after override activation remained unchanged through these operations. The first fixture's earlier whole-profile comparison differed only because elapsed-time bookkeeping ran before override activation; it was not used as proof of corruption.

### Equipment, failures, and lifetime

- Real card clicks equipped the purchased W2 Alien (Pet_131 Viewport), showed the equipped checkmark and exactly one follower, and produced server multiplier 2.2. Exchanged it for a purchased World1 Grey Cat (1.02), unequipped (1.0), and equipped W2 Alien again. No store writes occurred.
- Set Humanoid.Health to zero in the fixture to invoke actual death/respawn; 97 copies, equipped ID, one follower and effect remained. Actual World commands round-tripped World2 → World1 → World2 with the same Win, owned/equipped copies, generation, and multiplier.
- Insufficient Win: real UI click made no grant/debit/hatch. Direct authoritative request separately returned NotEnoughWin with Win 0 and count 97 unchanged.
- Five consecutive real purchase-button clicks yielded one purchase only: cost 1,000, count 97 → 98. Direct retry of the accepted request ID returned AlreadyApplied without another debit or copy.
- Real reset during an active hatch restored Win 1,000,000,000, the original single Dog/equipped ID, Level 1, generation 2, one follower, no busy lock, and no hatch. The 98 temporary new copies were discarded.
- Started another real level test (generation 3); committed one UI purchase while its response was held. Reset then released that old response: generation 4 remained at the original Win/single Dog, no hatch, no pending client request. A direct old-generation request returned PetStateChanged with no mutation.

## Persistence checks — isolated, not production rejoin

Direct Save during override returned StudioRuntimeOverride and did not increase writes (2 → 2). Direct Limited grant API returned StudioOverrideActive with no write. Save plus session Release during a later override also left writes unchanged (3 → 3), despite a temporary extra purchased copy. This exercised the same Save guard used by autosave/exit/shutdown; a real server shutdown or real account rejoin was not claimed.

Ordinary UI purchases outside override used the original durable path and survived Release/Load against the memory store. The initial comparison Dog was only runtime fixture state, so a separate persistence check used exclusively Pets acquired and equipped through real normal-state UI operations. Two such purchased Dog copies were retained, one equipped, Win 999,999,970. Entering a fresh actual level test and purchasing again produced three copies/Win 999,999,955 while store writes remained 7. Actual reset restored two copies/Win 999,999,970 and the original equipped copy, Level 1 and effect 1.02, with no hatch/busy state and exactly one follower. Normal Save/Release then wrote the restored profile (7 → 8); memory-store Load returned exactly those two IDs, original equipment, and original Win. The temporary third copy was absent.

`Verification.json` records UI observations and isolated request/reload checks. The two first fixture setup attempts failed on fixture API usage (reading OnServerInvoke and omitting FireClient's player), were corrected before accepted tests, and were not counted as product passes. The accepted Play's filtered server/client log histories contained no non-asset runtime errors. Existing inaccessible sound assets emitted authorization errors; successful audio playback is not claimed.

## Writeback and remaining limits

The source-only writer `tools/write_studio_normal_egg_preview.py` refuses an unexpected input hash or old target Source, compiles all three changed Sources, edits only their Source rows, and validates every existing instance/parent/property. `Writeback.json` records 4,915,682 preserved/checked property values, exact re-decoded Source matches, and the output SHA256. No extra place/backup/copy/migration was created. All temporary adapters, fixtures, and test state stayed in the unsaved owned Studio session and are absent from the saved file.

Actual UI results, direct server requests, in-memory persistence, and unverified live behavior are distinguished above. Live payments, production datastore writes/rejoin, actual process-shutdown persistence, second-client interaction, and every rare roll's visuals were not exercised. No Pet ownership-cap rejection exists to test. No unrelated regression sweep was performed.

Completion: Play stopped; owned Studio sessions closed without Save/Publish; same-file native reload/Source comparison and final lock release are recorded in `Completion.json`.
