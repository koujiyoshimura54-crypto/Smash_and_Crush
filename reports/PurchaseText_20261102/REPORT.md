# Dumbbell sale labels and purchase fonts — 2026-11-02

Implemented in the currently open canonical Y02 Studio, **PlaceId 126576845524886**, from its live unsaved Sources. Baseline: **e62d8d7** and [the preceding scoped audit](../RemainingTasksAudit_20261102/REPORT.md). All twelve selected live Sources matched their repository counterparts before editing. No old place/source snapshot was imported.

## Delivered changes

### ④ Sale presentation only

StarterGui.StrengthGui.InventoryPanelClient now displays **Sell** when the existing effective sale quantity is zero. Positive quantities retain the existing formatted sale return. The same string is sent to the actual PurchasedButtonVisual.Main.Amount, so the hidden original and visible clone agree.

The existing InventoryPresentation.SetButtonEnabled helper supplies Active/AutoButtonColor; Interactable follows Active. Zero ownership still hides both sale controls. The activation handler rechecks Active and the effective quantity after Forge.Refresh, preventing a refreshed invalid quantity from being submitted. Existing ResponsivePanels activation gating and Forge pending/identity handling remain intact.

ReplicatedStorage.Modules.ForgeInventory was inspected and left unchanged. Ownership remains a type-to-count map, with one grouped card per type. The server still protects one copy of the equipped type. **Individual-copy IDs are withdrawn from this task; no schema change or migration.** No World2 sale support, price, effect or inventory quantity change was implemented.

### ⑥ Font on the actual purchase renderer

ReplicatedStorage.Modules.HUDLayout.ApplyPurchaseTextFont applies only FontFace, using the existing editable **ReplicatedStorage.Config.StrengthHUDStyle.Font** (Fredoka One). Callers pass a purchase visual or specific purchase text, never a whole inventory/shop.

PurchaseButton applies this to the real PurchasedButtonVisual on creation/update and to later descendants. It does not rely on the suppressed original Text. Independent builders use the same helper:

| Changed Full Path | Exact display scope |
|---|---|
| ReplicatedStorage.Modules.HUDLayout | Shared Shop, Item/Speed purchase, StageSkip, Dumbbells/Aura and other existing PurchaseButton consumers; visible cloned text including price/state labels. |
| StarterGui.StrengthGui.InventoryPanelClient | Sell/disabled state and existing cloned sale label, as described above. |
| StarterGui.StrengthGui.InventoryCapacityUpgradeClient | Independent capacity/Speed PurchasedButtonVisual, including price changes. |
| StarterPlayer.StarterPlayerScripts.Services.StandClient | Limited Egg Open1 purchase visual and its physical offer's Price label. Pet names/probabilities and the separate availability message retain their fonts. |
| StarterPlayer.StarterPlayerScripts.Services.EggClient | Actual Open1/Open3/Open8 operation/price text and the pedestal purchase-price Info. |
| StarterPlayer.StarterPlayerScripts.Services.DumbbellStandClient | Amount Main/shadow and purchase Status/shadow in both Worlds. Strength-effect and station-number labels retain their fonts. |
| StarterPlayer.StarterPlayerScripts.Services.CheapClient | Workspace.Trophy.BillboardGui.Text and Price only; also handles purchase text arriving after the model/prompt. |
| StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient | Active World1 premium purchase label: Workspace.Treadmills.Diamond01.BillboardGui.Rebirth.Amount. General multipliers/requirements are excluded. |

The World2 premium station currently reports Robux - Unavailable in a combined multiplier/status label. That unavailable mixed label was not restyled wholesale.

The CheapClient arrival case was found in fresh Play: its first refresh could precede the server-created prompt, leaving authored purchase text at LegacyArial. Font application now precedes the prompt guard, and a narrowly filtered DescendantAdded handler styles only the two arriving Trophy purchase labels. No prompt eligibility, request route or purchase behavior was changed.

No font-maintenance frame loop was added. Existing button geometry, text size/scaling, stroke, color, layout, icons, IDs, price lookups and receipt paths were retained. Strength purchases/offline rewards, top Inventory tabs, non-purchase Item/Speed text and all Merge/tutorial presentation are outside the diff.

## Focused native Play results

Two short fixture-driven solo Play sessions were used. DataStore, Marketplace and Badge dependencies were redirected to temporary in-memory adapters; no production store or real checkout was used. Prepared inventories replace long progression. Actual game services and GUI builders ran.

### Sale

| Prepared state / action | Observed result |
|---|---|
| Three NORMAL_01, one equipped; input 2 and invoke the existing activation handler | Server count 1, equipped NORMAL_01 retained, Win and Win attribute 1000 -> 1006. |
| Request the last equipped copy directly through the actual server service | Rejected with EquippedLastCopy; state unchanged. |
| Three NORMAL_01, none equipped; excessive input clamped to 3 and invoke the existing handler | Server count 0, equipment empty, Win and attribute 1000 -> 1009; sale control hidden. |
| Input 0 or -2 | Effective quantity 0, original and clone both Sell, Active/Interactable/AutoButtonColor false. Invoking the gated activation did not send a SellDumbbell request. |
| Empty input | Preserves existing fallback to quantity 1 and its sale return. |
| Input 999 while one of three is equipped | Preserves existing clamp to quantity 2, Sell 6. |
| After selling down to the equipped last copy | ×1, Sell, effective quantity 0, disabled; captured and inspected. |

The existing unfocused quantity normalization can rewrite zero/negative input to the textbox value 1 while the evaluated quantity remains zero for that update. This behavior was not redesigned. No Keep 1 remains in the modified source or inspected sale label.

The observer invoked the existing ResponsivePanels activation callback; this is native UI-handler/remote execution, not physical mouse/keyboard input. The zero/negative case had only GetState requests, no SellDumbbell request. The final valid sale produced exactly one SellDumbbell request. Server-side last-copy rejection was also checked independently.

### Fonts, updates and lifecycle

- Inspected 146 actual common PurchasedButtonVisual.Main.Amount instances. **145 used Fredoka One**. The sole LegacyArial instance belonged to hidden Card04_Teleporter with Classification=LEGACY and no current PurchaseKind; it remains an unused legacy card, deliberately excluded.
- Native capacity and Speed purchase Amounts use Fredoka One. Updating the capacity price to a prepared 777 and restoring it retained the font.
- Actual Limited Egg creation, fetched mock price 99, closing/reopening and recreation after death retained Fredoka One. The unavailable offer's existing purchase handler returned false / Unavailable with **zero prompt delta**. Its offer was not a real purchasable product validation.
- Actual Egg sheets contained Open 1 / 15 Win, Open 3 / 45 Win and Open 8 / 120 Win in Fredoka One. Their on-screen visibility was not established; the inspected Basic sheet remained disabled.
- Both Worlds' dumbbell price/state labels use Fredoka One; adjacent Strength effects and station numbers remain LegacyArial.
- Trophy purchase Text/Price use Fredoka One, including a prepared late-arriving text clone. Its original label was restored after this runtime-only probe.
- World1 Premium's purchase Amount uses Fredoka One; its general multiplier retains LegacyArial.
- A prepared shared-button clone retained the font through 99 -> 1.234K, an Owned state, a new card/visual and a late text descendant. Eleven sampled non-font text/layout properties remained unchanged when the font helper ran.
- Actual death/respawn regenerated PlayerGui. **1,174 matching-path text observations had no FontFace-family differences** versus the pre-death runtime snapshot. The common purchase counts above were unchanged; the disabled last-copy Sell display also persisted. This includes the existing Aura/Dumbbells fonts and the untouched tab/general-text families.
- Static diff review verified no purchase target/product/receipt changes. Native mock refusal confirms the Limited Egg deny path; every purchase product was not individually submitted.

### Screen acceptance and an existing layout limit

At the unchanged 1390 × 622 viewport, inspected temporary screenshots showed:

- Limited Egg's Fredoka price **99** and existing Robux symbol readable and complete.
- Capacity **5** / Speed **100**, with existing Trophy icons and readable purchase numbers.
- Dumbbells' formatted Sell 6 and later disabled **Sell** / ×1; the visible normal purchase **20** and its Trophy icon were intact.

**Shop is not fully visually accepted.** Some existing shared Shop visuals measured Size={0,6},{0,44} in local UI units (about 4.76 × 34.87 screen pixels), with text bounds about 2 × 2. The screenshot showed narrow vertical artwork rather than a readable price. A runtime comparison restored the old Legacy font on the same actual label: the same dimensions and tiny text bounds remained, then Fredoka was restored. This establishes an existing geometry limitation rather than a font-only correction. Its broader layout cause was not re-audited or changed because button dimensions/layout were explicitly to remain unchanged.

The later Aura capture did not return and was abandoned. No new Aura/Egg raster acceptance or all-device/all-offer clipping guarantee is claimed. Their actual renderer FontFace checks are recorded separately from screenshots. No screenshots are retained or committed.

## Isolation and corrections during verification

A preliminary observer sampled a pending client sale and then issued an independent server request too early; that interleaved trial was discarded. Final sequential checks waited for committed server state. The first mock adapter lacked the intended async product-info response on the client; it was corrected for the second Play, where 99 is an explicitly mocked price. A Limited Egg probe initially ran outside its allowed proximity and its normal close handler removed the panel; it was repeated at the actual facility. Death removed the test-only PlayerGui BindableFunction, so the native observer was reattached before the post-respawn comparison. Tool/fixture errors are not presented as production failures or passing checks.

No new production error from the changed paths appeared in the final focused logs. Known sound authorization warnings remain untouched. The mock Limited Egg offer returned ProductAssociationUnavailable, and its denied action did not prompt. This work does not change Best Equip, Auto attack or sound permissions.

## Final Edit verification and deliverables

After stopping Play:

- Restored **38** temporary Source substitutions to their captured production versions, and removed **3** Edit fixture objects.
- Verified **461** Sources: exactly the eight intended production changes; every other Source matches the initial live state.
- Verified **22,273** protected authored instances and **82,465** recorded properties, plus their attributes/parents: **no differences**. No authored object/template/map delta is required.
- Camera CFrame/Focus and HttpEnabled=false are unchanged.
- Studio is **Edit**, available/focused DataModel **Edit**, with existing and new edits **unsaved**.
- No OS input, window rearrangement, camera/device-preview setting change, Save/Publish, rbxl writeback or Studio shutdown.
- All eight changed Luau files compiled; the final additional CheapClient change compiled again. Repository diff checks passed.

[Sources.json](Sources.json) records live before/after hashes and matching source files. [Evidence.json](Evidence.json) contains compact sanitized observations, not account identities, session tokens or saved test profiles. Documentation changes record only the confirmed scope and limits.

Remaining limits: the pre-existing shared Shop geometry problem; unreturned Aura capture and unestablished Egg sheet visibility; uninspected physical-offer pixels and other devices; physical input, production persistence and real checkout. No claim of complete visual acceptance is made for those items.
