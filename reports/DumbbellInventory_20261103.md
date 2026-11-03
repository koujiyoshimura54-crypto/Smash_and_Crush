# Dumbbell inventory and sale UI — 2026-11-03

## Live scope

Implemented in the current unsaved canonical Y01 Studio, PlaceId126576845524886. Current live Sources were read first; no older Git/rbxl replacement. Other Inventory content pages, economy/master values, sale authority, data format, recent Dumbbell gain/Battle Bag/Auto/Boss changes remain unchanged.

| Changed Full Path | Purpose |
|---|---|
| StarterGui.StrengthGui.InventoryPanelClient | Existing authoritative inventory/purchase/equip state and Forge transaction path now drive the measured view and one sale panel; remove inline quantity inputs. |
| ReplicatedStorage.Modules.DumbbellInventoryView | Dumbbells-only surfaces, equipped preview, card geometry, count badges, sale panel, pointer and event-driven following. |
| ReplicatedStorage.Modules.InventoryPresentation | Delegate the Dumbbells shell layout and skip its obsolete equipped geometry; restore existing shared shell styling on other tabs. |
| ReplicatedStorage.Modules.ResponsivePanels | Fit the measured Dumbbells design only while that page is active; retain other pages' original fit rules. |
| ReplicatedStorage.Modules.HUDLayout | Opt-in PurchaseFillBounds uses the target's measured rectangle; all existing callers without this attribute keep the original aspect-ratio behavior. |

Authored GUI: `StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells`, including its `Equipped` surface, `EquippedBadge`, `EquipmentGlow`, existing Preview/Multiplier and hidden legacy ItemName/Hint/Title. The page has DumbbellReferenceLayout and InventoryReferenceOwned attributes. [Edit installer](../tests/DumbbellInventoryLayout.install.luau) reproduces those settings from the new module; runtime cards and sale panel are built by the client. No sample holdings or QA objects remain in StarterGui.

## Reference measurements and materials

Actually opened `C:\Users\kouji\Downloads\ダンベル在庫と売却メニュー.png`: **1586×992**. Approximate visible edge measurements (antialiased borders vary a few pixels):

| Region | Reference X/Y | Reference width/height | Implementation design |
|---|---:|---:|---|
| Inventory shell | 78 / 82 | 1426 / 864 | Same design rectangle and proportional screen placement. |
| Header / tabs | 82 / 82; 94 / 230 | 1426 / 140; 1394 / 88 | Header140; tabs Y148 relative to shell; content Y270. |
| Equipped | 94 / 352 | 420 / 580 | Left420/1394 of content; 28px corners, 6px black border, inner lavender rim. |
| First card | 528 / 352 | about315 / 318 | Three desktop columns, 12px gaps, proportional318/315 card ratio. Two narrow columns. |
| Equipped status | 174 / 374 | 270 / 78 | Green display-only badge; 52px Fredoka cap. |
| Sale panel | 530 / 674 | about538 / 286 | Width538; height250 after removing the withdrawn Owned band. |
| Sale choices | 548 / 804 | about240 / 132 each | Existing Win skin in two equal columns, single price and Sell All/total price. |

Central presentation dimensions live in `DumbbellInventoryView.Geometry`; local text/surface measurements are in the same module. All content fonts read `StrengthHUDStyle.Font`; black text outlines are 3–6 design pixels depending on use. Existing Inventory tabs/localized equipment labels retain their existing localization behavior.

Reused:
- Current DumbbellItemMaster.Image for every card/equipped preview; no model or asset-ID changes.
- Purchased Shop Top.StudPattern (111868739606818) and Card01_SecretPack.Sunburst (96427887277553).
- `StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy` through HUDLayout.PurchaseButton, including Win art125143776516842, original gradient, button layers, hover/press and sound rules.
- Purchased Shop close artwork.
- Existing NumberFormat for Strength and price abbreviations.

The purchased button's UIListLayout initially pushed the two-line Sell All caption outside its button. Removed that layout only from these view-owned clones, retained the same skin, and explicitly placed its original Amount/Icon plus one caption. Existing source text is suppressed by HUDLayout; the clone renders one price. An opt-in fill mode prevents the old donor aspect ratio from squeezing the new sale buttons. ResponsiveOriginalZ is set on the clones, avoiding double layer offsets.

## Sale behavior and server preservation

Sell only opens/retargets one panel. One sends Count=1; All sends the selected type's latest count minus one if equipped. The client refreshes Forge state before sending, uses a local in-flight guard plus existing Responsive activation debounce and Forge pending transaction identity. No quantity entry, Owned line or Keep1 label is generated.

Panel closes on tab/Inventory close, tracks its selected card via canvas/size/position events, flips above when needed and clamps inside the content region. It is outside the ScrollingFrame clip. Background is an input-sinking Frame, not a decorative GuiButton, so it adds no button hover/click sound. Actual buttons retain shared disabled/sound behavior.

Existing ForgeService / ForgeInventory / PlayerDataService are unchanged. They validate live ownership/equipment, protect the last equipped copy, perform atomic inventory/Win mutation through the existing save path, and reject/reconcile repeated transaction identities. No new server format, individual IDs or price values.

**Existing World2 limit:** W2 Dumbbells have no SellWin value and the current server rejects W2 sales. Their existing no-sale behavior remains; no price was invented. W2 ownership/equip/purchase and permanent World2Visited visibility are retained.

## Isolated native Play verification

Three short native Play runs: initial render, corrected skin plus transaction tests, final count-badge/title comparison. All persistent/payment/badge/policy/messaging dependencies were temporarily redirected to memory. Inputs used native UI callbacks connected through the real Responsive.ConnectActivation path and actual client Remotes; no OS mouse/keyboard or real payment.

| Check | Observed result |
|---|---|
| Un-equipped5, sell one | NORMAL_01:5→4, Win10000→10003; panel changed total15→12, card×5→×4. Unit3 unchanged. |
| Remaining4, Sell All | Selected type4→0, Win10003→10015; other types and equipped NORMAL_02 retained. |
| Equipped5, rapid All | Five immediate callback attempts resulted in one sale of four copies; count1, Win10000→10012. |
| Replay / last equipped copy | Same identity returned AlreadyApplied with unchanged count1/Win10012. Fresh Count1 request returned EquippedLastCopy, unchanged data. |
| Existing Win purchase | NORMAL_07 unowned purchase debited750:10012→9262, granted one and auto-equipped through the original controller. |
| Existing free equip | Switching to NORMAL_01 retained Win9262; large preview became current image131314372434925 and +1 STR. |
| Open/close/retarget | Close hides panel; another Sell changes its target; tab change and Inventory close clear it. |
| Disabled state | Equipped count1 disables both choices. One still displays its unit price, not Keep1; All shows zero. |
| Old UI | No TextBoxes, no visible Owned line, one sale panel; old equipped name/hint are hidden. Count appears only on each card. |
| Death / recreation | Real Humanoid death/respawn retained working existing ResetOnSpawn=false GUI. Fresh Play recreated the view successfully; no duplicate panel. |
| Scroll / edge / narrow | Offscreen selected card hides its panel; return restores following. Rightmost-card popup clamped inside page. An isolated650px-wide reserved UI region fit the panel inside a448.6×488.9px content area; no viewport/device/camera change. |
| Input hit targets | At a price region, first interactive target was SellOne before underlying card/list. A non-button active Frame at the panel background consumed the background hit and is not bound by GuiButton SE. |
| W2 ownership cannot unlock | Injected W2 count2 with World2Visited=false remained hidden. Existing server unlock made it visible; no CurrentWorld inference. |
| Final typography/geometry | Final native pixels inspected: equipped glow/icon/value, count pill, centered Sell, original Win icons, one price per choice, two-line Sell All; Fredoka applied to actual cloned text. |

One first replay probe was sent too soon and failed the test's success expectation at the existing remote rate limit. A paced replay returned AlreadyApplied, with identical count/Win. No production change was made to bypass that limit.

Native console showed normal startup messages and no task-related runtime errors. Direct count/Win assignments were **fixture setup only**. Reported sale/purchase deltas came from real server transaction routes, not setup writes.

## Actual comparison and limitations

- [Original reference](DumbbellInventory_Reference_20261103.png)
- [Final native normal capture](DumbbellInventory_Normal_20261103.jpg)
- [Native narrow-region capture](DumbbellInventory_Narrow_20261103.jpg) — before the final decorative count-pill/title-centering retouch; same layout/operation.
- [Side-by-side region comparison](DumbbellInventory_Compare_20261103.png), generated by [comparison script](../tests/DumbbellInventoryCompare.py).

Current native viewport was1279×720; ScreenGui content1279×662. MCP returned1029×579 JPEGs. **A native1586×992 capture was not available without the prohibited viewport/window/device changes.** Comparison reduces only reference crops uniformly to53.6%; native crops remain unscaled. This is not a claim of exact same-resolution/pixel equivalence.

Remaining visible differences:
- Required existing dumbbell/bag artwork differs from the illustration, as expected; no replacement art was fabricated.
- Available purchased stud art uses square studs rather than the reference's circles; existing Win material is paler and its icon differs. Frame/card spacing and raster outlines are close measured fits, not exact texture/edge reproduction.
- Existing localized Equip/Equipped action text renders Japanese fallback glyphs because Fredoka has no Japanese glyphs. No global language/font workaround or translation disable was introduced. New display-only Equipped badge uses the requested English label.
- NORMAL_04's existing image77317637436768 reported IsLoaded=true but its art was not clearly visible in the captured row. Its ID/art was retained; image-content diagnosis is outside this UI change.
- No physical mouse/touch acceptance, actual narrow device, production save/rejoin or real payment was tested. Native programmatic activation and isolated narrow layout are distinguished above.

## Completion

Removed all QA adapters/endpoints/exports and stopped Play. Cleanup hash-verified478 production Sources/Enabled states and74 SoundIds, retaining the user's unsaved edits. All five changed Sources compile and match their Studio versions. Original canonical Studio remains **Edit and unsaved**; no Save, Publish, rbxl writeback or Studio shutdown. User manual Save/Publish is required.
