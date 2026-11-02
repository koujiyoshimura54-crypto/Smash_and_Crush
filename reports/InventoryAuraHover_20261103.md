# Inventory visibility, Aura rendering and hover audio — 2026-11-03

Applied to the current unsaved canonical Studio (PlaceId **126576845524886**, UniverseId **10765181857**), starting from Git **67907c0**. All six edited Sources matched their repository exports before this task. Changes were applied as localized live edits; no old place or full Git Source was imported.

## Results and causes

### World2 dumbbells

The previous client lock exempted owned/equipped W2 items and still generated visible locked cards. The list now follows the existing server arrival mirror **World2Visited**, with an additional successful inventory-state load requirement. This matches DumbbellService's existing PlayerDataService.HasReachedWorld2 purchase gate. HighestUnlockedWorld alone and CurrentWorld are not substituted for arrival.

Cards start hidden before parenting, then become visible only after authoritative arrival and loaded inventory state. UIGridLayout excludes the hidden cards. Hidden cards are inactive/non-interactable, their selected paint/state is cleared, and activation rechecks the same gate. Ownership, equipment, bonuses, purchasing and persistence are unchanged. The existing Studio arrival-preview reset remains separate from production's permanent saved World2Visited.

Native isolated results: 12 W1 / 0 W2 while locked, including a prepared owned W2_NORMAL_01 count of 2; every W2 creation observation was hidden. After server MarkWorld2Reached: 12 W1 / 12 W2. Returning the prepared CurrentWorld to 1 retained all 12 W2 cards. Actual equip of W2_NORMAL_01 succeeded. Artificially removing arrival while that item remained owned/equipped hid all W2 cards, cleared selection and left zero interactive hidden cards; the saved equipment/count were retained. Restored arrival survived real death/respawn. World changes here were prepared server state, not a new gate-travel/persistence regression.

### Aura font: already applied; Japanese uses fallback glyphs

Opened the actual Inventory Aura tab in native Play and inspected screenshots, not just FontFace properties. Actual visible text paths under
`Players.<LocalPlayer>.PlayerGui.StrengthGui.InventoryPanel.Content.Aura.AuraList.<AuraId>AuraCard` are:

- `AuraName`
- `StrengthBonus`
- `BuyButton.PurchasedButtonVisual.Main.Amount` for purchase price / Equip / Equipped
- `BuyButton.Label` remains the underlying text source; it is suppressed where the purchased visual renders.

All those renderers already use **ReplicatedStorage.Config.StrengthHUDStyle.Font = FredokaOne** through the existing Aura binding and HUDLayout helper. No competing visible Aura copy or legacy English-name label was found covering this page. The top tab's purchased label intentionally remains GothamSSm, outside scope.

The screenshots show Japanese names/effects and equipment labels in a different, thinner glyph style, while Latin/digits use Fredoka. Directly parsed the active Studio installation's `content/fonts/FredokaOne-Regular.ttf` cmap (version-7062aec9dbe74b14; family JSON declares its Regular face): **228 mapped codepoints, required Latin/digits present, zero Hiragana, zero Katakana, zero CJK ideographs**. A temporary same-Fredoka text probe rendered Latin and Japanese side by side and confirmed the visible difference. This establishes missing Japanese glyphs/fallback, not a missing FontFace assignment. The engine's particular fallback family was not identified.

**No additional font monitor, English conversion, localization disable or alternative font was introduced.** The existing common-font configuration and Japanese display are retained as directed. Reassigning Fredoka cannot give it Japanese glyphs. This is a diagnosed rendering limit, not a claim that Japanese now visually matches Fredoka.

### One currency price per Aura purchase

The original `Price.Amount` and `Price.CurrencyIcon` were visible above the same price in PurchasedButtonVisual. For Win/GamePass cards, the existing Price container is now hidden and non-active on every render. Its Amount and price-source metadata remain intact for asynchronous lookup and existing purchase rendering. Entitlement VIP/PACK descriptors are not duplicate Win/Robux prices and remain unchanged.

Native screen inspection also reproduced an existing startup bug: the purchased visual could cache approximately **7 × 45 local units** from an early 1-pixel viewport, leaving a thin line instead of a readable price. HUDLayout now exposes its existing resize function as RefitPurchaseButton; only Aura's render calls it. It recalculates the original donor ratio and existing control size, without changing card/control placement, dimensions, colors or font sizes. Normal measured visual width then returned to about176 local units.

Before/after screenshots: the duplicated upper Trophy+30 and lower button30 became just the lower button30; Japanese name and Strength effect remained. Red showed the existing Robux symbol and the isolated asynchronous price **219** only inside its button. Normal 1280×662 GUI region and an isolated 540-pixel available-width region were inspected, including equipped Japanese text. Price/name/effect/button TextFits passed; no new clipping or price overlap was seen in the inspected rows. The narrow check uses an in-memory panel reserve, not camera/device-preview changes or a physical-device test.

Actual Pink purchase through the existing native activation/Remote reduced Win **1,000,000 → 999,970**, granted/equipped Pink, and toggled Equipped → Equip → Equipped correctly. Old Price stayed hidden through pending/fetched prices, purchase, equip/unequip, reopen and death/respawn. Robux price219 was mocked; no checkout occurred.

### Unified hover; silent non-interactive UI

All existing hover owners now use UIFeedback.Hover and the same live **SoundService.UI.Hover** object. Removed Added.Hover's private0.22 volume multiplier. Volume, source ID, speed, SoundGroup and muting therefore come directly from the existing Sound. Current Volume **0.75**, speed1, ID **96375954366615**, no assigned SoundGroup.

A weak entry latch and deferred deepest-target selection suppress repeated enter callbacks and parent/child duplicates; the existing0.09-second rate limit remains. One shared Sound is stopped/restarted rather than stacking hover clones. Native MouseLeave releases the latch. Existing owners/markers prevent the generic binder duplicating their SE.

Following the additional user instruction, existing purchase/legacy click handlers also require the same visible, Active, Interactable condition. Non-interactive/hidden UI does not emit hover/click. Click source/volume, success sounds, Error refusals and Notification level-up settings are unchanged.

Measured native Sound.Played events from actual purchase/menu/tab callbacks:

| Source Hover.Volume | Purchase | Menu | Tab |
|---|---|---|---|
| 0.75 | 1 event, 0.75 | 1 event, 0.75 | 1 event, 0.75 |
| 0.30 | 1 event, 0.30 | 1 event, 0.30 | 1 event, 0.30 |
| 0 | 1 muted event | 1 muted event | 1 muted event |

Repeated enter without leave did not add events; nested parent/child produced1; touch-mode input produced0. Disabled purchase hover+click produced0. The existing ButtonClient.attach hover path on an isolated control used the same source/volume, and its disabled test emitted0. Reopen and real death/respawn retained the same handler counts and one playback per tested entry. StrengthGui's existing ResetOnSpawn=false was retained: this verifies survival of that real lifecycle, not forced recreation of the entire ScreenGui. Dynamically created/removed controls were separately exercised.

Hover.Volume was restored to **0.75**. Source SoundGroup remained nil throughout; assigned-group/mute behavior is preserved by playing that exact Sound rather than a stale clone. **Playback/volume/counts were measured; actual listening was not performed.** Input was programmatic native callbacks with a test mouse-input classification, not physical cursor control.

## Changed Full Paths

| Full Path | Change |
|---|---|
| StarterGui.StrengthGui.InventoryPanelClient | Loaded permanent-arrival visibility; hidden interaction/selection cleanup |
| StarterGui.StrengthGui.AuraInventoryClient | Hide old Win/Robux Price; refit existing purchased visual on render |
| ReplicatedStorage.Modules.HUDLayout | Shared hover route, disabled click guard, reusable existing resize entry |
| ReplicatedStorage.Modules.UIFeedback | Shared-source hover, entry/parent-child suppression, interaction predicate |
| ReplicatedStorage.Config.UISoundConfig | Remove independent hover volume/speed multipliers |
| StarterPlayer.StarterPlayerScripts.Services.ButtonClient | Shared hover and interaction-gated existing click |

InventoryPresentation and StrengthHUDStyle are unchanged. Inventory tabs/Item/Speed/Merge font Sources are unchanged. No Boss, Item set/Best Equip, rewards, equipment balance, save schema or Receipt changes.

## Isolation, fixtures and final state

Fixtures under tests/InventoryAuraHover.* are temporary native observers and inputs. They require __UI4QAMemory and the __UI4QAConnections module, with DataStore/Badge/Marketplace acquisitions redirected only during verification. The input fixture registers existing MouseEnter/MouseLeave/Activated callbacks and ResponsivePanels activation callbacks; it does not synthesize OS input. PriceReady releases the mock asynchronous lookup at219. Only the UI-input-type read is replaced with the fixture's mouse/touch classification.

A first verification pass exposed SetInventoryWorldLock(false) re-enabling hidden card input and the early-viewport Aura visual; both were fixed. The first hover counter could only observe the initial Played event when Play was called on an already-playing source; the final shared stop/restart produces one measurable playback per accepted entry without overlapping clones. Those earlier observations are not presented as the final passing results.

All **42 temporary Source substitutions** were restored and **5 Edit helper roots** removed. Cleanup verified all **465 production Sources/Enabled states** against the intended post-change baseline and preserved **74 SoundIds**. Final sources compile and repository exports match the live Edit Sources. Focused final Play output showed no new runtime error/infinite yield from the edited paths. Temporary screenshots were inspected without filesystem retention or Git inclusion.

Canonical Studio is **Edit with existing and new edits unsaved**. No Save/Publish, rbxl writeback, Studio shutdown, OS input, camera/window/device-preview changes, real payment or production data writes.

Remaining limits: Japanese cannot render in Fredoka itself; fallback family unidentified. No listening, physical-input/mobile-device acceptance, real checkout or production save/rejoin validation. Only representative Aura rows and states were inspected, not every entitlement/locale.
