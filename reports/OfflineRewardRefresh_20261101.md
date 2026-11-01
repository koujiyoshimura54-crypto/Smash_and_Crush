# Offline reward replacement on login — 2026-11-01

## Cause and production change

Applied to the current canonical Studio, PlaceId `126576845524886`. The original `ServerScriptService.Services.StrengthRewardState.Acquire` appended a reward per ownership token but retained all old rewards; `NextReward` selected the oldest unpaid entry. Thus an old unclaimed reward took precedence over the new interval. Time was already measured from confirmed departure (`Presence.At`), not last claim. PlayerDataOwnership fixes the acquisition timestamp across retries; PlayerDataService records the departure reference/time and persists normal/closing presence under existing ownership fencing.

Only **ServerScriptService.Services.StrengthRewardState** changes in production:

- On a new acquisition token, remove old ordinary rewards. Preserve a reward record only if an existing DoubleOffline purchase intent still references it. Keep Pending, Receipts, fixed purchase amounts and GrantedTotal intact.
- Select only the current owner's reward for the UI. Same-token acquisition retries do not regenerate it. A zero/unconfirmed interval has no fallback to an older reward.
- Reject normal Claim and double Prepare/Open for a previous login's reward. An old Prepared/Cancelled intent cannot be resumed or rebound from the new popup.
- Keep the existing receipt calculation: an old pending purchase receives the amount remaining to reach twice its original reward, including when the normal half was already claimed. Its receipt journal prevents another grant.

The existing PlayerDataService/StrengthRewardPersistence grant path, sole ReceiptService dispatcher and StrengthRewardService price/quote logic are unchanged. Cap3600 seconds, efficiency0.05, reference calculation, product3724845103 and all three Strength packs are unchanged. No UI layout/style, Ore merge, Battle Bag or tutorial change.

An unresolved old double-product intent continues to reserve that product slot until its receipt/reconciliation resolves. A new double quote is refused rather than associating a delayed payment with the new reward. The current normal claim remains available. This preserves the existing conservative purchase association; it does not add a new purchase reconciliation system.

## Verification

Executed native Luau with current Sources and isolated clocks/stores: **226 assertions** (60 existing reward/persistence checks, 11 ownership checks, 155 new refresh/receipt checks). Updated two obsolete carry-forward expectations in existing tests; added `tests/OfflineRewardRefresh.spec.luau`.

Verified unclaimed30min→10min replacement (90,000→30,000 at rate1000), claimed→new reward, same-login repeated View/acquisition, stale-ID rejection, normal spam, zero interval and3600-second cap. Mock receipt dispatch used the actual StrengthRewardService Source with isolated Data/Players/Studio dependencies: old unpaid reward grants180,000, previously normally claimed reward grants the remaining90,000, current30,000 stays untouched, and old/new receipt retries grant nothing extra. Paid intent bindings and processed receipt IDs survive memory reload and pruning. Before-write failure and lost-save-acknowledgement retries preserve progression and avoid duplicate grants.

One additional isolated native Play used actual PlayerDataService.Load/Release, ownership, persistence, UI and StrengthRewards remote, with every discovered DataStore acquisition and badge call redirected to the existing memory fixture. A temporary ownership clock supplied synthetic join times; no hour-long wait. This was **memory reloading within one Play session**, not a real disconnect/rejoin or production persistence test. StudioStartOverride was false.

- Actual UI displayed `+30K STRENGTH` after replacing the old90,000; native capture was inspected transiently. Twelve client checks covered stable repeated View/redisplay, stale Claim rejection and repeated normal claims.
- Normal claim added exactly30,000: Strength0→30,000, Level1→28, LevelProgress0→2205, matching unchanged LevelProgression. Repeated claims added nothing.
- After another synthetic10-minute interval, a fresh reward was received: Strength30,000→60,000, Level28→33, progress2205→155. A zero-time reload then hid the popup and exposed no old reward.
- No real purchase, physical button/mouse/keyboard operation, published-server rejoin or live save was tested. Mock receipts were not sent to Roblox. Console showed existing unrelated asset authorization messages; no relevant runtime error was observed.

## Final state

The canonical connection disappeared during the initial audit and the user reopened it. Reconfirmed PlaceId and the same current Sources before applying the patch; the Ore minimum and Battle Bag font edits were present. No file/Studio was opened or closed by the agent.

Stopped the isolated Play, restored all8 temporary Source substitutions exactly, removed every helper, and verified11 guarded Sources including corrected OreMerge/MergeShopView, Battle Bag, reward client/service/config, HUD/layout/style and Strength reference. Camera CFrame/Focus/FOV/type and ShowDevelopmentGui match their pre-test values. Final reward Source compiles and matches Git. No new directory or retained screenshot.

**Studio remains open in Edit with these changes unsaved. No Save/Publish or rbxl writeback was performed; the user must save manually.**
