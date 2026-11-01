# Bottom HUD reference implementation — 2026-11-01

Implemented the measured HUD in the current unsaved `MergeToForge_CurrentCloud.rbxl` Studio document. The two owner images were opened and inspected, not inferred from their filenames. The result preserves Auto Tap, dynamic data and the existing Strength reward transaction paths. Complete visual acceptance remains outstanding: existing icon artwork differs from the references, and native capture stopped responding before a complete final raster could be obtained.

## Scope and preservation

- Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`, connected local-file Studio only. The other Cloud Studio was not edited.
- Started from each current Studio Source. The current `StrengthDisplay` already differed from Git: its purchased progress-bar hierarchy and deferred attribute batching were retained before making the requested presentation changes.
- Original dirty checkout and unrelated files were preserved. Work recorded in the existing `SmashStrengthRewards` worktree, based on main `8efe5bcb88684b599979f22d8ea65900c73d2eb9`.
- No OS mouse/keyboard input, window/panel/display configuration or camera changes. No Studio Save/Publish, rbxl writeback, Studio shutdown or real payment.
- Final Play stopped. Two temporary memory-storage test insertions were removed by exact scoped matching; the remaining PlayerDataService Source matches its pre-test current-session hash. No `HUDReference*` fixture remains in the authored services.
- Local rbxl SHA256 remained `1951C12EB639703BD516DD925983F63A54AC3A701BB2C0EA6B4810FCCB62D97A`.

## Changed Full Paths

| Studio Full Path | Purpose |
|---|---|
| `ReplicatedStorage.Config.StrengthHUDStyle` | Shared editable font, text sizes/strokes, dimensions, borders, colors and image references |
| `ReplicatedStorage.Modules.StrengthHUDPresentation` | Idempotent native styling, gauges, clipped button art and measured layout |
| `ReplicatedStorage.Modules.HUDLayout` | Single placement authority, resize/menu/touch reservations and incremental invalidation |
| `ReplicatedStorage.Modules.StrengthRewardUI` | Restyle existing objects as well as fresh builds; reuse purchased popup controls |
| `StarterGui.StrengthGui.StrengthDisplay` | Current Strength and actual LevelProgress/requirement display |
| `StarterGui.StrengthGui.StrengthRewardClient` | HP lifecycle, pack quote formatting and official price integration |
| `StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient` | Keep equipment updates; delegate placement to HUDLayout |
| `StarterPlayer.StarterPlayerScripts.UI.AutoTapClient` | Keep state/input behavior; delegate placement to HUDLayout |

Authored GUI changes are under `StarterGui.StrengthGui.StrengthLevelHUD` (ItemEffectHUD, PlayerHealth, StrengthValueContainer, LevelPanel and StrengthPacks) and `StarterGui.StrengthGui.OfflineRewards`. `NativeGUI.json` records final relevant properties and assets. The Sources reproduce the style on existing/fresh GUI creation; they do not depend on a screenshot background. Old gauge labels remain hidden compatibility objects rather than duplicate active displays.

## Measurement and editable settings

References copied unchanged into this directory:

- `ReferenceInitial.png`: 三色購入ボタンと大きな腕アイコン.png, **1676 × 938**.
- `ReferenceHalf.png`: レベル50の半分進行UI.png, **1677 × 938**. Its additional one-pixel width was not stretched away.

The design coordinate system is 1676 × 938. Absolute target rectangles below are reproduced by the native geometry fixture, with no safe-area inset in the reference canvas. Real ScreenGui layout includes its native inset and uses a uniform scale.

| Element | X | Y | Width | Height |
|---|---:|---:|---:|---:|
| Complete bottom group | 408 | 612 | 876 | 294 |
| Item row | 482 | 612 | 728 | 60 |
| Red HP bar (heart extends left) | 476 | 684 | 336 | 52 |
| Strength container (arm and text) | 838 | 663 | 446 | 84 |
| Level gauge | 408 | 749 | 876 | 66 |
| Purchase row | 408 | 828 | 876 | 78 |
| Auto Tap, intentional addition | 1296 | 749 | 88 | 66 |

Purchase cards are 287 / 286 / 287 pixels wide, separated by 8 pixels; bottom margin 32 pixels. Their measured height is 78 pixels, with no further 20% reduction. Gauge-to-purchase gap is 13 pixels. Gauge/card borders are 5 pixels; level/HP/card corner radii are 17/12/5 pixels. The HP bar is short and follows the reference offset; its heart is 70 pixels. The Strength arm is 96 pixels and card arms are 100 pixels, clipped within the cards. The item icon slots are 72/66/76 pixels with positions adjusted for each existing asset's transparent padding.

`StrengthHUDStyle.Font` is `Enum.Font.FredokaOne`. `Text` contains role-specific native TextSize and black contextual stroke thickness. Final HUD sizes are Item31, HP41, Strength57 (minimum48), Level54, Progress48, Pack55. Outlines are 3.5/3.5/4.5/4/4/5 pixels respectively. White glyph height, not nominal TextSize alone, guided the adjustments. Measured reference white glyph heights were approximately 23/28/48/32/34/33 pixels for these roles; Roblox's Fredoka contours and width do not exactly reproduce the reference lettering. Text is not globally scaled to fit large values. Pack abbreviations preserve three significant figures, including 1.44K; 999Qi remains the same TextSize55.

`Geometry`, `Border`, `Colors`, `Assets` and `Offline` centralize the main dimensions/gaps, outlines, gradients, image geometry and popup rectangles. Editing these does not alter unrelated UI fonts. Offline title/amount/claim/double/price/close sizes are 46/43/38/32/25/44, with black outlines. Existing English, yellow amount, panel, buttons and icons are retained. Cloned claim title anchors and close text height were corrected to prevent clipping after the font change.

The level fill clips a full-width yellow-to-orange field against the dark remainder. Zero progress hides the fill; half progress fills exactly half of the inner area. Display uses `LevelProgress / LevelRequirements.GetRequiredStrength(level)` and does not project cumulative Strength. At maximum level the right side retains the existing MAX convention. No level requirements changed.

## Existing assets and behavior

| Asset | ID / source | Use |
|---|---|---|
| Owned yellow arm | `106106287008236`, also used by an existing treadmill billboard | Strength total and three card backgrounds |
| Existing heart | `79503513671021` | HP heart, final red tint configured separately |
| Purchased embossed squares | `97016358865650`, existing Shop card StudPattern | One 128px cell of its 512px 4×4 texture; 32px image slots, 53px repeat spacing |
| Purchased offline controls | `StarterGui.ScreenGui.Menus.OfflineEarnings` | Existing popup claim/close shapes |
| Purchased Robux price | `StarterGui.ScreenGui.Menus.RestockShop.Main.Common.BuyRobux` via HUDLayout.PurchaseButton | Offline double price, with shared font |

The previously used `87852658984573` image was inspected and is a shoe; the three pack cards and current Strength now use the existing owned yellow arm. The offline popup's pre-existing icon is deliberately retained under this request's instruction to preserve its icons. It still differs from a Strength-arm illustration; it was not silently replaced as part of a font-only popup change.

The three pack cards have one full-card purchase target, no green price strip, secondary button or explanation. Official client product prices are still fetched and gate purchase availability; native checkout displays them. Offline double still displays the fetched Robux price. This Play account returned18/90/270 for the packs and18 for double, rather than the reference base prices19/99/299/19. Values are not hardcoded to base prices.

Existing server Prepare/Open calls remain authoritative, and the presented amount is updated to the durable server quote before native checkout opens. Product IDs remain3724835102/3724835678/3724836170; durations120/720/2400. Offline config remains3600 seconds,0.05 efficiency, double3724845103. No receipt, reward, session or production persistence Source was changed by this HUD task.

Auto Tap remains at the right of the level gauge, with its actual remote, ON/OFF state and manual-input exclusion behavior. Its visible/touch target is reserved separately from the purchase row; compact layouts keep a minimum56px Auto Tap target. Art Frames are inactive. Repeated builds reuse objects and press connections; ItemEffectHUDClient no longer writes placement every RenderStepped. HUDLayout retains its existing dirty-layout loop rather than adding a per-frame full-GUI scan.

## Native validation and evidence

Four focused local Plays used memory-only PlayerDataService access and suppressed ordered-store writes. Test fixtures used native Scripts/LocalScripts where ordinary module contexts were required. Production saved data was not changed. Source compilation is reported separately from visual/runtime checks.

| Check | Observation |
|---|---|
| Initial values | Actual runtime offers +240 / +1.44K / +4.8K; zero level fill |
| Half progress | Isolated Lv50, actual requirement200010, progress100005 produced100K / 200K and fill0.5; Strength1.12M |
| HP | Native Humanoid damage, healing, zero/death and respawn reached100/100; one HP/purchase/popup/AutoTap root after respawn |
| Equipment effects | Actual isolated equipment payload updated +150STR / +50%DMG / +2Tier and pack quotes; changing to Common gave +1STR / +5%DMG / +0.25Tier |
| Large digits | 999999999999 displayed1T; isolated999Qi and +999Qi had no measured text clipping and pack font remained55 |
| Auto Tap | Existing native remote toggled ON → OFF → ON with matching label/state |
| Purchase callbacks | Production client handlers with mock Marketplace/remotes prepared/opened the correct three products once each, displayed the returned quantity before Open, and did not alter AutoTapEnabled |
| Offline callbacks | Mock close retained dismissal for the same reward ID, a new reward reopened, Claim used the normal request, and double targeted3724845103 |
| Input separation | Earlier Play native GetGuiObjectsAtPosition at pack centers resolved the relevant Purchase and no AutoTap target |
| Rebuild | Fresh and repeated build reused roots;209 descendants stable; an injected old font was repaired; HP fill present |
| Narrow layouts | Native isolated360×640 and640×360 canvases, plus representative touch/menu blocks: no target text clipping or purchase/AutoTap overlap; AutoTap ≥56px |
| Final popup | Title, amount, both claim labels, close and official Robux price all FredokaOne, TextFits true |
| Final Source | All8 compile and match exported Sources; PlayerDataService equals pre-test current Source; no authored test fixtures |

`Verification.json`, `GeometryCheck.luau` and `NativeGUI.json` retain machine-readable geometry, builder, final font/property and cleanup evidence. No user identifiers or saved player records are included. Relevant HUD runtime errors were not observed; existing audio authorization warnings remain (72 in the last console sample).

These are not real Robux transactions, receipt-processing regressions, production save verification or physical mouse/touch tests. Backend checks from the preceding Strength-reward delivery were not rerun for unchanged server logic.

## Rendered comparison and remaining differences

`Comparison-initial.png` and `Comparison-half.png` compare original reference crops with an actual native GUI rendering pass at approximately one source pixel per output pixel. `BeforeMCP.jpg` and `InitialPlay.png` retain the small normal Play captures. Auto Tap, map background, dynamic data and existing icon artwork are explicitly intentional differences; they are not erased from comparisons.

Capture limitations and method:

1. Native Studio captures returned only270×151 despite the1280×715 viewport. CaptureService also returned this resolution. A read-only window capture was black. No display setting or window was changed to force a larger image.
2. A temporary, isolated native GUI canvas1676×938 used the production presentation code. Scaling its rendering by1280/270 and moving only that fixture through eight crops yielded270×151 native tiles. The capture downsample and the fixture scale cancel in X; height rounding introduces about0.12% error (under0.4px across302px). This is not claimed as a full live1676×938 viewport screenshot.
3. Tiles were joined without image resampling. `compare.py` crops the reference at(400,610),1080×302 and makes the parallel image. The tiny repeated Studio overlay is capture noise, not an authored GUI element.
4. The complete images show the comparison pass before the last item-size, single-cell stud-pattern and heart-tint refinements. Four later upper-row tiles are retained in `FinalPartial`, clearly labeled; older upper tiles were recovered directly from their already assembled native image without resampling so the complete pass is internally consistent.
5. Native screen_capture subsequently hung, and CaptureService callbacks stopped completing, including after a Play restart. The final Play also returned empty GUI hit-test results for all sampled screen controls. Earlier successful hit tests are retained as earlier evidence, not presented as a final raster/input pass.

The exact complete final rendered result is therefore **unverified**. Final item/stud/tint Source and native property application were verified; a complete final normal/half/narrow rendered image was not obtainable. Existing arm, heart and equipment artwork has different shapes from the references; the heart remains faceted, and Fredoka glyph widths/stroke contours differ. Exact reference glyph/artwork identity is not claimed. Narrow-screen tests verified native geometry/TextBounds rather than a physical mobile display. Real pointer/touch activation and the final popup's full-resolution raster also remain unverified.

## Final state

The attempted full-string restoration of temporary PlayerDataService testing was rejected by automatic approval review because it could overwrite current unsaved edits. It was not performed. Restoration succeeded using only the two exact test insertions, followed by the original current-session hash check; no confirmation remains pending.

Studio is left open in Edit with the current changes **unsaved**. User manual Save/Publish is required. Git contains Sources, configuration/asset references, the requested comparison images and this English work record; it is not a saved rbxl replacement.
