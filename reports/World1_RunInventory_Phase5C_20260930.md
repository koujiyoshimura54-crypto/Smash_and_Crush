# World1 Run Inventory HUD — Phase 5C, 2026-09-30

## Scope

Baseline main and freshly fetched origin/main both resolved to `f1cc3a4666acfc1514fc3c57ffe66973f7a8137d` (ahead/behind 0/0). The existing untracked `reports/World1_Balance_Audit_20260916/build_report.md` was preserved and excluded from this change.

Studio Place: 101572058398926. Two implementation scripts only:

- `StarterGui.StrengthGui.RunInventoryHUDClient` (new LocalScript).
- `ReplicatedStorage.Modules.HUDLayout` (ten-line additive layout block).

The LocalScript creates `PlayerGui.StrengthGui.HUD.RunInventoryLabel` at runtime, beside the existing TopHUD layout region. It is a transparent, noninteractive TextLabel using the Level label's FontFace, white text and TextOutline. No GUI asset or Place file was saved/exported.

`Inventory <count> / <capacity>` reads only the server's `RunInventoryCount` and `RunInventoryCapacity`. Both AttributeChanged signals refresh the text immediately. There is no count polling, local quantity arithmetic, capacity validation, remote request, inventory access or client state mutation. Before initial replication only, missing values use `-` rather than inventing a capacity. Server initialization was observed as `Inventory 0 / 5`.

RunInventoryService publishes Count, Capacity, Id, WorldId and Active. Active does not hide or reset this HUD; it continues displaying server quantities. StrengthGui already has ResetOnSpawn=false. The label remains single across death, respawn and LoadCharacter; its attribute connections are disconnected on script destruction.

HUDLayout owns all added position, size and text-size values. Desktop/tablet place it at safe-area left padding and y=12, above Win. Compact landscape places it to the right of LeftHUD and below the Win row. The existing HUD regions' layout calculations are unchanged. The counter has no full-state colors, blink, button, panel, or FULL suffix.

## Current Play evidence

Tests ran in the actual Studio Play server/client. A temporary server Script required the live services and called the existing `EnemyDropGachaService.OnEnemyDefeated` entry point with server-owned confirmed-defeat fixtures. This was loot-to-HUD integration testing, not a full boss-combat replay. The real 20% roller and rarity definitions were not overridden. A temporary client LocalScript recorded label updates and the existing FULL result's visible state.

| Check | Observed result |
|---|---|
| Initial run | `Inventory 0 / 5` |
| Boss-drop acceptance 1–5 | Attempts 1, 7, 13, 16 and 21 produced `1 / 5`, `2 / 5`, `3 / 5`, `4 / 5`, `5 / 5`; the client recorded every transition |
| Sixth insertion | Existing TryAddDrop returned false / InventoryFull and count remained 5 |
| Existing FULL presentation | Continued real drop draws produced visible `RUN INVENTORY FULL`; the client simultaneously recorded `Inventory 5 / 5` |
| Death | Actual Humanoid.Health=0; client immediately observed `Inventory 0 / 5` |
| Automatic respawn | Health 100; count 0, capacity 5; HUD remained `0 / 5` |
| LoadCharacter | With three provisional items present, explicit LoadCharacter reset the HUD to `0 / 5` |
| Inactive | Server SetActive(false), count 0; label still visible as `0 / 5` |
| New run | After adding one provisional item, existing EnemyManager.StartRun reset to `0 / 5` |
| Future capacity notification | Server-side presentation fixtures set Capacity Attribute to 7 then 10; client displayed `3 / 7` then `3 / 10`, including on iPhone 7; service default remained 5 and normal lifecycle restored the attributes |
| Permanent / Equipped | Existing permanent ownership and equipment tables compared exactly equal throughout; their contents never contributed to the HUD |
| Duplicate HUD | Exactly one RunInventoryLabel after death, respawn, LoadCharacter and new-run checks |

The drop fixture completed after 28 calls. All test Scripts and temporary state existed only during Play and were absent after Stop. No permanent test items were added, equipped, removed or saved through a test command.

## Device verification

LandscapeSensor and StrengthGui's CoreUISafeInsets were preserved. Screenshots and live client rectangle/TextFits checks covered the devices below. Coordinates are in StrengthGui's safe-area space, below Roblox's reserved top area. All checks reported TextFits=true and no intersection with visible screen HUD labels/buttons, ReadyBadge or visible touch-control parts. Standard transparent DynamicThumbstick capture regions are not visual obstacles, matching the existing HUD policy.

| Device preset | Actual camera viewport | Inventory position | Label size | Text size |
|---|---|---|---|---|
| PC HD 1080 | 1918 × 1080 | 24, 12 | 220 × 28 | 22 |
| iPad Pro M5 13-inch | 1375 × 1031 | 24, 12 | 220 × 28 | 22 |
| Amazon Fire HD 10 | 959 × 598 | 19, 12 | 220 × 28 | 22 |
| iPhone 17 Pro | 749 × 361 | 153, 52 | 180 × 28 | 18 |
| iPhone 7 | 666 × 374 | 159, 52 | 180 × 28 | 18 |

Win, Level/Strength, left menu, right menu and touch controls remained readable. Drop roulette and item presentation were exercised concurrently. These are Studio Simulator checks, not physical-device tests.

## Regression and limits

All 499 original Studio script sources were fingerprinted before/after (length plus hash). Only HUDLayout changed; the other 498 originals matched. The new LocalScript was the only addition, with no original script removed. Both changed Studio sources were matched to the Git files after testing.

This verifies source preservation for RunInventoryService, EnemyDropGachaService/Client, EnemyDropRoller, ItemMaster, capacity/default/rejection rules, PlayerData/OwnedItems/EquippedItems, AutoSave, PlayerRemoving, World2, reward/shop/merge paths, Boss combat, Chase, damage, animations and VFX scripts. Death/reset and permanent/equipment preservation were also exercised in this Play. Full combat, World2 drops, autosave/exit persistence and every reward/purchase flow were not replayed in this UI phase; Phase 5B's separate evidence remains in its report.

No error from the new HUD or modified HUDLayout was observed. Console still contains existing unused-reference-model issues: TungTungSahur.Script nil Chatted, LaGrandeWalkPreviewController waiting for Walk_LaGrandeCombinasion, and Tralalero/Ballerina controllers waiting for Brainro_pack_3. They were not modified.

Final state: Play stopped, Edit verified, Device Simulator stopped and normal viewport restored. No Place save, GUI save/export or Publish. No Return button, banking, capacity purchase, detailed inventory, exchange/discard, or World2-specific Run Inventory was added.
