# Stone introduction rewards — 2026-11-01

Applied scoped changes to the current unsaved Edit document for PlaceId 126576845524886 (GameId 10765181857). The separate local-file Studio was not edited. No new checkout or directory, Save, Publish, rbxl write, OS input, camera/display change, or user Studio shutdown was used.

## Audited current behavior and migration decision

The live TimeRewardConfig had nine slots. Reward06 was normal-training-equivalent Strength for 15 seconds; Reward02 was a distinct 60-second Training Potion. Existing claims are keyed by reward ID and unioned on save; elapsed online time is persisted independently.

Keep Reward01–05 IDs attached to their original contents and move their ClaimOrder to slots 2–6. Retire Reward06 without deleting its historical claim flag. StoneIntro01 is a new independent claim. Do not shift numerical flags or reset elapsed time. Existing owners can claim the new TimeReward Stone once when eligible; moving an old reward never makes it claimable again.

There was no reliable durable lifetime World1 Stage1 defeat field. Runtime Defeated is per-run; FirstSmash is not specific to World1 Stage1; tutorial completion also has a Stage2 fallback, and stage skips exist. The user explicitly chose to exclude existing records from the first-boss guarantee, including genuinely unbeaten existing players. Missing FirstStage1Reward on an existing record normalizes to Consumed=true; only a genuinely new record starts Consumed=false. Persist the versioned state on the existing PlayerData save path.

## Final schedule

| Slot | Seconds | Stable reward ID | Contents |
|---|---:|---|---|
| 1 | 60 | StoneIntro01 | Stone ×1, ORE_001 |
| 2 | 120 | Reward01 | Win ×1 |
| 3 | 300 | Reward02 | Training Potion, 60 seconds, existing +1 treadmill tier |
| 4 | 420 | Reward03 | Win ×3 |
| 5 | 600 | Reward04 | Strength Potion, 180 seconds, existing ×1.5 |
| 6 | 900 | Reward05 | Win ×10 |
| 7 | 1200 | Reward07 | Training Potion, 180 seconds, existing +1 treadmill tier |
| 8 | 1800 | Reward08 | Win ×25 |
| 9 | 2700 | Reward09 | Existing guaranteed Item roll ×10 |

Stone uses OreConfig's existing image rbxassetid://131452437678251 and grants OwnedOres. All thresholds, slot count, retained quantities, potion effects and durations remain unchanged.

## Applied Full Paths

- ReplicatedStorage.Config.TimeRewardConfig
- ReplicatedStorage.Modules.FirstStage1RewardState (new)
- ReplicatedStorage.Modules.ForgeInventory
- ServerScriptService.Services.PlayerDataService
- ServerScriptService.Services.ForgePersistence
- ServerScriptService.Services.EnemyDropGachaService
- ServerScriptService.Services.TimeRewardService
- StarterGui.StrengthGui.TimeRewardsClient
- StarterGui.StrengthGui.PotionStatusClient
- StarterGui.StrengthGui.TimeRewardsPanel.Holder.Reward01 through Reward09: only RewardName.Text and Decor.Icon.Image updated to the mapped contents.

TimeRewardsClient binds the existing authored Reward01–09 cards by ClaimOrder, while sending stable reward IDs. GetImage uses the Ore catalogue or existing TimeReward assets: Win 106494459783367, Potion 88132060004695, Items 73989013612789. PotionStatusClient now obtains its icon by reward content, so moving Strength Potion does not give its status row a Win icon. No fonts, positions, sizes, borders or other UI were changed.

## Transactions and drop behavior

TimeReward's existing atomic item mutation now supports the Ore result: the OwnedOres delta and Claimed[StoneIntro01] commit together. Retries reuse the mutation ID. ForgeInventoryRevision remains a monotonic inventory-refresh signal, including non-Forge TimeReward ore changes.

After the existing owner/run/stage/defeat gates, the first eligible World1 Stage1 kill replaces its normal result with Stone ×1. It does not add a second result. A synchronous session reservation prevents another first award before the save finishes; the ordinary save/exit path flushes it. The existing Forge journal commits FirstStage1Reward and the ore delta atomically. A queue resuming after the save already resolved its reservation recognizes the original defeat ID and does not grant again.

The existing W1 Ore path grants durable OwnedOres after the Battle Bag capacity checks; it does not insert a provisional Item into the bag. This behavior is retained. A full bag discards the first replacement and still consumes the lifetime first defeat. Ordinary provisional Items keep their existing return/death behavior. Other stages and World2 use their original draw paths. No new client-callable action was added.

## Verification

- Native StudioTestService run with two real clients, scripted combat and memory-only stores: 28 focused checks passed. Both players actually defeated their own Stage1 Boss through EnemyManager.TryManualAttack; first Stone and ownership independence passed.
- A fresh player claimed one TimeReward Stone, defeated Stage1 for the second, then used the existing Forge request to consume both Stones and generate exactly one Dumbbell. Replays did not add consumption or loot.
- Ordinary second-kill routing was checked with a private cloned drop service whose roller returned an Item deterministically. This was a simulated subsequent defeat, not a second natural combat roll.
- Memory save/reload retained first-defeat state and claimed TimeRewards. Moved Reward01 remained claimed; unclaimed Reward02 remained ready; retired Reward06 history and elapsed time remained intact. An existing saved record with its new field absent was correctly excluded.
- Injected lost write acknowledgements for both TimeReward and first-boss transactions. Retry and save-flush/queue-resume confirmed exactly one Stone each. Full bag discarded the replacement, consumed eligibility and retained that state after run invalidation and memory reload.
- Pure native module tests passed 5151 assertions, including all 512 legacy claim combinations, new/legacy migration, two independent profiles, atomic grant/discard, replay and serialized roundtrip. Existing Ore minimum regression passed 264 assertions.
- Short normal Studio Play: actual rendered nine-card order, countdown thresholds, Stone art and label were inspected at the existing viewport size. All reward labels reported TextFits=true. Sending the actual TimeRewardClaim RemoteEvent produced Stone ×1 received, CLAIMED, and exactly one OwnedOres. No physical mouse click was simulated.
- No new task-related runtime error was seen in the visual Play console. Existing unrelated sound-asset authorization warnings remained. The first harness attempt failed after a test-only reset without reacquiring its offline-reward session owner; the fixture was corrected to release/load its fresh memory profile. Production reset behavior was not changed.
- After stopping, restored all seven temporary DataStore/Badge substitutions, removed every __Stone helper and checked all nine final Sources. All nine card positions/sizes/order matched their pre-edit snapshots. Eight protected Source hashes matched: OreMerge, MergeShopView, StrengthRewardState, StrengthHUDStyle, HUDLayout, RunInventoryHUDClient and both current tutorial clients.

Not verified: production DataStore writes, published-server rejoin, server-process crash recovery, physical pointer interaction, or separate death/rebirth/World-travel cycles. Save/reload above is an in-memory DataStore/session reload, not a live production reconnect. Existing lifetime state is independent of those gameplay states; no tutorial migration was performed.

## Reproduction and completion

Fixtures are tests/World1Ore/StoneOnboarding.luau and StoneOnboarding.server.luau, using the existing Memory.luau. Before native testing, substitute all seven live DataStore/Badge dependencies with Memory, install the pure module as __StonePure and a private EnemyDropGachaService clone as __StoneNormalProbe (only its Roller returns a valid Item deterministically). Then ExecuteMultiplayerTestAsync(2,{}) runs the server harness and EndTest returns its report. These helpers are not shipped in Studio.

Screenshots were inspected transiently and not retained, per AGENTS.md. Final state: canonical Studio open in Edit with the user's previous edits and this implementation unsaved. Manual user Save/Publish is required.
