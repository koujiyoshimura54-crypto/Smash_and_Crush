# Ore merge minimum correction — 2026-11-01

**Application update:** the existing commit was applied to PlaceId `126576845524886` and verified in isolated Studio Play on November 1. Studio remains unsaved in Edit. The original repository-only record below is retained; see the appended application results.

## Scope and status

The user explicitly requested correcting Ore merge to **2–5 total units**, consistent with the existing Item/Pet minimum of two. The earlier 1–5 Ore rule was a specification mismatch. This correction supersedes that minimum in the October26 report and GAME_SPEC entry.

Repository implementation is based on main `3d2b35201e59353e98ab3b4b24fc9b0e3a79d01c`. This session has no Roblox Studio connection. **Studio, the local rbxl, and Cloud have not been changed.** Do not report this commit as applied to the user's running game. Preserve the user's current unsaved Studio edits when applying the two Source changes; do not replace them wholesale from an older snapshot.

## Production Source changes

- `ReplicatedStorage.Modules.OreMerge`: Minimum=2; Evaluate rejects a single unit with SelectAtLeastTwoOres. Maximum remains5. Selection remains usable for a single selected ore's points, single-ore sales, and signatures of previously committed requests.
- `ReplicatedStorage.Modules.MergeShopView`: merge eligibility uses Evaluate; sell eligibility continues using Selection(...,true). The hint reads the shared minimum/maximum and displays Select2–5 Ores. One selected ore retains its count/points but has no merge outcomes and cannot enable Merge.

ForgeService's existing request path and ForgeInventory's existing mutation path both call Evaluate before consuming materials or granting a new result. No new server-side quantity rule or client-only bypass is introduced. Existing committed transactions retain their acknowledgement/deduplication path.

One ore can still be sold. Sales retain their existing prices and no five-unit sale limit. Quantities count units, including two copies of the same ore. Points, outcome thresholds/probabilities, prices, drops, existing ownership and Item/Pet merge rules are unchanged. No tutorial is implemented or modified.

## Verification

Executed the production pure modules in Luau via luau-web1.5.1, with only environment/dependency fixtures (Color3 and the unrelated World2 catalog). The test is `tests/World1Ore/MinimumCount.luau`; it can also run against the real modules in Studio without accessing PlayerData/DataStores.

264 assertions passed: all16 available ores reject single-unit merging regardless of points; counts2–5 accept repeats and retain valid probabilities; two different ores work; zero/six/fractional/reserved/insufficient holdings reject; a rejected one-ore transaction leaves holdings/Win/journal unchanged; two-unit consumption grants one result; retries do not duplicate it; one-unit and over-five-unit sales preserve prices; previously committed single-unit transactions remain idempotent. Production modules, ForgeService and MergeShopView compiled with Luau.

This is **not Studio Play**, real UI input, a live RemoteFunction test, or a persistence test. The unchanged service call sites and UI gate were inspected, not driven in a live client. Legacy October26 fixtures encode historical balances and single-ore acceptance; the focused MinimumCount suite is the current regression for this correction. Historical evidence was not rewritten.

## Pending application

Apply only the two production Source diffs to the current Studio document, preserving current edits. Confirm one selected ore shows its points while Merge is disabled, and two through five enable Merge; verify single-ore sale. Stop any test and return to Edit. Save/Publish remains the user's manual operation.

## Studio application and focused verification — 2026-11-01

Confirmed the existing Edit session's PlaceId `126576845524886` and GameId `10765181857`. Fetched and fast-forwarded to `d19dce60e287f745c6e98c5ebdc42bd64d06830a`. Both current target Sources matched that commit's parent, so there was no conflict. Applied its four localized edits to the current Sources, with exact current-Source guards. Final `ReplicatedStorage.Modules.OreMerge` and `ReplicatedStorage.Modules.MergeShopView` match the existing commit and compile. No duplicate implementation commit or wholesale Source import was needed; tutorial, layout and gameplay tuning were not edited.

One isolated Play used the existing memory-store fixture for all discovered DataStore acquisitions and badge calls. Seven dependency Sources and one temporary UI inspection entrypoint were restored exactly after Stop. Real PlayerData/Forge persistence code executed against memory only, without the Studio start override. A temporary fixture seeded 20 Stone, 20 Coal, one Iron and 7 Win in that memory session. No saved player data was used or changed.

The focused MinimumCount suite passed **264 assertions** against native modules, including historical one-unit transaction acknowledgement. **48 additional assertions** passed through the real client UI methods and `Remotes.ForgeRequest`:

| Case | Observed result |
| --- | --- |
| One selected; two selected then remove one | Count and 5-point total retained at one; zero candidates, `Select 2–5 Ores`, Merge non-interactable. Two showed candidates and enabled Merge; removing one disabled it again. |
| New direct request with one / six / more than owned | `SelectAtLeastTwoOres` / `TooManyMaterials` / `NotEnoughOres`; Ore, dumbbells, Win and journal sequence unchanged. |
| Same Ore twice / two different Ores / five units | UI enabled; exactly 2 / 2 / 5 selected units consumed; exactly one dumbbell each; no Win charge. |
| Sell one / sell six | UI enabled; exactly 1 / 6 consumed; existing Stone price credited 1 / 6 Win; no dumbbell granted. |
| Replay each successful merge and sale | `AlreadyApplied`; no additional consumption, Win change or dumbbell grant. |
| Submit while only one is selected | No request effect; inventory, Win and journal unchanged. |

A native Play capture visibly confirmed `Selected: 1/5`, `Total: 5 pt`, an empty candidate area, the shared 2–5 hint and grey disabled Merge. Other cases were checked through native GUI properties and actual remotes, not physical clicks or drag input. The first UI assertion mistakenly expected a fixed 4 points; it was corrected to read the unchanged OreConfig (Stone is 5), then passed. No production formula was changed to satisfy that assertion. Console otherwise showed unrelated pre-existing asset authorization failures, with no Forge/UI runtime error observed.

Play stopped; all temporary Sources were restored, helpers removed, and final target Sources rechecked. Edit camera CFrame/Focus/FOV/type and ShowDevelopmentGui match their pre-test values. No OS input, window/view rearrangement, Studio open/close, Save/Publish, rbxl write, real payment or production persistence test occurred. Screenshot was inspected transiently, not retained. **Changes are unsaved in Studio; the user must manually Save/Publish.**
