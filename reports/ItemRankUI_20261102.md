# Common Item rank UI — 2026-11-02

Applied minimal edits to the current unsaved canonical Studio, PlaceId126576845524886. The four target Sources matched baseline `0ffccc2` before editing. The other local-file Studio was untouched. This supersedes only the previous Item presentation, not its permanent completion proof or execution rules.

| Changed Full Path | Change |
| --- | --- |
| `StarterGui.StrengthGui.ItemInventoryTabClient` | Removes W1/W2 effect prefixes; derives filters from global catalogue ranks; selects exactly one rank; hides inaccessible buttons/cards. Existing unseen-Item attributes drive each rank's badge. |
| `ReplicatedStorage.Modules.InventoryPresentation` | Shared high-rank presentation: one existing gold star plus `×rank`, including equipped slots; ranks1–5 retain their existing image slots. |
| `ReplicatedStorage.Modules.ResponsivePanels` | Rank buttons occupy up to two rows of five without reducing their height; additional catalogue ranks can scroll vertically. Only the Item list's top offset changes as necessary. |
| `ReplicatedStorage.Modules.MergeShopView` | Descending Item rank, retaining within-rank order and grouping. Mixed-material rejection text no longer refers to World; rejection itself is unchanged. |

Catalogue rank lookup remains `ItemMergeConfig.GetRank`. UI filters have no five/ten-rank hard limit. Permanent `World1Cleared` visibility and existing W2-arrival purchase/merge permissions are unchanged. No IDs, saved data, server services, config, probabilities, prices, effects, fonts outside the new rank label, Pet/Ore order, K/M formatter, rewards or tutorials were changed.

## Focused checks

Used the previous memory-only DataStore/Badge adapters and native client probes in two short **solo** Play sessions; no multiplayer session or production write. No OS mouse/keyboard, window, camera or display changes.

- Uncleared: Inventory rank1 showed9 cards and only5 filter buttons; Merge showed45 cards, highest visible rank5. No W2 placeholders were created.
- Clear before arrival: existing server completion path unlocked10 buttons. Filters1,6,10 each displayed exactly9 matching-rank cards. All10 buttons remained inside their parent and their labels passed TextFits at the current viewport.
- Merge unlocked:90 material cards,9 per rank, sorted10→1. Compared each rank's item order against the unchanged config grouping; all matched.
- Selection2→1→0, removal, clearing and three reopen cycles passed through the existing view methods. An actual isolated ItemEquipRequest equipped rank10; the equipped slot displayed the matching compact rank.
- Actual native renders inspected Inventory cards/equipment/filter buttons and Merge materials/input/candidates. The first render exposed tiny rank labels because setting TextWrapped=false disabled TextScaled. Corrected the assignment to wrapped/scaled short text and repeated Play. Final10 Inventory/equipment labels and48 Merge high-rank labels were readable and passed TextFits. No related runtime error followed the final START/PASS markers.
- Effects retained their names/values without World prefixes. No literal W1/W2/World1/World2 appeared in inspected Merge text. The initial selection test probe compared the human-readable Selected label to a number; corrected the probe to use its numeric attribute, then the sequence passed without a gameplay change.

Normal viewport rendered checks were performed; physical input, narrow-device emulation and production save/rejoin were not repeated. No transaction arithmetic or persistence change required their broader regression. Screenshots were inspected in the tool without adding image files.

Stopped Play, restored all9 temporary Source substitutions to their current pre-test versions and removed QA objects. Final four production Sources match the repository and compile. Studio remains open in **unsaved Edit**; no Save, Publish, rbxl write or Studio exit. The owner must manually Save/Publish. Only the ordinary solo test API was used; the toolbar's remembered test selector is not exposed by the current MCP and was not independently verified.
