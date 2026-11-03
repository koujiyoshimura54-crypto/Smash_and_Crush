# Battle Bag, Shop artwork and Limited asset audit — 2026-11-03

## Scope and result

Canonical open Y02 Studio: **PlaceId 126576845524886 / UniverseId 10765181857**. Starting Git HEAD/origin/main: `2107c67`. The current unsaved Studio was the implementation baseline.

Implemented the Lobby-only Battle Bag rule and scoped Shop artwork repair. The four warning IDs belong to **reference character shirts, not Limited Pets**. Three approval failures reproduced in the final isolated Play; one was not freshly reproduced. No verified substitute asset was found, so no asset was replaced, reuploaded, deleted or suppressed.

The user accepted the previous Pet UI/SE repairs and Japanese fallback-font resolution. Those features were not readjusted. `UISoundConfig.Added.Hover.Volume=0.15` and its other existing unsaved values remain exact. The prior request to change Hover to 1 is superseded. Egg tutorial remains deferred.

**No Shop pixel acceptance is claimed.** Screen capture did not return an image; the main comparison run recorded zero RenderStepped callbacks and ImageLabel.IsLoaded=false. Native state, GUI properties/rectangles and actual server mutations are reported separately below.

## Changed Full Paths

| Full Path | Change |
| --- | --- |
| `StarterGui.StrengthGui.RunInventoryHUDClient` | Hide inside either physical Lobby footprint; show everywhere outside. Remove Stage-floor, combat, health and count-loaded gating. Keep quantities read-only. |
| `ServerScriptService.Services.BattleBagLobbyBounds` (new Script) | Read the two actual TrainingArea floors and publish CFrame/Size as presentation metadata in `ReplicatedStorage.BattleBagLobbyBounds`. This survives Workspace streaming. No inventory/progress writes. |
| `StarterGui.StrengthGui.EssentialStudShopClient` | Shop-only icon Fit/layer/clear-slot setup for current and subsequently generated cards. |
| `StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.<card>.Icon / Icon1 / Icon2` | Apply the same scoped artwork properties to 17 currently authored image objects. Exact paths and before/after values are in Evidence.json. |

[ApplyShopProductArtworkProperties.luau](../../tools/ApplyShopProductArtworkProperties.luau) reproduces only the authored image-property delta. The runtime publisher is created as a Script in Edit; its bounds Folder is transient replicated presentation state created during Play.

Unchanged: `ReplicatedStorage.Modules.HUDLayout`, `InventoryPresentation`, `ResponsivePanels`, `StarterGui.StrengthGui.RunReturnClient`, all Pet/SE/tutorial logic, prices, unlock rules, purchases, receipts, and asset references.

## 1. Battle Bag

The former client accepted only Stage Floor/LevelFloor footprints and also required living/loaded state. This incorrectly excluded corridor gaps and all other non-Stage locations.

The new decision is **inside either Lobby → hidden; outside both → visible**. Both icon and count use the same result. Count/capacity remain server-owned; unavailable numbers use the existing dash placeholders rather than becoming a progression condition. Before a character location or initial bounds exist, the authored hidden state remains. There is no Stage, wall, Boss, combat, RunInventoryActive or health qualification.

Reused floor-footprint convention:

- `Workspace.GeneratedMap.TrainingArea.Floor`: center (274.5,0,10.5), size (237,8,149).
- `Workspace.World2Map.TrainingArea.Floor`: center (14.6200123,1,1935.47998), size (237,2,169).

Actual Egg, treadmill, RestockShop/Limited and World2 facility pivots fit these Lobby footprints. The old `Workspace.MergeToForge` is a separate legacy map, not the active Merge shop; the active World1 guide targets `Workspace.RestockShop.Area`. No map geometry was changed.

Streaming is enabled. Therefore the final client reads four replicated attributes: World1CFrame, World1Size, World2CFrame, World2Size. The small server publisher reads the real floors at startup and every 0.5s, writing only changed values. This avoids treating a streamed-out Lobby floor as a visibility condition and tracks actual floor edits without hardcoded coordinates. The client retains its existing 0.2s update cadence.

Native isolated checks:

- Both Worlds: Lobby center, training side, shop/Egg side and just inside the boundary hid both elements.
- Boundary +0.5 studs, corridor gap, wall area, Boss side and a point outside Stage floors showed both.
- Stage changes, IsFighting=false, RunInventoryActive=false and RunReturnBusy=true did not hide the bag outside Lobby.
- Prepared count 3/5 remained 3/5 when moving to Lobby; only visibility changed.
- A dead character still located outside Lobby retained the bag; respawn into World2 Lobby hid it. This matches the latest location-only rule.
- Existing WorldTravelRequest ReturnWorld1 and ToWorld2 routes moved to their real Lobby spawns and hid the bag. Existing server lifecycle resets remained unchanged.
- Final streaming regression removed both Floor instances **on the test client only**, then restored them. In each World, Lobby stayed hidden, boundary exit and a point 1,200 studs beyond the floor center stayed visible. Replicated values equaled the real server floor CFrames/Sizes. This is simulated stream removal, not a bandwidth/streaming benchmark.
- Icon remained **42×42**, text **36px**, gap **12px**. HUDLayout.BattleBagScale stays 1.5; no cumulative scaling or Back changes.

An initial unanchored World2 side probe was pushed back inside by collision, and a rapid World change preceded client replication. Those readings were not used as acceptance evidence. Repeated location probes used prepared positioning, a stabilization delay and the actual client root position.

## 2. Shop artwork

The comparison used the actual generated `PlayerGui.StrengthGui.ShopPanel`, not just button prices.

Findings:

- Secret/Starter pack Icon2 used Crop. Secret's rectangular image box was approximately 140.47×77.77 in the comparison run.
- Secret pack icons and NormalDumbbell5 Icon shared ZIndex 2 with Sunburst; normal featured cards used icon 3 over decoration 2.
- Item icons used Stretch and extended into the Title rectangle. Dumbbell artwork slightly overlapped the right-hand title region.
- StrengthGui uses Global ZIndexBehavior. ResponsivePanels retains ResponsiveOriginalZ and adds 200, so changing ZIndex alone would not reliably survive refresh.
- ImageRectOffset/ImageRectSize were zero. No atlas crop or alternate source image was needed.

Repair:

- Product icons only use ScaleType.Fit. Image IDs, image-rectangle settings, transparency, aspect constraints and all ClipsDescendants values are preserved.
- Set an icon layer above direct StudPattern/Sunburst and preserve the corresponding ResponsiveOriginalZ. Titles and purchase buttons remain above artwork.
- Keep existing card sizes, ordering, backgrounds, decoration, labels and purchase areas. Adjust only icon slots to clear titles, captions and buttons.
- Apply before normal card cloning and to subsequently added cards/icons/decorations. No every-frame repair monitor and no shared Pet/Inventory/HUD styling changes.

Native property and callback checks:

- **69 generated cards** passed icon containment, Fit, decoration-layer and title/purchase rectangle-separation checks.
- Normal panel measured 728.41×539.70; an isolated runtime drawing region with 420px available width produced a 395.78×293.24 panel. Studio device-preview settings were not changed.
- The same checks passed after scroll offset 800, close/reopen, responsive layer refresh and death/respawn. Original purchase/content image identities were retained.
- With memory-only data, the actual existing NORMAL_01 purchase callback/server path changed Win 10000 → 9995, granted one copy and equipped it. Repeated operation did not charge another copy. Item purchase then changed Win 9995 → 9920. These are current live prices, not a balance adjustment.
- Input was delivered to the existing native activation callbacks through a temporary recorder. It was not a physical mouse click; paid prompts were intercepted by the test provider, and no real payment occurred.
- Because rendering was inactive, the actual responsive refresh function was also invoked directly by the temporary probe. These are runtime geometry/property results, not screenshots or rendered-hover acceptance.

Remaining visual checks: full source-image visibility, pixel-level clipping/overlap, rendered scrolling/hover, native pointer behavior and narrow-width readability. Previous Pet/SE user acceptance is retained; it was not reclassified as newly tested here.

## 4. Warning IDs and Limited assets

Marketplace GetProductInfoAsync returned **AssetTypeId 1 (Image)** for all four. Names below are the API's reported names; metadata access does not establish runtime permission.

| ID / API name | Confirmed owner target | Actual reference Full Path / property | Current evidence and affected content |
| --- | --- | --- | --- |
| 95256658378010 — ゲストマイルストーン2[+] | User kie_ta, 2420065260 | `Workspace.Ungroup.Forsaken Characters.Survivors.Sentinals.Guest 1337.Milestones.Milestone II Guest 1337.Shirt.ShirtTemplate` | Approval failure reproduced in final Play. Shirt image of this reference rig; no Limited Pet reference. |
| 139190015780830 — ゲスト 1337 | User EsqueletinP, 5277511068 | `Workspace.Ungroup.Forsaken Characters.Survivors.Sentinals.Guest 1337.Milestones.Milestone I Guest 1337.Shirt.ShirtTemplate` and `Workspace.Ungroup.Forsaken Characters.Survivors.Sentinals.Guest 1337.Milestones.Guest 1337.Shirt.ShirtTemplate` | Approval failure reproduced in final Play. Two reference-rig shirts; no Limited Pet reference. |
| 82687933211372 — BSOD Builderman Shirt | Group Ufphoe's UGC, **35845669** (CreatorTargetId; returned Creator.Id was 8279978444) | `Workspace.Ungroup.Forsaken Characters.Survivors.Support.Builderman.Skins Builderman.BSOD.Shirt.ShirtTemplate` | Approval failure reproduced in final Play. Reference BSOD shirt; no Limited Pet reference. |
| 7221927873 — クジラを爆破する | User Sailor3550, 841528202 | `Workspace.Ungroup.Forsaken Characters.Survivors.Sentinals.Shedletsky.Skins Shedletsky.Whales.Shirt.ShirtTemplate` | Existing session/history logs show an approval failure. Not freshly reproduced in the final run; not marked resolved. Reference Whales shirt; no Limited Pet reference. |

All five properties still contain their original `http://www.roblox.com/asset/?id=...` strings. Searches covered current Source and relevant mesh, texture, SurfaceAppearance, GUI, clothing and effect properties. The four IDs were not found in Limited templates or their source code. No normal working SE reference was changed.

The first isolated preload attempt for these exact IDs did not finish and GetAssetFetchStatus remained None; it was not a success or failure result. The later final Play independently emitted **“Asset is not approved for the requester”** for the first three listed IDs. That wording alone does not distinguish a privacy permission issue from approval/moderation status. Pixel-level missing-shirt appearance was not captured.

### Purchased originals, clones and minimal next action

- Current Studio retains 180 purchased models under `Workspace.Stud Egg & Pet`. All **14 Limited templates / 153 mesh parts** matched the corresponding purchased source MeshId and TextureID/TextureId references, with zero differences.
- World1 uses `ReplicatedStorage.Assets.LimitedEgg01Pets`; World2 uses the seven configured models in `ReplicatedStorage.Assets.World2Pets`. Exact mapping is in Evidence.json.
- Candidate, hatch and follower paths resolve these through `ReplicatedStorage.Modules.Pet.model`, `LimitedPetViewport`, and the existing StandClient/HatchClient/PetFollowClient. The warning shirts are in a separate imported Forsaken reference tree and are not dependencies of those Limited templates.
- Native candidate generation produced seven ViewportFrames in each World. No paid roll/hatch was performed. Geometry presence does not prove every texture loaded; hatch/follower visual retesting was unnecessary without an asset change and remains unperformed.
- Scoped Y02 lookups covered Downloads, Documents/OneDrive, repository assets, stage_skip_work clues and Roblox_SavedArchives. No relevant purchase archive or original image for these four shirts was identified. The `Downloads\Game` path in an older record is absent on this Y02 and was not assumed to exist. Unrelated archives were not unpacked; there was no full-drive scan.
- No same-image usable replacement ID or exact original clothing image was established. Keep the existing references. **No asset change is warranted on Limited Pets.**

For the three still-failing images, the listed owners should first check their image's approval/moderation status and access permissions. If restricted access is the cause, an authorized owner/collaborator must grant this game **UniverseId 10765181857** access via the image's Creator Dashboard **Permissions → Experiences**. Metadata can remain readable while runtime access is denied. The same check applies to 7221927873 if its failure is reproduced. A moderation issue requires the owner's review route; changing to another guessed ID is not a fix. [Roblox asset privacy and game permissions](https://create.roblox.com/docs/projects/assets/privacy#to-games).

No permissions, uploads, purchase ownership, receipt, silhouette or Pet effect settings were changed. Warnings were not hidden.

## Cleanup and preservation

Three short native Play sessions used an in-memory DataStore/Marketplace/Badge provider. Temporary service-reference counts were 38, 38 and 37; each was restored by exact-source comparison after Stop. Fixtures and client-only probes were removed; no production persistence or real transaction occurred.

Verified the 465 initial Sources plus the new publisher, script Enabled states, 65,143 initial GUI/asset/reference objects and 89,238 captured properties against the baseline plus intentional deltas. No unexpected changes or temporary objects remained. Current Source export matches Git. The existing unrelated untracked report remains excluded.

Edit camera CFrame/Focus and HttpEnabled were unchanged. No OS input/window/device-preview/camera-setting command was issued. During a normal respawn the Studio execution tool logged its own camera-type guard reset; the starting CameraType was not captured, so no assertion about that field is made. No repair-related runtime error remained; one diagnostic comparison used a source catalogue unavailable during Play and was successfully rerun against Edit originals. The isolated fake Badge provider warning and unrelated asset warnings were not treated as new regressions.

Studio is **stopped, focused Edit and unsaved**. No Save/Publish, rbxl writeback or Studio exit. All three final Sources and the property reproducer compiled. No full-game regression, new tutorial or balance change was added.

[Detailed evidence and authored property changes](Evidence.json).
