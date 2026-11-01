# Item Inventory and Merge presentation — 2026-11-01

## Authority and scope

Applied to the current unsaved canonical Studio, PlaceId **126576845524886**, studio instance `4e51dbeb-39a3-432d-a14b-4ae954c573f5`. The other local-file Studio was not touched. Repository baseline: `912d51cbc71e308023ab651113a81b71012a5acf`. Target live Sources matched the current checkout before editing; guarded line changes were applied to that live state, not a historical Source/rbxl replacement.

The current normal Inventory sorted Item kind before World. Merge already sorted by global rank, element and kind; that ordering was retained. Both views previously relied on World2 arrival for visibility. Normal Inventory displayed World2 local rarity; Merge used one star plus a number for ranks above5. Existing five Inventory rarity filters remain: each filter includes its World1 rank and corresponding World2 rank+5, ordered by World and then element/kind. No new tabs or All filter were introduced.

## Changed Full Paths

| Full Path | Change |
| --- | --- |
| `ReplicatedStorage.Modules.InventoryPresentation` | Scoped common font helper; shared global-rank image stars and sizing. |
| `ReplicatedStorage.Modules.MergeShopView` | Clear-based card filtering, image stars, K/M text, exact numeric sale editing; existing arrival-based selection permission preserved. |
| `ReplicatedStorage.Modules.ResponsivePanels` | Item star rows delegate to shared one/two-row sizing. |
| `ServerScriptService.Services.ItemMergeService` | Includes authoritative `World1Cleared` in its existing state response. |
| `ServerScriptService.Services.PlayerDataService` | Permanent clear flag, validated legacy migration, existing session/save integration. |
| `ServerScriptService.World.StageManager` | Marks the flag on successful World1 Stage10 completion. |
| `StarterGui.StrengthGui.InventoryPanelClient` | Reapplies the scoped common font during existing text initialization/updates. |
| `StarterGui.StrengthGui.ItemInventoryTabClient` | Filters before card creation, World-first sorting, global image stars and clear-attribute refresh. |

Authored GUI property changes: **47 text descendants**, exclusively below `StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells` and `.Aura`, had `Font` set to `ReplicatedStorage.Config.StrengthHUDStyle.Font`. Position, size, text size, color, stroke, language and icons were retained. Runtime-generated text follows the same helper; the shared style itself was unchanged. The property operation is reproducible without rebuilding GUI:

```luau
local content = game.StarterGui.StrengthGui.InventoryPanel.Content
local font = require(game.ReplicatedStorage.Config.StrengthHUDStyle).Font
for _, page in {content.Dumbbells, content.Aura} do
    for _, object in page:GetDescendants() do
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            object.Font = font
        end
    end
end
```

## Completion and compatibility

- World1 Stage10's trusted server completion path sets `World1Cleared`, independently of trophy pickup or World2 arrival. The replicated attribute and ItemMerge state drive presentation.
- Existing saved `World1Cleared`, validated `HighestUnlockedWorld >= 2` or saved `World2Visited` retain/recover permanent completion. The historical `World1Complete` badge is checked server-side if needed, with session-identity guards and three attempts on lookup errors. Failed lookups never grant completion.
- The existing Studio arrival-preview reset affects effective arrival, not saved completion proof. No Strength, Level, current World or Item ownership heuristic is used.
- Save uses the existing ownership-fenced path and monotonically preserves true. Death/run reset/World return do not reset this field. No existing inventory or equipment is deleted when cards are hidden.
- **Intentional existing permission difference:** Item display unlocks at World1 completion, while W2 purchase and Item merge execution still require World2 arrival. Their rules, including mixed-World rejection, were not relaxed. Newly visible but arrival-locked Merge cards cannot be selected.

## Presentation boundaries

The existing gold `76134658177553` and grey `126441080731699` star images are reused. Rank is sourced from `ItemMergeConfig.GetRank`: five columns, one row for ranks1–5 and two rows for ranks6–10. Inventory cards/equipment and Merge material/input/result cards use the same helper. Existing unowned secret artwork remains; hidden W2 cards are omitted from the grid entirely.

Only Dumbbell/Aura content text follows the shared Fredoka font. Inventory top tabs, Item, Speed and Merge retain their existing fonts. No new font size is imposed. Merge uses the existing `NumberFormat.Format` for counts, points, totals and result values while retaining units and prefixes. The sale TextBox switches to its exact integer while focused; only that exact editing session is parsed. No K/M string enters a calculation, remote payload or saved record.

## Focused native verification

All Play sessions used the existing memory adapter from `tests/World1Ore/Memory.luau` with temporary DataStore/Badge substitutions and native server/client probes. All substitutions were removed afterward. The committed fixture files are test-only and require those adapters; do not install them in a production place. There were no real DataStore writes or purchases.

| Check | Observed result |
| --- | --- |
| Before completion | Inventory current filter:9 W1 cards,0 W2. Merge:45 W1 cards in15 full rows; no W2 placeholders or blank rows. |
| Completion before arrival | Actual server `StageManager.ClearStage` path at prepared Stage10 set completion while HighestUnlockedWorld remained1 and arrival false. Both Item views revealed W2. This was a prepared completion call, not a combat playthrough. |
| Ordering/stars | Inventory current filter:9 W1 followed by9 W2; three kinds grouped per element. Merge:90 cards,9 per global rank1–10.113 generated star rows matched their rank, including5/6/10 and Merge input/candidate rows. |
| Fonts |271 runtime Dumbbell and123 Aura texts used the shared font. Tab font hash was unchanged.227 out-of-scope text objects rejected the scoped helper and retained FontFace. |
| Format boundaries |999 →999;1000 →1K;1500 →1.5K;1000000 →1M. Actual Ore count labels showed all four cases. Pet fixture showed ×1K and2K pt without changing its GothamBlack font. |
| Sale exactness | Focus exposed the raw sale quantity; entering1500 and blurring showed1.5K. A real client request sold1500 ORE_003 for7500 Win, exactly matching raw state. |
| Ore merge | Actual client request consumed2 Stone,999→997, and produced one Dumbbell. The existing2–5 rule remained unchanged. |
| Item selection/merge | Select/remove/reselect worked. Actual request consumed2 PROTEIN_COMMON_FIRE,1500→1498, and added1 PROTEIN_UNCOMMON_FIRE,1500→1501. Total Item quantity fell by1; display remained abbreviated and raw quantities exact. |
| Persistence/migration | Clear-only save/release/load remained true before trophy/arrival. Legacy gate, saved arrival and mocked completion-badge proof all migrated. Missing proof remained false. These are memory reloads, not production rejoins. |
| Lifecycle | Native Humanoid death/autorespawn retained completion. Run reset and fixture CurrentWorld2→1 retained it. Actual gate travel was not repeated. |
| Repeated UI lifecycle | Final focused Play:8 open/close/tab cycles and5 rarity changes passed. No error followed the final test START/PASS markers. |

The initial inventory fixture seeded session tables only; normal Save correctly retained transaction-owned durable inventory, so early sale/merge probes returned NotEnoughOres. The fixture was corrected to seed the memory store explicitly; the exact successful transactions above were then repeated. An initial grid assertion assumed fractional row heights; the engine-rounded149/150px stride was verified instead. Neither required a gameplay change.

Testing also found a real deferred star-layout callback after a card was destroyed. Added parent/grid guards and disconnected the size listener on destruction. The final short Play repeated the affected lifecycle without recurrence. Pre-existing sound asset authorization warnings were not changed.

## Actual rendered evidence

All captures below are original **1059×596** native images, not stretched, composited or AI-generated. Before/after columns use the same capture resolution; fixture numbers and tab selection are intentional differences. Images are retained at the user's explicit request.

| View | Before | After |
| --- | --- | --- |
| Normal Item Inventory | [Before](InventoryUI2_before_items.png) | [After](InventoryUI2_after_items.png) |
| Merge Item | [Before](InventoryUI2_before_merge.png) | [After](InventoryUI2_after_merge.png) |

- [Inventory rank10](InventoryUI2_item_rank10.png), [Merge rank6 and result/input](InventoryUI2_merge_rank6.png), [Ore counts and sale amount](InventoryUI2_merge_numbers.png).
- [Dumbbell font](InventoryUI2_dumbbell_font.png), [Aura font](InventoryUI2_aura_font.png).
- [Narrow Item views](InventoryUI2_narrow_items.png), [narrow Pet numbers](InventoryUI2_narrow_pet.png): actual engine rendering in temporary460×560 host regions, without changing OS display, camera or Studio emulation settings. The final Inventory panel measured357×536. Two-row stars, counts and text were inspected in these mounts. This is not physical-device testing. Pet/egg artwork was blank in the isolated mock; Pet artwork and a real Pet merge were not verified.

## Final state and limitations

Production save/rejoin, physical input, actual device emulation and live BadgeService outcomes were not tested. Programmatic native client actions verified routing/state, not OS clicks. No full Stage playthrough or unrelated regression was performed.

Final eight Sources matched repository files and compiled in Edit. Eleven protected Sources remained byte-identical: OreMerge, ItemMergeConfig, TimeRewardConfig/Service, EnemyDropGachaService, StrengthRewardState, StrengthHUDStyle, HUDLayout, RunInventoryHUDClient and both current tutorial clients. Test helpers and substitutions were removed. The canonical Studio is stopped in **Edit with unsaved changes**. No Save, Publish, rbxl write or Studio exit was performed. The owner must manually Save/Publish.
