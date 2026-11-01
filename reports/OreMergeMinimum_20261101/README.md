# Ore merge minimum correction — 2026-11-01

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
