# Strength rewards and HUD — 2026-10-31

Implemented in the unsaved Edit DataModel opened from `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. The original connected Studio was a Cloud session: its log recorded DownloadPlaceCopy, not an EditFile open. Its 18 relevant Sources matched the downloaded file. A separate Studio process (PID 10532) was opened with EditFile for the exact requested file; the original Cloud Studio (PID 16548) was left untouched. No GUI/OS input, camera change, Studio Save/Publish, place-file writeback or Studio shutdown was performed.

The original checkout had unrelated modified documents/BossChaseService and untracked files and was 21 commits behind remote main. Those files were preserved. This work used `C:\Users\kouji\SmashStrengthRewards`, based on `6a68a4c`.

## Current approved settings

Only `ReplicatedStorage.Config.StrengthRewardConfig` owns these settings. Offline cap: **3,600 seconds**, efficiency **0.05**, empty ordered decay bands. A rate of 1,000 for one hour produces 180,000; doubling produces a total of 360,000. Stored reward/quote amounts are immutable across configuration changes.

| Product | Product ID | Reference price | Reference seconds |
| --- | ---: | ---: | ---: |
| Small Strength Pack | 3724835102 | 19 | 120 |
| Medium Strength Pack | 3724835678 | 99 | 720 |
| Large Strength Pack | 3724836170 | 299 | 2400 |
| double offline reward | 3724845103 | 19 | — |

The client queries Marketplace product information. Reference prices never supply displayed prices. In the observed Play context the returned prices were **18 / 90 / 270**, and **18** for double offline. No checkout or actual charge was attempted.

## Implementation and authoritative paths

- `ReplicatedStorage.Config.StrengthRewardConfig` — all four products, offline cap/efficiency/decay.
- `ServerScriptService.Services.StrengthReference` — pure reference selector, no attribute/equipment mutation or grant.
- `ServerScriptService.Services.StrengthRewardState` — validated, copied offline/quote/receipt state and pure transitions.
- `ServerScriptService.Services.StrengthRewardPersistence` — existing owned PlayerData transaction adapter, retained ambiguous writes, exact delta application and LevelProgression.
- `ServerScriptService.Services.StrengthRewardService` — server quotes, two-step quote/display/prompt handshake, authenticated cancellation and receipt delivery.
- `ServerScriptService.Services.PlayerDataService` — schema normalization, existing mutation barrier/retry integration, departure snapshot, Studio preview protection.
- `ServerScriptService.Services.PlayerDataOwnership` — offline interval consumption in the same ownership acquisition write.
- `ServerScriptService.Services.GamePassService` — defer two cache cleanups until synchronous departure snapshot readers finish.
- `ServerScriptService.Systems.Controllers.PlayerDataController` — departure/shutdown hooks and reward endpoint bootstrap.
- `ServerScriptService.Systems.Purchases.ReceiptService` — dispatch four products within the existing sole ProcessReceipt implementation; existing Limited Egg and other branches retained.
- `ReplicatedStorage.Modules.StrengthRewardUI` — purchased material GUI construction and idempotent event binding.
- `ReplicatedStorage.Modules.HUDLayout` — sole HP/level/packs placement owner and popup scaling.
- `StarterGui.StrengthGui.StrengthRewardClient` — price lookup, claims/checkout handshake and Humanoid health binding.

Authored GUI roots: `StarterGui.StrengthGui.OfflineRewards`, `StarterGui.StrengthGui.StrengthLevelHUD.PlayerHealth`, and `StarterGui.StrengthGui.StrengthLevelHUD.StrengthPacks`. The builder is the reproducible source for these native instances. It reuses OfflineEarnings materials and HUDLayout.PurchaseButton's RestockShop.Main.Common.BuyRobux skin. The image reference was viewed directly; it is not pasted as a background. No elapsed time, efficiency, cap or formula text is displayed.

No independent Player HP GUI or health updater existed in the inspected Sources/StarterGui. The existing HP display was Roblox CoreGui. Its one replacement reads the same Humanoid, disables only CoreGui Health, and reconnects on respawn. No new gameplay health system was introduced.

Reference formula: `(Training.BaseGain + Dumbbell + Aura + Protein) * (Treadmill.Multiplier + Belt) * Rebirth * VIP * ElementSet * Pet / TrainingInterval`. Current interval remains 0.5. Current authoritative equipment getters are cross-world and derive item bonuses from each item's own WorldId. Candidate equipment is evaluated per candidate World without altering CurrentWorld. World2 requires durable arrival plus unlock history. Premium candidates require verified entitlement; Strength balance, Level and temporary potions are absent from the calculation. Normal training/walking numerical rules are unchanged.

Confirmed departure timestamps/rates are saved by normal removal and BindToClose. Acquisition consumes that interval atomically before publishing Loaded. Existing unclaimed rewards form an ordered queue; they are never overwritten. Reward/receipt markers, Strength and LV progression are written together. The existing pending mutation barrier prevents a stale normal save from erasing an ambiguous grant.

## Verification actually performed

- 60 isolated fake-clock/state/persistence assertions: current cap/efficiency, zero/short/over-cap intervals, first/legacy state, unclaimed retention, repeated acquisition, simultaneous/stale-online sessions, normal/spam claims, double/normal races, duplicate receipts, immutable quotes after configuration change, cancellation, prompt resume, all three packs, LV progress, malformed state, and commit-then-response-loss retries with concurrent training.
- 13 isolated reference assertions: normal/rebirth/premium access, World2 arrival retained in World1, unlock without arrival, equipment multipliers, balance/potion independence and no player mutation.
- 11 ownership/store assertions: failed read writes nothing, same acquisition retry, session fencing and no duplicate interval after ownership changes.
- All 13 changed Sources compiled using native Studio Luau. Final Edit Sources matched the recorded source fingerprints; temporary adapters and test objects were absent.
- Two actual local Plays used temporary in-memory PlayerData and disabled ranking writes. Test Sources were removed after each run; the existing Studio preview guard is retained in production Source. No production data was changed.
- A temporary ordinary server Script, running in the game's execution context, verified normal +180,000; repeated claim +0; packs +240/+1,440/+4,800 at reference rate 2; LV39/progress22575 after those grants; double/normal race total +360,000; duplicate +0; memory save/reload and duplicate receipt after reload +0.
- Client observed `+180K STRENGTH`, current Marketplace prices, HP damage/recovery, native HP disabled, and death/respawn returning to 100/100 with exactly one HP gauge, one pack row and one popup. Repeated Build returns the same roots.
- At 1280x715 the measured HP/level/pack rectangles were `(253,486,772,28)`, `(253,518,772,38)`, `(253,560,772,64)`; no mutual overlap. The 700x450 popup was at `(290,74.5)`. Relevant runtime error output was empty; existing restricted audio warnings remained.

## Explicit limits / conservative recovery

- Actual Robux payment, production DataStore persistence/rejoin and two real simultaneous clients were not tested. Receipt/state tests were simulated; they are not actual payment evidence. Studio checkout and live receipt grants for these products are disabled.
- A receipt without a matching durable intent, or from a different purchase Place, returns NotProcessedYet with a reconciliation warning. It is never marked paid with zero benefit. There is no operator reconciliation UI in this change.
- Roblox does not provide the locally generated quote ID in ProcessReceipt. A cancelled quote is therefore retained and resumed with its original amount, never replaced by a newer quote for that product. If its offline reward has already been normally claimed, a further double checkout is conservatively blocked until that outstanding intent is reconciled; it cannot silently target a later reward. This is a functional limitation of the current fail-closed cancellation policy, not a verified complete cancellation-recovery workflow.
- An unclean server termination or an unconfirmed final departure save leaves the record Online. No offline interval is inferred from an expired heartbeat, because an older server might still be online. Normal disconnect/removal and graceful shutdown use the exact departure path; crash recovery can forgo unproven offline earnings.
- Narrow-device rendering, native button activation through user input, and full visual fidelity remain unverified. GUI/OS input and viewport/camera changes were prohibited. The reused image asset reported IsLoaded=false in local Play; successful Strength-icon rendering is **not** claimed.
- The Edit before capture is retained as `Before.jpg`. After-capture requests did not complete in the separate hidden Studio; no synthetic image is presented as an actual comparison screenshot.

## Final state

Local-file Studio remains open in **Edit**, with changes held in memory and the popup hidden. Original Cloud Studio remains open and unchanged. No test fixture or temporary persistence override remains. The rbxl SHA256 remains `1951c12eb639703bd516dd925983f63a54ac3a701bb2c0ea6b4810fccb62d97a`.

The user must manually Save/Publish the edited local-file Studio. Git contains the implementation, tests, this English record and the acquired before image; Git does not save the Studio DataModel.
