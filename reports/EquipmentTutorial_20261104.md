# Equipment onboarding and Dumbbell Best Equip — 2026-11-04

Implemented in the current unsaved canonical Studio, PlaceId **126576845524886**, UniverseId **10765181857**. Current Studio Sources were the baseline; no old rbxl/Source replacement, new checkout, lock, Save or Publish was used.

## Behavior and persistence

- Phase 5: a banked, equip-capable Item enables Inventory → Items → the existing Item Best Equip. Ordinary individual equipment also completes. Provisional Battle Bag contents never enable it.
- Phase 6: the existing first successful Ore merge enables Inventory → Dumbbells → the new ordinary Dumbbell Best Equip. The normal merge still consumes/draws/grants. If the currently equipped owned Dumbbell is already optimal after the result, completion requires no extra operation and no downgrade.
- Both inherit the established Egg/Pet fresh/reset cohort. Missing new fields alone do **not** enroll ordinary legacy profiles. Already eligible fresh/reset profiles remain eligible. Existing valid self-equipment is recognized.
- One separate `EquipmentTutorial={Version=1,Eligible,ItemCompleted,DumbbellCompleted}` is normalized, published and saved through PlayerDataService. Equipment and completion are included in the same ordinary equipment save snapshot. Successful Ore transactions retain their existing journal/reset/ownership protections. Saves merge completion monotonically; reset establishes a new generation.
- There is no client completion remote or tutorial-specific reward/equip action. Server-owned inventories/equipment and confirmed merge progress decide completion. Stale generation-tagged equipment requests are rejected; old tagged UI snapshots are ignored.
- Presentation waits for the original floor guide, living current-World Lobby membership, data/control readiness and available presentation ownership. It pauses for competing screens, return/skip/combat, notifications and hatch/pending transactions. Closing dismisses until reopening/Lobby re-entry; newly qualifying inventory is not suppressed by an earlier unrelated close.
- The existing purchased renderer, white focus, broad dark shade, interpolation/clipping, pinned notification and coordinator are reused. Two small changes to Egg/PetMerge guides release hidden presentation ownership when the user opens the equipment Inventory; otherwise the new guide could wait forever. Their progression, equipment rules and hatch transaction ownership are unchanged.
- Dumbbell Best Equip compares actual finite master StrengthBonus values among valid owned types using the existing equip setter's eligibility. It selects one type, keeps current equipment on equal strength, and never buys/grants/sells/changes counts. Existing setter/save barriers and last-equipped-copy sale protection remain.
- Both Best Equip gradients read the current authored Dumbbell Equipped badge. Item surrounding headers/cards/tabs/fonts remain unchanged. The new Dumbbell button uses the existing purchased button renderer with one visible caption and the existing disabled/activation/SE rules. The large preview/+STR area is slightly re-spaced to fit it below the effect.

## Changed Full Paths

- `ReplicatedStorage.Modules.DumbbellEquipment`
- `ReplicatedStorage.Modules.EquipmentTutorialState`
- `ReplicatedStorage.Modules.EquipmentButtonStyle`
- `ReplicatedStorage.Modules.EquipmentTutorialGuide`
- `StarterPlayer.StarterPlayerScripts.Tutorial.EquipmentTutorialClient`
- `ServerScriptService.Services.PlayerDataService`
- `ServerScriptService.Services.ItemService`
- `ServerScriptService.Systems.Controllers.ItemController`
- `ServerScriptService.Services.DumbbellService`
- `ServerScriptService.Systems.Controllers.DumbbellController`
- `ReplicatedStorage.Modules.ForgeInventory`
- `ServerScriptService.Services.ForgePersistence`
- `ServerScriptService.Services.RunReturnPersistence`
- `StarterGui.StrengthGui.ItemInventoryTabClient`
- `ReplicatedStorage.Modules.DumbbellInventoryView`
- `StarterGui.StrengthGui.InventoryPanelClient`
- `ReplicatedStorage.Modules.EggPetTutorialGuide`
- `ReplicatedStorage.Modules.PetMergeTutorialGuide`

Authored objects:
- `StarterGui.ItemEquipTutorialGui`
- `StarterGui.DumbbellEquipTutorialGui`
- `StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells.Equipped.BestEquipButton`

Item's existing runtime target is `PlayerGui.StrengthGui.InventoryPanel.Content.Items.Equipped.EquipmentHeader.BestEquipButton`. Dumbbell's runtime target is `PlayerGui.StrengthGui.InventoryPanel.Content.Dumbbells.Equipped.BestEquipButton`. Both guides resolve these actual interactive controls, not their decorative text clones.

## Exact manual editing locations

Under **each** of `StarterGui.ItemEquipTutorialGui` and `StarterGui.DumbbellEquipTutorialGui`:

| Location | Editable item |
| --- | --- |
| `Messages.OpenInventory / ChooseTab / Equip / Complete` | StringValue.Value: short English instructions |
| `Canvas.Highlight.Outline` | Color, Thickness, Transparency, StrokeSizingMode |
| `Canvas.Highlight.Shadow` | Dark shade Color, Thickness, Transparency |
| `Canvas.Highlight.Corner` | CornerRadius |
| `Canvas.Highlight` Attributes | GuiGrow, PaddingX, PaddingY, MoveSeconds |
| `Canvas.Notification.Stack.Line.Message` | Authored notification FontFace/color/stroke |
| `Canvas.NotificationRegion` | Instruction band Position/Size |
| `Canvas.Notification` Attributes | ReferenceHeight, HeaderWidthScale, HeaderCenterX |
| root Attribute `CompletionSeconds` | Completion-notice duration |

Runtime only controls target geometry/visibility and notification animation. It does not recreate or reset these authored templates.
Shared Best Equip color source: `StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells.Equipped.EquippedBadge.UIGradient.Color`, read by `EquipmentButtonStyle`.
[Edit installer](../tools/InstallEquipmentTutorialGui.luau) clones the **current** approved Egg template only if each new template is absent. [Authored GUI properties](EquipmentTutorialGui_20261104.json) record the final hierarchy/settings; rerunning the installer preserved author edits.

## Focused verification

Three isolated native solo Play sessions after a short aborted fixture-setup attempt. All 39 DataStore/Marketplace/Badge/Policy/Messaging acquisition dependencies were redirected to a memory provider before Play. The existing reset command prints “Production reset” even though both its store handles were memory-backed. **No production writes or real purchases occurred.**

| Check | Evidence / outcome |
| --- | --- |
| Bag → bank | Existing RunInventory.TryAddDrop produced Bag1, OwnedItems empty, ItemReady=false. Existing RunReturnService.Request banked it, cleared Bag and set ItemReady=true; native guide targeted Inventory. |
| Phase 5 normal controls | Native Inventory open/tab/Best Equip callbacks used the existing ItemEquipRequest. Server returned BestEquipped, equipped Protein and recorded ItemCompleted. Actual white focus/green button/notification rendered. |
| Individual / failure | Unowned Glove returned NotOwned without completion. Owned Protein individual equip completed; a native client individual-equip callback also succeeded. |
| Phase 6 ordinary UI | Existing MergeShopView material method selected the same Stone card twice; selected count2/Evaluate valid. Existing SubmitItem → ForgeClient remote consumed Stone2, generated one NORMAL_01 and completed Ore. While results remained open, equipment guidance stayed paused. Closing Merge showed Inventory → Dumbbells → native Best Equip → server-confirmed completion. |
| Stronger equipment | NORMAL_01(+1) → owned NORMAL_06(+15). Counts unchanged; preview updated to +15 STR. Calling the existing server AddStrength with identical inputs yielded +2 before/+16 after. This gain check was an internal production-function call, **not** an OS/manual gameplay tap. |
| No downgrade / early self-equipment | Already equipped NORMAL_12(+100) remained equipped when the normal merge generated NORMAL_01. Both the previously self-equipped Item and post-merge optimal Dumbbell completed without redoing equipment. |
| Empty / rapid requests | Empty ownership returned NoDumbbells. A five-request burst yielded one AlreadyEquipped and four RateLimited results; no inventory change or extra completion. |
| Sale protection | Selling the equipped final NORMAL_06 returned EquippedLastCopy; count1 and Win0 remained. Existing sale algorithm unchanged. |
| Persistence / failure | Real Save/Release/Load against memory retained equipment and both completed states; no guide replay. Injected pre-write failure reported false; retry saved completion and equipment together. |
| Actual reset command | StudioDebugService.Execute(player,"/resetdata") cleared equipment/tutorial states and restored fresh eligibility. Token advanced. Old-token native Item and Dumbbell requests returned EquipmentStateChanged without completion. |
| Invalid merge | One Stone failed; no Ore completion/new equipment guide. Existing merge minimum/journal remain unchanged. |
| Legacy | Real memory load with missing EquipmentTutorial and excluded old cohort stayed ineligible, despite owned Items/Dumbbells. |
| Close / death / reopen | Close hid both pending equipment guides; reopen resumed one current step, the other waited. Actual Humanoid death/respawn retained progress and normal buttons; no duplicate guide/button. Return-busy paused both, clearing it resumed. |
| Existing guide arbitration | Egg GoToEgg retained ownership when an Item arrived: Item waited. Opening Inventory released hidden Egg ownership and showed Item Equip. Native PetMerge GoToMerge followed the same wait/handoff. Ore UI guidance remained active during the normal Stone merge. |
| Author changes | Edit-time growth1.24, outline.03, shadow.35 and custom instruction survived installer rerun/startup; Dumbbell step changes showed the custom text. Item instruction edits also survived tab changes with the final handoff fix. Exact approved defaults were restored afterward. |
| Pure selection/state | Twelve native Edit assertions passed, including real W1/W2 master effects, zero/no ownership, stable selection, malformed-state rejection and monotonic save. Distinct equal-strength types used a temporary cloned selector with a synthetic master because current real master values are unique; current-best retention was also checked in Play. |

Native callback drivers exercise real UI handlers/remotes, but are **not physical mouse/touch input**. Initial memory reloads did not advance the Pet client's generation, so Egg showed Loading; these were not arbitration evidence. The final fixture advanced the generation and verified actual Egg and PetMerge ownership/handoff. A syntax error in the first temporary callback-instrumentation attempt was removed/restored before continuing; it was not a shipped Source error.

## Actual rendering versus limits

Inspected native captures of:
- normal-width Item Best Equip focus and single green caption;
- normal-width Dumbbell showcase, retained Equipped status/icon/+STR, separate green Best Equip;
- narrow Item and Dumbbell regions with aligned focus, readable single captions and no overlap with Equipped;
- notification/white outline/dark shade on the current map.

The native viewport was 1279×720 (inset GUI1279×662); capture output was tool-scaled. Narrow tests used an in-game reserved UI region, yielding approximately 425×638 Item /470×638 Dumbbell panels. **No device-preview, camera or OS window changes.** This is not a physical-phone test. Native hit inspection put the actual Best Equip button first among interactive targets; no tutorial overlay intercepted it. Screenshot files are not retained per AGENTS.md.

Not verified: physical input, real public-server save/rejoin, real purchases, multi-client play, every possible screen resolution. No new Japanese fallback-font change. Existing Egg/Pet hatch/equipment gameplay was not re-run end-to-end; their unchanged transaction paths and focused presentation handoff were checked.

## Final integrity

All **18 changed/new Sources** compile and match the Git exports after newline normalization. Cleanup restored/verified **483 Sources and 74 SoundIds** and removed all QA helpers. No gameplay tuning, Item Best Equip scoring, inventory counts, reward prices, walking gate, Battle Bag rules or Boss collision code was changed. Studio is stopped, viewport focus is **Edit**, and current edits remain **unsaved**. User manual Save/Publish is required.
