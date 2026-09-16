# Dumbbell Buy Button Seen Notifications — 2026-09-16

## Baseline and audit

- Baseline: `main` / `6a52d4d4ee18ddccb0eb86ccf9951735b22f6662`.
- The current tab notification already persisted seen item IDs in `InventoryNotificationSeen.Dumbbells` and marked every currently available Dumbbell as seen when the Dumbbells tab opened.
- The existing Buy-button badge used that same `Dumbbells` set. Consequently, opening the tab cleared Buy badges for cards below the visible scroll area.
- Historical implementation before commit `04e9c50` had per-button session badges, but it did not persist them and also cleared its pending set when the panel opened.
- Purchase eligibility is owned by `DumbbellService.PurchaseDumbbell`: valid Dumbbell definition, loaded and writable player data, not owned, valid positive `PriceWin`, valid integer Win balance, and sufficient Win.

## Final implementation

- `InventoryNotificationSeen.Dumbbells` remains the tab-seen set.
- `InventoryNotificationSeen.DumbbellBuy` is a new, separate item-ID set for Buy-button seen state. Missing data normalizes to an empty set, so existing saves remain compatible. It is cloned, merged, autosaved, saved on leave, and returned through the existing notification remotes.
- `DumbbellService` exposes the purchase eligibility already used by `PurchaseDumbbell`. `DumbbellController.GetInventoryState` returns that authoritative purchasable map to the client. The notification client no longer recreates the Win/price/ownership decision.
- A Buy badge is shown only when the server says the item is currently purchasable and its ID is absent from `DumbbellBuy`.
- Opening the Dumbbells tab marks current IDs only in `Dumbbells`; it does not touch `DumbbellBuy`.
- A Buy button becomes seen when the panel, page, list, and button are visible and the button's `AbsolutePosition` / `AbsoluteSize` rectangle intersects both the Dumbbell `ScrollingFrame` viewport and the root GUI screen rectangle.
- The visibility check runs after rendering and when `CanvasPosition`, viewport geometry, page visibility, panel visibility, or button geometry changes. Only intersecting IDs are sent to the existing `MarkSeen` path.
- Purchase, equip, item prices, Aura, Speed, and Items notification behavior are unchanged.

## Play verification

Testing used the isolated Studio store `PlayerData_v1_DumbbellBuySeenQA_20260916_02`. The temporary QA script and response instrumentation were removed, and `DataStoreConfig` was restored byte-for-byte before the final normal Play.

| Case | Result |
|---|---|
| A — Win 500 unlock | Tab badge appeared. Buy badges appeared for purchasable `NORMAL_01` through `NORMAL_05`; locked `NORMAL_06` and `NORMAL_07` did not notify. |
| B — Open tab | Tab badge disappeared. At `CanvasPosition.Y = 0`, visible `NORMAL_01`/`02` Buy badges became seen, while offscreen `NORMAL_03`/`04`/`05` remained unseen and visible as notifications when rendered below the viewport. |
| C — Scroll | At `CanvasPosition.Y = 450`, `NORMAL_03`/`04`/`05` entered the viewport and their Buy badges disappeared. |
| D — No purchase | Cases B/C marked Buy notifications seen without pressing Buy. |
| E — Rejoin | After a normal PlayerData save and rejoin, `DumbbellBuy` still contained `NORMAL_01` through `NORMAL_05`; their badges did not return. |
| F — Next unlock | Raising Win to 2,000 caused the tab badge and only the new `NORMAL_06` Buy badge to appear. Earlier IDs remained seen. |
| G — Owned item | Purchasing `NORMAL_06` through the canonical service added ownership and removed it from notification eligibility; no owned-item Buy notification remained. |

The measured list viewport was position `(436.519, 184.242)` and size `(377.330, 291.030)`. The first two buttons at `Y = 368.364` intersected it; the later rows at `Y = 607.424` and `Y = 846.485` did not until scrolling.

The final normal-store Play ran for 52.658 seconds after all QA code was removed. Game console results: Runtime Error `0`, Warning `0`, Infinite Yield `0`.

## Scope

The Lua source inventory remained at 395 containers. Exactly five existing sources changed; none were added or removed:

- `ServerScriptService.Services.PlayerDataService`
- `ReplicatedStorage.Modules.InventoryNotificationState`
- `ServerScriptService.Services.DumbbellService`
- `ServerScriptService.Systems.Controllers.DumbbellController`
- `StarterGui.StrengthGui.InventoryNotificationClient`

Final live Studio sources matched the exported files in `sources/`. `fingerprints_before.json`, `fingerprints_after.json`, `scope_comparison.json`, and `play_evidence.json` preserve the audit evidence. The temporary verifier source is retained in `verification/` as documentation only and is not present in the game tree.
