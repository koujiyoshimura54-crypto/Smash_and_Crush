# Pet inventory, Best Equip and Basic Egg — 2026-11-03

## Authority and scope

The current unsaved Y02 Studio (PlaceId **126576845524886**) was authoritative. The ten inspected entry-point Sources matched the latest three-Pet implementation at `df149ce`; Git was fast-forwarded before editing, and no Git Source was imported over Studio. Existing three-slot equipment, acquisition history, silhouettes, Item/Ore ordering, tutorials and unrelated work were retained.

## Changed Full Paths

| Full Path | Change |
|---|---|
| ReplicatedStorage.Modules.Pet | Numeric inventory ordering; shared per-Pet multiplier text; trusted top-three selection and atomic BestEquip operation. |
| ServerScriptService.Services.PetServer | Best Equip entry into the existing durable mutation boundary. |
| ServerScriptService.Services.EggServer | Accept BestEquip through the existing PetRequest remote, cooldown, receipt and generation checks. |
| ServerScriptService.Services.PlayerDataService | Validate BestEquip, keep existing persistence/session protection, return without mutation when already best. No save-schema change. |
| StarterPlayer.StarterPlayerScripts.Services.PetClient | Permanent card multiplier, dedicated equipment/header area, purchased Best Equip button, scoped HUD font/outline, numeric ordering and responsive inventory cards. |
| ReplicatedStorage.Modules.Config | Only Basic.wins **15 → 3** and PetFollow.side **2.5 → 3.0**. |
| Workspace.Eggs.Basic.Prize.Info | Edit-time sign Text **15 → 3**. Reproducible with `tools/SyncBasicEggPrice.luau`. Existing server/client label initialization also reads the same price definition. |

Runtime UI paths are under `Players.LocalPlayer.PlayerGui.ScreenGui.Menus.Inventory.Main`: `2PetsEquipInfo`, `PetBestEquip.Title/Button`, and `Items.<owned-copy-ID>.StrengthMultiplier`. Hover text is in the purchased `PetHover` clone. Shared asset templates are left intact so Pet Merge retains its original point/count presentation.

Inventory ordering compares actual StrengthPercent numerically, then species ID and individual ID. Equipment does not move a weak card ahead of a strong one. Best Equip prefers existing equipment at equal strength, preserves selected slots, fills empty slots, and selects only owned copies with a defined ability and available model. The client submits an action and existing request metadata, never a strength ranking or selected IDs. One durable operation publishes all three confirmed IDs. Immediate replay is acknowledged, stale revisions/generations are refused, rapid requests are throttled, and an already-best request produces no revision/save change.

The original `ItemsTab.EquipBest` material and ButtonClient supply appearance and audio. The request is deferred until activation callbacks finish, so disabling a pending button cannot suppress its existing click sound. No second sound owner or per-frame font monitor was added. Pet-only text uses StrengthHUDStyle.Font and its Price outline settings (Fredoka One, black 2px). Localization remains enabled. The two-line equipment label uses TextWrapped before TextScaled; setting TextWrapped=false had disabled scaling during the first verification and was corrected before delivery.

The list begins below the header, clips scrolling cards, and uses four columns at the normal measured width / three at narrower widths. The multiplier's bottom strip does not overlap its card title, image or equipment check. Pet Merge's construction path receives no multiplier/font/layout changes. Follow back distance, height, models, bob, movement and turning values are unchanged. The original additive multiplier remains **1 + sum(StrengthPercent)/100**.

## Verification and isolation

Two **solo Test** runs used StudioTestService.ExecutePlayModeAsync, not Server & Clients or multiplayer. All DataStoreService, MarketplaceService and BadgeService dependencies were temporarily redirected to the existing in-memory QA provider before Play. Product prompts were blocked/stubbed; no production data or real payment was used. Fixture seeds are prepared test states, not naturally earned progression.

| Check | Result and evidence class |
|---|---|
| Native server selection/transactions | **24 assertions passed**: descending numeric order, original Merge points order, one revision for top three, forged client ranking ignored, replay, throttle, already-best no-op, stale revision/view refusal, all three equipped-merge guards, manual unequip/replacement, equal-strength current-copy/slot preference, and 0/1/2 owned copies. Same-species distinct IDs were exercised. |
| Actual training | Configured Ninja +80%, Shark +60%, Crocodile +30% gave **×2.7**. Native StrengthManager.AddStrength(10) added **27** with other test bonuses cleared. No Pet effect definition or formula changed. |
| Persistence | Existing save path wrote equipment/discovery into the isolated store; JSON reload through Pet.NormalizeState retained both. This is memory-backed save/reload, not a production rejoin. |
| Native client button | Captured existing activation callbacks invoked the real PetRequest path: one business callback + one audio callback, **one Click.Played event**, three authoritative checkmarks, and total **×3.7** for +130/+80/+60. |
| UI geometry and fonts | At measured content widths **599.40px** and **370.41px** (390px test panel), actual generated labels used FredokaOne; header, button and ten cards reported TextFits. Header/list clearance was **10.54px / 12.63px**. Card sides were **125.87px / 107.42px**. Rectangle assertions excluded multiplier/title/image/check overlap. Long-name, different-strength, equal-strength and same-species cards were included. |
| Rebuild/scroll/death | Refresh/reopen and scrolling retained card order and header separation; the list clips descendants. Death/respawn retained three equipped IDs, correct labels and exactly one Best Equip button. Hover and card both reported Ninja **×1.8**. Material tiles had no StrengthMultiplier and retained their original font. |
| Basic transactions | Real EggServer Open1/Open3/Open8 consumed **3/9/24 Win**: **100 → 97 → 88 → 64**. Counts were 1/3/8. A balance of 2 rejected Open1 with NotEnoughWin and no revision/debit. Native candidate button text was **3/9/24 Win**; server sign was **3**. |
| Discovery/Limited | Native normal candidate properties distinguished acquired colored Dog/Grey Cat/Pink Bunny/Sheep/Bear from unseen black Camel/Slime. Explicit Limited 01/02 presentation creation produced seven white-tinted Viewports each. Other Egg prices, odds and effects are unchanged in Source. |
| Follow formation — simulation only | Invoking the captured existing follower update callback produced strongest center X≈0, others X≈−3/+3, rear Z≈4. After actual character movement and a test turn, callback-stepped positions remained within the existing 0.5-stud arrival tolerance. Death retained three distinct follower IDs. This is not natural RenderStepped animation acceptance. |

### Display limitation

This session's native client ran Heartbeat/Stepped but **zero RenderStepped events** during a two-second observation (120/121/0). The screenshot request produced no image and was terminated after waiting. Menu opening tweens and automatic follower rendering consequently did not progress in that client. No OS input, window manipulation, camera change, device preview change or rendering-setting workaround was used.

For geometry checks only, the isolated runtime inventory's UIScale was set to its completed-open value and its panel drawing width was varied. The existing follower callback was explicitly stepped only by the fixture. These are property/layout and simulation results. **Card readability, actual pixels, narrow-screen visual quality, visible hover text, natural opening transitions and visible stop/move/turn animation remain unverified.** No screenshot is claimed inspected or retained. Japanese fallback fonts and actual pointer/touch interaction remain unverified.

## Cleanup and reproducibility

Temporary native scripts, callback capture, service substitutions and simulated layout state were removed. All **465 initial Sources** matched either their exact initial text or one of the six intentional final Sources. Protected StarterGui/ReplicatedStorage.Assets parents, properties and attributes had **zero unexpected changes**. The Basic sign remained 3. No __PetQA instances remained. Edit camera CFrame/Focus and HttpEnabled matched the baseline.

Final six Sources and the archived fixtures/price-sync helper passed luau-compile; git diff --check passed. The fixtures are `tests/PetInventoryBestEquip.{server,client,Connections}.luau`. To repeat, install them temporarily with the existing `tests/World1Presentation/Memory.luau` provider (GetProductInfoAsync aliases its fake GetProductInfo), replace service acquisitions only for the isolated run, and capture the existing activation/follower callbacks. They are not installed in the delivered place.

Studio was verified **Edit, focused Edit** after EndTest. Solo Test arguments were verified at runtime; the toolbar dropdown's pixels were unavailable and are not claimed verified. All existing edits and this implementation remain **unsaved**. No Save, Publish, rbxl write, Studio close, production reset, tutorial addition or unrelated implementation was performed. The pre-existing untracked report `Visual_Templates_Secret_VIP_Green_20260917.md` was excluded from this change.
