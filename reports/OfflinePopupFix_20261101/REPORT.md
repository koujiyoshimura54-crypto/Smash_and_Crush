# Offline popup and integer pack quotes — 2026-11-01

Applied only the five requested changes to the current unsaved local-file Studio, starting from commit463b708 and current Studio reads. All six targeted Sources matched that commit at the start; current authored object properties were independently snapshotted and preserved. The owner reference `Downloads/オフライン報酬ポップアップ.png` was opened and inspected for its arm/glow, not used as a panel-sized background.

## Changed Full Paths

- `ReplicatedStorage.Config.StrengthHUDStyle`
- `ReplicatedStorage.Modules.StrengthHUDPresentation`
- `ReplicatedStorage.Modules.StrengthRewardUI`
- `StarterGui.StrengthGui.StrengthRewardClient`
- `ServerScriptService.Services.StrengthRewardState`
- `ServerScriptService.Services.StrengthRewardService`

Authored GUI changes are confined to contents of `StarterGui.StrengthGui.OfflineRewards`: Title, StrengthIcon, new StrengthHalo, Amount, Claim/Main and Double/Main/Price. No lower HUD placement/design/text-size changes were applied. The complete authored bottom-HUD property snapshot and the HUDLayout/AutoTap/Item/StrengthDisplay Sources are unchanged.

## Five changes

1. **Arm and halo:** Both fresh generation and restyling use the same existing yellow arm as the working Strength HUD, asset106106287008236, with ScaleType.Fit. The former donor shoe is no longer selected. A native GUI halo uses twelve transparent circular layers and sixteen fading yellow rays behind the arm. Its204×204 rectangle is separated from title/amount; the arm is192×192. No image upload or screenshot background.
2. **Offline text only:** Shared `Text.OfflineTitle` increased46→58 and `Text.OfflineAmount`43→60, both with black4px outlines and Fredoka One. The amount remains yellow. Internal title/amount rectangles were adjusted to fit; all lower-HUD font settings are unchanged. Native TextFits passed integer,125K,1.44M and999.99Qi strings.
3. **Claim buttons:** Existing positions/sizes and handlers retained. Claim is yellow-green; double is yellow-orange. Each uses a4px black inner outline. The old colored/purple backing is hidden and its visible gradient-stroke replacement is disabled by the shared stroke function. No purple frame remains visible.
4. **Integrated price:** Removed the purchased green mini-button visual and all regeneration calls. Reused existing Robux asset100116824861927 with a plain price label. Price is inactive/non-interactable below the one full-size Double.Button input. The existing product info query supplies the price (18 in this account's Play, not a hardcoded19). Product3724845103 and the original Prepare/Open/Claim logic remain.
5. **Integer pack quotes:** Server `StrengthRewardState.PackAmount(rate, seconds)` floors only the final product. StrengthRewardService uses it for new View offers and Prepare operations. New Pack intents also validate/finalize the supplied amount at the durable-state boundary. The existing pending-intent branch runs before this finalization, so previously promised fractions are preserved on resume and receipt. Receipt grant reads the saved amount without recalculation. No flooring was added to offline rewards, current balances, LevelProgress or Training.

The outer panel is unchanged:700×450, centered position(0.5,0.5), background transparency approximately0.22, background RGB22/26/35. No position/background/size setter was added to the offline restyling function. Existing outer border, close control and responsive panel scale remain. Claim/Double remain at(22,358)/(358,358),320×76.

Offline3600 seconds/5%, double3724845103, pack products3724835102/3724835678/3724836170, durations120/720/2400 and price lookup remain unchanged. Existing receipt identity/session/save protections remain.

## Focused validation

One memory-only native Play was used. Two temporary Studio-only storage/ordered-write guards were inserted into current PlayerDataService and removed by exact matching after Play. Its entire remaining Source matches the pre-test current-session hash. No real checkout, live receipt processing or production data write.

- 33 native state/progression assertions passed:240.9→240,1440.9→1440,4800.75→4800; integer inputs; saved quote equals receipt gain; duplicate receipt gain0; pre-existing240.9 intent resumes and grants240.9; fractional existing Strength10.25 and LevelProgress0.375 remain fractional; offline claim123.75 and additional double123.75 remain unchanged.
- Native service View fixture used the actual new service Source with isolated Data/Reference adapters. Rate2.0075 produced240/1445/4818; old pending240.9 remained240.9 even at a changed rate.
- Current formatter still displays1440 as1.44K and4800 as4.8K. Offline integer and large abbreviated text fit; title/price fit.
- Native GUI hit testing at price, double title and button center returned exactly the same `Double.Button` active input. No separate price handler was added.
- The production client callback body, with isolated remotes/product info and a test dispatcher in place of Activated, retained normal Claim and double3724845103. Two calls while Prepare was yielding produced exactly one Prepare and one Open. Missing reward blocked purchase; AutoTapEnabled was unchanged. This is a mock callback test, not a physical click or paid transaction.
- Repeated offline styling kept124 descendants stable and the arm asset matched the bottom HUD. Six final Sources compile and match the exported files.
- Before/after outer-panel properties and complete lower-HUD property snapshots match. HUDLayout, AutoTapClient, ItemEffectHUDClient and StrengthDisplay Sources are unchanged. No broad progression/respawn rerun was needed for these untouched paths.

`Verification.json` contains the results without player identifiers. An initial hit-test diagnostic incorrectly forwarded both results of string.gsub into table.insert; it was corrected in the probe and the native hit tests then passed. No related production runtime error was observed. Existing audio authorization warnings remain.

## Rendered evidence and limits

`Play.png` and `FinalPlay.jpg` are actual normal native Play captures with125K and1.44M test amounts. Native capture returned270×151. The arm/glow, enlarged white/yellow text, black claim outlines and integrated Robux price were visually inspected.

`PopupNative.png` is a detailed native GUI tile assembly of the same authored popup. A temporary isolated clone used UIScale1280/270 to compensate for capture downsampling; nine270×151 tiles were joined and cropped700×450 without image resizing. Y rounding is about0.12%. The transparent panel exposes a repeating game background and tiny Studio capture overlays in this assembled image: these are capture artifacts, not changes to the game map or popup background. The close button overhang is outside this detail crop. Use the normal Play images for the whole real composition.

No physical mouse/touch input, real Robux payment, production save, real mobile screen or full-resolution native viewport capture was performed. These are the remaining verification limits, not claims of live checkout certification. No camera, OS input, window/panel or display setting was changed.

## Final state

Play stopped; temporary runtime fixtures removed with Play and test Source insertions removed. Studio remains open in **unsaved Edit**, preserving prior edits and these changes. No Save/Publish, rbxl writeback or Studio closure. The rbxl SHA256 remains `1951C12EB639703BD516DD925983F63A54AC3A701BB2C0EA6B4810FCCB62D97A`. User manual Save/Publish is required. Unrelated checkout changes were not included.
