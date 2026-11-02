# Aura catalog, Eclipse and content font — 2026-11-02

## Authority and scope

Implemented against the open Y02 Edit DataModel, PlaceId **126576845524886**. The 12 targeted live Sources initially matched Git baseline `b44d4fb`; the live state was captured before editing. No place file or historical Source tree was imported. Earlier references: `e62d8d7`, `reports/RemainingTasksAudit_20261102/REPORT.md`, and `reports/PurchaseText_20261102`.

The latest user exception takes precedence over the original seven-always-visible request: **Eclipse is hidden from the World1 Aura list and visible in World2.** This is a presentation filter, not a new ownership/effect restriction. An equipped Eclipse remains equipped and contributes its single bonus when returning to World1. The other six standard Auras remain listed. Existing VIP and Secret entitlement cards remain after the standard catalog.

Best Equip, elemental sets, combat, Merge/tutorial presentation, inventory tabs and non-Aura text were not changed. No save schema or data migration was introduced.

## Final editable configuration

| Saved ID | Display name | Purchase | Strength addition | List |
|---|---|---|---:|---|
| Pink | Pink Aura | 30 Win | 5 | Both worlds |
| Purple | Purple Aura | 75 Win | 10 | Both worlds |
| Yellow | Yellow Aura | 200 Win | 30 | Both worlds |
| Green | Green Aura | 25,000 Win | 500 | Both worlds |
| Blue | Blue Aura | 250,000 Win | 1,500 | Both worlds |
| Red | Red Aura | Existing pass 1975173075; fetched price | 500 | Both worlds |
| W2_AURA_06 | Eclipse Aura | Existing pass 2045204630; fetched price | 2,000 | World2 only |

Green, Blue and Eclipse values are the user's provisional tuning values. Eclipse keeps the existing premium saved ID and pass; it is not a second product. No Red prerequisite or additive Red bonus was added. The 299 Robux reference remains `World2GameplayConfig.Auras[6].BasePrice`; the client does not use it as a fixed price. A read-only real Marketplace response during this session returned localized prices 90/270 for Red/Eclipse. The isolated UI deliberately received **319** for Eclipse and displayed 319, proving it follows the existing price resolver.

`AuraConfig` owns the catalog order, visibility, normal prices/bonuses and visual settings. `World2GameplayConfig.Auras[6]` retains the existing premium product record and defines the Eclipse name, image and bonus. The existing `Premium.Aura` reference continues to point to that same row.

## Compatibility and server authority

`W2_AURA_01`–`05` remain resolvable with their old bonuses **200, 350, 500, 750, 1000**, old visual templates, and original IDs. They are excluded from `Config.Order`, marked `Listed=false` / `LegacyOwnedOnly=true`, and their new purchase paths return `Unavailable`. Their saved owned/equipped fields are not deleted or remapped.

`AuraService.GetOwnedAuras` now iterates all definitions rather than only the visible catalog. Retirement therefore does not revoke a saved owner's usable Aura. Game Pass ownership still requires the existing server verification cache. `AuraController` and its purchase-success verification/retry logic were left unchanged. Single-slot equipment, the Red auto-equip behavior, Eclipse explicit equip behavior and VIP/Secret entitlements remain intact.

## Actual text and image rendering

The initial placed Aura labels already had Fredoka One in their properties. This baseline did not establish that all reported visual differences were caused by LegacyArial. Native Japanese rendering remained visibly different from Latin text despite the common FontFace; glyph fallback is the likely explanation, but the engine's specific substitute font was not identified.

The Aura client now binds the content descendants, including late cloned `PurchasedButtonVisual.Main.Amount`, to the editable `StrengthHUDStyle.Font`. A FontFace change signal corrects later paint overrides, and each render reapplies the shared helper. There is no per-frame font monitor. Text size, color, stroke, positions, dimensions and localization settings are preserved. A deliberate Legacy override and a late-added text label both returned to Fredoka One. Native screenshots showed the English Eclipse title, numeric additions/prices, and the HUD's Latin/digit styling; Japanese text was not replaced with English.

The requested icon **rbxassetid://96141188431939** was fetched and inspected: dark/purple fire, golden lightning and a golden base ring. In the actual client, direct ContentProvider loading consistently returned `Failure`, while **the same asset's** `rbxthumb://type=Asset&id=96141188431939&w=420&h=420` returned `Success`. No approval/permission cause was established from the logs. The requested direct ID remains the primary Config image. A single asynchronous load check selects the configured same-asset thumbnail only on failure/timeout; no polling, substitute artwork, upload or permission change was added. Its `IsLoaded=true` and visible card image were verified. Image loading remains asynchronous: the immediate post-respawn screenshot still had pending image loads for several cards, so instantaneous post-respawn image completion is not claimed.

## Eclipse character effect

`EclipseAuraVisual` reuses existing Red fire and Pink lightning emitter assets and the existing server Aura lifecycle. It creates two fire emitters, one gold lightning emitter and a four-Beam gold ring. It does not attach the inventory image to the character. Color, emitter volume, sizes, rates, lifetime, textures, ring radius/width and clearance are editable in `AuraConfig.Get("W2_AURA_06").VisualSettings`.

Native screen inspection caught two presentation issues during development: the donor fire's negative Z offset hid most particles inside the body, and the zero-speed lightning inherited a velocity-facing orientation. The final Eclipse-only settings correct these. The ring uses a local Weld offset and reacts to Humanoid HipHeight / root size changes without a frame loop. The old authored Aura templates are unchanged.

## Changed Full Paths

1. `ReplicatedStorage.Config.AuraConfig`
2. `ReplicatedStorage.Config.World2GameplayConfig`
3. `ReplicatedStorage.Modules.EclipseAuraVisual` — new ModuleScript
4. `ServerScriptService.Services.AuraService`
5. `ServerScriptService.Services.AuraCharacterEffects`
6. `StarterGui.StrengthGui.AuraInventoryClient`

Non-Source Edit differences:

- `StarterGui.StrengthGui.InventoryPanel.Content.Aura.AuraList.GreenAuraCard.Price.Amount.Text`: `500` → `25000`.
- `...GreenAuraCard.StrengthBonus.Text`: `+50 Strength` → `+500 Strength`.
- `...BlueAuraCard.Price.Amount.Text`: `1250` → `250000`.
- `...BlueAuraCard.StrengthBonus.Text`: `+150 Strength` → `+1500 Strength`.
- Added `...AuraList.W2_AURA_06AuraCard` and its 21 descendants, cloned from the current Red card. Hidden in the Edit default/World1 state; name/image/bonus are Eclipse and the Edit price is `...`, awaiting Marketplace resolution.

`tools/InstallAuraCatalog20261102.luau` reproduces these GUI differences after the matching Sources are installed. It updates existing cards without replacing their geometry or decorations and does not save/publish. `Evidence.json` lists every added object and changed property.

## Focused native Play verification

Three short native **solo Test** sessions were started through `StudioTestService:ExecutePlayModeAsync` and ended through `EndTest`. No multiplayer/Server & Clients launcher or OS input was used. Temporary dependency redirection covered 38 Sources (DataStore, Marketplace, Badge and an activation observation hook); server/client fixtures ran as native Script/LocalScript, not isolated command-bar require caches. Data was in memory, pass ownership and purchase completion were simulated, and no real checkout was opened. Studio's existing pass-effects setting was enabled only inside the temporary runtime VM and its original Source remains unchanged.

| Check | Result / evidence |
|---|---|
| Catalog | Six standard cards in World1; seven in World2; VIP/Secret retained; no legacy World2 duplicate cards. |
| Existing Green/Blue owners | Bonuses 500/1500 applied without repurchase. Fresh isolated purchases debited 25,000 and 250,000 Win. |
| Separate pass ownership | Neither, Red-only, Eclipse-only and both cases passed. Unowned equip rejected; existing pass 2045204630 granted W2_AURA_06 without Red. |
| Purchase operation | Native Aura button invoked the mock checkout once with pass **2045204630**; the existing server success event updated ownership; ordinary client equip then selected Eclipse. No actual payment. |
| Red / Eclipse | Red 500 in both world states; Eclipse 2000 even when both passes owned. World1 card hiding did not revoke Eclipse ownership/equipment. |
| Legacy data | W2_AURA_05 remained equipped with bonus 1000 and survived an in-memory save. W2_AURA_02 purchase rejected with `Unavailable`. |
| Training once | Base 1 yielded 501 / 1501 / 2001 for Green / Blue / Eclipse, each with multiplier 1 and no other equipped bonus. |
| Strength purchase/offline reference | Unchanged `StrengthReference.Get` returned 1002 / 3002 / 4002 per second at the existing 0.5-second interval. Both consumers use this shared reference; formulas/receipts were not changed. |
| Fonts | All 77 Aura text objects in the final populated UI used Fredoka One; cloned purchase text, late-created text, price update, reopening and GUI regeneration after death passed. Item/Speed general text retained their prior families. |
| Actual display | 1390×622 screenshots inspected: requested image through same-ID thumbnail, price/state text and Robux glyph, English Eclipse name and numeric additions, Japanese localization, dark/purple particles, gold lightning and ring. |
| Narrow case | A temporary **360px card-only fixture** showed full Green/Eclipse names, effects, price and icon with `TextFits=true`. This was not a narrow device/viewport test. |
| Effect lifecycle | Unequip removed the effect; Green/Eclipse switching left one model; 20 repeated syncs did not duplicate; death removed all effect models; native respawn recreated one. |
| Ring growth / respawn | Growth changed expected Y from -2.8192676 to -3.3090845; final error < 0.000001 stud. Respawn error < 0.000001 stud. |

World comparisons used prepared `CurrentWorld` state; native death/respawn used the existing corresponding spawn flow. A natural portal journey was not separately exercised. No maximum-size avatar sweep, physical narrow device, live paid-account ownership, real receipt or production save test is claimed. Captures were inspected transiently and are not committed.

The console contained existing unrelated asset warnings and a temporary observation error caused by a QA bridge being removed with PlayerGui on respawn; that bridge was moved to PlayerScripts in the later test. No new production Aura runtime error was observed. This is not a clean-console claim for the entire game.

## Final Edit preservation and delivery

After the last Play, all 38 temporary Source substitutions were verified against their exact expected temporary versions and restored. All `__Aura*` fixtures were removed. Of the initial **461 Sources**, only the five intended existing Sources differ; the sixth production Source is the new module. There were no unexpected Source differences. Among **16,493 protected GUI/asset/template objects**, only the four intended Text properties changed, no original object was removed/reparented, and the 22 new card objects were present. Original camera CFrame/Focus and HttpEnabled matched the start snapshot.

`StudioTestService.EditModeActive=true`, the connection reports Edit with the Edit DataModel focused, and the solo Test API returned successfully. The connection does not expose the toolbar dropdown's selected label; that UI label is **not independently verified**. No Server & Clients launch was used in this task.

The Studio remains open and **unsaved**. No Save, Publish, rbxl write-back, close, window arrangement, camera-setting or device-preview operation was performed. The unrelated pre-existing untracked report `reports/Visual_Templates_Secret_VIP_Green_20260917.md` is excluded. This report is the current Aura behavior record; any older Aura values/list descriptions in balance/UI/status documents should be reconciled to the table and World1 Eclipse exception above.
