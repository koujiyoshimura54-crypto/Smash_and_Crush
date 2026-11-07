# Dumbbell purchase notification filter — 2026-11-07

Canonical Studio: PlaceId126576845524886, loaded version463; started from live Edit and Git f5882b3. The target Source matched the checkout before editing. Existing edits were preserved.

## Change

Full Path: **StarterGui.StrengthGui.InventoryNotificationClient**.

The old notification candidate set copied server purchase eligibility without comparing equipment strength. It now additionally requires the candidate's `DumbbellItemMaster.StrengthBonus >= equipped.StrengthBonus`, using the equipped ID from the same loaded inventory response. No equipment means a zero bonus. Price, grade/number and total player Strength are not comparison inputs.

The filtered set feeds the existing purchase-card, Dumbbells-tab and Inventory-entry exposure logic. Equal/higher candidates retain existing seen and purchase eligibility rules. Normal and Best Equip acknowledgements already supply refreshed state; additional equipment/session/World2-arrival, character-added and GUI-enabled listeners request fresh state for the same filter. No seen-history bulk clearing was added. Item/Pet/Ore/Aura/Speed behavior, purchase/sale, ownership, equipment effects, world gating and styling were not changed.

## Focused isolated native Play

DataStore and external payment/service calls used temporary memory substitutes. Equipment requests used the actual client RemoteEvent and server normal/Best Equip controller. Inventories, Win and World2-visited state were isolated fixtures; no production player data or purchases were used.

| Case | Result |
|---|---|
| W1: equipped NORMAL_12 (+100), NORMAL_02 (+3) newly purchasable | Card, tab and Inventory Dumbbell reason all false; Inventory badge false when no other reason existed. |
| W1: normal equip NORMAL_01 (+1) | NORMAL_02 card/tab/Inventory notifications true. |
| W1: normal equip NORMAL_12, then repeat with Best Equip | Existing lower card/tab/Inventory reason cleared in both cases. |
| W2: equipped W2_NORMAL_12 (+3000), W2_NORMAL_02 (+900) purchasable | Lower notifications false, including affordable W1 candidates. |
| W2: normal equip W2_NORMAL_01 (+800), then strong normal/Best Equip | Upper notification appeared; both strong-equipment paths removed lower notifications. |
| Equal bonus | A direct presentation-state fixture kept an eligible equal-bonus candidate; naturally equipped/owned purchase exclusions are unchanged. |
| Other notifications | Unseen Item survived filtering and death; existing Aura availability kept Inventory's aggregate badge visible. |
| GUI disable/enable, close/reopen, death/respawn | Lower candidate stayed excluded after refreshed loaded state. |
| World2 locked | All12 World2 cards and their purchase badges remained hidden; W1 upper notification remained available. |

Actual desktop window images were inspected before/after W1 Best Equip: upper purchase badges were visible with +1 equipped; with +100 equipped, lower purchase and Dumbbells-tab badges disappeared while Item/Aura/Inventory badges remained. W2/lifecycle/locked cases were native property and state assertions, not separate image certifications. No physical mouse/keyboard input or device testing was performed. Existing unrelated asset authorization warnings remained; no relevant runtime errors were observed. Luau compile and Git whitespace checks passed.

## Cleanup and delivery

Restored39 service substitutions and removed the temporary notification probe/memory module. Final live audit:488 Sources,487 unchanged, exactly the notification Source changed; no helpers, Enabled differences, HTTP or Edit camera/focus changes. Play stopped and viewport returned to Edit. Temporary images were deleted.

Native Save to Roblox (`RBXMainWindow.savePlaceToRobloxAction`) was invoked for the existing canonical destination. Its transient success status was not captured during this phase. The Studio log records `StudioSavePlaceToCloud` completing in3755ms at2026-11-07 01:18:05 UTC.

The user subsequently reported accidentally closing Studio. After their reopened Studio reconnected, the canonical PlaceId126576845524886 loaded **version474**. Direct source comparisons confirmed the notification fix and all21 preceding LootUX sources exactly match their intended shipping contents; all488 Sources are present and no isolation/probe markers remain. Thus the saved cloud contents were verified by reopening, without replaying edits, reverting Git or loading an old recovery file. This verifies the scoped Sources; it is not a fresh audit of every unrelated authored property. The reopened Studio is stopped in Edit. No Publish, rbxl writeback or agent-initiated Studio close was performed.

Delivery uses a normal commit/push to origin/main, excluding the pre-existing untracked Visual_Templates report. The final response identifies the delivered commit.
