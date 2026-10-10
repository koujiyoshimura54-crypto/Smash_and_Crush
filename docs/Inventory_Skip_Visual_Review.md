# Inventory / Skip visual review — 2026-10-10

CurrentCloud was opened in Studio Edit. These are real Studio captures of the purchased UI; no generated images or replacement UI assets. Inventory cards use the existing renderers with in-memory display fixtures, with Remote writes/purchase prompts prohibited. They do not prove live ownership, purchasing, merge, saving or translation delivery.

| View | Actual capture |
|---|---|
| Dumbbells: equipped and selected card | [PC](Inventory_Dumbbells_Edit.jpg) |
| Items: sockets, rarity tabs, Equip / Equipped | [PC](Inventory_Items_Edit.jpg) |
| Merge: initial selection screen | [PC](Inventory_Merge_Edit.jpg) |
| Aura: purchased Win buttons | [PC](Inventory_Aura_Edit.jpg) |
| Speed: purchased Win / Robux artwork | [PC](Inventory_Speed_Edit.jpg) |
| Inventory: short landscape layout | [844×390 equivalent](Inventory_Mobile_Edit.jpg) |
| Inventory: Japanese text width sample | [844×390 equivalent](Inventory_Mobile_Japanese_Edit.jpg) |
| Skip: scroll end, Stage10 fully reachable | [PC](SkipStage_End_Edit.jpg) |
| Skip: Japanese text width sample | [844×390 equivalent](SkipStage_Mobile_Japanese_Edit.jpg) |

The screenshot canvas is 1280×720. Mobile captures apply the same layout to an 844×390 available area; these are viewport-equivalent checks, not physical-device or touch-emulator tests. Japanese headings/tabs in the width samples were assigned temporarily in Edit, then discarded. Production translations were not replaced. Some image assets were still loading in the early captures. Speed's Robux price remains `...` in the offline fixture because Marketplace price fetching is suppressed; the existing live fetching path is unchanged.

## Changes and donor

- Donor: `StarterGui.StrengthGui.ShopPanel`, its `Top`, `Top.Close`, and `MainScrollingFrame.Holder.Card01_SecretPack`. Reused their existing purchased artwork. Replaced the oversized header-relative panel stroke and red StarterPack stroke with the Shop border/neutral card stroke, sized for each surface. Kept the requested light purple/pink palette.
- Targets: `StarterGui.StrengthGui.InventoryPanel` and `StarterGui.StageSkipGui.Panel`. Removed the old title-icon overlap, yellow inner rim, excess rounding and redundant body studs. Kept the existing title/close/control paths. Header/tab/content spacing and Skip row margins now leave clear separation.
- Sources: `ReplicatedStorage.Modules.InventoryPresentation`, `ReplicatedStorage.Modules.ResponsivePanels`, `StarterGui.StrengthGui.InventoryPanelClient`. Inventory alone uses a shorter design in landscape viewports below500px high. Sockets clear the header, cards fit the available scroll window, and the equipped pane stays visible. Text-bearing surfaces no longer tint their own white lettering with the background gradient.
- Existing yellow Win / green Robux `PurchasedButtonVisual` objects and `HUDLayout` renderer retained. Saved Skip artwork now shows the actual buttons in Edit too. Price/ID/purchase/equip/merge/Skip/server/save logic and other screens were not changed. Current in-file Aura/Speed Sources already had purchased-button integration missing from the older canonical files; those current Sources were preserved, not replaced from Git.

## Verification and limits

- Fresh binary reDecode:180249 instances, dense/header/INST/PRNT valid,76129 instance-reference values,381 SharedStrings /206347 indexes, UniqueId duplicates0. No persisted instances added or removed. Exact row/chunk checks allow only895 target UI property values and3 Source values. All other properties/Sources remain unchanged, including Dance Girl, Pet/Egg, Map and gameplay.
- All3 changed Sources plus the Edit fixture compile. Exact final disk loaded in Studio Edit; all3 Sources were read back. Display fixture covered all5 tabs, reopen, Owned / Equipped,9 Robux item cards, selected color, old-color repaint guard and desktop restoration. Scroll endpoints checked for Dumbbells, Items, Aura and Skip. Final mobile layout assertions confirmed no socket/header overlap, complete item-card height and196px dumbbell cards, then310px on desktop.
- Unverified: Cloud126576845524886 deployment/runtime, real purchases/ownership/save, end-to-end merge selection/result, actual translation delivery, portrait devices and touch input. No claim of complete live-game visual validation.
- During the second verification session a tool unexpectedly reported Play mode and returned two gameplay images; this agent never invoked Start Play. The next state query and Edit readback were already Edit/PlaceId0. Those two images were excluded and not saved as evidence. No cause was inferred. No Stop call was issued because it had already returned to Edit. No Save/Publish or real purchase/data-changing command was issued.
- Only the three disposable verification Studios were closed. Final process and target `.lock` absent. No user Studio existed at preflight. No backup, alternate rbxl or work folder. Final file SHA256: `a2f7ec57940b48a08b46433c4c92c8c0fe69a153cec3e7ef2bcac3d4da3cf26a`.

Property provenance: [exact before/after values](Inventory_Skip_Visual_Refinement.json). Reproduction fixture: [InventorySkinEditPreview.luau](../tests/InventorySkinEditPreview.luau), for a disposable local Edit session only; never save that fixture session.
