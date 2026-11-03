# Dumbbell Lobby Strength correction — 2026-11-03

## Scope and cause

Canonical live Studio: PlaceId 126576845524886, UniverseId 10765181857. Started from its current unsaved Sources at Git base 2173c0e. The separate local-file Studio was not edited.

Changed Full Path: **ServerScriptService.Services.StrengthManager** (one production Source, two small edits).

The old AddStrength gate was `sourceMultiplier ~= nil`. TrainingManager supplies that argument for treadmills, but AutoTapService.AwardNormalTraining (manual taps and automatic walking ticks) does not. Consequently the equipped Dumbbell was omitted from normal Lobby gains. This historical condition predates the Item-set refactor; it was still present in the current live Source. Equipment ownership and bonus lookup were intact.

AddStrength now queries the existing server-only **ServerScriptService.Services.TrainingLobbyAreaService.IsInTrainingLobby(player)** at award time. It adds the raw equipped Dumbbell bonus only within the current World's authored TrainingArea.Floor footprint. This covers the inspected red-carpet paths and treadmill Areas; no bounds, zones, equipment state, or map objects were changed. Battle gains omit only this component. Returning restores it without an equip operation.

The formula and order are otherwise unchanged: (base amount + per-tick Dumbbell/Aura/Protein additions) × existing source, Rebirth, potion, VIP and Pet factors. Treadmill source multipliers still apply normally. No new award loop, input handling, or cadence was added.

## Native Play evidence

Two isolated StudioTestService multiplayer runs used two real test clients and the native server Script VM, not plugin-only module copies. All DataStore, Badge, Marketplace, Policy and Messaging dependencies were temporarily redirected to memory/stubs before startup; no live player data, real payments or production messaging were used.

Only fixture ownership/progression/position was prepared. Equipment changes used DumbbellService's existing equip/unequip APIs. Manual taps used the existing AutoTapRequest Remote from the client. Walking used programmatic Humanoid movement (16.4–22.0 studs per sample), with Auto ON and the unchanged TrainingController heartbeat awarding real gains. Treadmill ticks came from the native TrainingManager loop. A temporary wrapper observed StrengthManager.AddStrength arguments and actual server Strength differences; it did not alter the result. **No SetStrength or direct Strength assignment was used to manufacture gain results.**

Other additions were zero and all non-treadmill multipliers were one. Measurements below are per existing gain tick; every observed call and total server delta matched the independent expected arithmetic.

| World / condition | Equipped Dumbbell addition | Expected / measured Strength per tick |
|---|---:|---:|
| W1 Lobby, manual tap | none / NORMAL_01 +1 / NORMAL_02 +3 | 1 / 2 / 4 |
| W1 Lobby, real walking with Auto | none / +1 / +3 | 1 / 2 / 4 |
| W1 Normal01 treadmill, original ×1 | none / +1 / +3 | 1 / 2 / 4 |
| W1 red carpet / after treadmill / return / respawn | +3 | 4 |
| W1 Battle, manual tap away from combat contact | none / +1 / +3 | 1 / 1 / 1 |
| W2 Lobby, manual tap | none / W2_NORMAL_01 +800 / W2_NORMAL_02 +900 | 1 / 801 / 901 |
| W2 Lobby, real walking with Auto | none / +800 / +900 | 1 / 801 / 901 |
| W2 01 treadmill, original ×5 | none / +800 / +900 | 5 / 4,005 / 4,505 |
| W2 red carpet / after treadmill / return / respawn | +900 | 901 |
| W2 Battle, manual tap away from combat contact | none / +800 / +900 | 1 / 1 / 1 |
| Actual WorldTravelRequest W1 → W2 → W1 | NORMAL_02 +3 retained | 4 / 4 |
| Independent second real client, W1 | NORMAL_01 +1 | 2 |

Example raw sample totals: W2 walking with +900 awarded 1,802 across two native ticks; W2 treadmill with +900 awarded 9,010 across two ticks. Boarding therefore retained the same +900 base component, while the existing ×5 treadmill multiplied the complete gain.

Both Worlds passed equipment retention across actual Humanoid death/automatic respawn. Battle return used the existing LobbySpawnService placement, and inter-World travel used the real server-validated travel Remote. Changing/gaining on the first client left the second client's equipment and Strength unchanged; its independent manual gain was +2. Client StrengthGain notifications also reported actual committed deltas.

The first run passed nine cases. Two walking fixture cases initially waited for a nonexistent PlayerModule; the W2 treadmill fixture's anchored avatar changed body size as Strength increased, moving its feet out of the thin training zone. The fixture was corrected to use direct Humanoid input and hold its existing selected size tier at 1. Only those three affected cases were rerun, all passed. No gameplay changes were made to address these fixture conditions. The checked-in fixtures contain these corrections.

## Reference rates and preservation

StrengthReference, DumbbellService, GetNormalTrainingGain, AddRewardStrength and the shared arithmetic module are unchanged. Native checks confirmed the same equipped reference rate across carpet/treadmill/Battle locations, with the same durable World access. Thus purchase/offline prospective rates still include raw equipment independently of current location; already fixed rewards, pending purchases and receipts were not recalculated or touched.

Item/Pet/Aura/Rebirth values, each-Item ×1.5, Best Equip, treadmill settings, input intervals, combat, tutorials, SE and UI were preserved. Boss Ore Battle Bag changes from 2173c0e were preserved by the complete pre-test Source manifest.

## Verification limits and cleanup

- This was native isolated Play with programmatic movement/input, not OS input or a manual production session.
- No new screenshots/UI appearance assertions: this task changes server gains, not presentation.
- Normal walking with Auto OFF and stationary Auto behavior were not redesigned. Existing Auto policy remains unchanged.
- No broad regression of Boss battles, all body sizes, every treadmill tier, payments or production saving/rejoin. Existing asset authorization/not-found warnings appeared in the test console and were outside this task; no asset changes were made.
- Compile and exact live Source match passed. Temporary dependency patches and helpers were removed. All **475** pre-test Sources/Enabled states and **74** SoundIds matched the post-implementation baseline; no __DumbQA objects remain.
- Canonical Studio is back in **Edit with unsaved changes**. No Save, Publish, rbxl write, OS input, camera/device-preview change or user Studio shutdown was performed. The user must manually Save/Publish.

Fixtures: tests/DumbbellLobby.server.luau and tests/DumbbellLobby.client.luau. They are not installed in the final DataModel and require the memory-isolation harness to run safely.
