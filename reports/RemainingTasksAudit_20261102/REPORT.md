# Y02 remaining-task audit — 2026-11-02

Audit only. Canonical open Studio: **PlaceId 126576845524886**. Baseline Git and fetched origin/main: **60e84fd853e61923c41ee46e7f0914564d22badc**. Current Edit Sources and objects were read before comparing repository records; repository content was never imported over the place.

No production implementation, data migration, balance, font, map or asset permission change was made. Only this report directory is delivered. Findings distinguish current Source, native runtime inspection, inspected screen pixels and earlier evidence.

## Scope, previous work and preservation

Read AGENTS.md and the relevant specifications/history. Principal prior records:

- [World1 presentation fixes](../World1Presentation_20261102/REPORT.md), commit 60e84fd.
- [Merge arrow audit](../OreMergeArrowAudit_20261102/REPORT.md), commit 1d07150.
- [Completed Merge presentation](../OreMergeTutorialDisplay_20261102/REPORT.md), commit 351b4b5.
- [Inventory UI2](../InventoryUI2_20261101.md).
- [Ore inventory and sale implementation](../World1Ore_20261026/README.md).
- [Earlier World1 run](../World1SingleRun_20261027/README.md).

All **17** production Sources in the 60e84fd presentation manifest match the currently open Studio. This includes TutorialGuideClient, the ten World1 appearance scripts, World1BossPresentation, PersonalTrophyVisibility, CombatClient, Stage03AttackVisual, EnemyManager and TrophyRewardService. These repairs were not reimplemented.

The previous carpet/Trophy visual limits remain: this audit obtained a carpet-area image, but machines obstructed the route and it did not establish visible arrows before/on/across the carpet. No new Trophy raster acceptance is claimed. Prior native measurements and two-client results remain historical evidence, not a new test here. Completed Merge highlight/dimming/notification and all start/pause conditions were preserved.

One scoped live-vs-repository discrepancy was only an extra trailing newline in ReplicatedStorage.Modules.ElementSetBonus; it was preserved. Selected source hashes and comparison outcomes are in [SourceManifest.json](SourceManifest.json). Entries without a current src mirror are not classified as missing Studio implementation.

## ④ Dumbbell identity, counts and sale UI

**Status: requested surplus-sale behavior implemented; individual-copy identity not implemented; Keep 1 presentation needs clarification.**

Current ownership is a count per catalog ItemId. EquippedDumbbell is a catalog ItemId, not an acquired-copy UUID. No separate per-copy ownership collection is used by the inspected purchase/merge/equip/sell/save chain.

| Current Full Path | Actual responsibility |
|---|---|
| ReplicatedStorage.Modules.InventoryCounts | Normalize quantities, including legacy true -> 1. |
| ServerScriptService.Services.PlayerDataService | OwnedDumbbells count map; EquippedDumbbell string; normalization, mutation snapshots and saved payload. |
| ServerScriptService.Services.DumbbellService | Ownership queries, buying, equipping; some compatibility queries expose owned booleans while count state remains authoritative. |
| ServerScriptService.Systems.Controllers.DumbbellController | Returns counts and equipped catalog ID to the client. |
| ReplicatedStorage.Modules.ForgeInventory | MergeOre increments the result type's count; BuyDumbbell initializes an unowned type; SellDumbbell validates quantity and protects the equipped last copy. |
| ServerScriptService.Services.ForgeService | Validates session token/generation/sequence and operation identity, then returns committed inventory state. |
| ServerScriptService.Services.ForgePersistence | Atomic persistence integration for forge/count/Win mutations. |
| StarterGui.StrengthGui.InventoryPanelClient | One card per type, OwnedCount, sell quantity, Keep 1 and pending-state controls. |

World1 buying uses a forge operation UUID. The forge journal's Id, Sequence, Signature and ResultId identify/deduplicate mutations; they are **not** identities of each dumbbell. World2's existing purchase path also stores count ownership, not copy identities. No identity value is displayed in the inventory.

The server rejects an equipped type only when the requested sale quantity would remove its last owned copy. The UI uses:

- maximum sale = owned count minus one when this type is equipped;
- effective quantity = numeric textbox value, floored and clamped to that maximum;
- a positive quantity enables the sale and shows its return;
- zero effective quantity displays **Keep 1** and disables interaction;
- zero ownership hides the sale control.

Therefore Keep 1 can also appear for a typed zero/negative quantity, even where it does not accurately describe the reason. World1 sale support should not be mistaken for an implemented World2 sale system.

**Native isolated result:** prepared NORMAL_01 count 3 with NORMAL_01 equipped. The actual ForgeService accepted selling 2 (Applied), leaving count 1 and the equipped type unchanged. Selling that last copy returned EquippedLastCopy. The actual inventory then showed ×1 / Keep 1, SellQuantity=0, Active=false and Interactable=false. This was prepared test inventory, not production inventory or a persistence migration.

**Minimum follow-up:** the confirmed three-copies requirement does not require introducing individual IDs. Clarify the zero-quantity/last-equipped-copy label and retain the existing server guard and grouped cards.

If unique acquired-copy IDs are independently required later, use a versioned, idempotent migration: convert each existing count to that many persistent internal records, preserve catalog IDs/unknown legacy entries, select one instance of the previously equipped type, and keep UI counts derived by type. Generate and persist stable IDs once per migration/operation, including retry behavior; do not regenerate them inside retrying UpdateAsync callbacks. Update purchase, merge result, equip, sale selection and save together, protecting the equipped UID. No such migration was attempted here.

Unverified: real production persistence round-trip, future unique-ID requirements and World2 sale policy. None is needed to establish the currently working World1 surplus sale.

## ⑤ Aura's actual Fredoka One renderer

**Status: implemented in the inspected current Aura UI; the reported missing application was not reproduced.**

Authored root: StarterGui.StrengthGui.InventoryPanel.Content.Aura.

Runtime root: PlayerGui.StrengthGui.InventoryPanel.Content.Aura.AuraList (PlayerGui below the local player; no account identifier is recorded).

For PinkAuraCard, PurpleAuraCard and YellowAuraCard:

- AuraName, StrengthBonus and Price.Amount use Font=FredokaOne and FontFace family rbxasset://fonts/families/FredokaOne.json.
- BuyButton and BuyButton.Label have TextTransparency=1; inspecting these alone would not establish the visible purchase font.
- The drawn price is BuyButton.PurchasedButtonVisual.Main.Amount. Its Font and FontFace are also Fredoka One, with prices 30, 75 and 200 respectively.
- Generated additional Aura cards inspected at runtime likewise had Fredoka One on their actual purchase Amount children; being present/Visible is not proof that offscreen rows were rendered within the scroller.

ReplicatedStorage.Modules.HUDLayout.PurchaseButton clones StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy or BuyRobux, whose original Main.Amount uses LegacyArial. It suppresses the old button text and creates PurchasedButtonVisual.

ReplicatedStorage.Modules.InventoryPresentation.ApplyInventoryContentFont repairs text only within the scoped Dumbbells/Aura content. It runs before the purchased-visual early return in the relevant presentation calls. StarterGui.StrengthGui.InventoryPanelClient also applies it during initialization and deferred DescendantAdded handling, including new cloned descendants. StarterGui.StrengthGui.AuraInventoryClient updates labels/prices; no later font reset was observed after the renderer settled.

**Screen inspection:** the existing 1390 × 622 viewport was captured without changing camera or preview settings. The first three Aura rows and their numeric prices were visible. Japanese localized names/Strength labels coexist with the Latin/numeric Fredoka presentation. The Japanese glyph appearance is consistent with glyph fallback despite the correct FontFace setting; Roblox's exact resolved fallback family was not identified. This is different from leaving the visible Amount child at LegacyArial.

**Minimum follow-up:** no new Aura implementation is justified by this sample. Retain a focused Aura regression when fixing the shared purchase renderer in ⑥. A specific still-wrong label/state would be needed to diagnose another fault. No general tab/Item/Speed or Merge font change is proposed.

Unverified: every scrolled/generated card's pixels, all locales/devices and the engine-selected Japanese fallback font. Screenshots were inspected temporarily, not retained in Git.

## ⑥ Purchase-button font coverage

**Status: partially implemented. A shared fix covers many buttons, but independent builders remain.**

The common HUDLayout.PurchaseButton does not normalize the font of its cloned visible text. The donor uses LegacyArial. Changing an original hidden Price/Label alone will not affect PurchasedButtonVisual.Main.Amount. Aura/Dumbbells are corrected by the scoped helper described above; other callers lack that correction.

| Active family / code Full Path | Actual display path or template | Current evidence |
|---|---|---|
| StarterGui.StrengthGui.EssentialStudShopClient; StarterGui.StrengthGui.ShopBenefitsClient | PlayerGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.<card>.PurchaseArea.Purchase.PurchasedButtonVisual.Main.Amount; some item cards use <card>.Purchase directly | Native children LegacyArial. Opened Shop; top Starter/Secret labels were visible. Their mocked price was "...", not a verified real price. Other rows may be offscreen. |
| StarterGui.StrengthGui.ItemInventoryTabClient | PlayerGui.StrengthGui.InventoryPanel.Content.Items.OwnedItems.<id>.WinPurchase.PurchasedButtonVisual.Main.Amount and Robux purchase equivalents | Native cloned purchase text LegacyArial; general Item text is outside this task. |
| StarterGui.StrengthGui.SpeedInventoryClient | PlayerGui.StrengthGui.InventoryPanel.Content.Speed.SpeedList.Premium.BuyButton.PurchasedButtonVisual.Main.Amount | Native LegacyArial; general Speed text is outside this task. |
| StarterPlayer.StarterPlayerScripts.UI.StageSkipClient | PlayerGui.StageSkipGui.Panel.Stages.Stage2.WinButton.PurchasedButtonVisual.Main.Amount and RobuxButton, also later stages | Native LegacyArial. |
| StarterGui.StrengthGui.InventoryCapacityUpgradeClient | PlayerGui.StrengthGui.InventoryCapacityUpgradePanel.InventoryCapacity.Purchase.PurchasedButtonVisual.Main.Amount and Speed.Purchase.PurchasedButtonVisual.Main.Amount | Separate bindWinButton clones the donor directly. Native Amount LegacyArial, old Price hidden. Panel auto-hid before capture; that image is not visual acceptance. |
| StarterPlayer.StarterPlayerScripts.Services.StandClient | Clones StarterGui.ScreenGui.Menus.RestockShop.Main.Common.BuyRobux for the LimitedEgg offer | Source/template LegacyArial; this panel was not opened in the audit. |
| StarterPlayer.StarterPlayerScripts.Services.EggClient | ReplicatedStorage.Assets.Templates.OpenEgg.Opens.Open1.Title, Open3.Title, Open8.Title | Separate billboard builder updates Open n / Win text without font normalization. Current template LegacyArial; egg panel pixels not inspected. |
| StarterPlayer.StarterPlayerScripts.Services.DumbbellStandClient | Workspace.PerStepButtons.1.BillboardGui.Amount.Main / Status; Workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons.1.BillboardGui.Amount.Main / Status | Current physical purchase sign text LegacyArial; updater changes text, not font. |
| StarterPlayer.StarterPlayerScripts.Services.CheapClient | Workspace.Trophy.BillboardGui.Text and Price | Separate x2-Win offer sign uses LegacyArial; distinct from personal Stage Trophy claim devices. |

ReplicatedStorage.Modules.StrengthHUDPresentation already applies the configured Fredoka treatment to Strength-pack and offline-reward purchase presentation. The normal HUD Strength-pack text was visible during inspection. The offline reward panel was not opened for a new visual comparison.

StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient also owns physical station text. The inspected World2 premium station Workspace.World2Map.TrainingArea.TreadmillDisplays.07.StationBillboard.Multiplier uses LegacyArial but currently says Robux - Unavailable; it is not evidence of a presently purchasable offer. World1's premium sign Workspace.Treadmills.Diamond01.BillboardGui.Rebirth.Amount also uses LegacyArial. Keep these physical labels separate from the common screen-button renderer and avoid expanding a purchase-text change to every training label.

Dormant purchased ScreenGui shop pages are not counted as additional active shops merely because their old text still exists. StarterPlayer.StarterPlayerScripts.Main is disabled; selected pieces are explicitly reused by the current bootstrap.

**Minimum follow-up:** define/apply the intended text font at the shared visible purchase renderer, including newly cloned descendants and subsequent refreshes. Reuse that treatment in InventoryCapacityUpgradeClient's separate builder and the active independent egg/stand purchase displays. Preserve Robux image/icon objects, prices, callbacks and non-purchase labels. Do not modify the Roblox checkout dialog. Do not rely on a donor-only change unless runtime descendants and exceptions are also covered.

Unverified: pixels of every shop row, egg/limited-egg panels, every physical offer, actual remote prices and real paid checkout. Runtime property inspection establishes the remaining LegacyArial renderers; it is not a claim that all were simultaneously visible.

## ⑦ Best Equip and elemental sets

**Status: policy decision pending; current per-slot selection is implemented, automatic set optimization is absent.**

ServerScriptService.Services.ItemService.EquipBestItems evaluates each slot independently using protein gain, glove Boss-damage bonus and belt treadmill benefit. Equal scores use ItemId ordering, except an already equipped owned item with that same score is retained. It does not evaluate ReplicatedStorage.Modules.ElementSetBonus.

The set module gives a 1.5 multiplier when all three equipped items share an eligible element (Fire, Ice or Electric). ServerScriptService.Services.StrengthManager applies this to Strength acquisition. ServerScriptService.World.BossCombatService uses the captured Strength and glove modifier for damage; the elemental set is not another direct damage multiplier at equal current Strength.

Native prepared inventory, using the actual ItemService:

| Comparison | Selected glove | Set multiplier | Protein / belt / glove effect |
|---|---|---:|---|
| Best from empty equipment | Common Electric | 1 | +15 / +1 tier / +0.05 |
| Manual all-Ice selection | Common Ice | 1.5 | +15 / +1 tier / +0.05 |
| Best after the manual Ice selection | Common Ice retained | 1.5 | Same |
| Best after adding a stronger Uncommon Fire glove | Uncommon Fire | 1 | +15 / +1 tier / +0.10 |

Other slots were Uncommon Ice Protein and Rare Ice TrainingBelt. This reproduces the earlier report's missed set completion from an uncommitted tie, while identifying the already implemented equal-score equipped-item retention.

**Minimum follow-up:** choose the intended objective first. An explicit growth/damage mode or an agreed tie policy could evaluate combinations across three slots. For equal current Strength, the stronger Fire glove gives 1.10 versus 1.05 direct Boss damage, while the Ice set improves Strength growth by 1.5. Neither is universally best. No weighting, mode or automatic replacement was implemented.

Unverified: exhaustive catalog optimization, long-term progression speed and the desired player-facing Best Equip policy.

## ⑧ Auto attack after leaving the Boss

**Status: current continuation reproduced; contact/range policy decision pending.**

The three layers are different:

1. Auto ON: ServerScriptService.Services.AutoTapService / PlayerDataService retains the toggle independently of whether a battle exists.
2. Client presentation: StarterPlayer.StarterPlayerScripts.Combat.CombatClient consumes combat attack events and plays the existing attack presentation.
3. Server damage: ServerScriptService.World.EnemyManager, BossCombatService and BossChaseService decide whether an accepted personal encounter continues.

Initial contact requires the unlocked Boss, live character and current stage, with CombatZone overlap against the character or its WallCombatTrigger. The trigger has its existing size/forward offset. Once the MiniBoss encounter exists, EnemyManager retains it while the character/stage/actor/session match and BossChaseService.ContainsPlayer accepts the player.

ContainsPlayer checks the real StageFloor's local X/Z bounds. It does not check height, Boss distance or facing. Delayed player hits revalidate world, player/character, stage/session/actor and defeated/completed state, but do not add a per-hit distance/angle/height check. The existing arena-exit update ends the encounter.

ServerScriptService.World.BossAttackService has separate range, facing and body-height checks for **Boss-to-player** damage. Those incoming-attack rules must not be reported as outgoing Auto-hit restrictions.

Native World1 Stage1, prepared wall clearance and Strength=1:

| Prepared state | Auto | Fighting | Server observation |
|---|---|---|---|
| Initial Boss contact | true | true | HP 374, one accepted attack |
| Inside stage, initially 75.06 studs from Boss | true | true | After about 2.1 s HP 371, four attacks; Boss chase reduced distance to 41.47 |
| Same X/Z with player raised 100 studs | true | true | After about 1.7 s HP 369, six attacks; distance still about 100.31 |
| Beyond the stage's X boundary | true | false | Encounter ended; Auto toggle stayed on |

The character was anchored/repositioned only as a runtime test fixture to make comparisons stable. The elevated case is not evidence that normal movement can reach that height. A separate native client observation received four attack and four gauge events; the punch animation track was sampled after it finished. No continuous/video-based punch-motion acceptance is claimed.

**Minimum follow-up:** determine whether retained chasing is also intended to permit remote player hits. If contact damage is required, separate encounter/chase retention from outgoing-hit eligibility, recheck at acceptance/impact and align client presentation. No limit or attack-condition change was made. The current observation is actual server HP loss, not merely the toggle or a historical screenshot.

Unverified: World2 native reproduction, all stage shapes, physical player input and the intended remote-hit design policy.

## ⑨ Asset access errors

**Status: current authorization failures confirmed for nine Sound assets; usage/impact differs.**

The current native Play log explicitly reported "User is not authorized to access Asset." All nine corresponding client Sound objects had IsLoaded=false and TimeLength=0. This supports an authorization diagnosis, not an assertion that moderation is pending or that the asset was deleted.

| Asset ID | Type / Full Path | Current use and impact supported by evidence |
|---|---|---|
| 110783070910373 | Sound; SoundService.UI.Click | Active HUD button interactions and configured hatch knock; sound unavailable. |
| 70375637366855 | Sound; SoundService.UI.Hover | Active HUDLayout hover feedback; sound unavailable. |
| 117918896943222 | Sound; SoundService.UI.Notification | Active NotifyClient pin/push, including tutorial/pet notifications; sound unavailable. |
| 132703558395523 | Sound; SoundService.UI.Success | Active HatchClient path via Config.Hatch crackPath; no hatch was performed in this audit. |
| 93441624600336 | Sound; SoundService.UI.Winner | Active HatchClient rarePath; no rare hatch was performed in this audit. |
| 80878570230928 | Sound; SoundService.UI.Cash | Retained duplicatePath config; current Hatch startup does not bind this duplicate sound. Active invocation not established. |
| 137456349421517 | Sound; SoundService.UI.Error | Referenced by legacy PurchaseClient; active use in the present bootstrap not established. |
| 92759730216628 | Sound; SoundService.Music.Classic Easter | Retained music object, not playing; MusicClient startup is in the disabled legacy loader. Current BGM consumer not established. |
| 75011432119943 | Sound; SoundService.Music.Fun And Games (Sleigh Bells Version) | Same retained/dormant distinction as above. |

Relevant call paths: ReplicatedStorage.Modules.HUDLayout; ReplicatedStorage.Modules.Config.Hatch.Sounds; StarterGui.StrengthGui.LeftMenuClient; StarterPlayer.StarterPlayerScripts.Services.PetClient, HatchClient, NotifyClient, PurchaseClient, MusicClient and SoundClient. LeftMenu's current bootstrap starts the pet/notification/hatch/egg/stand path; it does not enable the whole legacy Main loader.

No new animation authorization failure was observed in this focused Play. The earlier ten-Boss visible-motion acceptance remains in the 60e84fd report; it was not repeated. This does not certify every asset in the place. No bulk preload, upload, replacement or permission change occurred.

**Minimum follow-up:** first resolve experience/owner authorization for the confirmed active UI/notification/hatch sounds, or separately approve replacements if authorization is unavailable. Check whether the remaining four retained references are needed before changing them. Do not treat every retained failing sound as a currently broken active feature.

Unverified: Creator Dashboard ownership/permission details, moderation status beyond the explicit log, sound audibility after a permission repair, dormant consumer activation and unexercised asset paths.

## Evidence boundaries and final Edit state

One focused solo Play used temporary memory-backed DataStore, Marketplace and Badge adapters. Prepared inventory/equipment/stage state shortened the specific comparisons. Native services executed the sale, equipment choice and encounter damage; runtime inspection read the actual cloned GUI. Real production stores, resetdata, migrations, purchases and receipts were not exercised. The Marketplace placeholder prices are not live price validation.

After Play stopped:

- All **37** temporary Source substitutions were restored to their captured live originals.
- Both temporary Edit fixture objects were removed; runtime observers ended with Play.
- All **461** captured Sources match the starting Edit state.
- **19,053** protected instances and **55,309** recorded properties, plus attributes/parents in the protected roots, match the baseline with no differences.
- Camera CFrame/Focus and HttpEnabled=false match the baseline.
- Studio reports **Edit**, available/focused DataModel **Edit**.
- No OS mouse/keyboard input, window rearrangement, camera/device-preview setting change, Save/Publish, rbxl writeback or Studio shutdown.
- Existing unsaved edits remain unsaved. No game implementation files are included in this audit commit.

Protected object roots were StarterGui, ReplicatedStorage.Assets and Workspace.GeneratedMap.TrainingArea; this is a scoped preservation check, not a claim that all engine-created internal objects are identical after Play. Screenshots were not retained. [Evidence.json](Evidence.json) contains only selected, sanitized observations, without account identifiers, forge tokens or test save records.

Suggested next grouping: clarify ④'s sale wording together with ⑥'s shared purchase text and its independent builders; retain ⑤ as a focused regression, not a new redesign. Handle ⑦ and ⑧ after choosing their evaluation/contact policies. Handle ⑨ through targeted asset authorization work separately. No fixes were made in this audit.
