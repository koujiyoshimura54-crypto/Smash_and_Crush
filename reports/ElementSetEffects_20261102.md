# Item element sets and Best Equip — 2026-11-02

Applied to the currently open canonical Studio, PlaceId 126576845524886 / UniverseId 10765181857. The local rbxl Studio was not touched. Current Sources were read first and edited by exact matching fragments. The existing target files matched Git before this task; all unrelated unsaved work was retained.

## Changed Studio Full Paths

- ReplicatedStorage.Modules.ElementSetBonus
- ReplicatedStorage.Modules.StrengthCalculation (new pure arithmetic module)
- ServerScriptService.Services.ItemService
- ServerScriptService.Services.StrengthManager
- ServerScriptService.Services.StrengthReference
- ServerScriptService.World.BossCombatService
- ServerScriptService.MergeToForge.BossCombatService
- StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient
- StarterGui.StrengthGui.ItemInventoryTabClient

Sources mirror these paths in src, except the Stage01 adapter: [its exact Source](./ElementSet_ServerScriptService.MergeToForge.BossCombatService.luau) is recorded here without creating another directory.

## Behavior

The existing three owned, type-correct, same-element slots still establish a set, regardless of rank/World. ElementSetBonus.GetEffects resolves base config effects and multiplies only Protein, Glove bonus and Belt addition by 1.5. It does not mutate config or equipment. Both Worlds/all ten ranks and mixed rarities use this path.

StrengthCalculation.Gain is shared by live StrengthManager gains and StrengthReference rates. The old final Element multiplier was removed from both. Treadmill multiplier is still machine + effective Belt + temporary Training potion; walking retains its existing different inputs. Reference.Get excludes temporary potions. Best Equip captures a fixed context including current temporary potions and compares the same training equation at eligible equipment. CurrentWorld/equipment are never temporarily changed.

Best Equip evaluates combinations of owned/equippable Items, pruned to the strongest base effect per type/element (monotonic effects make weaker same-element choices dominated). Duplicate counts add no candidates. It ranks training rate, Boss bonus, then smallest change from current equipment. At current config this needs at most 27 combinations. EquipItem retains validation and dirty tracking.

Both Boss implementations now refresh only effective Glove when obtaining/attacking an unfinished encounter, so a removed set stops affecting the next hit. Encounter Strength remains the existing snapshot. No attack range, chase, timing, contact, targeting or Auto conditions changed.

Equipped Inventory cards and HUD use effective effects; unequipped cards keep base effects. The existing badge says "Item ×1.5". HUD formatting retains the fractional 0.375 Belt addition. Fonts, positions, stars, ordering and World visibility are unchanged.

## Measured examples

- W1 Uncommon Protein 15 -> 22.5, Common Glove 5% -> 7.5%, Common Belt 0.25 -> 0.375.
- With base gain 1 and treadmill multiplier 2, no other bonuses: old full-set result (1+15)*(2+0.25)*1.5 = 54 per tick; new result (1+22.5)*(2+0.375) = 55.8125. Actual Strength and LevelProgress increments matched 55.8125.
- Strength 100 with the Common set dealt 107.5 Boss damage. Swapping to the off-element Uncommon Glove removed the set and dealt 110, not an extra final 1.5 multiplier.
- Best Equip chose GLOVE_COMMON_FIRE (base +5%, effective +7.5%) over GLOVE_UNCOMMON_ICE (+10%) because it completed the set and improved training.
- W2 Rare set: Protein 1500, Glove +142.5%, Belt +7.5. Values survived actual character death/respawn.
- A committed mock pack retained its original 1234 quote; duplicate mock receipt granted zero. A saved departure rate of 1000 still produced 180000 for one hour. Product configuration and all receipt/offline transition Sources were untouched.

## Verification and limits

Two short solo Plays used the existing memory-only DataStore/Badge adapter across all seven current persistence consumers. No real payments or production save writes. Native server test: **72 assertions**, including all ranks, set on/off/repeated swaps, actual Strength/LevelProgress and Boss HP mutations, weaker-Glove set selection, no-set choices, missing slot, exact equipment tie retention, training tie/Boss preference, W2 reference history, potion exclusion, fixed quotes and duplicate receipts.

The updated StrengthReference isolated specification passed **13 assertions**, including rebirth/Premium access and retained W2 eligibility. This pure stub test was run in Edit, separately from native Play; it is not production persistence verification.

Actual existing WorldTravelRequest and ReturnWorld1 requests were exercised from their real triggers in isolated Play. Server effects and client HUD survived both directions. Character death/automatic respawn preserved the W2 set and its HUD. Inventory set-on/set-off render updates were observed. At the unchanged 720x405 viewport, screenshots showed W1/W2 HUD and equipped/base cards without visible loss; temporary captures were inspected, not committed. One Common Protein HUD TextFits diagnostic returned false while the complete "+1.5 STR" was visibly rendered. No layout/font adjustment was made. Other resolutions and live server/client network timing remain unverified.

The first QA client BindableFunction was removed by PlayerGui respawn; a subsequent query of that helper failed, then direct runtime inspection confirmed the actual persistent HUD. A second test helper attempted native Source access and was denied; the pure reference specification was rerun successfully using the permitted Edit reader. These were fixture/probe errors, not shipped runtime errors. World2 travel also emitted pre-existing asset permission errors (95256658378010,139190015780830,82687933211372,7221927873,119910397965139); their assets/settings were not changed. Badge failure was the intentional memory stub.

After each Play all substitutions were restored. Final verification checked **463 production Sources**, Enabled states and **74 SoundIds** against the pre-test manifest; no QA helpers remain. The latest registered audio IDs, tutorials, Aura/Eclipse, Ore merge and offline reward changes are retained. No Save, Publish, rbxl write, OS input, camera/window changes or Studio exit.

